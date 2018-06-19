library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.helperpkg.all;
use work.nn_arith_package.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

--
-- A derivative processor computes one of the rows or columns of the
-- weight derivative matrix. A backprop stage has as many derivative units
-- as there are transpose matrix multiplication processors.
--
-- They are organised like so:
--
-- 
-- serial fifo ---> DU ---> DU ---> DU ...
--                  ^       ^       ^
--                  |       |       |
--                  (parallel fifos)
--
-- If the forward propagation stage is row-major (i.e made of row processors),
-- then a(l-1) input is serial. Furthermore, the transpose matrix is column major,
-- meaning that d(l) input is parallel. Therefore, "parallel fifos" in the above
-- ascii art correspond to delta-L from last backward stage, and "serial fifo" is
-- the duplicated a(l - 1) fifo from the last forward stage.
--
-- If the forward stage is col-major, then a(l - 1) input is parallel. With the transpose
-- matrix being row-major, the d(l) input is serial. Therefore the mapping is the opposite.

entity derivative_processor is
    generic (width: integer := 100);
    port (
        clk:        in std_logic;
        alrst:      in std_logic;
    -- parallel side
        p_din:      in std_logic_vector (15 downto 0);
        p_vin:      in std_logic;
        p_ren:      out std_logic;
        p_ack:      in std_logic;
    -- serial side
        s_din:      in std_logic_vector (15 downto 0);
        s_vin:      in std_logic;
        s_ren:      out std_logic;
        -- to the next unit down the line
        s_dfwd:     out std_logic_vector (15 downto 0);
        s_vfwd:     out std_logic;
        s_req:      in std_logic;
        s_ack:      out std_logic;
    -- output stream
        dataout:    out std_logic_vector (15 downto 0);
        validout:   out std_logic
    );
end derivative_processor;

--TODO:
-- WIP
-- correct wptr increment logic
-- correct state machine
-- 
-- test items:
-- serial input latency insensitive?
-- need to test alongside row/col processor eventually

architecture Behavioral of derivative_processor is
    signal wptr: integer range 0 to width - 1;
    -- init: hold p_ren high, s_ren low, wait for p_ack
    -- wait_p: following p_ack, wait for p_din and p_vin to latch, read s
    -- stream: stream output product for each s_vin
    type state_t is (init, wait_p,stream);
    signal this_state: state_t;
    signal next_state: state_t;
    -- multiplication results
    subtype full_prod_t is std_logic_vector (31 downto 0);
    signal prod_full: std_logic_vector (31 downto 0); 
    -- whether the product will be valid
    signal prod_valid: std_logic;
    signal validout_pipe: std_logic;
    -- latched multiplicand/multiplier when one of the two interfaces
    -- was starved
    signal p_latched: std_logic_vector (15 downto 0);

begin
-- serial data forwarding
    fwd_proc:
    process (clk, alrst) is
    begin
        if (rising_edge(clk)) then
            if (alrst = '0') then
                s_dfwd <= (others => '0');
                s_vfwd <= '0';
            else
                s_dfwd <= s_din;
                s_vfwd <= s_vin;
            end if;
        end if;
    end process;

-- width pointer process
    wptr_proc:
    process (clk, alrst) is
    begin
        if (rising_edge (clk)) then
            if (alrst = '0') then
                wptr <= 0;
            elsif (s_vin = '1') then
                wptr <= (wptr + 1) mod width;
            end if;
        end if;
    end process;

-- product stream generation
    mult_proc:
    process (clk, alrst) is
    begin
        if (rising_edge (clk)) then
            if (alrst = '0') then
                prod_full <= (others => '0'); 
                validout <= '0';
                dataout <= (others => '0');
                validout_pipe <= '0';
            else
                validout <= validout_pipe;
                validout_pipe <= prod_valid;
                -- TODO: add prod_full register input
                prod_full <= full_prod_t (
                             to_sfixed (p_latched, PARAM_DEC - 1, -PARAM_FRC) *
                             to_sfixed (s_din,     PARAM_DEC - 1, -PARAM_FRC));
                dataout <= fun_mul_truncate (prod_full);
            end if;
        end if;
    end process;

-- multiplicant latching process
    mult_latch_proc:
    process (clk, alrst) is
    begin
        if (rising_edge(clk)) then
            if (alrst = '0') then
                p_latched <= (others => '0');
            else
                if (p_vin = '1') then
                    p_latched <= p_din;
                end if;
            end if;
        end if;
    end process;

-- state transition process;
    stat_proc: 
    process (clk, alrst) is
    begin
        if (rising_edge(clk)) then
            if (alrst = '0') then
                this_state <= init;
            else
                this_state <= next_state;
            end if;
        end if;
    end process;

    prod_valid <= '1' when this_state = stream and s_vin = '1' else '0'; 
-- output logic;
    output_proc:
    process (this_state, p_vin, s_vin, wptr) is
    begin
        case this_state is
            when init =>
                p_ren <= '1';
                s_ren <= '0';
                if (p_ack = '0') then
                    next_state <= init;
                else
                    next_state <= wait_p;
                end if;
            when wait_p =>
                p_ren <= '0';
                if (p_vin = '1') then
                    s_ren <= '1';
                    next_state <= stream;
                else
                    s_ren <= '0';
                    next_state <= wait_p;
                end if;
            when stream =>
                p_ren <= '0';
                s_ren <= '1';
                if (wptr = width - 1) then
                    next_state <= init;
                else
                    next_state <= stream;
                end if;
        end case;
    end process;


end Behavioral;
