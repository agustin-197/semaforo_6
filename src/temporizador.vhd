library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------
--asignacion de las entradas y salidas
entity temporizador is
    generic (N : integer);
    port(
        clk : in std_logic;
        hab : in std_logic;
        reset : in std_logic;
        P : in std_logic_vector (5 downto 0);
        Z : out std_logic;
        T : out std_logic);
    end temporizador;
-------------------------------------------------------

--logica del temporizador (que hace el temporizador)

architecture arch of temporizador is
   signal D, D_sig : unsigned (5 downto 0);
begin

--------------------------------------------
    --proceso detecta si hay flanco ascendente
    memori: process(clk)
    begin
        if rising_edge(clk) then
            D <= D_sig;
        end if;
    end process;

    D_sig <= (others=>'0') when reset else
             D when not hab else
             unsigned(P) when Z else
             D - 1;
    Z <= D ?= 0;
    T <= D ?= 1;

   end arch;

