library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mef_maestra_semaforo is
    port(
    clk, rst: in std_logic;
    eeo, ens, peo, pns: in std_logic;
    listo: in std_logic;
    peor, pnsr: out std_logic;
    recarga: out std_logic_vector(5 downto 0);
    luz_eo, luz_ns : std_logic_vector(2 downto 0);
    );
end entity mef_maestra_semaforo;

architecture impl of mef_maestra_semaforo is
constant S_INICIO std_logic_vector(2 downto 0) := "000";
constant S_CV_EO std_logic_vector(2 downto 0) := "001";
constant S_T_EONS std_logic_vector(2 downto 0) := "010";
constant S_CVA_EO std_logic_vector(2 downto 0) := "011";
constant S_CV_NS std_logic_vector(2 downto 0) := "100";
constant S_T_NSEO std_logic_vector(2 downto 0) := "101";
constant S_CVA_NS std_logic_vector(2 downto 0) := "110";
constant L_ROJO std_logic_vector(2 downto 0) := "001";
constant L_AMARILLO std_logic_vector(2 downto 0) := "010";    
constant L_VERDE std_logic_vector(2 downto 0) := "100";
constant T_10S std_logic_vector(TWIDTH-1 downto 0) := "00001010";
constant T_50S std_logic_vector(TWIDTH-1 downto 0) := "00110010";

signal est_act, est_sig, est_sig1: std_logic_vector(2 downto 0);
signal peo_k, pns_k, peo_act, pns_act: std_logic;
signal nrst: std_logic --((FALTAN SEÑALES))

begin
rst <= not nreset;

habilitacion_1hz: entity prescaler
generic map (DIVISOR => CLK_FREQ)
port map (clk=>clk, rst=>rst, tic=> hab_1hz)

eeo <= emergencia_1 ;
ens <=not emergencia_1 and emergencia_2;
peo <=(not emergencia_1)and(not emergencia_2)and peatonal_1;
pns <=(not emergencia_1)and(not emergencia_2)and(not peatonal_1)and peatonal_2;

--Registrar pedidos peatonales (mediante flip flop JK)
--Logica de ff JK
peo_sig <= '0' when rst else
            (peo and not peo_act)or(not peo_k and peo_act)

pns_sig <= '0'
            (pns and not pns_act)or(not pns_k pns_act)


t1: entity temporizador
generic map(TWIDTH =>TIMER_WIDTH)
port map (
clk => clk,
nreset => nreset_temporizador,
hab => hab_1hz,
recarga => recarga,
listo => listo,
);

    --registro
memoria_estado: process(clk)
begin
    if rising_edge(clk) then
        est_act<=est_sig;
    end if;
    end process;

est_sig1 <= S_INICIO when rst else
    est_sig;

-- LES(combinacional)
les: process(all)
begin

    est_sig <= S_INICIO; --Asignacion por defecto

    case est_act is
        when S_INICIO =>
            if listo then
                est_sig <= S_CV_EO;
            
            elsif   then
            
            elsif   then
            
            elsif   then
        
        end if
        --  else
        --    est_sig <= S_INICIO;
        --      o puede ser est_sig <= est_act;
                 
        when S_CV_EO =>
            if eeo then
                est_sig <= S_CV_EO;
                elsif ens then
                    
            --HACERRRRR)))))))))))
                
        when S_T_EONS =>
                if eeo and listo then
                    est_sig<= S_CV_EO;
                elsif listo then
                    est_sig <= S_CV_NS
                end if;

        when S_CVA_EO =>
        when S_CVA_NS =>
        when S_T_NSEO =>
        when S_CVA_NS=>
        
    end case;

    end process;

    nreset_temporizador <= '0' when est_sig /= est_act else
                        '1';


-- LS (combinacional)
ls: process(all)
begin
    --(((((CREO Q Falta un case aquiiii)))))
    
        peo_k <='0'; --por defecto
        pns_k <='0';    --por defecto


        when S_INICIO =>
        luz_eo <= L_ROJO;
        luz_ns <= L_ROJO;
        recarga <= T_10S;
        --peo_k <='0';
        --pns_k <='0';

        when S_CV_EO =>
           luz_eo <= L_VERDE;
        luz_ns <= L_ROJO;
        recarga <= T_50S;

        when S_T_EONS =>
                           
        when S_CVA_EO =>
        luz_eo <= L_VERDE;
        luz_ns <= L_ROJO;
        recarga <= T_50S;
        pns_k <= '1';


        when S_CVA_NS =>
        when S_T_NSEO =>
        when S_CVA_NS=>
end process;

--((((((((((((HACER DECODIFICADORRRRRR))))))))))))

end architecture impl;