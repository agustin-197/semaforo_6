library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlador_semaforo is
    generic (
        constant N_PRE      : integer;
        constant C_PRE      : unsigned(N_PRE-1 downto 0);
        constant N_TIMER    : integer;
        constant T_VERDE    : integer;
        constant T_AMARILLO : integer;
        constant T_PEATON   : integer);
    port (
        clk : in std_logic;
        nreset : in std_logic;
        --solicitudes
        solicitud_peaton_a : in std_logic;
        solicitud_peaton_b : in std_logic;
        solicitud_emergencia_a : in std_logic;
        solicitud_emergencia_b : in std_logic;
        --confirmaciones
        confirmacion_peaton_a : out std_logic;
        confirmacion_peaton_b : out std_logic;
        confirmacion_emergencia_a : out std_logic;
        confirmacion_emergencia_b : out std_logic;

        transito_a : out std_logic_vector (1 downto 0);
        peaton_a : out std_logic;
        transito_b : out std_logic_vector (1 downto 0);
        peaton_b : out std_logic);
end controlador_semaforo;

architecture arch of controlador_semaforo is
begin

end arch ;
