library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temporizador is
    port(
        recarga:in std_logic_vector (5 downto 0);
        clk, nrst:in std_logic;
        listo: out std_logic;
        hab: in std_logic
    );
end temporizador;

architecture impl of temporizador is
    signal est_actual, est_sig , est_sig1: unsigned(5 downto 0);
begin
    
    registro: process(clk)
    begin
        if rising_edge(clk) then
            est_act<= est_sig;
        end if;
    end process;
    --datapath
    listo<= '1' when est_act = 1 else
            '0';
    --"una forma"  est_sig <= (others =>'0') when not rst
    est_sig <= est_act when not hab else
            (others=>0) when not nrst else
            unsigned(recarga) when est_act = 0 else           
            est_act -1;
            
    
        est_sig1 when hab else
        est_act;
        est_sig1 <= recarga when est_act = "000000" else
                    std_logic_vector(unsigned(est_act) - 1);

end impl;

        end arch;