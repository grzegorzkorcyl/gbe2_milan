library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity main_module is
port(
	-- to hardware pins
	fpga_1_sfp_a_rd_p_pin : in std_logic;
	fpga_1_sfp_a_rd_n_pin : in std_logic;
	fpga_1_sfp_a_td_p_pin : out std_logic;
	fpga_1_sfp_a_td_n_pin : out std_logic;
	fpga_1_sfp_b_rd_p_pin : in std_logic;
	fpga_1_sfp_b_rd_n_pin : in std_logic;
	fpga_1_sfp_b_td_p_pin : out std_logic;
	fpga_1_sfp_b_td_n_pin : out std_logic;
	
	fpga_0_sfp_a_rd_p_pin : in std_logic;
	fpga_0_sfp_a_rd_n_pin : in std_logic;
	fpga_0_sfp_a_td_p_pin : out std_logic;
	fpga_0_sfp_a_td_n_pin : out std_logic;
	fpga_0_sfp_b_rd_p_pin : in std_logic;
	fpga_0_sfp_b_rd_n_pin : in std_logic;
	fpga_0_sfp_b_td_p_pin : out std_logic;
	fpga_0_sfp_b_td_n_pin : out std_logic;
	
	fpga_1_phy_125_clk_pin : in std_logic;
	fpga_0_rst_1_sys_rst_pin : in std_logic;
	fpga_0_Hard_Ethernet_MAC_TemacPhy_RST_n_pin	: out std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_RXD_0_pin : in std_logic_vector(7 downto 0);
	fpga_0_Hard_Ethernet_MAC_GMII_RX_CLK_0_pin : in std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_RX_DV_0_pin : in std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_RX_ER_0_pin : in std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_TXD_0_pin : out std_logic_vector(7 downto 0);
	fpga_0_Hard_Ethernet_MAC_GMII_TX_CLK_0_pin : out std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_TX_EN_0_pin : out std_logic;
	fpga_0_Hard_Ethernet_MAC_GMII_TX_ER_0_pin : out std_logic;
	
	MAIN_CLK_OUT                     : out std_logic;
	MAIN_RESET_OUT                   : out std_logic;
	
	-- receiver 1 interface
	REC1_LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	REC1_LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	REC1_LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	REC1_LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	REC1_LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	REC1_LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	REC1_LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	REC1_LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;
	
	-- receiver 2 interface
	REC2_LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	REC2_LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	REC2_LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	REC2_LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	REC2_LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	REC2_LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	REC2_LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	REC2_LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;
	
	-- transmitter 1 interface
	TRANS1_LL_DATA_IN              : in std_logic_vector(31 downto 0);
	TRANS1_LL_REM_IN               : in std_logic_vector(1 downto 0);
	TRANS1_LL_SOF_N_IN             : in std_logic;
	TRANS1_LL_EOF_N_IN             : in std_logic;
	TRANS1_LL_SRC_READY_N_IN       : in std_logic;
	TRANS1_LL_DST_READY_N_OUT      : out std_logic;
	TRANS1_LL_READ_CLK_OUT         : out std_logic
);
end main_module;

architecture Behavioral of main_module is

signal clk_125, userclk : std_logic;
signal rx_clk : std_logic;
signal reset   : std_logic;
signal reset_i   : std_logic;
signal client_rxd1, client_rxd2, client_rxd3, client_rxd4 : std_logic_vector(7 downto 0);
signal client_rx_dv1, client_tx_dv1, client_rx_dv2, client_tx_dv2, client_tx_dv3, client_rx_dv3, client_rx_dv4, client_tx_dv4 : std_logic;
signal client_fb1, client_fb2, client_fb3, client_fb4 : std_logic;
signal client_txd1, client_txd2, client_txd3, client_txd4 : std_logic_vector(7 downto 0);
signal client_good_frame1, client_bad_frame1 : std_logic;
signal client_good_frame2, client_bad_frame2 : std_logic;
signal client_good_frame3, client_bad_frame3 : std_logic;
signal client_good_frame4, client_bad_frame4 : std_logic;
signal rx_clk_i, userclk_i           : std_logic;
signal reset_ctr                     : unsigned(31 downto 0);
signal v5_clk_125                    : std_logic;
signal clk125_o_bufg                 : std_logic;
signal clk62_5                       : std_logic;
signal gtreset                       : std_logic;
signal reset_r                       : std_logic_vector(3 downto 0);
signal clk_125_ds                    : std_logic;
signal client_stats1, client_stats2, client_stats3, client_stats4  : std_logic; 
signal client_ack1, client_ack2, client_ack3, client_ack4      : std_logic;
signal v5_gmii_rx_clk                : std_logic;
signal clk125_fb, clk62_5_pre_bufg, tx_clk : std_logic;
signal ll_sof, ll_eof, ll_src, ll_dst, ll_clk : std_logic;
signal ll_data : std_logic_vector(31 downto 0);
signal ll_rem : std_logic_vector(1 downto 0);

begin
	
	MAIN_CLK_OUT <= rx_clk;
	MAIN_RESET_OUT <= reset;

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
		
		LL_UDP_OUT_DATA_OUT         => REC1_LL_UDP_OUT_DATA_OUT,
		LL_UDP_OUT_REM_OUT          => REC1_LL_UDP_OUT_REM_OUT,
		LL_UDP_OUT_SOF_N_OUT        => REC1_LL_UDP_OUT_SOF_N_OUT,
		LL_UDP_OUT_EOF_N_OUT        => REC1_LL_UDP_OUT_EOF_N_OUT,
		LL_UDP_OUT_SRC_READY_N_OUT  => REC1_LL_UDP_OUT_SRC_READY_N_OUT,
		LL_UDP_OUT_DST_READY_N_IN   => REC1_LL_UDP_OUT_DST_READY_N_IN,
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => REC1_LL_UDP_OUT_WRITE_CLK_OUT,

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
		
		RX_DATA_IN           => client_rxd2,
		RX_DATA_DV_IN        => client_rx_dv2,
		RX_DATA_GF_IN        => client_good_frame2,
		RX_DATA_BF_IN        => client_bad_frame2,
		
		TX_DATA_OUT          => client_txd2,
		TX_DATA_DV_OUT       => client_tx_dv2,
		TX_DATA_FB_OUT       => client_fb2,
		TX_DATA_ACK_IN       => client_ack2,
		TX_DATA_STATS_VALID_IN => client_stats2,
		
		LL_UDP_OUT_DATA_OUT         => REC2_LL_UDP_OUT_DATA_OUT,
		LL_UDP_OUT_REM_OUT          => REC2_LL_UDP_OUT_REM_OUT,
		LL_UDP_OUT_SOF_N_OUT        => REC2_LL_UDP_OUT_SOF_N_OUT,
		LL_UDP_OUT_EOF_N_OUT        => REC2_LL_UDP_OUT_EOF_N_OUT,
		LL_UDP_OUT_SRC_READY_N_OUT  => REC2_LL_UDP_OUT_SRC_READY_N_OUT,
		LL_UDP_OUT_DST_READY_N_IN   => REC2_LL_UDP_OUT_DST_READY_N_IN,
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => REC2_LL_UDP_OUT_WRITE_CLK_OUT,
		
		LL_DATA_IN              => (others => '0'),
		LL_REM_IN               => (others => '0'),
		LL_SOF_N_IN             => '1',
		LL_EOF_N_IN             => '1',
		LL_SRC_READY_N_IN       => '1',
		LL_DST_READY_N_OUT      => open,
		LL_READ_CLK_OUT         => open		
	);
	
	REC3 : receiver_module
	generic map(
		UDP_RECEIVER         => 1,
		UDP_TRANSMITTER      => 0,
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
		MAC_ADDRESS          => x"4444efbe0000"
	)
	port map(
		SYS_CLK              => '0',
		RESET_IN             => reset,
		CLK_125_IN           => v5_gmii_rx_clk,
		TX_CLK_IN            => v5_gmii_rx_clk,
		
		RX_DATA_IN           => client_rxd4,
		RX_DATA_DV_IN        => client_rx_dv4,
		RX_DATA_GF_IN        => client_good_frame4,
		RX_DATA_BF_IN        => client_bad_frame4,
		
		TX_DATA_OUT          => client_txd4,
		TX_DATA_DV_OUT       => client_tx_dv4,
		TX_DATA_FB_OUT       => client_fb4,
		TX_DATA_ACK_IN       => client_ack4,
		TX_DATA_STATS_VALID_IN => client_stats4,
		
		LL_UDP_OUT_DATA_OUT         => open,
		LL_UDP_OUT_REM_OUT          => open,
		LL_UDP_OUT_SOF_N_OUT        => open,
		LL_UDP_OUT_EOF_N_OUT        => open,
		LL_UDP_OUT_SRC_READY_N_OUT  => open,
		LL_UDP_OUT_DST_READY_N_IN   => '1',
		LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
		LL_UDP_OUT_WRITE_CLK_OUT    => open,

		LL_DATA_IN              => TRANS1_LL_DATA_IN,
		LL_REM_IN               => TRANS1_LL_REM_IN,
		LL_SOF_N_IN             => TRANS1_LL_SOF_N_IN,
		LL_EOF_N_IN             => TRANS1_LL_EOF_N_IN,
		LL_SRC_READY_N_IN       => TRANS1_LL_SRC_READY_N_IN,
		LL_DST_READY_N_OUT      => TRANS1_LL_DST_READY_N_OUT,
		LL_READ_CLK_OUT         => TRANS1_LL_READ_CLK_OUT		
	);

    v5_emac_block_inst_1 : v5_dual_mac_block
    port map (
          -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      => v5_clk_125,
      -- 125MHz clock input from BUFG
      CLK125                          => clk_125,
      -- 62.5MHz clock input from BUFG
      CLK62_5                         => clk62_5,

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  => client_rxd1,
      EMAC0CLIENTRXDVLD               => client_rx_dv1,
      EMAC0CLIENTRXGOODFRAME          => client_good_frame1,
      EMAC0CLIENTRXBADFRAME           => client_bad_frame1,
      EMAC0CLIENTRXFRAMEDROP          => open,
      EMAC0CLIENTRXSTATS              => open,
      EMAC0CLIENTRXSTATSVLD           => open,
      EMAC0CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  => client_txd1,
      CLIENTEMAC0TXDVLD               => client_tx_dv1,
      EMAC0CLIENTTXACK                => client_ack1,
      CLIENTEMAC0TXFIRSTBYTE          => client_fb1,
      CLIENTEMAC0TXUNDERRUN           => '0',
      EMAC0CLIENTTXCOLLISION          => open,
      EMAC0CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC0TXIFGDELAY           => (others => '0'),
      EMAC0CLIENTTXSTATS              => open,
      EMAC0CLIENTTXSTATSVLD           => client_stats1,
      EMAC0CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => '0',
      CLIENTEMAC0PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        => open,
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                => open,

      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           => fpga_0_sfp_a_td_p_pin,
      TXN_0                           => fpga_0_sfp_a_td_n_pin,
      RXP_0                           => fpga_0_sfp_a_rd_p_pin,
      RXN_0                           => fpga_0_sfp_a_rd_n_pin,
      PHYAD_0                         => "00001",
      RESETDONE_0                     => open,

      -- EMAC1 Clocking

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXD                  => client_rxd2,
      EMAC1CLIENTRXDVLD               => client_rx_dv2,
      EMAC1CLIENTRXGOODFRAME          => client_good_frame2,
      EMAC1CLIENTRXBADFRAME           => client_bad_frame2,
      EMAC1CLIENTRXFRAMEDROP          => open,
      EMAC1CLIENTRXSTATS              => open,
      EMAC1CLIENTRXSTATSVLD           => open,
      EMAC1CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC1
      CLIENTEMAC1TXD                  => client_txd2,
      CLIENTEMAC1TXDVLD               => client_tx_dv2,
      EMAC1CLIENTTXACK                => client_ack2,
      CLIENTEMAC1TXFIRSTBYTE          => client_fb2,
      CLIENTEMAC1TXUNDERRUN           => '0',
      EMAC1CLIENTTXCOLLISION          => open,
      EMAC1CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC1TXIFGDELAY           => (others => '0'),
      EMAC1CLIENTTXSTATS              => open,
      EMAC1CLIENTTXSTATSVLD           => client_stats2,
      EMAC1CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             => '0',
      CLIENTEMAC1PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC1CLIENTSYNCACQSTATUS        => open,
      -- EMAC1 Interrupt
      EMAC1ANINTERRUPT                => open,

      -- Clock Signals - EMAC1
      -- 1000BASE-X PCS/PMA Interface - EMAC1
      TXP_1                           => fpga_0_sfp_b_td_p_pin,
      TXN_1                           => fpga_0_sfp_b_td_n_pin,
      RXP_1                           => fpga_0_sfp_b_rd_p_pin,
      RXN_1                           => fpga_0_sfp_b_rd_n_pin,
      PHYAD_1                         => "00001",
      RESETDONE_1                     => open,

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          => clk_125_ds,

      -- RocketIO Reset input
      GTRESET                         => gtreset,

      -- Asynchronous Reset
      RESET                           => reset
   );
	
	v5_emac_block_inst_2 : v5_dual_mac_block
    port map (
          -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      => open, --v5_clk_125,
      -- 125MHz clock input from BUFG
      CLK125                          => clk_125,
      -- 62.5MHz clock input from BUFG
      CLK62_5                         => clk62_5,

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  => client_rxd3,
      EMAC0CLIENTRXDVLD               => client_rx_dv3,
      EMAC0CLIENTRXGOODFRAME          => client_good_frame3,
      EMAC0CLIENTRXBADFRAME           => client_bad_frame3,
      EMAC0CLIENTRXFRAMEDROP          => open,
      EMAC0CLIENTRXSTATS              => open,
      EMAC0CLIENTRXSTATSVLD           => open,
      EMAC0CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  => client_txd3,
      CLIENTEMAC0TXDVLD               => client_tx_dv3,
      EMAC0CLIENTTXACK                => client_ack3,
      CLIENTEMAC0TXFIRSTBYTE          => client_fb3,
      CLIENTEMAC0TXUNDERRUN           => '0',
      EMAC0CLIENTTXCOLLISION          => open,
      EMAC0CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC0TXIFGDELAY           => (others => '0'),
      EMAC0CLIENTTXSTATS              => open,
      EMAC0CLIENTTXSTATSVLD           => client_stats3,
      EMAC0CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => '0',
      CLIENTEMAC0PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        => open,
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                => open,

      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           => fpga_1_sfp_a_td_p_pin,
      TXN_0                           => fpga_1_sfp_a_td_n_pin,
      RXP_0                           => fpga_1_sfp_a_rd_p_pin,
      RXN_0                           => fpga_1_sfp_a_rd_n_pin,
      PHYAD_0                         => "00001",
      RESETDONE_0                     => open,

      -- EMAC1 Clocking

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXD                  => client_rxd4,
      EMAC1CLIENTRXDVLD               => client_rx_dv4,
      EMAC1CLIENTRXGOODFRAME          => client_good_frame4,
      EMAC1CLIENTRXBADFRAME           => client_bad_frame4,
      EMAC1CLIENTRXFRAMEDROP          => open,
      EMAC1CLIENTRXSTATS              => open,
      EMAC1CLIENTRXSTATSVLD           => open,
      EMAC1CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC1
      CLIENTEMAC1TXD                  => client_txd4,
      CLIENTEMAC1TXDVLD               => client_tx_dv4,
      EMAC1CLIENTTXACK                => client_ack4,
      CLIENTEMAC1TXFIRSTBYTE          => client_fb4,
      CLIENTEMAC1TXUNDERRUN           => '0',
      EMAC1CLIENTTXCOLLISION          => open,
      EMAC1CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC1TXIFGDELAY           => (others => '0'),
      EMAC1CLIENTTXSTATS              => open,
      EMAC1CLIENTTXSTATSVLD           => client_stats4,
      EMAC1CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             => '0',
      CLIENTEMAC1PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC1CLIENTSYNCACQSTATUS        => open,
      -- EMAC1 Interrupt
      EMAC1ANINTERRUPT                => open,

      -- Clock Signals - EMAC1
      -- 1000BASE-X PCS/PMA Interface - EMAC1
      TXP_1                           => fpga_1_sfp_b_td_p_pin,
      TXN_1                           => fpga_1_sfp_b_td_n_pin,
      RXP_1                           => fpga_1_sfp_b_rd_p_pin,
      RXN_1                           => fpga_1_sfp_b_rd_n_pin,
      PHYAD_1                         => "00001",
      RESETDONE_1                     => open,

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          => clk_125_ds,

      -- RocketIO Reset input
      GTRESET                         => gtreset,

      -- Asynchronous Reset
      RESET                           => reset
   );
				
	bufg_clk125_ds: BUFG port map(I => fpga_1_phy_125_clk_pin, O => clk_125_ds);

	-- 125MHz from transceiver is routed through a BUFG and input 
	-- to DCM.
	bufg_clk125_o: BUFG port map(I => v5_clk_125, O => clk125_o_bufg);

	-- 125MHz from DCM is routed through a BUFG and input to the 
	-- MAC wrappers.
	-- This clock can be shared between multiple MAC instances.
	bufg_clk125 : BUFG port map(I => clk125_fb, O => clk_125);

	clk62_5_bufg : BUFG port map(I => clk62_5_pre_bufg, O => clk62_5);

	-- Divide 125MHz reference clock down by 2 to get
	-- 62.5MHz clock for 2 byte GTX internal datapath.
	clk62_5_dcm : DCM_BASE 
	port map 
	(CLKIN      => clk125_o_bufg,
	CLK0       => clk125_fb,
	CLK180     => open,
	CLK270     => open,
	CLK2X      => open,
	CLK2X180   => open,
	CLK90      => open,
	CLKDV      => clk62_5_pre_bufg,
	CLKFX      => open,
	CLKFX180   => open,
	LOCKED     => open,
	CLKFB      => clk_125,
	RST        => reset_i);

	rx_clk_i  <= clk_125;
	userclk_i <= clk_125;

	rx_clk    <= rx_clk_i;
	userclk   <= userclk_i;
	
	GTRESET_PROC : process(reset, clk125_o_bufg)
	begin
		if (reset = '1') then
			reset_r <= "1111";
		elsif rising_edge(clk125_o_bufg) then
			reset_r <= reset_r(2 downto 0) & reset_i;
		end if;
	end process;

	gtreset <= reset_r(3);
	
	RESET_PROC : process(v5_gmii_rx_clk)
	begin
		if rising_edge(v5_gmii_rx_clk) then
			if (reset_ctr > x"0000_f000" and reset_ctr < x"0000_ffff") then
				reset <= '1';
			else
				if (fpga_0_rst_1_sys_rst_pin = '0') then
					reset <= '1';
				else
					reset <= '0';
				end if;
			end if;
		end if;
	end process RESET_PROC;
	
	-- copper
--	copper_mac : mac_v5_copper_block
--	port map (
--		-- EMAC0 Clocking
--		-- TX Clock output from EMAC
--		TX_CLK_OUT                      => open,
--		-- EMAC0 TX Clock input from BUFG
--		TX_CLK_0                        => v5_gmii_rx_clk, --userclk_i,
--		
--		-- Client Receiver Interface - EMAC0
--		EMAC0CLIENTRXD                  => client_rxd3,
--		EMAC0CLIENTRXDVLD               => client_rx_dv3,
--		EMAC0CLIENTRXGOODFRAME          => client_good_frame3,
--		EMAC0CLIENTRXBADFRAME           => client_bad_frame3,
--		EMAC0CLIENTRXFRAMEDROP          => open,
--		EMAC0CLIENTRXSTATS              => open,
--		EMAC0CLIENTRXSTATSVLD           => open,
--		EMAC0CLIENTRXSTATSBYTEVLD       => open,
--
--		-- Client Transmitter Interface - EMAC0
--		CLIENTEMAC0TXD                  => client_txd3,
--		CLIENTEMAC0TXDVLD               => client_tx_dv3,
--		EMAC0CLIENTTXACK                => client_ack3,
--		CLIENTEMAC0TXFIRSTBYTE          => client_fb3,
--		CLIENTEMAC0TXUNDERRUN           => '0',
--		EMAC0CLIENTTXCOLLISION          => open,
--		EMAC0CLIENTTXRETRANSMIT         => open,
--		CLIENTEMAC0TXIFGDELAY           => (others => '0'),
--		EMAC0CLIENTTXSTATS              => open,
--		EMAC0CLIENTTXSTATSVLD           => client_stats3,
--		EMAC0CLIENTTXSTATSBYTEVLD       => open,
--
--		-- MAC Control Interface - EMAC0
--		CLIENTEMAC0PAUSEREQ             => '0',
--		CLIENTEMAC0PAUSEVAL             => (others => '0'),
--
--		-- Clock Signals - EMAC0
--		GTX_CLK_0                       => v5_gmii_rx_clk,
--		-- GMII Interface - EMAC0
--		GMII_TXD_0                      => fpga_0_Hard_Ethernet_MAC_GMII_TXD_0_pin,
--		GMII_TX_EN_0                    => fpga_0_Hard_Ethernet_MAC_GMII_TX_EN_0_pin,
--		GMII_TX_ER_0                    => fpga_0_Hard_Ethernet_MAC_GMII_TX_ER_0_pin,
--		GMII_TX_CLK_0                   => fpga_0_Hard_Ethernet_MAC_GMII_TX_CLK_0_pin,
--		GMII_RXD_0                      => fpga_0_Hard_Ethernet_MAC_GMII_RXD_0_pin,
--		GMII_RX_DV_0                    => fpga_0_Hard_Ethernet_MAC_GMII_RX_DV_0_pin,
--		GMII_RX_ER_0                    => fpga_0_Hard_Ethernet_MAC_GMII_RX_ER_0_pin,
--		GMII_RX_CLK_0                   => v5_gmii_rx_clk,
--
--		-- Asynchronous Reset
--		RESET                           => reset
--	);
	
	fpga_0_Hard_Ethernet_MAC_TemacPhy_RST_n_pin <= '1';
	
	bufg_rx_0 : BUFG port map (I => fpga_0_Hard_Ethernet_MAC_GMII_RX_CLK_0_pin, O => v5_gmii_rx_clk);
	
	delayctrl : IDELAYCTRL port map ( RDY => open, RST => reset, REFCLK => v5_gmii_rx_clk);
	
	RESET_CTR_PROC : process(v5_gmii_rx_clk)
	begin
		if rising_edge(v5_gmii_rx_clk) then
			if (reset_ctr < x"0000_ffff") then
				reset_ctr <= reset_ctr + 1;
			end if;
		end if;
	end process RESET_CTR_PROC;
	
end Behavioral;

