library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
library work;
--use work.trb_net_std.all;

package trb_net_gbe_protocols is

constant c_SIMULATE           : integer range 0 to 1 := 0;

-- CANNOT drive global signals in entity and read he out in the other in XST
-- g_MY_IP is being set by DHCP Response Constructor
--signal g_MY_IP                : std_logic_vector(31 downto 0);
-- g_MY_MAC is being set by Main Controller
--signal g_MY_MAC               : std_logic_vector(47 downto 0);

-- PROTOCOLS DEFINITIONS
-- 1. ARP
-- 2. DHCP
-- 3. Ping
-- 4. TcpForward
-- 5. DataTX (tx only)
-- 6. DataRX

constant c_MAX_FRAME_TYPES    : integer range 1 to 16 := 2;
constant c_MAX_PROTOCOLS      : integer range 1 to 16 := 4;
constant c_MAX_IP_PROTOCOLS   : integer range 1 to 16 := 3;
constant c_MAX_UDP_PROTOCOLS  : integer range 1 to 16 := 3;
constant c_MAX_TCP_PROTOCOLS  : integer range 1 to 16 := 2;

type frame_types_a is array(c_MAX_FRAME_TYPES - 1 downto 0) of std_logic_vector(15 downto 0);
constant FRAME_TYPES : frame_types_a := (x"0800", x"0806"); 
-- IPv4, ARP

type ip_protos_a is array(c_MAX_IP_PROTOCOLS - 1 downto 0) of std_logic_vector(7 downto 0);
constant IP_PROTOCOLS : ip_protos_a := (x"11", x"01", x"06");
-- UDP, ICMP, TCP

-- this are the destination ports of the incoming packet
type udp_protos_a is array(c_MAX_UDP_PROTOCOLS - 1 downto 0) of std_logic_vector(15 downto 0);
constant UDP_PROTOCOLS : udp_protos_a := (x"0044", x"61a8", x"61a8");
-- DHCP client, Data

type tcp_protocols_a is array(c_MAX_TCP_PROTOCOLS - 1 downto 0) of std_logic_vector(15 downto 0);
constant TCP_PROTOCOLS : tcp_protocols_a := (x"1700", x"0050");
-- Telnet, HTTP

component trb_net16_gbe_response_constructor_ARP is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
		
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IDENT_OUT        : out	std_logic_vector(15 downto 0);
			
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_DHCP is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
		
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IDENT_OUT	    : out	std_logic_vector(15 downto 0);
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	DHCP_START_IN		: in	std_logic;
	DHCP_DONE_OUT		: out	std_logic;
	DHCP_MY_IP_OUT    : out std_logic_vector(31 downto 0);
	
-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_Ping is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
	
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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
		
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_Stat is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
	
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	
	TC_BUSY_IN		: in	std_logic;
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;	
		
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	STAT_DATA_IN : in std_logic_vector(c_MAX_PROTOCOLS * 32 - 1 downto 0);
	STAT_ADDR_IN : in std_logic_vector(c_MAX_PROTOCOLS * 8 - 1 downto 0);
	STAT_DATA_RDY_IN  : in std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
	STAT_DATA_ACK_OUT : out std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_DataTX is
generic ( STAT_ADDRESS_BASE : integer := 0
);
	port (
		CLK			: in	std_logic;  -- system clock
		RESET			: in	std_logic;
		
	-- INTERFACE	
		PS_DATA_IN		: in	std_logic_vector(8 downto 0);
		PS_WR_EN_IN		: in	std_logic;
		PS_ACTIVATE_IN		: in	std_logic;
		PS_RESPONSE_READY_OUT	: out	std_logic;
		PS_BUSY_OUT		: out	std_logic;
		PS_SELECTED_IN		: in	std_logic;
		PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
		PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
		PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
		PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
		PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
		PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
		
		PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
		PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
			
		TC_RD_EN_IN		: in	std_logic;
		TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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

		STAT_DATA_OUT : out std_logic_vector(31 downto 0);
		STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
		STAT_DATA_RDY_OUT : out std_logic;
		STAT_DATA_ACK_IN  : in std_logic;
		
		RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
		SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
	-- END OF INTERFACE
	
	-- protocol specific ports
		UDP_CHECKSUM_OUT     : out std_logic_vector(15 downto 0);
	
		SCTRL_DEST_MAC_IN    : in std_logic_vector(47 downto 0);
		SCTRL_DEST_IP_IN     : in std_logic_vector(31 downto 0);
		SCTRL_DEST_UDP_IN    : in std_logic_vector(15 downto 0);
		
		LL_DATA_IN           : in std_logic_vector(31 downto 0);
		LL_REM_IN            : in std_logic_vector(1 downto 0);
		LL_SOF_N_IN          : in std_logic;
		LL_EOF_N_IN          : in std_logic;
		LL_SRC_READY_N_IN    : in std_logic;
		LL_DST_READY_N_OUT   : out std_logic;
		LL_READ_CLK_OUT      : out std_logic;		
	-- end of protocol specific ports
	
	-- debug
		DEBUG_OUT		: out	std_logic_vector(31 downto 0)
	);
end component;

component trb_net16_gbe_response_constructor_Telnet is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
	
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
	TC_FRAME_SIZE_OUT	: out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	: out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		: out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		: out	std_logic_vector(15 downto 0);
	TC_IP_SIZE_OUT		      : out	std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT		   : out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	   : out	std_logic_vector(15 downto 0);
	TC_BUSY_IN		: in	std_logic;
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
		
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_TcpForward is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
	
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
		
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

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

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

component trb_net16_gbe_response_constructor_DataRX is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			: in	std_logic;  -- system clock
	RESET			: in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		: in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		: in	std_logic;
	PS_ACTIVATE_IN		: in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		: out	std_logic;
	PS_SELECTED_IN		: in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	: in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN  : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN   : in std_logic_vector(31 downto 0);
		
	TC_RD_EN_IN		: in	std_logic;
	TC_DATA_OUT		: out	std_logic_vector(8 downto 0);
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
	
	STAT_DATA_OUT : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT : out std_logic;
	STAT_DATA_ACK_IN  : in std_logic;
	
	RECEIVED_FRAMES_OUT	: out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		: out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

	PS_ID_IP_IN	        : in	std_logic_vector(15 downto 0);
	PS_FO_IP_IN	        : in	std_logic_vector(15 downto 0);
	PS_CHECKSUM_IN	    : in	std_logic_vector(15 downto 0);

	-- interface to provide udp data to kernel
	LL_UDP_OUT_DATA_OUT         : out std_logic_vector(31 downto 0);
	LL_UDP_OUT_REM_OUT          : out std_logic_vector(1 downto 0);
	LL_UDP_OUT_SOF_N_OUT        : out std_logic;
	LL_UDP_OUT_EOF_N_OUT        : out std_logic;
	LL_UDP_OUT_SRC_READY_N_OUT  : out std_logic;
	LL_UDP_OUT_DST_READY_N_IN   : in std_logic;
	LL_UDP_OUT_FIFO_STATUS_IN   : in std_logic_vector(3 downto 0);
	LL_UDP_OUT_WRITE_CLK_OUT    : out std_logic;

-- debug
	DEBUG_OUT		: out	std_logic_vector(31 downto 0)
);
end component;

end package;
