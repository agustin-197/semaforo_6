library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity prescaler_tb is
end prescaler_tb;

architecture arch of prescaler_tb is
    constant periodo : time := 1 us;
    constant N : integer := 4;
    constant divisor : integer := 10;
    signal nreset, clk, tc : std_logic;
    signal preload : std_logic_vector (N-1 downto 0);
begin

    dut: entity prescaler generic map(
        N => N
    )port map(
        clk => clk,
        nreset => nreset,
        tc => tc,
        preload => preload);

    gen_clk : process
    begin
        clk <= '0';
        wait for periodo/2;
        clk <= '1';
        wait for periodo/2;
    end process;

    estimulo : process
    begin
        preload <= std_logic_vector(to_unsigned(divisor - 1,N));
        nreset <= '0';
        wait until rising_edge(clk);
        wait for periodo/4;
        nreset <= '1';
        wait;
    end process;

    evaluacion : process
    begin
        wait until rising_edge(nreset);
        espera : for i in divisor-1 downto 1 loop
            assert tc = '0'
                report "Salida de cuenta terminal prematura"
                severity error;
            wait for periodo;
        end loop ; -- espera
        assert tc = '1'
            report "Se espera cuenta terminal"
            severity error;
        wait for periodo;
        assert tc = '0'
            report "Salida de cuenta terminal prematura"
            severity error;
        wait for periodo;
        finish;
    end process;
end arch;