library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity top is
    port (
        clk : in std_logic;
        nreset : in std_logic;
        solicitud_peaton_a : in std_logic;
        solicitud_peaton_b : in std_logic;
        solicitud_emergencia_a : in std_logic;
        solicitud_emergencia_b : in std_logic;

        confirmacion_peaton_a : out std_logic;
        confirmacion_peaton_b : out std_logic;
        confirmacion_emergencia_a : out std_logic;
        confirmacion_emergencia_b : out std_logic;
        rojo_a         : out std_logic;
        amarillo_a     : out std_logic;
        verde_a        : out std_logic;
        cruce_peaton_a : out std_logic;
        rojo_b         : out std_logic;
        amarillo_b     : out std_logic;
        verde_b        : out std_logic;
        cruce_peaton_b : out std_logic);
end top;

architecture arch of top is
    -- Base de tiempo
    constant N_PRE : integer := 24;
    constant frecuencia : integer := 12000000;
    constant C_PRE : unsigned(N_PRE-1 downto 0) := to_unsigned(frecuencia - 1,N_PRE);

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

    signal transito_a : std_logic_vector(1 downto 0);
    signal transito_b : std_logic_vector(1 downto 0);

begin
    rojo_a <= transito_a ?= ROJO;
    amarillo_a <= transito_a ?= AMARILLO;
    verde_a <= transito_a ?= VERDE;
    rojo_b <= transito_b ?= ROJO;
    amarillo_b <= transito_b ?= AMARILLO;
    verde_b <= transito_b ?= VERDE;

    U1: entity controlador_semaforo generic map(
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
        peaton_a   => cruce_peaton_a,
        transito_b => transito_b,
        peaton_b   => cruce_peaton_b
    );

end arch ; -- arch