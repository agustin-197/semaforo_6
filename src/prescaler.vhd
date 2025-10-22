library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Genera un pulso cada preload + 1 ciclos de reloj
entity prescaler is
    generic (
        constant N : integer);
    port(
        nreset : in std_logic; -- sincrónico
        clk    : in std_logic;
        preload: in std_logic_vector (23 downto 0);
        tc     : out std_logic
    );
end prescaler;

architecture arch of prescaler is
    signal cuenta_sig : unsigned (23 downto 0);
    signal cuenta     : unsigned (23 downto 0);
    signal cero       : std_logic;
    signal carga      : std_logic;
begin
    registro: process (clk)
    begin
        if rising_edge(clk) then
            cuenta <= cuenta_sig;
        end if;
    end process;
    tc <= cero;
    cero <= cuenta ?= 0; -- = devuelve un boolean, ?= un std_logic
    carga <= not nreset or cero;
    cuenta_sig <= unsigned(preload) when carga else
                  cuenta - 1;
end arch;