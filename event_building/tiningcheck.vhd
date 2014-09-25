library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.vcomponents.all;

LIBRARY std;
USE std.textio.ALL;

LIBRARY work;
--USE work.FIFO_pkg.ALL;
--USE work.FIFO_32_BIT_pkg.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;
entity timingcheck is
port(
 clk : std_logic;
 reset : std_logic;
 pulse_1						: in std_logic;
 super_busrt_number_1 	: in std_logic_vector(31 downto 0);
 pulse_2						: in std_logic;
 super_busrt_number_2 	: in std_logic_vector(31 downto 0);
 LL_EOF_N_1 				: in std_logic;
 LL_EOF_N_2 				: in std_logic;
 
 set_src_rdy				: out std_logic;
 set_SOF						: out std_logic;
 set_EOF						: out std_logic;
 enable_1					: out std_logic;
 enable_2					: out std_logic
 );
end timingcheck;

architecture Behavioral of timingcheck is
type state_type is (s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12);
signal state : state_type;
signal read_enable_1 : std_logic;
signal read_enable_2 : std_logic;
signal sbn_1 : std_logic_vector(31 downto 0);
signal sbn_2 : std_logic_vector(31 downto 0);
signal FIFO_1_FULL : std_logic;
signal FIFO_2_FULL : std_logic;
signal FIFO_1_EMPTY : std_logic;
signal FIFO_2_EMPTY : std_logic;
signal DATA_FIFO_1_OUT : std_logic_vector(31 downto 0);
signal DATA_FIFO_2_OUT : std_logic_vector(31 downto 0);
signal EOF_1 : std_logic;
signal EOF_2 : std_logic;
signal sig_set_src_rdy : std_logic;
signal sig_set_sof :std_logic;
signal sig_set_eof :std_logic;
signal enable_1_q, enable_2_q :std_logic;

component FIFO_32_BIT is
   PORT (
           CLK                       : IN  std_logic;
           RST                       : IN  std_logic;
           WR_EN 		     				 : IN  std_logic;
           RD_EN                     : IN  std_logic;
           DIN                       : IN  std_logic_vector(32-1 DOWNTO 0);
           DOUT                      : OUT std_logic_vector(32-1 DOWNTO 0);
           FULL                      : OUT std_logic;
           EMPTY                     : OUT std_logic);

  end component;
  
begin

FIFO_IN_1_instance: fifo_512x32 PORT MAP (  
			RD_CLK			=> CLK ,
			WR_CLK         => CLK,
         RST         => reset,       
         WR_EN			=> pulse_1,
         RD_EN 		=> read_enable_1,
         DIN			=> super_busrt_number_1,
         DOUT 			=> DATA_FIFO_1_OUT,
			FULL  		=> FIFO_1_FULL,
			EMPTY 		=> FIFO_1_EMPTY
);

FIFO_IN_2_instance: fifo_512x32 PORT MAP (
			RD_CLK			=> CLK ,                  
			WR_CLK			=> CLK ,                  
         RST         => reset,       
         WR_EN			=> pulse_2,
         RD_EN 		=> read_enable_2,
         DIN			=> super_busrt_number_2,
         DOUT 			=> DATA_FIFO_2_OUT,
			FULL  		=> FIFO_2_FULL,
			EMPTY 		=> FIFO_2_EMPTY
);

process(CLK,reset)
begin
	if reset = '1' then
		state <= s1;
		read_enable_1 <= '0';
		read_enable_2 <= '0';
		enable_1_q <= '0';
		enable_2_q <= '0';
		sig_set_sof <= '1';		
		sig_set_eof <= '1';
		sig_set_src_rdy <= '0';
	elsif clk'event and clk = '1' then
		read_enable_1 <= '0';
		read_enable_2 <= '0';
		enable_1_q <= '0';
		enable_2_q <= '0';
		sig_set_src_rdy <= '1';
		sig_set_sof <= '1';
		sig_set_eof <= '1';
		case state is
			when s1 => 
				if FIFO_1_EMPTY = '0' and FIFO_2_EMPTY = '0'  then
					read_enable_1 <= '1';
					read_enable_2 <= '1';
					sig_set_sof <= '1';
					sig_set_eof <= '1';
					sig_set_src_rdy <= '1';
					state <= s2;
				end if;			
			when s2 => 		
					state <= s3;
			when s3 =>
					if DATA_FIFO_1_OUT < DATA_FIFO_2_OUT then
						state <= s4;
						
					elsif DATA_FIFO_1_OUT > DATA_FIFO_2_OUT then
						state <= s5;
						
					elsif DATA_FIFO_1_OUT = DATA_FIFO_2_OUT then
						state <= s6;
						
					end if;
			when s4 =>
				sig_set_src_rdy <= '0';
				sig_set_sof <= '0';
				enable_1_q <= '1';
				enable_2_q <= '0';
				sig_set_eof <= '1';
				state <= s10;
			when s10 =>
				sig_set_src_rdy <= '0';
				sig_set_sof <= '1';
				enable_1_q <= '1';
				enable_2_q <= '0';
				sig_set_eof <= '1';
				if EOF_1 = '1' then
					enable_1_q <= '0';
					enable_2_q <= '0';
					sig_set_eof <= '0';
					if sig_set_eof = '0' then
						sig_set_src_rdy <= '1';
						state <= s8;
					end if;
				else 
					state <= s10;
				end if;
			when s5 =>
				sig_set_src_rdy <= '0';
				sig_set_sof <= '0';
				sig_set_eof <= '1';
				enable_1_q <= '0';
				enable_2_q <= '1';
				state <= s11;
			when s11 =>
				sig_set_src_rdy <= '0';
				sig_set_sof <= '1';
				sig_set_eof <= '1';
				enable_1_q <= '0';
				enable_2_q <= '1';
				if EOF_2 = '1' then
					enable_1_q <= '0';
					enable_2_q <= '0';
					sig_set_eof <= '0';
					if sig_set_eof = '0' then
						sig_set_src_rdy <= '1';
						state <= s9;
					end if;
				else 
					state <= s11;
				end if;
			when s6 =>
				sig_set_src_rdy <= '0';
					sig_set_sof <= '0';
					enable_1_q <= '1';
					enable_2_q <= '0';
					sig_set_eof <= '1';
					state <= s12;
			when s12 =>
				sig_set_src_rdy <= '0';
					sig_set_sof <= '1';
					enable_1_q <= '1';
					enable_2_q <= '0';
					sig_set_eof <= '1';
					if EOF_1 = '1' then
						enable_1_q <= '0';
						enable_2_q <= '1';
						sig_set_sof <= '1';
						sig_set_eof <= '1';
						state <= s7;
					else 
						state <= s12;	
					end if;
			when s7 =>
				sig_set_src_rdy <= '0';
				sig_set_EOF <= '0';
				enable_1_q <= '0';
				enable_2_q <= '1';
				sig_set_EOF <= '1';
--				if sig_set_EOF = '0' then
--					enable_1_q <= '0';
--					enable_2_q <= '1';
--					sig_set_sof <= '1';
--					sig_set_EOF <= '1';
--				end if;
				if EOF_2 = '1' then
					enable_1_q <= '0';
					enable_2_q <= '1';
					sig_set_eof <= '0';
					state <= s1;
				else 
					state <= s7;
				end if;
			when s8 =>
				if FIFO_1_EMPTY = '1' then
					sig_set_src_rdy <= '1';
					state <= s8;
				else
					read_enable_1 <= '1';
					state <= s2;
				end if;
			when s9 =>
				if FIFO_2_EMPTY = '1' then
					sig_set_src_rdy <= '1';
					state <= s9;
				else
					read_enable_2 <= '1';
					state <= s2;
				end if;
		end case;
	end if;
end process;
set_src_rdy <= sig_set_src_rdy;
set_SOF <= sig_set_sof;
set_EOF <= sig_set_eof;
enable_1 <= enable_1_q;
enable_2 <= enable_2_q;
eof_1 <= LL_EOF_N_1;
eof_2 <= LL_EOF_N_2;

end Behavioral;

