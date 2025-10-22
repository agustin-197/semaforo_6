library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity temporizador_tb is
end temporizador_tb;

architecture tb of temporizador_tb is
    constant N : integer := 6;
    constant periodo : time := 1 sec;
    signal P : unsigned (N-1 downto 0);
    signal clk, hab, reset, Z, T : std_logic;
begin
    dut : entity temporizador generic map (N=>N) port map (
        clk=>clk,
        hab=>hab,
        reset=>reset,
        P => std_logic_vector(P),
        Z => Z,
        T => T
    );

    reloj : process
    begin
        clk <= '0';
        wait for periodo/2;
        clk <= '1';
        wait for periodo/2;
    end process;

    estimulo : process
    begin
        reset <= '1';
        wait until rising_edge(clk);
        wait for periodo/4;
        reset <= '0';
        hab <= '0';
        P <= to_unsigned(50-1,N);
        wait for 10 * periodo;
        hab <= '1';
        wait for 50 * periodo;
        P <= to_unsigned(10-1,N);
        wait for 10 * periodo;
        P <= to_unsigned(50-1,N);
        wait for 29 * periodo;
        reset <= '1';
        wait for periodo;
        reset <= '0';
        P <= to_unsigned(10-1,N);
        wait;
    end process;

    evaluacion : process
        constant E_NO_FIN  : string := "Esperaba fin de temporización";
        constant E_NO_CERO : string := "Esperaba cuenta cero";
    begin
        wait until falling_edge(reset);
        wait for (60 - 1) * periodo;
        assert T report E_NO_FIN severity error; -- Ciclo final de temporización
        wait for periodo;
        assert Z report E_NO_CERO severity error; -- Ciclo de carga
        wait for (10 - 1) * periodo;
        assert T report E_NO_FIN severity error; -- Ciclo final de temporización
        wait for periodo;
        assert Z report E_NO_CERO severity error; -- Ciclo de carga
        wait for 30 * periodo;
        assert Z report E_NO_CERO severity error; -- Ciclo de carga (por reset)
        wait for (10-1) * periodo;
        assert T report E_NO_FIN severity error; -- Ciclo final de temporización
        wait for periodo;
        assert Z report E_NO_CERO severity error; -- Ciclo de carga
        wait for periodo;
        finish;
    end process;

end tb;