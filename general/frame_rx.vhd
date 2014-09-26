library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity frame_rx is
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
end frame_rx;

architecture Behavioral of frame_rx is

signal fifo_rd_en, fifo_empty : std_logic;
signal rec_bytes_ctr : unsigned(15 downto 0);

signal fr_src_mac                    : std_logic_vector(47 downto 0);
signal fr_dest_mac                   : std_logic_vector(47 downto 0);
signal fr_src_ip                     : std_logic_vector(31 downto 0);
signal fr_dest_ip                    : std_logic_vector(31 downto 0);
signal fr_src_udp                    : std_logic_vector(15 downto 0);
signal fr_dest_udp                   : std_logic_vector(15 downto 0);
signal fr_id_ip                      : std_logic_vector(15 downto 0);
signal fr_fo_ip                      : std_logic_vector(15 downto 0);
signal fr_q                          : std_logic_vector(8 downto 0);
signal fr_rd_en                      : std_logic;
signal fr_frame_valid                : std_logic;
signal fr_get_frame                  : std_logic;
signal fr_frame_size                 : std_logic_vector(15 downto 0);
signal fr_frame_proto                : std_logic_vector(15 downto 0);
signal fr_ip_proto                   : std_logic_vector(7 downto 0);
signal vlan_id                       : std_logic_vector(31 downto 0);

signal rc_src_mac                    : std_logic_vector(47 downto 0);
signal rc_dest_mac                   : std_logic_vector(47 downto 0);
signal rc_src_ip                     : std_logic_vector(31 downto 0);
signal rc_dest_ip                    : std_logic_vector(31 downto 0);
signal rc_src_udp                    : std_logic_vector(15 downto 0);
signal rc_dest_udp                   : std_logic_vector(15 downto 0);
signal rc_rd_en                      : std_logic;
signal rc_q                          : std_logic_vector(8 downto 0);
signal rc_loading_done               : std_logic;
signal rc_frame_proto                : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal rc_frame_ready                : std_logic;
signal rc_frame_size                 : std_logic_vector(15 downto 0);

signal my_mac                        : std_logic_vector(47 downto 0);

signal main_debug                    : std_logic_vector(63 downto 0);
signal fr_cs_out           : std_logic_vector(15 downto 0);

begin


FRAME_RECEIVER : trb_net16_gbe_frame_receiver
port map(
	CLK			            => RX_CLIENT_CLK_0,
	RESET			            => RESET,
	LINK_OK_IN              => '1',
	ALLOW_RX_IN		         => '1',
	RX_MAC_CLK		         => RX_CLIENT_CLK_0,

-- input signals from TS_MAC
	MAC_RX_EOF_IN		      => EMAC0CLIENTRXGOODFRAME,
	MAC_RX_ER_IN		      => '0',
	MAC_RXD_IN		         => EMAC0CLIENTRXD,
	MAC_RX_EN_IN		      => EMAC0CLIENTRXDVLD,
	MAC_RX_FIFO_ERR_IN	   => '0',
	MAC_RX_FIFO_FULL_OUT   	=> open,
	MAC_RX_STAT_EN_IN	      => '0',
	MAC_RX_STAT_VEC_IN	   => (others => '0'),

-- output signal to control logic
	FR_Q_OUT		            => fr_q,
	FR_RD_EN_IN		         => fr_rd_en,
	FR_FRAME_VALID_OUT	   => fr_frame_valid,
	FR_GET_FRAME_IN		   => fr_get_frame,
	FR_FRAME_SIZE_OUT	      => fr_frame_size,
	FR_FRAME_PROTO_OUT	   => fr_frame_proto,
	FR_IP_PROTOCOL_OUT	   => fr_ip_proto,
	FR_ALLOWED_TYPES_IN	   => (others => '1'),
	FR_ALLOWED_IP_IN	      => (others => '1'),
	FR_ALLOWED_UDP_IN	      => (others => '1'),
	FR_ALLOWED_TCP_IN       => (others => '1'),
	FR_VLAN_ID_IN		      =>  vlan_id,
	
	FR_SRC_MAC_ADDRESS_OUT	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_OUT => fr_dest_mac,
	FR_SRC_IP_ADDRESS_OUT	=> fr_src_ip,
	FR_DEST_IP_ADDRESS_OUT	=> fr_dest_ip,
	FR_SRC_UDP_PORT_OUT	   => fr_src_udp,
	FR_DEST_UDP_PORT_OUT	   => fr_dest_udp,
	
	FR_ID_IP_OUT            => fr_id_ip,
	FR_FO_IP_OUT            => fr_fo_ip,
	FR_UDP_CHECKSUM_OUT     => fr_cs_out,
	
	FR_MY_MAC_IN            => RC_MY_MAC_IN,
	FR_REDIRECT_TRAFFIC_IN  => RC_REDIRECT_TRAFFIC_IN,

	DEBUG_OUT		         => open
);

RECEIVE_CONTROL : trb_net16_gbe_receive_control
port map(
	CLK			            => RX_CLIENT_CLK_0,
	RESET			            => RESET,

-- signals to/from frame_receiver
	RC_DATA_IN		         => fr_q,
	FR_RD_EN_OUT		      => fr_rd_en,
	FR_FRAME_VALID_IN	      => fr_frame_valid,
	FR_GET_FRAME_OUT	      => fr_get_frame,
	FR_FRAME_SIZE_IN	      => fr_frame_size,
	FR_FRAME_PROTO_IN     	=> fr_frame_proto,
	FR_IP_PROTOCOL_IN	      => fr_ip_proto,
	
	FR_SRC_MAC_ADDRESS_IN	=> fr_src_mac,
	FR_DEST_MAC_ADDRESS_IN  => fr_dest_mac,
	FR_SRC_IP_ADDRESS_IN	   => fr_src_ip,
	FR_DEST_IP_ADDRESS_IN	=> fr_dest_ip,
	FR_SRC_UDP_PORT_IN	   => fr_src_udp,
	FR_DEST_UDP_PORT_IN	   => fr_dest_udp,
	
	FR_ID_IP_IN            => fr_id_ip,
	FR_FO_IP_IN            => fr_fo_ip,
	FR_UDP_CHECKSUM_IN     => fr_cs_out,

-- signals to/from main controller
	RC_RD_EN_IN		         => RC_RD_EN_IN,
	RC_Q_OUT		            => RC_Q_OUT,
	RC_FRAME_WAITING_OUT	   => RC_FRAME_WAITING_OUT,
	RC_LOADING_DONE_IN	   => RC_LOADING_DONE_IN,
	RC_FRAME_SIZE_OUT	      => RC_FRAME_SIZE_OUT,
	RC_FRAME_PROTO_OUT	   => RC_FRAME_PROTO_OUT,
	RC_SRC_MAC_ADDRESS_OUT	=> RC_SRC_MAC_ADDRESS_OUT,
	RC_DEST_MAC_ADDRESS_OUT => RC_DEST_MAC_ADDRESS_OUT,
	RC_SRC_IP_ADDRESS_OUT	=> RC_SRC_IP_ADDRESS_OUT,
	RC_DEST_IP_ADDRESS_OUT	=> RC_DEST_IP_ADDRESS_OUT,
	RC_SRC_UDP_PORT_OUT	   => RC_SRC_UDP_PORT_OUT,
	RC_DEST_UDP_PORT_OUT	   => RC_DEST_UDP_PORT_OUT,
	RC_ID_IP_OUT            => RC_ID_IP_OUT,
	RC_FO_IP_OUT            => RC_FO_IP_OUT,
	RC_REDIRECT_TRAFFIC_IN  => RC_REDIRECT_TRAFFIC_IN,
	
	RC_CHECKSUM_OUT         => RC_CHECKSUM_OUT,

-- statistics
	FRAMES_RECEIVED_OUT   	=> open,
	BYTES_RECEIVED_OUT	   => open,

	DEBUG_OUT		         => open
);

end Behavioral;

