library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlador_semaforo is
    generic (
        N_PRE      : integer; --Ancho de bits del prescaler (divisor de frecuencia).
        C_PRE      : unsigned(N_PRE-1 downto 0); --Valor de cuenta del prescaler (carga).
        N_TIMER    : integer; --Ancho de bits del contador principal (timer).
        T_VERDE    : integer; --Tiempo luz verde
        T_AMARILLO : integer; --Tiempo luz amarillo
        T_PEATON   : integer); --Tiempo de cruce peaton
    port (
        clk : in std_logic;
        nreset : in std_logic;

        --solicitudes
        solicitud_peaton_a : in std_logic; --pulsador peaton a
        solicitud_peaton_b : in std_logic; --pulsador peaton b
        solicitud_emergencia_a : in std_logic; --detector de emergencia a
        solicitud_emergencia_b : in std_logic; --detector de emergencia b

        --confirmaciones
        confirmacion_peaton_a : out std_logic; --direccion a en modo cruce peaton
        confirmacion_peaton_b : out std_logic; --direccion b en modo cruce peaton
        confirmacion_emergencia_a : out std_logic; --direccion a modo emergencia
        confirmacion_emergencia_b : out std_logic; --direccion b modo emergencia

        transito_a : out std_logic_vector (1 downto 0); --control luz semaforo direccion a
        transito_b : out std_logic_vector (1 downto 0); --control luz semaforo direccion b
        peaton_a : out std_logic; --control semaforo peaton a
        peaton_b : out std_logic); --control semaforo peaton b
        
end controlador_semaforo;

architecture arch of controlador_semaforo is

type estado_t is(
VERDE_A, --calle A verde
AMARILLO_A, -- calle a amarillo
VERDE_B, --calle B verde
AMARILLO_B, --calle A amarillo
EMERGENCIA_A_T, --transicion verde A a amarillo A para dar lugar emergencia B (verde calle B) 
EMERGENCIA_B_T, --transicion verde B a amarillo B para dar lugar emergencia A (verde calle A)
EMERGENCIA_A_M, --mantiene A en verde
EMERGENCIA_B_M --mantiene B en verde
);

signal estado_actual, estado_siguiente: estado_t;
signal carga_timer: integer; --cuenta que se carga en el temporizador
signal timer_t_out: std_logic; --señal generada por temporizador al final de la cuenta
signal hab_timer : std_logic;

--Señales para almacenar las solicitudes peatonales
signal m_peaton_a, m_peaton_b: std_logic := '0';--guarda el pulsador peaton
signal peaton_a_det, peaton_b_det: std_logic := '0'; --detecta el pulsador peaton
begin

--PRESCALER----------------------------------------------------
U_PRESCALER: entity work.prescaler
    generic map (
        N => N_PRE
    )
    port map (
        nreset  => nreset,
        clk     => clk,
        preload => std_logic_vector(C_PRE), 
        tc      => hab_timer
    );

--TEMPORIZADOR-------------------------------------------------
U_TIMER: entity work.temporizador
    generic map(
      N => N_TIMER  
    )
    port map(
      clk   => clk,
      hab   => hab_timer,
      reset => not nreset,  --reset es activo en '0'
      P     => std_logic_vector(to_unsigned(carga_timer, N_TIMER)),
      Z     => timer_t_out,
      T     => open --T no se usa, queda abierta
    );
---------------------------------------------------------------

process (clk, nreset) is
begin

--limpia memoria cuando confirma
if nreset = '0' then
  m_peaton_a  <= '0';
  m_peaton_b  <= '0';
  peaton_a_det <= '0';
  peaton_b_det <= '0';


elsif rising_edge(clk) then
        --peaton a
        if solicitud_peaton_a='1' and peaton_a_det='0' then
            m_peaton_a <= '1';
        end if;
        peaton_a_det <= solicitud_peaton_a;

        --peaton b
        if solicitud_peaton_b='1' and peaton_b_det='0' then
            m_peaton_b <= '1';
        end if;
        peaton_b_det <= solicitud_peaton_b;

        --Limpia memoria de solicitud peaton cuando termina su verde
        if estado_actual = AMARILLO_A or estado_actual = AMARILLO_B or 
        estado_actual = EMERGENCIA_A_M or estado_actual = EMERGENCIA_B_M then
            m_peaton_a <= '0';
            m_peaton_b <= '0';
        end if;
           
    end if ;

end process;

-- Logica de cambio de estado---------------------------------
process (clk, nreset) is
    begin
        if nreset = '0' then
        estado_actual <= VERDE_A; --establezco inicio en verde direccion A
    elsif rising_edge(clk) then
        estado_actual <= estado_siguiente;
        end if;
    end process;
--Logica de transicion-----------------------------------------
--PRIORIDADES: 1° emergencia, 2°peaton, 3° transicion normal (autos)

--proceso para determinar el estado siguiente y el tiempo de cuenta
process(estado_actual, timer_t_out, solicitud_emergencia_a, solicitud_emergencia_b, m_peaton_a, m_peaton_b) is
begin
    estado_siguiente <= estado_actual; --se queda en el mismo estado
    carga_timer <= T_VERDE; --Asigno tiempo verde

    case estado_actual is
    
        --ESTADOS NORMALES Y PEATONALES (CALLE A)
        when VERDE_A => 
            --si hay emergencia en b y no hay solicitud peaton a, transicion inmediata
            if solicitud_emergencia_b = '1' and m_peaton_a ='0' then
                estado_siguiente <= EMERGENCIA_A_T; --transiciona a B
            elsif timer_t_out='1' then
                estado_siguiente <= AMARILLO_A;
                carga_timer <= T_AMARILLO;
            else
            --si se pide peaton a, mantener verde
                if m_peaton_a = '1' then
                    carga_timer <= T_PEATON;
                else
                carga_timer <= T_VERDE;
                end if;
            end if;

        when AMARILLO_A =>
            carga_timer <= T_AMARILLO;
            if timer_t_out = '1' then
                
            --si hay emergencia b inactiva no confirmada, ir a estado de transicion (pasa al estado Verde B)
            if solicitud_emergencia_b ='1' then
                estado_siguiente <= EMERGENCIA_B_M;
                carga_timer <= 0;
                
                else
                    estado_siguiente <= VERDE_B;
                    carga_timer <= T_VERDE;
                end if;
            end if ; 
        
        --ESTADOS NORMALES Y PEATONALES (CALLE B)
        when VERDE_B =>
            --si hay emergencia en a sin solicitud peaton b, hay trancision 
            if solicitud_emergencia_a = '1' and m_peaton_b ='0' then
                estado_siguiente <= EMERGENCIA_B_T;
                carga_timer <= T_AMARILLO;
            elsif timer_t_out = '1' then
                estado_siguiente <= AMARILLO_B;
                carga_timer <= T_AMARILLO;
            else
                --si se pide peaton b, mantiene verde
                if m_peaton_b = '1' then
                    carga_timer <= T_PEATON;
                else
                    carga_timer <= T_VERDE;
                end if ;
                                
            end if ;
        
        when AMARILLO_B =>
            carga_timer <= T_AMARILLO;
            if timer_t_out = '1' then
                --si hay solicitud de emergencia a, inactiva no confirmada, ir a estado de transicion (pasa al estado verde A)
                if solicitud_emergencia_a = '1' then
                    estado_siguiente <= EMERGENCIA_A_M;
                    carga_timer <= 0;
                    else
                        estado_siguiente <= VERDE_A;
                        carga_timer <= T_VERDE;
                                        
                end if ;    
            end if ;
    
        --FASES de EMERGENCIA
        when EMERGENCIA_B_T => --calle B esta verde, se le fuerza amarillo
            carga_timer <= T_AMARILLO;
            if timer_t_out = '1' then
                estado_siguiente <= EMERGENCIA_A_M;
                carga_timer <= 0; --mantiene hasta q la emergencia se desactive
                
            end if ;
        when EMERGENCIA_A_M => --calle A en verde por emergencia (bloquea B)
            carga_timer <= 0;
            if solicitud_emergencia_a = '0' then
                estado_siguiente <= AMARILLO_A;
                carga_timer <= T_AMARILLO;
            end if ;

        when EMERGENCIA_A_T => --calle A esta verde, se le fuerza amarillo
            carga_timer <= T_AMARILLO;
            if timer_t_out = '1' then
                estado_siguiente <= EMERGENCIA_B_M;
                carga_timer <= 0;                
            end if ;
        
        when EMERGENCIA_B_M => --Calle B en verde por emergencia (Bloquea A)
            carga_timer <= 0;
            if solicitud_emergencia_b = '0' then
                estado_siguiente <= AMARILLO_B;
                carga_timer <= T_AMARILLO;
            end if ;      
    end case ;
end process;
----------------------------------------------
-- Logica de salida (luces y confirmaciones)
-- Verde = "00", Amarillo = "01" , Rojo = "10"

process(estado_actual, solicitud_emergencia_a, solicitud_emergencia_b, m_peaton_a, m_peaton_b) is
begin

        --resetear todas las salidas a un valor seguro
    transito_a <= "10"; --rojo
    peaton_a <= '0'; --apagado
    transito_b <="10";--rojo
    peaton_b <= '0'; --apagado
    confirmacion_emergencia_a <= '0';
    confirmacion_emergencia_b <= '0';
    confirmacion_peaton_a <= '0';
    confirmacion_peaton_b <= '0';

    case estado_actual is
    
        when VERDE_A => 
            transito_a <= "00"; --verde
            transito_b <= "10"; --rojo
            confirmacion_peaton_a <= m_peaton_a;--confirma que esta modo peaton
            peaton_b <= '1'; --peaton B puede cruzar
    
        when AMARILLO_A =>
            transito_a <= "01";--amarillo
            transito_b <= "10";--rojo
            peaton_a <= '1';

        when VERDE_B =>
            transito_b <= "00";--verde
            transito_a <= "10";--rojo
            confirmacion_peaton_b <= m_peaton_b;--confirma que esta modo peaton
            peaton_a <= '1';

        when AMARILLO_B =>
            transito_b <= "01";--amarillo
            transito_a <= "10";--rojo
            peaton_a <= '1';

        when EMERGENCIA_A_T =>
            transito_a <= "10";--rojo
            transito_b <= "01";--amarillo(forzado)

        when EMERGENCIA_A_M =>
            transito_a <= "00";--verde (hasta que termine emergencia)
            transito_b <= "10";--rojo
            confirmacion_emergencia_a <= '1'; 

        when EMERGENCIA_B_T =>
             transito_b <= "10";--rojo
            transito_a <= "01";--amarillo(forzado)

        when EMERGENCIA_B_M =>
            transito_b <= "00";--verde (hasta que termine emergencia)
            transito_a <= "10";--rojo
            confirmacion_emergencia_b <= '1'; 
    end case ;
end process;

end arch ;
