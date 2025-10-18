library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity mef_maestra_semaforo is
end mef_maestra_semaforo;

architecture tb of mef_maestra_semaforo is
    signal A,B,y : std_logic;
begin
    DUT : entity mef_maestra_semaforo port map (A => A, B => B, y => y);
    stim : process is
    begin
            end process;
end tb;
