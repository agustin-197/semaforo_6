library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.all;

entity controlador_semaforo_tb is
end controlador_semaforo_tb;

architecture tb of controlador_semaforo_tb is

    -- Base de tiempo
    constant N_PRE : integer := 4;
    constant frecuencia : integer := 10;
    constant C_PRE : unsigned(N_PRE-1 downto 0) := to_unsigned(frecuencia - 1,N_PRE);
    constant periodo : time := 1 sec / frecuencia;

    -- Configuración semáforo
    constant N_TIMER : integer := 6;
    constant T_VERDE  : integer := 50;
    constant T_AMARILLO : integer := 10;
    constant T_PEATON : integer := 50;

    -- Código de luces
    constant ROJO : std_logic_vector(1 downto 0) := "10";
    constant AMARILLO : std_logic_vector(1 downto 0) := "11";
    constant VERDE : std_logic_vector(1 downto 0) := "01";
    constant NEGRO : std_logic_vector(1 downto 0) := "00";

    -- Solicitudes y confirmaciones emergencia y peaton

    signal solicitud_peaton_a        : std_logic;
    signal solicitud_peaton_b        : std_logic;
    signal solicitud_emergencia_a    : std_logic;
    signal solicitud_emergencia_b    : std_logic;
    signal confirmacion_peaton_a     : std_logic;
    signal confirmacion_peaton_b     : std_logic;
    signal confirmacion_emergencia_a : std_logic;
    signal confirmacion_emergencia_b : std_logic;

    -- Control luces

    signal transito_a : std_logic_vector(1 downto 0);
    signal transito_b : std_logic_vector(1 downto 0);
    signal peaton_a   : std_logic;
    signal peaton_b   : std_logic;

    -- Reloj y reset

    signal clk    : std_logic;
    signal nreset : std_logic;

begin

    dut : entity controlador_semaforo generic map (
        N_PRE      => N_PRE,
        C_PRE      => C_PRE,
        N_TIMER    => N_TIMER,
        T_VERDE    => T_VERDE,
        T_AMARILLO => T_AMARILLO,
        T_PEATON   => T_PEATON
    ) port map (
        clk => clk,
        nreset => nreset,

        solicitud_peaton_a        => solicitud_peaton_a,
        solicitud_peaton_b        => solicitud_peaton_b,
        solicitud_emergencia_a    => solicitud_emergencia_a,
        solicitud_emergencia_b    => solicitud_emergencia_b,
        confirmacion_peaton_a     => confirmacion_peaton_a,
        confirmacion_peaton_b     => confirmacion_peaton_b,
        confirmacion_emergencia_a => confirmacion_emergencia_a,
        confirmacion_emergencia_b => confirmacion_emergencia_b,

        transito_a => transito_a,
        peaton_a   => peaton_a,
        transito_b => transito_b,
        peaton_b   => peaton_b
    );

    reloj : process
    begin
        clk <= '0';
        wait for periodo / 2;
        clk <= '1';
        wait for periodo / 2;
    end process;

    proc_estimulo : process
        file archivo_estimulo : text open read_mode is "../src/controlador_semaforo_estimulo.txt";
        variable linea_estimulo : line;
        -- solicitud_peaton_a&solicitud_peaton_b
        -- &solicitud_emergencia_a&solicitud_emergencia_b
        variable estimulo : std_logic_vector (3 downto 0);
        variable lectura_correcta : boolean;
        variable nr_procesadas,nr_ignoradas : integer := 0;
        variable duracion_segundos : integer;
    begin
        nreset <= '0';
        wait until rising_edge(clk);
        wait for periodo/4;
        nreset <= '1';
        while not endfile(archivo_estimulo) loop
            readline(archivo_estimulo,linea_estimulo);
            read(linea_estimulo,estimulo,lectura_correcta);
            if lectura_correcta then
                read(linea_estimulo,duracion_segundos,lectura_correcta);
            end if;
            if not lectura_correcta then
                nr_ignoradas := nr_ignoradas + 1;
                next;
            end if;
            nr_procesadas := nr_procesadas + 1;
            solicitud_peaton_a <= estimulo(3);
            solicitud_peaton_b <= estimulo(2);
            solicitud_emergencia_a <= estimulo(1);
            solicitud_emergencia_b <= estimulo(0);
            wait for 1 sec * duracion_segundos;
        end loop;
        report "Fin archivo estímulo, "&integer'image(nr_procesadas)
                &" líneas procesadas y "&integer'image(nr_ignoradas)
                &" ignoradas."
        severity note;
        wait;
    end process;

    evaluacion : process
        file archivo_patron : text open read_mode is "../src/controlador_semaforo_patron.txt";
        variable linea_patron : line;
        -- transito_a&peaton_a&transito_b&peaton_b
        -- &confirmacion_peaton_a&confirmacion_peaton_b
        -- &confirmacion_emergencia_a&confirmacion_emergencia_b
        variable patron : std_logic_vector (9 downto 0);
        variable lectura_correcta : boolean;
        variable nr_linea,nr_procesadas,nr_ignoradas : integer := 0;
        variable duracion_segundos : integer;
    begin
        wait until rising_edge(nreset);
        while not endfile(archivo_patron) loop
            nr_linea := nr_linea + 1;
            readline(archivo_patron,linea_patron);
            read(linea_patron,patron,lectura_correcta);
            if lectura_correcta then
                read(linea_patron,duracion_segundos,lectura_correcta);
            end if;
            if not lectura_correcta then
                nr_ignoradas := nr_ignoradas + 1;
                next;
            end if;
            nr_procesadas := nr_procesadas + 1;
            assert patron(9 downto 8) = transito_a
                report "Semaforo A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(7) = peaton_a
                report "Semaforo peatonal A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(6 downto 5) = transito_b
                report "Semaforo B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(4) = peaton_b
                report "Semaforo peatonal B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(3) = confirmacion_peaton_a
                report "Confirmación de pedido de cruce peatonal A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(2) = confirmacion_peaton_b
                report "Confirmación de pedido de cruce peatonal B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(1) = confirmacion_emergencia_a
                report "Confirmación de pedido de emergencia A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(0) = confirmacion_emergencia_b
                report "Confirmación de pedido de emergencia B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            wait for 1 sec * duracion_segundos;
        end loop;
        report "Fin de archivo patrón, "&integer'image(nr_procesadas)
               &" lineas procesadas, "&integer'image(nr_ignoradas)
               &" ignoradas."
            severity note;
        finish;
    end process;
end tb ; -- tb