
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
entity eventbuilder_v3 is
  port(
	CLK : in std_logic;
	reset : in std_logic;
	
	LL_IN_D_1                        : in std_logic_vector(31 downto 0);
	LL_IN_REM_1                      : in  std_logic_vector(1 downto 0);
	LL_IN_SRC_RDY_N_1                : in  std_logic;
	LL_IN_SOF_N_1                    : in  std_logic;
	LL_IN_EOF_N_1                    : in  std_logic;
	LL_IN_DST_RDY_N_1                : out std_logic;
		
	LL_IN_D_2                        : in std_logic_vector(31 downto 0);
	LL_IN_REM_2                      : in  std_logic_vector(1 downto 0);
	LL_IN_SRC_RDY_N_2                : in  std_logic;
	LL_IN_SOF_N_2                    : in  std_logic;
	LL_IN_EOF_N_2                    : in  std_logic;
	LL_IN_DST_RDY_N_2                : out std_logic;	
	
	LL_OUT_D                        : out std_logic_vector(31 downto 0);
	LL_OUT_REM                      : out  std_logic_vector(1 downto 0);
	LL_OUT_SRC_RDY_N                : out  std_logic;
	LL_OUT_SOF_N                    : out  std_logic;
	LL_OUT_EOF_N                    : out  std_logic;
	LL_OUT_DST_RDY_N                : in std_logic
);
end eventbuilder_v3;

architecture Behavioral of eventbuilder_v3 is

component data_transmitter is
port(
	CLK : in std_logic;
	reset : in std_logic;
	
	LL_IN_D                        : in std_logic_vector(31 downto 0);
	LL_IN_REM                      : in  std_logic_vector(1 downto 0);
	LL_IN_SRC_RDY_N                : in  std_logic;
	LL_IN_SOF_N                    : in  std_logic;
	LL_IN_EOF_N                    : in  std_logic;
	
	--LL_IN_DST_RDY_N                : out std_logic;
	write_enable 						 : out std_logic;
	timing_pulse						 : out std_logic;
	Data									 : out std_logic_vector(33 downto 0);
	super_burst_number_out			 : out std_logic_vector(31 downto 0)
);
end component;

component timingcheck is
port(
 clk							: in std_logic;
 reset						: in std_logic;
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
end component;

component FIFO is
   PORT (
           CLK                       : IN  std_logic;
           RST                       : IN  std_logic;
           WR_EN 		     				 : IN  std_logic;
           RD_EN                     : IN  std_logic;
           DIN                       : IN  std_logic_vector(34-1 DOWNTO 0);
           DOUT                      : OUT std_logic_vector(34-1 DOWNTO 0);
           FULL                      : OUT std_logic;
           EMPTY                     : OUT std_logic);

  end component;

signal timing_pulse_1 	: std_logic;
signal timing_pulse_2 	: std_logic;
signal sbn_1 			 	: std_logic_vector(31 downto 0);
signal sbn_2				: std_logic_vector(31 downto 0);
signal write_enable_1 	: std_logic;
signal write_enable_2   : std_logic;
signal read_enable_1		: std_logic;
signal read_enable_2		: std_logic;
signal FIFO_1_WR_EN		: std_logic;
signal FIFO_1_RD_EN		: std_logic;
signal DATA_FIFO_1_IN	: std_logic_vector(33 downto 0);
signal DATA_FIFO_1_OUT	: std_logic_vector(33 downto 0);
signal FIFO_1_FULL		: std_logic;
signal FIFO_1_EMPTY		: std_logic;
signal FIFO_2_WR_EN		: std_logic;
signal FIFO_2_RD_EN		: std_logic;
signal DATA_FIFO_2_IN	: std_logic_vector(33 downto 0);
signal DATA_FIFO_2_OUT	: std_logic_vector(33 downto 0);
signal FIFO_2_FULL		: std_logic;
signal FIFO_2_EMPTY		: std_logic;
signal data1				: std_logic_vector(33 downto 0);
signal data2				: std_logic_vector(33 downto 0);
signal data_out				: std_logic_vector(33 downto 0);
signal sig_set_src_rdy, sig_set_sof, sig_set_EOF, sig_LL_OUT_SOF_N, sig_LL_OUT_EOF_N 	: std_logic;
begin

timingcheck_instance : timingcheck PORT MAP(
 clk 							=> clk,
 reset						=> reset,
 pulse_1						=> timing_pulse_1,
 super_busrt_number_1 	=> sbn_1,
 pulse_2						=> timing_pulse_2,
 super_busrt_number_2 	=> sbn_2,
 LL_EOF_N_1 				=> DATA_FIFO_1_OUT(33),
 LL_EOF_N_2 				=> DATA_FIFO_2_OUT(33),
 set_src_rdy				=> sig_set_src_rdy,
 set_SOF						=> sig_set_SOF,
 set_EOF						=> sig_set_EOF,
 enable_1					=> read_enable_1,
 enable_2					=> read_enable_2 
);

data_transmitter_1_instance : data_transmitter PORT MAP(

	CLK 						=> CLK,
	reset 					=> reset,
	
	LL_IN_D           	=> LL_IN_D_1,         
	LL_IN_REM         	=> LL_IN_REM_1,
	LL_IN_SRC_RDY_N   	=> LL_IN_SRC_RDY_N_1,
	LL_IN_SOF_N       	=> LL_IN_SOF_N_1,
	LL_IN_EOF_N       	=> LL_IN_EOF_N_1,
	
	--LL_IN_DST_RDY_N   	=> LL_IN_DST_RDY_N_1,
	write_enable				=> write_enable_1,
	timing_pulse			=> timing_pulse_1,
	Data						=> data1,
	super_burst_number_out => sbn_1	
);

data_transmitter_2_instance : data_transmitter PORT MAP(

	CLK 						=> CLK,
	reset 					=> reset,
	
	LL_IN_D           	=> LL_IN_D_2,         
	LL_IN_REM         	=> LL_IN_REM_2,
	LL_IN_SRC_RDY_N   	=> LL_IN_SRC_RDY_N_2,
	LL_IN_SOF_N       	=>  LL_IN_SOF_N_2,
	LL_IN_EOF_N       	=> LL_IN_EOF_N_2,
	
	--LL_IN_DST_RDY_N   	=> LL_IN_DST_RDY_N_2,
	write_enable				=> write_enable_2,
	timing_pulse			=> timing_pulse_2,
	Data						=> data2,
	super_burst_number_out => sbn_2	
);

FIFO_IN_1_instance: fifo_8192x34 PORT MAP (
			CLK			=> CLK ,                  
         RST         => reset,       
         WR_EN			=> FIFO_1_WR_EN,
         RD_EN 		=> read_enable_1,
         DIN			=> DATA_FIFO_1_IN,
         DOUT 			=> DATA_FIFO_1_OUT,
			FULL  		=> FIFO_1_FULL,
			EMPTY 		=> FIFO_1_EMPTY
);

FIFO_IN_2_instance: fifo_8192x34 PORT MAP (
			CLK			=> CLK ,                  
         RST         => reset,       
         WR_EN			=> FIFO_2_WR_EN,
         RD_EN 		=> read_enable_2,
         DIN			=> DATA_FIFO_2_IN,
         DOUT 			=> DATA_FIFO_2_OUT,
			FULL  		=> FIFO_2_FULL,
			EMPTY 		=> FIFO_2_EMPTY
);

process(CLK,reset)--write_enable FIFO 1
begin
	if reset = '1' then
		FIFO_1_WR_EN <= '0';
	elsif clk'event and clk = '1' then	
		if write_enable_1 = '1' and FIFO_1_FULL = '0' then
			FIFO_1_WR_EN <= '1';
			DATA_FIFO_1_IN <= Data1;
		else 
			FIFO_1_WR_EN <= '0';
		end if;
	end if;
end process;

process(CLK,reset)--write_enable FIFO 2
begin
	if reset = '1' then
		FIFO_2_WR_EN <= '0';
	elsif clk'event and clk = '1' then	
		if write_enable_2 = '1' and FIFO_2_FULL = '0' then	
			FIFO_2_WR_EN <= '1';
			DATA_FIFO_2_IN <= Data2;
		else 
			FIFO_2_WR_EN <= '0';
		end if;
	end if;
end process;

process(CLK,reset)--resd enable FIFO 1
begin
	if reset = '1' then
		FIFO_1_RD_EN <= '0';
	elsif clk'event and clk = '1' then
		if  read_enable_1 = '1' then
				data_out <= DATA_FIFO_1_OUT;
			--	LL_OUT_SRC_RDY_N <= '0';
--				sig_LL_OUT_SOF_N   <= not data_out(32);                
--				sig_LL_OUT_EOF_N   <= not data_out(33);				
		elsif read_enable_2 = '1' then
			data_out <= DATA_FIFO_2_OUT;
			--LL_OUT_SRC_RDY_N <= '0';
--			sig_LL_OUT_SOF_N   <= not data_out(32);                
--			sig_LL_OUT_EOF_N   <= not data_out(33);
		else 
			--LL_OUT_SRC_RDY_N <= '1';
--			sig_LL_OUT_SOF_N <= sig_LL_OUT_SOF_N;			
--			sig_LL_OUT_EOF_N <= sig_LL_OUT_EOF_N;
		end if;
	end if;
end process;

LL_OUT_D       <= data_out(31 downto 0);
LL_OUT_SOF_N <= sig_set_sof;
LL_OUT_EOF_N <= sig_set_eof;
LL_OUT_SRC_RDY_N <= sig_set_src_rdy;
LL_IN_DST_RDY_N_1	<= FIFO_1_FULL;
LL_IN_DST_RDY_N_2	<= FIFO_2_FULL;

end Behavioral;

