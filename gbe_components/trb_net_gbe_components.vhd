library ieee;
library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
library work;

use work.trb_net_gbe_protocols.all;

package trb_net_gbe_components is

  function or_all  (arg : std_logic_vector)
    return std_logic;
  function and_all (arg : std_logic_vector)
    return std_logic;
	 
component main_module is
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
end component;

component receiver_module is
generic (
	UDP_RECEIVER         : integer range 0 to 1;
	UDP_TRANSMITTER      : integer range 0 to 1;
	MAC_ADDRESS          : std_logic_vector(47 downto 0)
);
port (
	SYS_CLK              : in std_logic;
	RESET_IN             : in std_logic;
	CLK_125_IN           : in std_logic;
	TX_CLK_IN            : in std_logic;
	
	RX_DATA_IN           : in std_logic_vector(7 downto 0);
	RX_DATA_DV_IN        : in std_logic;
	RX_DATA_GF_IN        : in std_logic;
	RX_DATA_BF_IN        : in std_logic;
	
	TX_DATA_OUT          : out std_logic_vector(7 downto 0);
	TX_DATA_DV_OUT       : out std_logic;
	TX_DATA_FB_OUT       : out std_logic;
	TX_DATA_ACK_IN       : in std_logic;
	TX_DATA_STATS_VALID_IN : in std_logic;
	
	LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;
	
	LL_DATA_IN              : in std_logic_vector(31 downto 0);
	LL_REM_IN               : in std_logic_vector(1 downto 0);
	LL_SOF_N_IN             : in std_logic;
	LL_EOF_N_IN             : in std_logic;
	LL_SRC_READY_N_IN       : in std_logic;
	LL_DST_READY_N_OUT      : out std_logic;
	LL_READ_CLK_OUT         : out std_logic
	
	);
end component;

component trb_net16_gbe_protocol_prioritizer is
port (
	CLK			      : in	std_logic;
	RESET			      : in	std_logic;
	
	FRAME_TYPE_IN		: in	std_logic_vector(15 downto 0);  -- recovered frame type	
	PROTOCOL_CODE_IN	: in	std_logic_vector(7 downto 0);  -- ip protocol
	UDP_PROTOCOL_IN	: in	std_logic_vector(15 downto 0);
	TCP_PROTOCOL_IN   : in  std_logic_vector(15 downto 0);
	
	CODE_OUT		      : out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0)
);
end component;

component trb_net16_gbe_type_validator is
port (
	CLK			             : in	std_logic;  -- 125MHz clock input
	RESET			             : in	std_logic;
	-- ethernet level
	FRAME_TYPE_IN		       : in	std_logic_vector(15 downto 0);  -- recovered frame type	
	SAVED_VLAN_ID_IN	       : in	std_logic_vector(15 downto 0);  -- recovered vlan id
	ALLOWED_TYPES_IN	       : in	std_logic_vector(31 downto 0);  -- signal from gbe_setup
	VLAN_ID_IN		          : in	std_logic_vector(31 downto 0);  -- two values from gbe setup

	-- IP level
	IP_PROTOCOLS_IN		    : in	std_logic_vector(7 downto 0);
	ALLOWED_IP_PROTOCOLS_IN	 : in	std_logic_vector(31 downto 0);
	
	-- UDP level
	UDP_PROTOCOL_IN		    : in	std_logic_vector(15 downto 0);
	ALLOWED_UDP_PROTOCOLS_IN : in	std_logic_vector(31 downto 0);
	
	-- TCP level
	TCP_PROTOCOL_IN          : in std_logic_vector(15 downto 0);
	ALLOWED_TCP_PROTOCOLS_IN : in std_logic_vector(31 downto 0);
	
	VALID_OUT		          : out	std_logic
);
end component;

component trb_net16_gbe_protocol_selector is
generic (
	DO_SIMULATION           : integer range 0 to 1 := 0;
	UDP_RECEIVER         : integer range 0 to 1;
	UDP_TRANSMITTER      : integer range 0 to 1
	);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	PS_DATA_IN		: in	std_logic_vector(8 downto 0); 
	PS_WR_EN_IN		: in	std_logic;
	PS_PROTO_SELECT_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_BUSY_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	PS_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	PS_RESPONSE_READY_OUT	: out	std_logic;
	
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_ID_IP_IN	        : in	std_logic_vector(15 downto 0);
	PS_FO_IP_IN	        : in	std_logic_vector(15 downto 0);
	PS_CHECKSUM_IN	    : in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
	PS_MY_IP_OUT  : out std_logic_vector(31 downto 0);
	
	MC_BUSY_IN    : in std_logic;
	
-- singals to/from transmi controller with constructed response
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	TC_IDENT_OUT		: out	std_logic_vector(15 downto 0);
	TC_CHECKSUM_OUT		: out	std_logic_vector(15 downto 0);
	
	-- counters from response constructors
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	PROTOS_DEBUG_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	-- misc signals for response constructors
	DHCP_START_IN		: in	std_logic;
	DHCP_DONE_OUT		: out	std_logic;
	
	-- interface to provide udp data to kernel
	LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;

	LL_DATA_IN              : in std_logic_vector(31 downto 0);
	LL_REM_IN               : in std_logic_vector(1 downto 0);
	LL_SOF_N_IN             : in std_logic;
	LL_EOF_N_IN             : in std_logic;
	LL_SRC_READY_N_IN       : in std_logic;
	LL_DST_READY_N_OUT      : out std_logic;
	LL_READ_CLK_OUT         : out std_logic;	
	
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_mac_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from main controller
	MC_TSMAC_READY_OUT	: out	std_logic;
	MC_RECONF_IN		: in	std_logic;
	MC_GBE_EN_IN		: in	std_logic;
	MC_RX_DISCARD_FCS	: in	std_logic;
	MC_PROMISC_IN		: in	std_logic;
	MC_MAC_ADDR_IN		: in	std_logic_vector(47 downto 0);

-- signal to/from Host interface of TriSpeed MAC
	TSM_HADDR_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HDATA_OUT		: out	std_logic_vector(7 downto 0);
	TSM_HCS_N_OUT		: out	std_logic;
	TSM_HWRITE_N_OUT	: out	std_logic;
	TSM_HREAD_N_OUT		: out	std_logic;
	TSM_HREADY_N_IN		: in	std_logic;
	TSM_HDATA_EN_N_IN	: in	std_logic;

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_main_control is
generic (
	DO_SIMULATION           : integer range 0 to 1 := 0;
	UDP_RECEIVER         : integer range 0 to 1;
	UDP_TRANSMITTER      : integer range 0 to 1;
	MAC_ADDRESS          : std_logic_vector(47 downto 0)
);
port (
	CLK			: in	std_logic;
	RESET			: in	std_logic;

-- signals to/from receive controller
	RC_FRAME_WAITING_IN	: in	std_logic;
	RC_LOADING_DONE_OUT	: out	std_logic;
	RC_DATA_IN		: in	std_logic_vector(8 downto 0);
	RC_RD_EN_OUT		: out	std_logic;
	RC_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_IN	: in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

	RC_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	RC_ID_IP_IN            : in std_logic_vector(15 downto 0);
	RC_FO_IP_IN            : in std_logic_vector(15 downto 0);
	RC_CHECKSUM_IN         : in std_logic_vector(15 downto 0);

-- signals to/from transmit controller
	TC_TRANSMIT_CTRL_OUT	: out	std_logic;  -- slow control frame is waiting to be built and sent
	TC_TRANSMIT_DATA_OUT	: out	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		: in	std_logic;
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_IDENT_OUT		: out	std_logic_vector(15 downto 0);
	TC_CHECKSUM_OUT     : out   std_logic_vector(15 downto 0);
	TC_TRANSMIT_DONE_IN	: in	std_logic;
	
	PCS_AN_COMPLETE_IN      : in std_logic;
	MC_MY_MAC_OUT           : out std_logic_vector(47 downto 0);
	MC_REDIRECT_TRAFFIC_OUT : out std_logic;
	
	-- interface to provide udp data to kernel
	LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;

	LL_DATA_IN              : in std_logic_vector(31 downto 0);
	LL_REM_IN               : in std_logic_vector(1 downto 0);
	LL_SOF_N_IN             : in std_logic;
	LL_EOF_N_IN             : in std_logic;
	LL_SRC_READY_N_IN       : in std_logic;
	LL_DST_READY_N_OUT      : out std_logic;
	LL_READ_CLK_OUT         : out std_logic;	

	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_transmit_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from packet constructor
	PC_READY_IN		: in	std_logic;
	PC_DATA_IN		: in	std_logic_vector(7 downto 0);
	PC_WR_EN_IN		: in	std_logic;
	PC_IP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	PC_UDP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	PC_FLAGS_OFFSET_IN	: in	std_logic_vector(15 downto 0);
	PC_SOD_IN		: in	std_logic;
	PC_EOD_IN		: in	std_logic;
	PC_FC_READY_OUT		: out	std_logic;
	PC_FC_H_READY_OUT	: out	std_logic;
	PC_TRANSMIT_ON_IN	: in	std_logic;

      -- signals from ip_configurator used by packet constructor
	IC_DEST_MAC_ADDRESS_IN     : in    std_logic_vector(47 downto 0);
	IC_DEST_IP_ADDRESS_IN      : in    std_logic_vector(31 downto 0);
	IC_DEST_UDP_PORT_IN        : in    std_logic_vector(15 downto 0);
	IC_SRC_MAC_ADDRESS_IN      : in    std_logic_vector(47 downto 0);
	IC_SRC_IP_ADDRESS_IN       : in    std_logic_vector(31 downto 0);
	IC_SRC_UDP_PORT_IN         : in    std_logic_vector(15 downto 0);

-- signal to/from main controller
	MC_TRANSMIT_CTRL_IN	: in	std_logic;  -- slow control frame is waiting to be built and sent
	MC_TRANSMIT_DATA_IN	: in	std_logic;
	MC_DATA_IN		: in	std_logic_vector(8 downto 0);
	MC_RD_EN_OUT		: out	std_logic;
	MC_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	MC_FRAME_TYPE_IN	: in	std_logic_vector(15 downto 0);
	
	MC_DEST_MAC_IN		: in	std_logic_vector(47 downto 0);
	MC_DEST_IP_IN		: in	std_logic_vector(31 downto 0);
	MC_DEST_UDP_IN		: in	std_logic_vector(15 downto 0);
	MC_SRC_MAC_IN		: in	std_logic_vector(47 downto 0);
	MC_SRC_IP_IN		: in	std_logic_vector(31 downto 0);
	MC_SRC_UDP_IN		: in	std_logic_vector(15 downto 0);
	
	MC_IP_PROTOCOL_IN	: in	std_logic_vector(7 downto 0);
	MC_IP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	MC_UDP_SIZE_IN		: in	std_logic_vector(15 downto 0);
	MC_FLAGS_OFFSET_IN	: in	std_logic_vector(15 downto 0);
	MC_CHECKSUM_IN      : in    std_logic_vector(15 downto 0);
	MC_BUSY_OUT		: out	std_logic;
	MC_TRANSMIT_DONE_OUT	: out	std_logic;

-- signal to/from frame constructor
	FC_DATA_OUT		: out	std_logic_vector(7 downto 0);
	FC_WR_EN_OUT		: out	std_logic;
	FC_READY_IN		: in	std_logic;
	FC_H_READY_IN		: in	std_logic;
	FC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	FC_IP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	FC_UDP_SIZE_OUT		: out	std_logic_vector(15 downto 0);
	FC_IDENT_OUT		: out	std_logic_vector(15 downto 0);  -- internal packet counter
	FC_FLAGS_OFFSET_OUT	: out	std_logic_vector(15 downto 0);
	FC_CHECKSUM_OUT     : out   std_logic_vector(15 downto 0);
	FC_SOD_OUT		: out	std_logic;
	FC_EOD_OUT		: out	std_logic;
	FC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);

	DEST_MAC_ADDRESS_OUT    : out    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_OUT     : out    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_OUT       : out    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_OUT     : out    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_OUT      : out    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_OUT        : out    std_logic_vector(15 downto 0);


-- debug
	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_transmit_control2 is
port (
	CLK			         : in	std_logic;
	RESET			     : in	std_logic;

-- signal to/from main controller
	TC_DATAREADY_IN        : in 	std_logic;
	TC_RD_EN_OUT		        : out	std_logic;
	TC_DATA_IN		        : in	std_logic_vector(7 downto 0);
	TC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	TC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	TC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	TC_TRANSMISSION_DONE_OUT : out	std_logic;
	TC_IDENT_IN             : in	std_logic_vector(15 downto 0);
	TC_CHECKSUM_IN          : in    std_logic_vector(15 downto 0);

-- signal to/from frame constructor
	FC_DATA_OUT		     : out	std_logic_vector(7 downto 0);
	FC_WR_EN_OUT		 : out	std_logic;
	FC_READY_IN		     : in	std_logic;
	FC_H_READY_IN		 : in	std_logic;
	FC_FRAME_TYPE_OUT	 : out	std_logic_vector(15 downto 0);
	FC_IP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_UDP_SIZE_OUT		 : out	std_logic_vector(15 downto 0);
	FC_IDENT_OUT		 : out	std_logic_vector(15 downto 0);  -- internal packet counter
	FC_CHECKSUM_OUT      : out  std_logic_vector(15 downto 0);
	FC_FLAGS_OFFSET_OUT	 : out	std_logic_vector(15 downto 0);
	FC_SOD_OUT		     : out	std_logic;
	FC_EOD_OUT		     : out	std_logic;
	FC_IP_PROTOCOL_OUT	 : out	std_logic_vector(7 downto 0);

	DEST_MAC_ADDRESS_OUT : out    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_OUT  : out    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_OUT    : out    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_OUT  : out    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_OUT   : out    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_OUT     : out    std_logic_vector(15 downto 0);

-- debug
	DEBUG_OUT		     : out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_receive_control is
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;

-- signals to/from frame_receiver
	RC_DATA_IN		: in	std_logic_vector(8 downto 0);
	FR_RD_EN_OUT		: out	std_logic;
	FR_FRAME_VALID_IN	: in	std_logic;
	FR_GET_FRAME_OUT	: out	std_logic;
	FR_FRAME_SIZE_IN	: in	std_logic_vector(15 downto 0);
	FR_FRAME_PROTO_IN	: in	std_logic_vector(15 downto 0);
	FR_IP_PROTOCOL_IN	: in	std_logic_vector(7 downto 0);
	
	FR_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	FR_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	FR_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	FR_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	FR_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	FR_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
		
	FR_ID_IP_IN            : in   std_logic_vector(15 downto 0);
	FR_FO_IP_IN            : in   std_logic_vector(15 downto 0);
	FR_UDP_CHECKSUM_IN      : in    std_logic_vector(15 downto 0);

-- signals to the rest of the logic
	RC_RD_EN_IN		: in	std_logic;
	RC_Q_OUT		: out	std_logic_vector(8 downto 0);
	RC_FRAME_WAITING_OUT	: out	std_logic;
	RC_LOADING_DONE_IN	: in	std_logic;
	RC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_OUT	: out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	
	RC_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
	RC_ID_IP_OUT            : out   std_logic_vector(15 downto 0);
	RC_FO_IP_OUT            : out   std_logic_vector(15 downto 0);	
	RC_REDIRECT_TRAFFIC_IN  : in  std_logic;

	RC_CHECKSUM_OUT         : out  std_logic_vector(15 downto 0);

-- statistics
	FRAMES_RECEIVED_OUT	: out	std_logic_vector(31 downto 0);
	BYTES_RECEIVED_OUT	: out	std_logic_vector(31 downto 0);


	DEBUG_OUT		: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_frame_receiver is
port (
	CLK			            : in	std_logic;  -- system clock
	RESET			            : in	std_logic;
	LINK_OK_IN              : in    std_logic;
	ALLOW_RX_IN		         : in	std_logic;
	RX_MAC_CLK		         : in	std_logic;  -- receiver serdes clock

-- input signals from TS_MAC
	MAC_RX_EOF_IN		      : in	std_logic;
	MAC_RX_ER_IN		      : in	std_logic;
	MAC_RXD_IN		         : in	std_logic_vector(7 downto 0);
	MAC_RX_EN_IN		      : in	std_logic;
	MAC_RX_FIFO_ERR_IN	   : in	std_logic;
	MAC_RX_FIFO_FULL_OUT  	: out	std_logic;
	MAC_RX_STAT_EN_IN	      : in	std_logic;
	MAC_RX_STAT_VEC_IN	   : in	std_logic_vector(31 downto 0);

-- output signal to control logic
	FR_Q_OUT		            : out	std_logic_vector(8 downto 0);
	FR_RD_EN_IN		         : in	std_logic;
	FR_FRAME_VALID_OUT	   : out	std_logic;
	FR_GET_FRAME_IN		   : in	std_logic;
	FR_FRAME_SIZE_OUT	      : out	std_logic_vector(15 downto 0);
	FR_FRAME_PROTO_OUT	   : out	std_logic_vector(15 downto 0);
	FR_IP_PROTOCOL_OUT	   : out	std_logic_vector(7 downto 0);
	FR_ALLOWED_TYPES_IN	   : in	std_logic_vector(31 downto 0);
	FR_ALLOWED_IP_IN	      : in	std_logic_vector(31 downto 0);
	FR_ALLOWED_UDP_IN	      : in	std_logic_vector(31 downto 0);
	FR_ALLOWED_TCP_IN    	: in	std_logic_vector(31 downto 0);
	FR_VLAN_ID_IN		      : in	std_logic_vector(31 downto 0);
	
	FR_SRC_MAC_ADDRESS_OUT	: out	std_logic_vector(47 downto 0);
	FR_DEST_MAC_ADDRESS_OUT : out	std_logic_vector(47 downto 0);
	FR_SRC_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	FR_DEST_IP_ADDRESS_OUT	: out	std_logic_vector(31 downto 0);
	FR_SRC_UDP_PORT_OUT	   : out	std_logic_vector(15 downto 0);
	FR_DEST_UDP_PORT_OUT	   : out	std_logic_vector(15 downto 0);
	
	FR_ID_IP_OUT            : out   std_logic_vector(15 downto 0);
	FR_FO_IP_OUT            : out   std_logic_vector(15 downto 0);
	FR_UDP_CHECKSUM_OUT     : out   std_logic_vector(15 downto 0);
	
	FR_MY_MAC_IN            : in std_logic_vector(47 downto 0);
	FR_REDIRECT_TRAFFIC_IN  : in   std_logic;

	DEBUG_OUT		         : out	std_logic_vector(95 downto 0)
);
end component;

-- gk 01.07.10
component trb_net16_ipu2gbe is
port( 
	CLK                         : in    std_logic;
	RESET                       : in    std_logic;
	-- IPU interface directed toward the CTS
	CTS_NUMBER_IN               : in    std_logic_vector (15 downto 0);
	CTS_CODE_IN                 : in    std_logic_vector (7  downto 0);
	CTS_INFORMATION_IN          : in    std_logic_vector (7  downto 0);
	CTS_READOUT_TYPE_IN         : in    std_logic_vector (3  downto 0);
	CTS_START_READOUT_IN        : in    std_logic;
	CTS_READ_IN                 : in    std_logic;
	CTS_DATA_OUT                : out   std_logic_vector (31 downto 0);
	CTS_DATAREADY_OUT           : out   std_logic;
	CTS_READOUT_FINISHED_OUT    : out   std_logic;      --no more data, end transfer, send TRM
	CTS_LENGTH_OUT              : out   std_logic_vector (15 downto 0);
	CTS_ERROR_PATTERN_OUT       : out   std_logic_vector (31 downto 0);
	-- Data from Frontends
	FEE_DATA_IN                 : in    std_logic_vector (15 downto 0);
	FEE_DATAREADY_IN            : in    std_logic;
	FEE_READ_OUT                : out   std_logic;
	FEE_BUSY_IN                 : in    std_logic;
	FEE_STATUS_BITS_IN          : in    std_logic_vector (31 downto 0);
	-- slow control interface
	START_CONFIG_OUT			: out	std_logic; -- reconfigure MACs/IPs/ports/packet size
	BANK_SELECT_OUT				: out	std_logic_vector(3 downto 0); -- configuration page address
	CONFIG_DONE_IN				: in	std_logic; -- configuration finished
	DATA_GBE_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to GbE
	DATA_IPU_ENABLE_IN			: in	std_logic; -- IPU data is forwarded to CTS / TRBnet
	MULT_EVT_ENABLE_IN			: in    std_logic;
	MAX_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- the maximum size of one HadesQueue  -- gk 08.04.10
	MIN_MESSAGE_SIZE_IN			: in	std_logic_vector(31 downto 0); -- gk 20.07.10
	READOUT_CTR_IN				: in	std_logic_vector(23 downto 0); -- gk 26.04.10
	READOUT_CTR_VALID_IN			: in	std_logic; -- gk 26.04.10
	-- PacketConstructor interface
	ALLOW_LARGE_IN				: in	std_logic;  -- gk 21.07.10
	PC_WR_EN_OUT                : out   std_logic;
	PC_DATA_OUT                 : out   std_logic_vector (7 downto 0);
	PC_READY_IN                 : in    std_logic;
	PC_SOS_OUT                  : out   std_logic;
	PC_EOS_OUT                  : out   std_logic; -- gk 07.10.10
	PC_EOD_OUT                  : out   std_logic;
	PC_SUB_SIZE_OUT             : out   std_logic_vector(31 downto 0);
	PC_TRIG_NR_OUT              : out   std_logic_vector(31 downto 0);
	PC_PADDING_OUT              : out   std_logic;
	MONITOR_OUT                 : out   std_logic_vector(223 downto 0);
	DEBUG_OUT                   : out   std_logic_vector(383 downto 0)
);
end component;

component trb_net16_gbe_packet_constr is
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	MULT_EVT_ENABLE_IN      : in    std_logic;  -- gk 06.10.10
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(7 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_START_OF_SUB_IN      : in    std_logic;
	PC_END_OF_SUB_IN        : in    std_logic;  -- gk 07.10.10
	PC_END_OF_DATA_IN       : in    std_logic;
	PC_TRANSMIT_ON_OUT	: out	std_logic;
	-- queue and subevent layer headers
	PC_SUB_SIZE_IN          : in    std_logic_vector(31 downto 0); -- store and swap
	PC_PADDING_IN           : in std_logic;  -- gk 29.03.10
	PC_DECODING_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_EVENT_ID_IN          : in    std_logic_vector(31 downto 0); -- swap
	PC_TRIG_NR_IN           : in    std_logic_vector(31 downto 0); -- store and swap!
	PC_QUEUE_DEC_IN         : in    std_logic_vector(31 downto 0); -- swap
	PC_MAX_FRAME_SIZE_IN    : in	std_logic_vector(15 downto 0); -- DO NOT SWAP
	PC_DELAY_IN             : in	std_logic_vector(31 downto 0);  -- gk 28.04.10
	-- FrameConstructor ports
	TC_WR_EN_OUT            : out   std_logic;
	TC_DATA_OUT             : out   std_logic_vector(7 downto 0);
	TC_H_READY_IN           : in    std_logic;
	TC_READY_IN             : in    std_logic;
	TC_IP_SIZE_OUT          : out   std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT         : out   std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT     : out   std_logic_vector(15 downto 0);
	TC_SOD_OUT              : out   std_logic;
	TC_EOD_OUT              : out   std_logic;
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end component;

component trb_net16_gbe_frame_constr is
port( 
	-- ports for user logic
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	LINK_OK_IN              : in    std_logic;  -- gk 03.08.10
	--
	WR_EN_IN                : in    std_logic;
	DATA_IN                 : in    std_logic_vector(7 downto 0);
	START_OF_DATA_IN        : in    std_logic;
	END_OF_DATA_IN          : in    std_logic;
	IP_F_SIZE_IN            : in    std_logic_vector(15 downto 0);
	UDP_P_SIZE_IN           : in    std_logic_vector(15 downto 0); -- needed for fragmentation
	HEADERS_READY_OUT       : out   std_logic;
	READY_OUT               : out   std_logic;
	DEST_MAC_ADDRESS_IN     : in    std_logic_vector(47 downto 0);
	DEST_IP_ADDRESS_IN      : in    std_logic_vector(31 downto 0);
	DEST_UDP_PORT_IN        : in    std_logic_vector(15 downto 0);
	SRC_MAC_ADDRESS_IN      : in    std_logic_vector(47 downto 0);
	SRC_IP_ADDRESS_IN       : in    std_logic_vector(31 downto 0);
	SRC_UDP_PORT_IN         : in    std_logic_vector(15 downto 0);
	FRAME_TYPE_IN           : in    std_logic_vector(15 downto 0);
	IHL_VERSION_IN          : in    std_logic_vector(7 downto 0);
	TOS_IN                  : in    std_logic_vector(7 downto 0);
	IDENTIFICATION_IN       : in    std_logic_vector(15 downto 0);
	CHECKSUM_IN             : in    std_logic_vector(15 downto 0);
	FLAGS_OFFSET_IN         : in    std_logic_vector(15 downto 0);
	TTL_IN                  : in    std_logic_vector(7 downto 0);
	PROTOCOL_IN             : in    std_logic_vector(7 downto 0);
	FRAME_DELAY_IN          : in    std_logic_vector(31 downto 0);  -- gk 09.12.10
	-- ports for packetTransmitter
	RD_CLK                  : in    std_logic; -- 125MHz clock!!!
	FT_DATA_OUT             : out   std_logic_vector(8 downto 0);
	FT_TX_EMPTY_OUT         : out   std_logic;
	FT_TX_RD_EN_IN          : in    std_logic;
	FT_START_OF_PACKET_OUT  : out   std_logic;
	FT_TX_DONE_IN           : in    std_logic;
	FT_TX_DISCFRM_IN	: in	std_logic;
	-- debug ports
	BSM_CONSTR_OUT          : out   std_logic_vector(7 downto 0);
	BSM_TRANS_OUT           : out   std_logic_vector(3 downto 0);
	DEBUG_OUT               : out   std_logic_vector(63 downto 0)
);
end component;

component pulse_sync is
port(
	CLK_A_IN        : in    std_logic;
	RESET_A_IN      : in    std_logic;
	PULSE_A_IN      : in    std_logic;
	CLK_B_IN        : in    std_logic;
	RESET_B_IN      : in    std_logic;
	PULSE_B_OUT     : out   std_logic
);
end component;

component signal_sync is
  generic(
    WIDTH : integer := 1;     --
    DEPTH : integer := 3
    );
  port(
    RESET    : in  std_logic; --Reset is neceessary to avoid optimization to shift register
    CLK0     : in  std_logic;                          --clock for first FF
    CLK1     : in  std_logic;                          --Clock for other FF
    D_IN     : in  std_logic_vector(WIDTH-1 downto 0); --Data input
    D_OUT    : out std_logic_vector(WIDTH-1 downto 0)  --Data output
    );
end component;	

component trb_net16_gbe_frame_trans is
port (
	CLK					: in	std_logic;
	RESET				: in	std_logic;
	LINK_OK_IN              : in    std_logic;  -- gk 03.08.10
	TX_MAC_CLK			: in	std_logic;
	TX_EMPTY_IN			: in	std_logic;
	START_OF_PACKET_IN	: in	std_logic;
	DATA_ENDFLAG_IN		: in	std_logic; -- (8) is end flag, rest is only for TSMAC
	-- NEW PORTS
-- 	HADDR_OUT			: out	std_logic_vector(7 downto 0);
-- 	HDATA_OUT			: out	std_logic_vector(7 downto 0);
-- 	HCS_OUT				: out	std_logic;
-- 	HWRITE_OUT			: out	std_logic;
-- 	HREAD_OUT			: out	std_logic;
-- 	HREADY_IN			: in	std_logic;
-- 	HDATA_EN_IN			: in	std_logic;
	TX_FIFOAVAIL_OUT	: out	std_logic;
	TX_FIFOEOF_OUT		: out	std_logic;
	TX_FIFOEMPTY_OUT	: out	std_logic;
	TX_DONE_IN			: in	std_logic;
	TX_STAT_EN_IN		: in	std_logic;
	TX_STATVEC_IN		: in	std_logic_vector(30 downto 0);
	TX_DISCFRM_IN		: in 	std_logic;
	-- Debug
	BSM_INIT_OUT		: out	std_logic_vector(3 downto 0);
	BSM_MAC_OUT			: out	std_logic_vector(3 downto 0);
	BSM_TRANS_OUT		: out	std_logic_vector(3 downto 0);
	DBG_RD_DONE_OUT		: out	std_logic;
	DBG_INIT_DONE_OUT	: out	std_logic;
	DBG_ENABLED_OUT		: out	std_logic;
	DEBUG_OUT			: out	std_logic_vector(63 downto 0)
);
end component;

component trb_net16_med_ecp_sfp_gbe_8b is
-- gk 28.04.10
generic (
	USE_125MHZ_EXTCLK			: integer range 0 to 1 := 1
);
port(
	RESET					: in	std_logic;
	GSR_N					: in	std_logic;
	CLK_125_OUT				: out	std_logic;
	CLK_125_RX_OUT				: out	std_logic;
	CLK_125_IN				: in std_logic;  -- gk 28.04.10  used when intclk
	--SGMII connection to frame transmitter (tsmac)
	FT_TX_CLK_EN_OUT		: out	std_logic;
	FT_RX_CLK_EN_OUT		: out	std_logic;
	FT_COL_OUT				: out	std_logic;
	FT_CRS_OUT				: out	std_logic;
	FT_TXD_IN				: in	std_logic_vector(7 downto 0);
	FT_TX_EN_IN				: in	std_logic;
	FT_TX_ER_IN				: in	std_logic;
	FT_RXD_OUT				: out	std_logic_vector(7 downto 0);
	FT_RX_EN_OUT				: out	std_logic;
	FT_RX_ER_OUT				: out	std_logic;
	--SFP Connection
	SD_RXD_P_IN				: in	std_logic;
	SD_RXD_N_IN				: in	std_logic;
	SD_TXD_P_OUT			: out	std_logic;
	SD_TXD_N_OUT			: out	std_logic;
	SD_REFCLK_P_IN			: in	std_logic;
	SD_REFCLK_N_IN			: in	std_logic;
	SD_PRSNT_N_IN			: in	std_logic; -- SFP Present ('0' = SFP in place, '1' = no SFP mounted)
	SD_LOS_IN				: in	std_logic; -- SFP Loss Of Signal ('0' = OK, '1' = no signal)
	SD_TXDIS_OUT			: out	std_logic; -- SFP disable
	-- Autonegotiation stuff
	MR_RESET_IN				: in	std_logic;
	MR_MODE_IN				: in	std_logic;
	MR_ADV_ABILITY_IN		: in 	std_logic_vector(15 downto 0);
	MR_AN_LP_ABILITY_OUT	: out	std_logic_vector(15 downto 0);
	MR_AN_PAGE_RX_OUT		: out	std_logic;
	MR_AN_COMPLETE_OUT		: out	std_logic; 
	MR_AN_ENABLE_IN			: in	std_logic;
	MR_RESTART_AN_IN		: in	std_logic;
	-- Status and control port
	STAT_OP					: out	std_logic_vector (15 downto 0);
	CTRL_OP					: in	std_logic_vector (15 downto 0);
	STAT_DEBUG				: out	std_logic_vector (63 downto 0);
	CTRL_DEBUG				: in	std_logic_vector (63 downto 0)
);
end component;

component gbe_setup is
port(
	CLK                      : in std_logic;
	RESET                    : in std_logic;

	-- interface to regio bus
	BUS_ADDR_IN               : in std_logic_vector(7 downto 0);
	BUS_DATA_IN               : in std_logic_vector(31 downto 0);
	BUS_DATA_OUT              : out std_logic_vector(31 downto 0);  -- gk 26.04.10
	BUS_WRITE_EN_IN           : in std_logic;  -- gk 26.04.10
	BUS_READ_EN_IN            : in std_logic;  -- gk 26.04.10
	BUS_ACK_OUT               : out std_logic;  -- gk 26.04.10

	GBE_TRIG_NR_IN            : in std_logic_vector(31 downto 0);

	-- output to gbe_buf
	GBE_SUBEVENT_ID_OUT       : out std_logic_vector(31 downto 0);
	GBE_SUBEVENT_DEC_OUT      : out std_logic_vector(31 downto 0);
	GBE_QUEUE_DEC_OUT         : out std_logic_vector(31 downto 0);
	GBE_MAX_PACKET_OUT        : out std_logic_vector(31 downto 0);
	GBE_MIN_PACKET_OUT        : out std_logic_vector(31 downto 0);
	GBE_MAX_FRAME_OUT         : out std_logic_vector(15 downto 0);
	GBE_USE_GBE_OUT           : out std_logic;
	GBE_USE_TRBNET_OUT        : out std_logic;
	GBE_USE_MULTIEVENTS_OUT   : out std_logic;
	GBE_READOUT_CTR_OUT       : out std_logic_vector(23 downto 0);  -- gk 26.04.10
	GBE_READOUT_CTR_VALID_OUT : out std_logic;  -- gk 26.04.10
	GBE_DELAY_OUT             : out std_logic_vector(31 downto 0);
	GBE_ALLOW_LARGE_OUT       : out std_logic;
	GBE_ALLOW_RX_OUT          : out std_logic;
	GBE_ALLOW_BRDCST_ETH_OUT  : out std_logic;
	GBE_ALLOW_BRDCST_IP_OUT   : out std_logic;
	GBE_FRAME_DELAY_OUT	  : out std_logic_vector(31 downto 0);
	GBE_ALLOWED_TYPES_OUT	  : out	std_logic_vector(31 downto 0);
	GBE_ALLOWED_IP_OUT	  : out	std_logic_vector(31 downto 0);
	GBE_ALLOWED_UDP_OUT	  : out	std_logic_vector(31 downto 0);
	GBE_VLAN_ID_OUT           : out std_logic_vector(31 downto 0);
	-- gk 28.07.10
	MONITOR_BYTES_IN          : in std_logic_vector(31 downto 0);
	MONITOR_SENT_IN           : in std_logic_vector(31 downto 0);
	MONITOR_DROPPED_IN        : in std_logic_vector(31 downto 0);
	MONITOR_SM_IN             : in std_logic_vector(31 downto 0);
	MONITOR_LR_IN             : in std_logic_vector(31 downto 0);
	MONITOR_HDR_IN            : in std_logic_vector(31 downto 0);
	MONITOR_FIFOS_IN          : in std_logic_vector(31 downto 0);
	MONITOR_DISCFRM_IN        : in std_logic_vector(31 downto 0);
	MONITOR_LINK_DWN_IN       : in std_logic_vector(31 downto 0);  -- gk 30.09.10
	MONITOR_EMPTY_IN          : in std_logic_vector(31 downto 0);  -- gk 01.10.10
	MONITOR_RX_FRAMES_IN      : in std_logic_vector(31 downto 0);
	MONITOR_RX_BYTES_IN       : in std_logic_vector(31 downto 0);
	MONITOR_RX_BYTES_R_IN     : in std_logic_vector(31 downto 0);
	-- gk 01.06.10
	DBG_IPU2GBE1_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE2_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE3_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE4_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE5_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE6_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE7_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE8_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE9_IN          : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE10_IN         : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE11_IN         : in std_logic_vector(31 downto 0);
	DBG_IPU2GBE12_IN         : in std_logic_vector(31 downto 0);
	DBG_PC1_IN               : in std_logic_vector(31 downto 0);
	DBG_PC2_IN               : in std_logic_vector(31 downto 0);
	DBG_FC1_IN               : in std_logic_vector(31 downto 0);
	DBG_FC2_IN               : in std_logic_vector(31 downto 0);
	DBG_FT1_IN               : in std_logic_vector(31 downto 0);
	DBG_FT2_IN               : in std_logic_vector(31 downto 0);
	DBG_FR_IN                : in std_logic_vector(95 downto 0);
	DBG_RC_IN                : in std_logic_vector(63 downto 0);
	DBG_MC_IN                : in std_logic_vector(63 downto 0);
	DBG_TC_IN                : in std_logic_vector(31 downto 0);
	DBG_FIFO_RD_EN_OUT        : out std_logic;
	
	DBG_SELECT_REC_IN	: in	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	DBG_SELECT_SENT_IN	: in	std_logic_vector(c_MAX_PROTOCOLS * 16 - 1 downto 0);
	DBG_SELECT_PROTOS_IN	: in	std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	
	DBG_FIFO_Q_IN             : in std_logic_vector(15 downto 0)
	--DBG_FIFO_RESET_OUT       : out std_logic
);
end component;


component ip_configurator is
port( 
	CLK							: in	std_logic;
	RESET						: in	std_logic;
	-- configuration interface
	START_CONFIG_IN				: in	std_logic; -- start configuration run
	BANK_SELECT_IN				: in	std_logic_vector(3 downto 0); -- selects config bank 
	CONFIG_DONE_OUT				: out	std_logic; -- configuration run ended, new values can be used
	MEM_ADDR_OUT				: out	std_logic_vector(7 downto 0); -- address for
	MEM_DATA_IN					: in	std_logic_vector(31 downto 0); -- data from IP memory
	MEM_CLK_OUT					: out	std_logic; -- clock for BlockRAM
	-- information for IP cores
	DEST_MAC_OUT				: out	std_logic_vector(47 downto 0); -- destination MAC address
	DEST_IP_OUT					: out	std_logic_vector(31 downto 0); -- destination IP address
	DEST_UDP_OUT				: out	std_logic_vector(15 downto 0); -- destination port
	SRC_MAC_OUT					: out	std_logic_vector(47 downto 0); -- source MAC address
	SRC_IP_OUT					: out	std_logic_vector(31 downto 0); -- source IP address
	SRC_UDP_OUT					: out	std_logic_vector(15 downto 0); -- source port
	MTU_OUT						: out	std_logic_vector(15 downto 0); -- MTU size (max frame size)
	-- Debug
	DEBUG_OUT					: out	std_logic_vector(31 downto 0)
);
end component;

component gbe_main is
generic (
	DO_SIMULATION        : integer range 0 to 1 := 0;
	USE_VIRTEX4          : integer range 0 to 1 := 1;
	USE_VIRTEX5          : integer range 0 to 1 := 0;
	USE_SFP              : integer range 0 to 1 := 1;
	USE_COPPER           : integer range 0 to 1 := 0
);
port (
	SYS_CLK           : in std_logic;
	RESET_IN          : in std_logic;
	CLK_125_IN        : in std_logic;
	CLK_40_IN         : in std_logic;  -- connect to positive pin

	-- connect to the sfp of choice
	SFP_CP_IN         : in std_logic;
	SFP_LED_BLUE_OUT  : out std_logic;
	SFP_LED_GREEN_OUT : out std_logic;
	SFP_TD_P_OUT      : out std_logic;
	SFP_TD_N_OUT      : out std_logic;
	SFP_RD_P_IN       : in std_logic;
	SFP_RD_N_IN       : in std_logic;
	
	-- connect to the copper cable interface
	CU_PHY_RST_N_OUT     : out std_logic;
	CU_GMII_TXD_OUT      : out std_logic_vector(7 downto 0);
	CU_GMII_TX_EN_OUT    : out std_logic;
	CU_GMII_TX_ERR_OUT   : out std_logic;
	CU_GMII_TX_CLK_OUT   : out std_logic;
	CU_GMII_RXD_IN       : in std_logic_vector(7 downto 0);
	CU_GMII_RX_DV_IN     : in std_logic;
	CU_GMII_RX_ERR_IN    : in std_logic;
	CU_GMII_RX_CLK_IN    : in std_logic;
	
	-- add here connections between external logic and protocols
	-- interface to transmit udp data out
	LL_DATA_IN           : in std_logic_vector(31 downto 0);
	LL_REM_IN            : in std_logic_vector(1 downto 0);
	LL_SOF_N_IN          : in std_logic;
	LL_EOF_N_IN          : in std_logic;
	LL_SRC_READY_N_IN    : in std_logic;
	LL_DST_READY_N_OUT   : out std_logic;
	LL_READ_CLK_OUT      : out std_logic;
	
	-- interface to receive tcp data from kernel
	LL_TCP_IN_DATA_IN           : in std_logic_vector(31 downto 0);
	LL_TCP_IN_REM_IN            : in std_logic_vector(1 downto 0);
	LL_TCP_IN_SOF_N_IN          : in std_logic;
	LL_TCP_IN_EOF_N_IN          : in std_logic;
	LL_TCP_IN_SRC_READY_N_IN    : in std_logic;
	LL_TCP_IN_DST_READY_N_OUT   : out std_logic;
	LL_TCP_IN_READ_CLK_OUT      : out std_logic;
	
	-- interface to provide tcp data to kernel
	LL_TCP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_TCP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_TCP_OUT_SOF_N_OUT        : out std_logic;
	LL_TCP_OUT_EOF_N_OUT        : out std_logic;
	LL_TCP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_TCP_OUT_DST_READY_N_IN   : in std_logic;
	LL_TCP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_TCP_OUT_WRITE_CLK_OUT    : out std_logic;
	
	-- interface to provide udp data to kernel
	LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;
	
	SCTRL_VEC_IN                : in std_logic_vector(255 downto 0);
	SCTRL_VALID_IN              : in std_logic;
	SCTRL_VEC_OUT               : out std_logic_vector(255 downto 0)
	);
end component;

component tmac_pcs_block is
   port(
      -- Client Receiver Interface - EMAC0
      RX_CLIENT_CLK_0                 : out std_logic;
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      TX_CLIENT_CLK_0                 : out std_logic;
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        : out std_logic;

 
      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- unused transceiver
      TXN_1_UNUSED                    : out std_logic;
      TXP_1_UNUSED                    : out std_logic;
      RXN_1_UNUSED                    : in  std_logic;
      RXP_1_UNUSED                    : in  std_logic;

      -- MDIO Interface - EMAC0
      MDC_IN_0                        : in  std_logic;
      MDIO_0_I                        : in  std_logic;
      MDIO_0_O                        : out std_logic;
      MDIO_0_T                        : out std_logic;
      HOSTCLK                         : in  std_logic;
      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs 
      MGTCLK_P                        : in  std_logic;
      MGTCLK_N                        : in  std_logic;

      DCLK                            : in  std_logic;

		signal_detect_out : out std_logic;
        
        
      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
end component;

component temac_v5_block is
   port(
      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      : out std_logic;                 
      -- 125MHz clock input from BUFG
      CLK125                          : in  std_logic;
      -- 62.5MHz clock input from BUFG
      CLK62_5                         : in  std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                : out std_logic;

 
      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- unused transceiver
      TXN_1_UNUSED                    : out std_logic;
      TXP_1_UNUSED                    : out std_logic;
      RXN_1_UNUSED                    : in  std_logic;
      RXP_1_UNUSED                    : in  std_logic;

      -- MDIO Interface - EMAC0
      MDC_IN_0                        : in  std_logic;
      MDIO_0_I                        : in  std_logic;
      MDIO_0_O                        : out std_logic;
      MDIO_0_T                        : out std_logic;

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs 
      CLK_DS                          : in  std_logic;
     
      -- RocketIO Reset input
      GTRESET                         : in  std_logic;

        
        
      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
end component;

component frame_rx is
port (
	RESET                           : in std_logic;
	
	-- connections to emac
	RX_CLIENT_CLK_0                 : in std_logic;
	EMAC0CLIENTRXD                  : in std_logic_vector(7 downto 0);
	EMAC0CLIENTRXDVLD               : in std_logic;
	EMAC0CLIENTRXGOODFRAME          : in std_logic;
	EMAC0CLIENTRXBADFRAME           : in std_logic;
	EMAC0CLIENTRXFRAMEDROP          : in std_logic;
	EMAC0CLIENTRXSTATS              : in std_logic_vector(6 downto 0);
	EMAC0CLIENTRXSTATSVLD           : in std_logic;
	EMAC0CLIENTRXSTATSBYTEVLD       : in std_logic;
	
	-- signalc to/from main controller
	RC_RD_EN_IN	                    : in	std_logic;
	RC_Q_OUT		                    : out	std_logic_vector(8 downto 0);
	RC_FRAME_WAITING_OUT	           : out	std_logic;
	RC_LOADING_DONE_IN	           : in	std_logic;
	RC_FRAME_SIZE_OUT	              : out	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_OUT	           : out	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	RC_SRC_MAC_ADDRESS_OUT	        : out	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_OUT         : out	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_OUT	        : out	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_OUT	        : out	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_OUT	           : out	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_OUT	           : out	std_logic_vector(15 downto 0);
	RC_ID_IP_OUT	           : out	std_logic_vector(15 downto 0);
	RC_FO_IP_OUT	           : out	std_logic_vector(15 downto 0);
	RC_MY_MAC_IN                    : in   std_logic_vector(47 downto 0);
	RC_REDIRECT_TRAFFIC_IN          : in   std_logic;
	
	RC_CHECKSUM_OUT                 : out std_logic_vector(15 downto 0);
	
	DEBUG_OUT                       : out std_logic_vector(127 downto 0)
);
end component;

component frame_tx is
port (
	MAIN_CTRL_CLK : in std_logic;
	RESET : in std_logic;

	-- part to connect to frame rec main controller module
	MC_TRANSMIT_CTRL_IN	    : in	std_logic;  -- slow control frame is waiting to be built and sent
	MC_DATA_IN		        : in	std_logic_vector(8 downto 0);
	MC_RD_EN_OUT		    : out	std_logic;
	MC_FRAME_SIZE_IN	    : in	std_logic_vector(15 downto 0);
	MC_FRAME_TYPE_IN	    : in	std_logic_vector(15 downto 0);
	MC_DEST_MAC_IN		    : in	std_logic_vector(47 downto 0);
	MC_DEST_IP_IN		    : in	std_logic_vector(31 downto 0);
	MC_DEST_UDP_IN		    : in	std_logic_vector(15 downto 0);
	MC_SRC_MAC_IN		    : in	std_logic_vector(47 downto 0);
	MC_SRC_IP_IN		    : in	std_logic_vector(31 downto 0);
	MC_SRC_UDP_IN		    : in	std_logic_vector(15 downto 0);
	MC_IP_PROTOCOL_IN	    : in	std_logic_vector(7 downto 0);
	MC_IDENT_IN             : in std_logic_vector(15 downto 0);
	MC_CHECKSUM_IN          : in std_logic_vector(15 downto 0);
	MC_TRANSMIT_DONE_OUT	: out	std_logic;

	-- emac interface
	CLIENTEMAC0TXD : out std_logic_vector(7 downto 0);
	CLIENTEMAC0TXDVLD : out std_logic;
	CLIENTEMAC0TXFIRSTBYTE : out std_logic;
	CLIENTEMAC0TXUNDERRUN : out std_logic;
	TX_CLIENT_CLK_0 : in std_logic;
	EMAC0CLIENTTXACK : in std_logic;
	EMAC0CLIENTTXSTATSVLD : in std_logic;

	DEBUG_OUT : out std_logic_vector(127 downto 0)
);
end component;

component fifo_8_64 is
port (
  rst : in std_logic;
  wr_clk : in std_logic;
  rd_clk : in std_logic;
  din : in std_logic_vector(7 downto 0);
  wr_en : in std_logic;
  rd_en : in std_logic;
  dout : out std_logic_vector(63 downto 0);
  full : out std_logic;
  empty : out std_logic
);
end component;

component fifo_4096x9 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

component fifo_65536x32x8 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

component fifo_65536x8x32 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

component local_link_dummy is
generic (
	DO_SIMULATION        : integer range 0 to 1 := 1
);
port (
	RESET_N               : in std_logic;
	LL_DATA_OUT           : out std_logic_vector(31 downto 0);
	LL_REM_OUT            : out std_logic_vector(1 downto 0);
	LL_SOF_N_OUT          : out std_logic;
	LL_EOF_N_OUT          : out std_logic;
	LL_SRC_READY_N_OUT    : out std_logic;
	LL_DST_READY_N_IN     : in std_logic;
	LL_LEN_OUT            : out std_logic_vector(15 downto 0);
	LL_LEN_READY_OUT      : out std_logic;
	LL_LEN_ERR_OUT        : out std_logic;
	LL_READ_CLK_IN        : in std_logic
);
end component;

component mac_copper_block is
   port(
      -- Client Receiver Interface - EMAC0
      RX_CLIENT_CLK_0                 : out std_logic;
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      TX_CLIENT_CLK_0                 : out std_logic;
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

 
      -- Clock Signals - EMAC0
      GTX_CLK_0                       : in  std_logic;
      -- GMII Interface - EMAC0
      GMII_TXD_0                      : out std_logic_vector(7 downto 0);
      GMII_TX_EN_0                    : out std_logic;
      GMII_TX_ER_0                    : out std_logic;
      GMII_TX_CLK_0                   : out std_logic;
      GMII_RXD_0                      : in  std_logic_vector(7 downto 0);
      GMII_RX_DV_0                    : in  std_logic;
      GMII_RX_ER_0                    : in  std_logic;
      GMII_RX_CLK_0                   : in  std_logic;

      -- The following two ports are to enable the 200ms reset for the 
      -- DCM in the Rx PHY path of EMAC0 to be bypassed during simulation
      -- NOTE: These should be tied together for normal operation
      RESET_200MS_0                   : out std_logic;
      RESET_200MS_IN_0                : in  std_logic;
      HOSTCLK                         : in  std_logic;
        
        
      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
end component;

component mac_v5_copper_block is
   port(
      -- EMAC0 Clocking
      -- TX Clock output from EMAC
      TX_CLK_OUT                      : out std_logic;
      -- EMAC0 TX Clock input from BUFG
      TX_CLK_0                        : in  std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

 
      -- Clock Signals - EMAC0
      GTX_CLK_0                       : in  std_logic;
      -- GMII Interface - EMAC0
      GMII_TXD_0                      : out std_logic_vector(7 downto 0);
      GMII_TX_EN_0                    : out std_logic;
      GMII_TX_ER_0                    : out std_logic;
      GMII_TX_CLK_0                   : out std_logic;
      GMII_RXD_0                      : in  std_logic_vector(7 downto 0);
      GMII_RX_DV_0                    : in  std_logic;
      GMII_RX_ER_0                    : in  std_logic;
      GMII_RX_CLK_0                   : in  std_logic;

        
        
      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
end component;

 component v5_dual_mac_block is
   port(
      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                          : in  std_logic;
      -- 62.5MHz clock input from BUFG
      CLK62_5                         : in  std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC0CLIENTRXDVLD               : out std_logic;
      EMAC0CLIENTRXGOODFRAME          : out std_logic;
      EMAC0CLIENTRXBADFRAME           : out std_logic;
      EMAC0CLIENTRXFRAMEDROP          : out std_logic;
      EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD           : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC0TXDVLD               : in  std_logic;
      EMAC0CLIENTTXACK                : out std_logic;
      CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC0TXUNDERRUN           : in  std_logic;
      EMAC0CLIENTTXCOLLISION          : out std_logic;
      EMAC0CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS              : out std_logic;
      EMAC0CLIENTTXSTATSVLD           : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             : in  std_logic;
      CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                : out std_logic;

      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           : out std_logic;
      TXN_0                           : out std_logic;
      RXP_0                           : in  std_logic;
      RXN_0                           : in  std_logic;
      PHYAD_0                         : in  std_logic_vector(4 downto 0);
      RESETDONE_0                     : out std_logic;

      -- EMAC1 Clocking

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXD                  : out std_logic_vector(7 downto 0);
      EMAC1CLIENTRXDVLD               : out std_logic;
      EMAC1CLIENTRXGOODFRAME          : out std_logic;
      EMAC1CLIENTRXBADFRAME           : out std_logic;
      EMAC1CLIENTRXFRAMEDROP          : out std_logic;
      EMAC1CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
      EMAC1CLIENTRXSTATSVLD           : out std_logic;
      EMAC1CLIENTRXSTATSBYTEVLD       : out std_logic;

      -- Client Transmitter Interface - EMAC1
      CLIENTEMAC1TXD                  : in  std_logic_vector(7 downto 0);
      CLIENTEMAC1TXDVLD               : in  std_logic;
      EMAC1CLIENTTXACK                : out std_logic;
      CLIENTEMAC1TXFIRSTBYTE          : in  std_logic;
      CLIENTEMAC1TXUNDERRUN           : in  std_logic;
      EMAC1CLIENTTXCOLLISION          : out std_logic;
      EMAC1CLIENTTXRETRANSMIT         : out std_logic;
      CLIENTEMAC1TXIFGDELAY           : in  std_logic_vector(7 downto 0);
      EMAC1CLIENTTXSTATS              : out std_logic;
      EMAC1CLIENTTXSTATSVLD           : out std_logic;
      EMAC1CLIENTTXSTATSBYTEVLD       : out std_logic;

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             : in  std_logic;
      CLIENTEMAC1PAUSEVAL             : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC1CLIENTSYNCACQSTATUS        : out std_logic;
      -- EMAC1 Interrupt
      EMAC1ANINTERRUPT                : out std_logic;

      -- Clock Signals - EMAC1
      -- 1000BASE-X PCS/PMA Interface - EMAC1
      TXP_1                           : out std_logic;
      TXN_1                           : out std_logic;
      RXP_1                           : in  std_logic;
      RXN_1                           : in  std_logic;
      PHYAD_1                         : in  std_logic_vector(4 downto 0);
      RESETDONE_1                     : out std_logic;

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          : in  std_logic;

      -- RocketIO Reset input
      GTRESET                         : in  std_logic;

      -- Asynchronous Reset
      RESET                           : in  std_logic
   );
  end component;

component fifo_1024x8 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

COMPONENT fifo_generator_v8_2
  PORT (
    rst : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

component fifo_2048x32x8 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

component fifo_2048x8x32 IS
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

COMPONENT fifo_8192x34
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(33 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT fifo_512x72
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(71 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT fifo_512x32
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

end package;

package body trb_net_gbe_components is
	 
	   function or_all (arg : std_logic_vector)
    return std_logic is
    variable tmp : std_logic := '1';
    begin
      tmp := '0';
      for i in arg'range loop
        tmp := tmp or arg(i);
      end loop;  -- i
      return tmp;
  end function or_all;
  
    function and_all (arg : std_logic_vector)
    return std_logic is
    variable tmp : std_logic := '1';
    begin
      tmp := '1';
      for i in arg'range loop
        tmp := tmp and arg(i);
      end loop;  -- i
      return tmp;
  end function and_all;
  
end package body trb_net_gbe_components;