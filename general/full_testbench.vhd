library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity full_testbench is
end full_testbench;

architecture Behavioral of full_testbench is

signal clk_125, userclk : std_logic;
signal rx_clk : std_logic;
signal reset   : std_logic;
signal reset_i   : std_logic;
signal client_rxd1, client_rxd2, client_rxd3 : std_logic_vector(7 downto 0);
signal client_rx_dv1, client_tx_dv1, client_rx_dv2, client_tx_dv2, client_tx_dv3, client_rx_dv3 : std_logic;
signal client_fb1, client_fb2, client_fb3 : std_logic;
signal client_txd1, client_txd2, client_txd3 : std_logic_vector(7 downto 0);
signal client_good_frame1, client_bad_frame1 : std_logic;
signal client_good_frame2, client_bad_frame2 : std_logic;
signal client_good_frame3, client_bad_frame3 : std_logic;
signal rx_clk_i, userclk_i           : std_logic;
signal reset_ctr                     : unsigned(31 downto 0);
signal v5_clk_125                    : std_logic;
signal clk125_o_bufg                 : std_logic;
signal clk62_5                       : std_logic;
signal gtreset                       : std_logic;
signal reset_r                       : std_logic_vector(3 downto 0);
signal clk_125_ds                    : std_logic;
signal client_stats1, client_stats2, client_stats3  : std_logic; 
signal client_ack1, client_ack2, client_ack3      : std_logic;
signal v5_gmii_rx_clk                : std_logic;
signal clk125_fb, clk62_5_pre_bufg, tx_clk : std_logic;
signal ll_sof, ll_eof, ll_src, ll_dst, ll_clk : std_logic;
signal ll_data : std_logic_vector(31 downto 0);
signal ll_rem : std_logic_vector(1 downto 0);
component eventbuilder_v3 is
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
end component;

signal ll_sof1, ll_eof1, ll_src1, ll_dst1, ll_clk1 : std_logic;
signal ll_data1 : std_logic_vector(31 downto 0);
signal ll_rem1 : std_logic_vector(1 downto 0);

signal ll_sof2, ll_eof2, ll_src2, ll_dst2, ll_clk2 : std_logic;
signal ll_data2 : std_logic_vector(31 downto 0);
signal ll_rem2 : std_logic_vector(1 downto 0);

signal ll_sof3, ll_eof3, ll_src3, ll_dst3, ll_clk3 : std_logic;
signal ll_data3 : std_logic_vector(31 downto 0);
signal ll_rem3 : std_logic_vector(1 downto 0);

begin

--evtbuilder: eventbuilder_v3 
--  port map(
--	CLK                            => rx_clk,
--	reset                          => reset,
--	
--	LL_IN_D_1                      => ll_data1,
--	LL_IN_REM_1                    => ll_rem1,
--	LL_IN_SRC_RDY_N_1              => ll_src1,
--	LL_IN_SOF_N_1                  => ll_sof1,
--	LL_IN_EOF_N_1                  => ll_eof1,
--	LL_IN_DST_RDY_N_1              => ll_dst1,
--		
--	LL_IN_D_2                      => ll_data2,
--	LL_IN_REM_2                    => ll_rem2,
--	LL_IN_SRC_RDY_N_2              => ll_src2,
--	LL_IN_SOF_N_2                  => ll_sof2,
--	LL_IN_EOF_N_2                  => ll_eof2,
--	LL_IN_DST_RDY_N_2              => ll_dst2,
--	
--	LL_OUT_D                       => ll_data3,
--	LL_OUT_REM                     => ll_rem3,
--	LL_OUT_SRC_RDY_N               => ll_src3,
--	LL_OUT_SOF_N                   => ll_sof3,
--	LL_OUT_EOF_N                   => ll_eof3,
--	LL_OUT_DST_RDY_N               => ll_dst3
--);

ll_tester : entity work.ll_client
	port map(TX_D         => ll_data1,
		     TX_REM       => ll_rem1,
		     TX_SRC_RDY_N => ll_src1,
		     TX_SOF_N     => ll_sof1,
		     TX_EOF_N     => ll_eof1,
		     TX_DST_RDY_N => ll_dst1,
		     USER_CLK     => ll_clk1);


	REC1 : receiver_module
	generic map(
		UDP_RECEIVER         => 1,
		UDP_TRANSMITTER      => 0,
		MAC_ADDRESS          => x"1111efbe0000"
	)
	port map(
		SYS_CLK              => '0',
		RESET_IN             => reset,
		CLK_125_IN           => rx_clk,
		TX_CLK_IN            => userclk,
		
		RX_DATA_IN           => client_rxd1,
		RX_DATA_DV_IN        => client_rx_dv1,
		RX_DATA_GF_IN        => client_good_frame1,
		RX_DATA_BF_IN        => client_bad_frame1,
		
		TX_DATA_OUT          => client_txd1,
		TX_DATA_DV_OUT       => client_tx_dv1,
		TX_DATA_FB_OUT       => client_fb1,
		TX_DATA_ACK_IN       => client_ack1,
		TX_DATA_STATS_VALID_IN => client_stats1,
		
		LL_UDP_OUT_DATA_OUT         => ll_data1,
		LL_UDP_OUT_REM_OUT          => ll_rem1,
		LL_UDP_OUT_SOF_N_OUT        => ll_sof1,
		LL_UDP_OUT_EOF_N_OUT        => ll_eof1,
		LL_UDP_OUT_SRC_READY_N_OUT  => ll_src1,
		LL_UDP_OUT_DST_READY_N_IN   => ll_dst1,
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => ll_clk1,

		LL_DATA_IN              => (others => '0'),
		LL_REM_IN               => (others => '0'),
		LL_SOF_N_IN             => '1',
		LL_EOF_N_IN             => '1',
		LL_SRC_READY_N_IN       => '1',
		LL_DST_READY_N_OUT      => open,
		LL_READ_CLK_OUT         => open	
	);
	
	REC2 : receiver_module
	generic map(
		UDP_RECEIVER         => 1,
		UDP_TRANSMITTER      => 0,
		MAC_ADDRESS          => x"2222efbe0000"
	)
	port map(
		SYS_CLK              => '0',
		RESET_IN             => reset,
		CLK_125_IN           => rx_clk,
		TX_CLK_IN            => userclk,
		
		RX_DATA_IN           => client_rxd1,
		RX_DATA_DV_IN        => client_rx_dv1,
		RX_DATA_GF_IN        => client_good_frame1,
		RX_DATA_BF_IN        => client_bad_frame1,
		
		TX_DATA_OUT          => client_txd2,
		TX_DATA_DV_OUT       => client_tx_dv2,
		TX_DATA_FB_OUT       => client_fb2,
		TX_DATA_ACK_IN       => client_ack2,
		TX_DATA_STATS_VALID_IN => client_stats2,
		
		LL_UDP_OUT_DATA_OUT         => ll_data2,
		LL_UDP_OUT_REM_OUT          => ll_rem2,
		LL_UDP_OUT_SOF_N_OUT        => ll_sof2,
		LL_UDP_OUT_EOF_N_OUT        => ll_eof2,
		LL_UDP_OUT_SRC_READY_N_OUT  => ll_src2,
		LL_UDP_OUT_DST_READY_N_IN   => ll_dst2,
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => ll_clk2,
		
		LL_DATA_IN              => (others => '0'),
		LL_REM_IN               => (others => '0'),
		LL_SOF_N_IN             => '1',
		LL_EOF_N_IN             => '1',
		LL_SRC_READY_N_IN       => '1',
		LL_DST_READY_N_OUT      => open,
		LL_READ_CLK_OUT         => open		
	);
	
	TRANS1 : receiver_module
	generic map(
		UDP_RECEIVER         => 0,
		UDP_TRANSMITTER      => 1,
		MAC_ADDRESS          => x"3333efbe0000"
	)
	port map(
		SYS_CLK              => '0',
		RESET_IN             => reset,
		CLK_125_IN           => v5_gmii_rx_clk,
		TX_CLK_IN            => v5_gmii_rx_clk,
		
		RX_DATA_IN           => client_rxd3,
		RX_DATA_DV_IN        => client_rx_dv3,
		RX_DATA_GF_IN        => client_good_frame3,
		RX_DATA_BF_IN        => client_bad_frame3,
		
		TX_DATA_OUT          => client_txd3,
		TX_DATA_DV_OUT       => client_tx_dv3,
		TX_DATA_FB_OUT       => client_fb3,
		TX_DATA_ACK_IN       => client_ack3,
		TX_DATA_STATS_VALID_IN => client_stats3,
		
		LL_UDP_OUT_DATA_OUT         => open,
		LL_UDP_OUT_REM_OUT          => open,
		LL_UDP_OUT_SOF_N_OUT        => open,
		LL_UDP_OUT_EOF_N_OUT        => open,
		LL_UDP_OUT_SRC_READY_N_OUT  => open,
		LL_UDP_OUT_DST_READY_N_IN   => '1',
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => open,

		LL_DATA_IN              => ll_data1,
		LL_REM_IN               => ll_rem1,
		LL_SOF_N_IN             => ll_sof1,
		LL_EOF_N_IN             => ll_eof1,
		LL_SRC_READY_N_IN       => ll_src1,
		LL_DST_READY_N_OUT      => ll_dst1,
		LL_READ_CLK_OUT         => open		
	);

process
begin
	v5_gmii_rx_clk <= '1';
	wait for 4 ns;
	v5_gmii_rx_clk <= '0';
	wait for 4 ns;
end process;

rx_clk <= v5_gmii_rx_clk;
userclk <= v5_gmii_rx_clk;

testbench_process : process
begin

	reset <= '1';
	client_rx_dv1 <= '0';
	client_rxd1 <= x"00";
	client_good_frame1 <= '0';
	wait for 100 ns;
	reset <= '0';
	wait for 100 ns;
	
	wait until rising_edge(rx_clk);
	client_rx_dv1 <= '1';
-- dest mac
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";
	wait until rising_edge(rx_clk);
-- src mac
	client_rxd1		<= x"00";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"aa";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"bb";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"cc";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"dd";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ee";
	wait until rising_edge(rx_clk);
-- frame type
	client_rxd1		<= x"08";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"00";
	wait until rising_edge(rx_clk);
-- ip headers
	client_rxd1		<= x"45";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"10";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"01";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"5a";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"01";  -- id
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"03";  -- id
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"00";  -- f/o
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"00";  -- f/o
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ff";  -- ttl
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"11";  -- udp
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"cc";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"cc";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"c0";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"a8";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"00";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"01";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"c0";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"a8";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"00";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"02";
-- udp headers
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"61";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"a8";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"61";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"a8";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"02";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"2c";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"aa";
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"bb";
-- payload
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"ab";
	
	for i in 1 to 100 loop
		wait until rising_edge(rx_clk);
		client_rxd1		<= std_logic_vector(to_unsigned(i, 8));
	end loop;
	
	wait until rising_edge(rx_clk);
	client_rxd1		<= x"cd";
		wait until rising_edge(rx_clk);
	client_rxd1		<= x"ef";
		wait until rising_edge(rx_clk);
	client_rxd1		<= x"aa";
	wait until rising_edge(rx_clk);
		client_good_frame1 <= '1';
	
	wait until rising_edge(rx_clk);
	client_rx_dv1 <='0';
	client_good_frame1 <= '0';
	
	
	wait;

end process testbench_process;




end Behavioral;

