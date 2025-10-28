library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

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
EMERGENCIA_A, --dar lugar emergencia A (verde calle A) y calle B rojo
EMERGENCIA_B, --dar lugar emergencia B (verde calle B) y calle A rojo 
VERDE_ADICIONAL_A, --mantiene A en verde
VERDE_ADICIONAL_B, --mantiene B en verde
CANCELA_A, --cancela verde A
CANCELA_B --cancela verde B
);

signal estado_actual, estado_siguiente: estado_t;
signal carga_timer: integer; --cuenta que se carga en el temporizador
signal t_out: std_logic; --señal generada por temporizador al final de la cuenta
signal hab_timer : std_logic;--habilita el conteo

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
--MEMORIAS PEATONES
memoria_peaton_A:process (clk, nreset) is
begin
        if nreset ='0' then
            m_peaton_a <= '0';
        elsif rising_edge(clk) then
        --peaton a
        if solicitud_peaton_a='1'then
            m_peaton_a <= '1';            
        elsif peaton_a_det='1' then
            m_peaton_a <= '0';
        end if;
        end if;
    end process;

        --peaton b
memoria_peaton_B:process (clk, nreset) is
begin
        if nreset ='0' then
            m_peaton_b <= '0';
        elsif rising_edge(clk) then
        --peaton a
        if solicitud_peaton_b='1'then
            m_peaton_b <= '1';            
        elsif peaton_b_det='1' then
            m_peaton_b <= '0';
        end if;
        end if;
    end process;

-- Registro---------------------------------
memoria:process (clk, nreset) is
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
Logica_estado_sig:process(all) is
begin
    estado_siguiente <= estado_actual; --se queda en el mismo estado
    case estado_actual is
    
        --ESTADOS(CALLE A)
        when VERDE_A => 
            if solicitud_emergencia_a and t_out then
                estado_siguiente <= EMERGENCIA_A;
                elsif solicitud_emergencia_b and not m_peaton_a and not solicitud_emergencia_a then
                estado_siguiente <= CANCELA_A;
                elsif m_peaton_a and t_out then
                estado_siguiente <= VERDE_ADICIONAL_A    ;
                elsif not m_peaton_a and not solicitud_emergencia_a and t_out then
                estado_siguiente <= AMARILLO_A;                        
            end if;
            
        when VERDE_ADICIONAL_A =>
            if t_out then
                estado_siguiente <= AMARILLO_A;
                
            end if ;
        when AMARILLO_A =>
            if t_out then
                estado_siguiente <= VERDE_B;
            end if ;
      
        when CANCELA_A => --calle A esta verde, se le fuerza amarillo
            estado_siguiente <= AMARILLO_A;

        when EMERGENCIA_A => --calle A en verde por emergencia (bloquea B)
            if not solicitud_emergencia_a then
                estado_siguiente <= AMARILLO_A;
                
            end if ;


        --ESTADOS (CALLE B)
        when VERDE_B =>
           if solicitud_emergencia_b and t_out then
                estado_siguiente <= EMERGENCIA_B;
                elsif solicitud_emergencia_a and not m_peaton_b and not solicitud_emergencia_b then
                estado_siguiente <= CANCELA_B;
                elsif m_peaton_b and t_out then
                estado_siguiente <= VERDE_ADICIONAL_B    ;
                elsif not m_peaton_b and not solicitud_emergencia_b and t_out then
                estado_siguiente <= AMARILLO_B;                        
            end if;

        when VERDE_ADICIONAL_B =>
            if t_out then
                estado_siguiente <= AMARILLO_B;
                
            end if ;
        when AMARILLO_B =>
            if t_out then
                estado_siguiente <= VERDE_A;
            end if ;
    
    
        when CANCELA_B => --calle B esta verde, se le fuerza amarillo
            estado_siguiente <= AMARILLO_B;
       
        when EMERGENCIA_B => --Calle B en verde por emergencia (Bloquea A)
            if not solicitud_emergencia_b then
                estado_siguiente <= AMARILLO_B;
                
            end if ;

        when others => estado_siguiente <= VERDE_A;
    end case ;
end process;
----------------------------------------------
-- Logica de salida (luces)
-- Verde = "00", Amarillo = "01" , Rojo = "10",

--LOGICA DE SALIDA------------------------------------------------------------
luces:process(all) is
begin

    case estado_actual is
    
        when VERDE_A => 
            transito_a <= "00"; --verde
            transito_b <= "10"; --rojo
            peaton_a <='1'; --verde peaton A
            peaton_b <='0'; --espera peaton B
            
        when AMARILLO_A =>
            transito_a <= "01";--amarillo
            transito_b <= "10";--rojo
            
        when VERDE_B =>
            transito_b <= "00";--verde
            transito_a <= "10";--rojo
            peaton_b <='1'; --verde peaton B
            peaton_a <='0'; --espera peaton A

        when AMARILLO_B =>
            transito_b <= "01";--amarillo
            transito_a <= "10";--rojo

        when others => 
             transito_a <= "10";--rojo
             transito_b <= "10";--rojo 
             peaton_a ='0';
             peaton_b ='0';   
        
        
            
    end case ;

end process;

end arch ;
