library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity receiver_module is
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
end receiver_module;

architecture STRUCTURE of receiver_module is

signal tc_transmit_ctrl, tc_transmit_data, tc_rd_en, tc_transmit_done : std_logic;
signal tc_ip_proto : std_logic_vector(7 downto 0);
signal tc_data : std_logic_vector(8 downto 0);
signal tc_frame_size, tc_frame_type, tc_dest_udp, tc_src_udp, tc_ident, tc_checksum : std_logic_vector(15 downto 0);
signal tc_dest_mac, tc_src_mac, my_mac : std_logic_vector(47 downto 0);
signal tc_dest_ip, tc_src_ip : std_logic_vector(31 downto 0);

signal rc_src_mac                    : std_logic_vector(47 downto 0);
signal rc_dest_mac                   : std_logic_vector(47 downto 0);
signal rc_src_ip                     : std_logic_vector(31 downto 0);
signal rc_dest_ip                    : std_logic_vector(31 downto 0);
signal rc_src_udp                    : std_logic_vector(15 downto 0);
signal rc_dest_udp                   : std_logic_vector(15 downto 0);
signal rc_id_ip                      : std_logic_vector(15 downto 0);
signal rc_fo_ip                      : std_logic_vector(15 downto 0);
signal rc_rd_en                      : std_logic;
signal rc_q                          : std_logic_vector(8 downto 0);
signal rc_loading_done               : std_logic;
signal rc_frame_proto                : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal rc_frame_ready                : std_logic;
signal rc_frame_size, rc_checksum    : std_logic_vector(15 downto 0);

begin
	
	tx : frame_tx
	port map (
		MAIN_CTRL_CLK			=> CLK_125_IN,
		RESET                   => RESET_IN,
		
		CLIENTEMAC0TXD          => TX_DATA_OUT,
		CLIENTEMAC0TXDVLD       => TX_DATA_DV_OUT,
		CLIENTEMAC0TXFIRSTBYTE  => TX_DATA_FB_OUT,
		CLIENTEMAC0TXUNDERRUN   => open,
		TX_CLIENT_CLK_0         => TX_CLK_IN,
		EMAC0CLIENTTXACK        => TX_DATA_ACK_IN,
		EMAC0CLIENTTXSTATSVLD   => TX_DATA_STATS_VALID_IN,
		
		MC_TRANSMIT_CTRL_IN	    => tc_transmit_ctrl,
		MC_DATA_IN		        => tc_data,
		MC_RD_EN_OUT		    => tc_rd_en,
		MC_FRAME_SIZE_IN	    => tc_frame_size,
		MC_FRAME_TYPE_IN	    => tc_frame_type,
		MC_DEST_MAC_IN		    => tc_dest_mac,
		MC_DEST_IP_IN		    => tc_dest_ip,
		MC_DEST_UDP_IN		    => tc_dest_udp,
		MC_SRC_MAC_IN		    => tc_src_mac,
		MC_SRC_IP_IN		    => tc_src_ip,
		MC_SRC_UDP_IN		    => tc_src_udp,
		MC_IP_PROTOCOL_IN	    => tc_ip_proto,
		MC_IDENT_IN             => tc_ident,
		MC_CHECKSUM_IN          => (others => '0'), --tc_checksum,
		MC_TRANSMIT_DONE_OUT	=> tc_transmit_done,

		DEBUG_OUT               => open
	);

	rx : frame_rx
	port map (
		RESET                     => RESET_IN,
		RX_CLIENT_CLK_0           => CLK_125_IN,
		
		EMAC0CLIENTRXD            => RX_DATA_IN,
		EMAC0CLIENTRXDVLD         => RX_DATA_DV_IN,
		EMAC0CLIENTRXGOODFRAME    => RX_DATA_GF_IN,
		EMAC0CLIENTRXBADFRAME     => RX_DATA_BF_IN,
		EMAC0CLIENTRXFRAMEDROP    => '0',
		EMAC0CLIENTRXSTATS        => (others => '0'),
		EMAC0CLIENTRXSTATSVLD     => '0',
		EMAC0CLIENTRXSTATSBYTEVLD => '0',
	
		-- signalc to/from main controller
		RC_RD_EN_IN	              => rc_rd_en,
		RC_Q_OUT		              => rc_q,
		RC_FRAME_WAITING_OUT	     => rc_frame_ready,
		RC_LOADING_DONE_IN	     => rc_loading_done,
		RC_FRAME_SIZE_OUT	        => rc_frame_size,
		RC_FRAME_PROTO_OUT	     => rc_frame_proto,
		RC_SRC_MAC_ADDRESS_OUT	  => rc_src_mac,
		RC_DEST_MAC_ADDRESS_OUT   => rc_dest_mac,
		RC_SRC_IP_ADDRESS_OUT	  => rc_src_ip,
		RC_DEST_IP_ADDRESS_OUT	  => rc_dest_ip,
		RC_SRC_UDP_PORT_OUT	     => rc_src_udp,
		RC_DEST_UDP_PORT_OUT	     => rc_dest_udp,
		RC_ID_IP_OUT              => rc_id_ip,
		RC_FO_IP_OUT              => rc_fo_ip,
		RC_CHECKSUM_OUT           => rc_checksum, 
		RC_MY_MAC_IN              => my_mac,
		RC_REDIRECT_TRAFFIC_IN    => '0',
		
		DEBUG_OUT                 => open
	);
	
	main_controller : trb_net16_gbe_main_control
	generic map(
		DO_SIMULATION           => 0,
		UDP_RECEIVER            => UDP_RECEIVER,
		UDP_TRANSMITTER         => UDP_TRANSMITTER,
		MAC_ADDRESS             => MAC_ADDRESS
	)
	port map(
		CLK			            => CLK_125_IN,
		RESET			        => RESET_IN,

		-- signals to/from receive controller
		RC_FRAME_WAITING_IN	   => rc_frame_ready,
		RC_LOADING_DONE_OUT	   => rc_loading_done,
		RC_DATA_IN		       => rc_q,
		RC_RD_EN_OUT		   => rc_rd_en,
		RC_FRAME_SIZE_IN	   => rc_frame_size,
		RC_FRAME_PROTO_IN	   => rc_frame_proto,
		RC_SRC_MAC_ADDRESS_IN  => rc_src_mac,
		RC_DEST_MAC_ADDRESS_IN => rc_dest_mac,
		RC_SRC_IP_ADDRESS_IN   => rc_src_ip,
		RC_DEST_IP_ADDRESS_IN  => rc_dest_ip,
		RC_SRC_UDP_PORT_IN	   => rc_src_udp,
		RC_DEST_UDP_PORT_IN	   => rc_dest_udp,
		RC_ID_IP_IN            => rc_id_ip,
		RC_FO_IP_IN            => rc_fo_ip,
		RC_CHECKSUM_IN         => rc_checksum,

		-- signals to/from transmit controller
		TC_TRANSMIT_CTRL_OUT   => tc_transmit_ctrl,
		TC_TRANSMIT_DATA_OUT   => tc_transmit_data,
		TC_DATA_OUT		       => tc_data,
		TC_RD_EN_IN		       => tc_rd_en,
		TC_FRAME_SIZE_OUT	   => tc_frame_size,
		TC_FRAME_TYPE_OUT	   => tc_frame_type,
		TC_DEST_MAC_OUT	       => tc_dest_mac,
		TC_DEST_IP_OUT		   => tc_dest_ip,
		TC_DEST_UDP_OUT		   => tc_dest_udp,
		TC_SRC_MAC_OUT		   => tc_src_mac,
		TC_SRC_IP_OUT		   => tc_src_ip,
		TC_SRC_UDP_OUT		   => tc_src_udp,
		TC_IP_PROTOCOL_OUT	   => tc_ip_proto,
		TC_IDENT_OUT           => tc_ident,
		TC_CHECKSUM_OUT        => tc_checksum,
		TC_TRANSMIT_DONE_IN	   => tc_transmit_done,
		
		PCS_AN_COMPLETE_IN      => '1',
		MC_MY_MAC_OUT           => my_mac,
		
		-- interface to provide tcp data to kernel
		LL_UDP_OUT_DATA_OUT         => LL_UDP_OUT_DATA_OUT,
		LL_UDP_OUT_REM_OUT          => LL_UDP_OUT_REM_OUT,
		LL_UDP_OUT_SOF_N_OUT        => LL_UDP_OUT_SOF_N_OUT,
		LL_UDP_OUT_EOF_N_OUT        => LL_UDP_OUT_EOF_N_OUT,
		LL_UDP_OUT_SRC_READY_N_OUT  => LL_UDP_OUT_SRC_READY_N_OUT,
		LL_UDP_OUT_DST_READY_N_IN   => LL_UDP_OUT_DST_READY_N_IN,
		LL_UDP_OUT_FIFO_STATUS_IN   => LL_UDP_OUT_FIFO_STATUS_IN,
		LL_UDP_OUT_WRITE_CLK_OUT    => LL_UDP_OUT_WRITE_CLK_OUT,
		
		LL_DATA_IN              => LL_DATA_IN,
		LL_REM_IN               => LL_REM_IN,
		LL_SOF_N_IN             => LL_SOF_N_IN,
		LL_EOF_N_IN             => LL_EOF_N_IN,
		LL_SRC_READY_N_IN       => LL_SRC_READY_N_IN,
		LL_DST_READY_N_OUT      => LL_DST_READY_N_OUT,
		LL_READ_CLK_OUT         => LL_READ_CLK_OUT,
	
		DEBUG_OUT		             => open
	);

end architecture STRUCTURE;

