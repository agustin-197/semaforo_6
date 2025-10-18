library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity temporizador_tb is
end temporizador_tb;

architecture tb of temporizador_tb is
    signal clock, nreset, ready : std_logic;
    signal recarga : std_logic_vector (5 downto 0);
    constant period: time:=10 ns;
begin
    dut: entity temporizador
    port map (
        recarga=>recarga,
        clk=>clock,
        listo=>ready

    );

    clk_gen: process
    begin
    clock <= '1';
    wait for period/2;
    clock<= '0';
    wait for period/2;
    end process;

    evaluacion: process
    begin
        wait until rising_edge(clock);
        wait for period/4;
        nreset <= '0';
        recarga <="001010";
        wait for 3*period;
        nreset<='1';
        finish;
    end process;        

end architecture tb;
