library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity main is
port(
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
	fpga_0_Hard_Ethernet_MAC_GMII_TX_ER_0_pin : out std_logic
);
end main;

architecture Behavioral of main is

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

signal clk,reset : std_logic;

begin

transceivers:  main_module
port map(
	-- to hardware pins
	fpga_1_sfp_a_rd_p_pin => fpga_1_sfp_a_rd_p_pin,
	fpga_1_sfp_a_rd_n_pin => fpga_1_sfp_a_rd_n_pin,
	fpga_1_sfp_a_td_p_pin => fpga_1_sfp_a_td_p_pin,
	fpga_1_sfp_a_td_n_pin => fpga_1_sfp_a_td_n_pin,
	fpga_1_sfp_b_rd_p_pin => fpga_1_sfp_b_rd_p_pin,
	fpga_1_sfp_b_rd_n_pin => fpga_1_sfp_b_rd_n_pin,
	fpga_1_sfp_b_td_p_pin => fpga_1_sfp_b_td_p_pin,
	fpga_1_sfp_b_td_n_pin => fpga_1_sfp_b_td_n_pin,

	fpga_0_sfp_a_rd_p_pin => fpga_0_sfp_a_rd_p_pin,
	fpga_0_sfp_a_rd_n_pin => fpga_0_sfp_a_rd_n_pin,
	fpga_0_sfp_a_td_p_pin => fpga_0_sfp_a_td_p_pin,
	fpga_0_sfp_a_td_n_pin => fpga_0_sfp_a_td_n_pin,
	fpga_0_sfp_b_rd_p_pin => fpga_0_sfp_b_rd_p_pin,
	fpga_0_sfp_b_rd_n_pin => fpga_0_sfp_b_rd_n_pin,
	fpga_0_sfp_b_td_p_pin => fpga_0_sfp_b_td_p_pin,
	fpga_0_sfp_b_td_n_pin => fpga_0_sfp_b_td_n_pin,

	fpga_1_phy_125_clk_pin => fpga_1_phy_125_clk_pin,
	fpga_0_rst_1_sys_rst_pin => fpga_0_rst_1_sys_rst_pin,
	fpga_0_Hard_Ethernet_MAC_TemacPhy_RST_n_pin	=> fpga_0_Hard_Ethernet_MAC_TemacPhy_RST_n_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_RXD_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_RXD_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_RX_CLK_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_RX_CLK_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_RX_DV_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_RX_DV_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_RX_ER_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_RX_ER_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_TXD_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_TXD_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_TX_CLK_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_TX_CLK_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_TX_EN_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_TX_EN_0_pin,
	fpga_0_Hard_Ethernet_MAC_GMII_TX_ER_0_pin => fpga_0_Hard_Ethernet_MAC_GMII_TX_ER_0_pin,
	
	MAIN_CLK_OUT                     => clk,
	MAIN_RESET_OUT                   => reset,
	
	-- receiver 1 interface
	REC1_LL_UDP_OUT_DATA_OUT         => ll_data1,
	REC1_LL_UDP_OUT_REM_OUT          => ll_rem1,
	REC1_LL_UDP_OUT_SOF_N_OUT        => ll_sof1,
	REC1_LL_UDP_OUT_EOF_N_OUT        => ll_eof1,
	REC1_LL_UDP_OUT_SRC_READY_N_OUT  => ll_src1,
	REC1_LL_UDP_OUT_DST_READY_N_IN   => ll_dst1,
	REC1_LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
	REC1_LL_UDP_OUT_WRITE_CLK_OUT    => ll_clk1,
	
	-- receiver 2 interface
	REC2_LL_UDP_OUT_DATA_OUT         => ll_data2,
	REC2_LL_UDP_OUT_REM_OUT          => ll_rem2,
	REC2_LL_UDP_OUT_SOF_N_OUT        => ll_sof2,
	REC2_LL_UDP_OUT_EOF_N_OUT        => ll_eof2,
	REC2_LL_UDP_OUT_SRC_READY_N_OUT  => ll_src2,
	REC2_LL_UDP_OUT_DST_READY_N_IN   => ll_dst2,
	REC2_LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
	REC2_LL_UDP_OUT_WRITE_CLK_OUT    => ll_clk2,
	
	-- transmitter 1 interface
	TRANS1_LL_DATA_IN              => ll_data3,
	TRANS1_LL_REM_IN               => ll_rem3,
	TRANS1_LL_SOF_N_IN             => ll_sof3,
	TRANS1_LL_EOF_N_IN             => ll_eof3,
	TRANS1_LL_SRC_READY_N_IN       => ll_src3,
	TRANS1_LL_DST_READY_N_OUT      => ll_dst3,
	TRANS1_LL_READ_CLK_OUT         => ll_clk3
);

evtbuilder: eventbuilder_v3 
  port map(
	CLK                            => clk,
	reset                          => reset,
	
	LL_IN_D_1                      => ll_data1,
	LL_IN_REM_1                    => ll_rem1,
	LL_IN_SRC_RDY_N_1              => ll_src1,
	LL_IN_SOF_N_1                  => ll_sof1,
	LL_IN_EOF_N_1                  => ll_eof1,
	LL_IN_DST_RDY_N_1              => ll_dst1,
		
	LL_IN_D_2                      => ll_data2,
	LL_IN_REM_2                    => ll_rem2,
	LL_IN_SRC_RDY_N_2              => ll_src2,
	LL_IN_SOF_N_2                  => ll_sof2,
	LL_IN_EOF_N_2                  => ll_eof2,
	LL_IN_DST_RDY_N_2              => ll_dst2,
	
	LL_OUT_D                       => ll_data3,
	LL_OUT_REM                     => ll_rem3,
	LL_OUT_SRC_RDY_N               => ll_src3,
	LL_OUT_SOF_N                   => ll_sof3,
	LL_OUT_EOF_N                   => ll_eof3,
	LL_OUT_DST_RDY_N               => ll_dst3
);
	
end Behavioral;

