library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

package helperpkg is
constant PARAM_DEC: integer;
constant PARAM_FRC: integer;
constant LEARN_RATE: real;
constant DFIFO: integer;
end package;

package body helperpkg is
constant PARAM_DEC: integer := 8;
constant PARAM_FRC: integer := 8;
constant LEARN_RATE: real := 0.1;
constant DFIFO: integer := 256;
end package body;