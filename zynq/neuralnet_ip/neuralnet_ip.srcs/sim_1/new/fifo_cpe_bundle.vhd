library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.helperpkg.all;
use work.nn_arith_package.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee.math_real.all;
-- simulation only module to ease testbench design
entity fifo_cpe_bundle is
    generic (nrows: integer; dfifo: integer);
    port (
        clk: in std_logic;
        alrst: in std_logic;
    -- fifo ports 
        writeen	: in  std_logic;
        datain	: in  std_logic_vector (15 downto 0);
        full   : out std_logic;
    -- cpe ports
        osync      : out std_logic;
        isync      : in std_logic;
        ivfwd      : in std_logic;
        idfwd      : in std_logic_vector (31 downto 0);
        ovfwd      : out std_logic;
        odfwd      : out std_logic_vector (31 downto 0));
end fifo_cpe_bundle;

architecture Behavioral of fifo_cpe_bundle is
    component column_processor
        generic (nrows: integer);
        port (clk        : in std_logic;
              alrst      : in std_logic;
              l1_rden    : out std_logic;
              l1_raddr   : out integer range 0 to nrows - 1; 
              l1_din     : in std_logic_vector (15 downto 0);
              l1_vin     : in std_logic;
              ve_datain  : in std_logic_vector (15 downto 0);
              ve_validin : in std_logic;
              ve_req     : out std_logic;
              ve_ack     : in std_logic;
              osync      : out std_logic;
              isync      : in std_logic;
              ivfwd      : in std_logic;
              idfwd      : in std_logic_vector (31 downto 0);
              ovfwd      : out std_logic;
              odfwd      : out std_logic_vector (31 downto 0));
    end component;

    component std_fifo is
        generic (
            constant data_width  : positive := 8;
            constant fifo_depth	: positive := 256
        );
        port ( 
            clk		: in  std_logic;
            rst		: in  std_logic;
            writeen	: in  std_logic;
            datain	: in  std_logic_vector (data_width - 1 downto 0);
            readen	: in  std_logic;
            dataout	: out std_logic_vector (data_width - 1 downto 0);
            ackout      : out std_logic;
            validout    : out std_logic;
            empty	: out std_logic;
            full	: out std_logic
        );
    end component std_fifo;

    signal l1_rden: std_logic;
    signal l1_raddr: integer range 0 to nrows - 1; 
    signal l1_din: std_logic_vector (15 downto 0);
    signal l1_vin: std_logic;
    signal ve_datain: std_logic_vector (15 downto 0);
    signal ve_validin: std_logic;
    signal ve_req: std_logic;
    signal ve_ack: std_logic;

    -- fifo signals
    signal empty: std_logic;
    signal readen: std_logic;

begin

    fake_memory: process (clk) is
    begin
        if (rising_edge (clk)) then
            l1_vin <= l1_rden;
            if (l1_rden = '1') then
                l1_din <= std_logic_vector (to_unsigned(l1_raddr, 8)) & X"00";
            end if;
        end if;
    end process;
    
    readen <= '1' when ve_req = '1' and empty = '0' else '0';
    fifo_port_map: std_fifo
    generic map (data_width => 16, fifo_depth => dfifo)
    port map (
        clk => clk,
        rst => alrst,
        writeen => writeen,
        datain => datain, 
        readen => readen,
        dataout => ve_datain,
        ackout => ve_ack,
        validout => ve_validin,
        empty => empty,
        full => full 
    );

    cpe_port_map: column_processor
    generic map (nrows => nrows)
    port map (
        clk => clk,
        alrst => alrst,
        l1_rden => l1_rden,
        l1_raddr => l1_raddr,
        l1_din => l1_din,
        l1_vin => l1_vin,
        ve_datain => ve_datain,
        ve_validin => ve_validin,
        ve_req => ve_req,
        ve_ack => ve_ack,
        osync => osync,
        isync => isync,
        ivfwd => ivfwd,
        idfwd => idfwd,
        ovfwd => ovfwd,
        odfwd => odfwd
    );


end Behavioral;