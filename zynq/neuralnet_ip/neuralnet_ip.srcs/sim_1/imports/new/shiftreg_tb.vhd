-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 30.1.2018 10:54:03 GMT

library ieee;
use ieee.std_logic_1164.all;
use work.helperpkg.all;


entity tb_vector_shifter is
end tb_vector_shifter;

architecture tb of tb_vector_shifter is
    
    constant nrows : integer := 5;
    
    component vector_shifter
        generic(
            nrows: integer
        );
        port (clk             : in std_logic;
              alrst           : in std_logic;
              array_in        : in wordarr_t (nrows - 1 downto 0);
              valid_in        : in std_logic_vector (nrows - 1 downto 0);
              valid_out       : out std_logic;
              activated_out   : out std_logic_vector (15 downto 0);
              unactivated_out : out std_logic_vector (15 downto 0));
    end component;

    signal clk             : std_logic;
    signal alrst           : std_logic;
    signal array_in        : wordarr_t (nrows - 1 downto 0);
    signal valid_in        : std_logic_vector (nrows - 1 downto 0);
    signal valid_out       : std_logic;
    signal activated_out   : std_logic_vector (15 downto 0);
    signal unactivated_out : std_logic_vector (15 downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : vector_shifter
    generic map (
        nrows => nrows
    )
    port map (clk             => clk,
              alrst           => alrst,
              array_in        => array_in,
              valid_in        => valid_in,
              valid_out       => valid_out,
              activated_out   => activated_out,
              unactivated_out => unactivated_out);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        array_in <= (others => (others => '0'));
        valid_in <= (others => '0');

        -- Reset generation
        -- EDIT: Check that alrst is really your reset signal
        alrst <= '0';
        wait for 100 ns;
        alrst <= '1';
        wait for 100 ns;

        -- EDIT Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_vector_shifter of tb_vector_shifter is
    for tb
    end for;
end cfg_tb_vector_shifter;