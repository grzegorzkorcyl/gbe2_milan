----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:11:17 09/04/2013 
-- Design Name: 
-- Module Name:    data_transmitter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_transmitter is
port(
CLK : in std_logic;
	reset : in std_logic;
	
	LL_IN_D                        : in std_logic_vector(31 downto 0);
	LL_IN_REM                      : in  std_logic_vector(1 downto 0);
	LL_IN_SRC_RDY_N                : in  std_logic;
	LL_IN_SOF_N                    : in  std_logic;
	LL_IN_EOF_N                    : in  std_logic;
	
	--LL_IN_DST_RDY_N                : out std_logic;
	write_enable						 : out std_logic;
	timing_pulse						 : out std_logic;
	Data									 : out std_logic_vector(33 downto 0);
	super_burst_number_out			 : out std_logic_vector(31 downto 0)
	);
end data_transmitter;

architecture Behavioral of data_transmitter is
type state_type is (s1, s2, s3);
signal state : state_type;
signal count : natural range 0 to 10 := 0;
signal pulse : std_logic;
signal super_burst_number : std_logic_vector(31 downto 0);
begin

process(clk,reset)
begin
	if reset = '1' then
	 state <= s1;
	 count <= 0;
	elsif clk'event and clk = '1' then
		pulse <= '0';
		write_enable <= '0';
		case state is
			when s1 =>
				write_enable <= '0';
				if LL_IN_SOF_N = '0' and LL_IN_EOF_N = '1' and LL_IN_SRC_RDY_N = '0' then
					state <= s2;
					write_enable <= '1';
					Data(31 downto 0) <= LL_IN_D;
					Data(32) <= not LL_IN_SOF_N;
					Data(33) <= not LL_IN_EOF_N;
				end if;
			when s2 => 
				write_enable <= '1';
				Data(31 downto 0) <= LL_IN_D;
				Data(32) <= not LL_IN_SOF_N;
				Data(33) <= not LL_IN_EOF_N;
				if count < 2 then
					count <= count + 1;
					pulse <= '0';
				elsif count = 2 then
					super_burst_number <= LL_IN_D;
					pulse <= '1';
					count <= 0;
					state <= s3;
				end if;
			when s3 =>
				write_enable <= '1';
				pulse <= '0';
				Data(31 downto 0) <= LL_IN_D;
				Data(32) <= not LL_IN_SOF_N;
				Data(33) <= not LL_IN_EOF_N;
				if LL_IN_EOF_N = '0' and LL_IN_SOF_N = '1' then
					state <= s1;
				end if;
		end case;
	end if;
end process;
timing_pulse <= pulse;
super_burst_number_out <= super_burst_number;
end Behavioral;

