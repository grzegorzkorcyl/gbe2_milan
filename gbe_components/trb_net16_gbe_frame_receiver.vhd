LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

--********
-- here all frame checking has to be done, if the frame fits into protocol standards
-- if so FR_FRAME_VALID_OUT is asserted after having received all bytes of a frame
-- otherwise, after receiving all bytes, FR_FRAME_VALID_OUT keeps low and the fifo is cleared
-- also a part of addresses assignemt has to be done here

entity trb_net16_gbe_frame_receiver is
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
	FR_SRC_UDP_PORT_OUT	    : out	std_logic_vector(15 downto 0);
	FR_DEST_UDP_PORT_OUT	: out	std_logic_vector(15 downto 0);
	
	FR_ID_IP_OUT            : out   std_logic_vector(15 downto 0);
	FR_FO_IP_OUT            : out   std_logic_vector(15 downto 0);
	FR_UDP_CHECKSUM_OUT     : out   std_logic_vector(15 downto 0);
	
	FR_MY_MAC_IN            : in std_logic_vector(47 downto 0);
	FR_REDIRECT_TRAFFIC_IN  : in   std_logic;

	DEBUG_OUT		         : out	std_logic_vector(95 downto 0)
);
end trb_net16_gbe_frame_receiver;


architecture trb_net16_gbe_frame_receiver of trb_net16_gbe_frame_receiver is

attribute syn_encoding	: string;
type filter_states is (IDLE, REMOVE_DEST, REMOVE_SRC, REMOVE_TYPE, SAVE_FRAME, DROP_FRAME, REMOVE_VID, REMOVE_VTYPE, REMOVE_IP, REMOVE_UDP, REMOVE_TCP, DECIDE, CLEANUP);
signal filter_current_state, filter_next_state : filter_states;
attribute syn_encoding of filter_current_state : signal is "safe,gray";

signal fifo_wr_en                           : std_logic;
signal rx_bytes_ctr                         : std_logic_vector(15 downto 0);
signal frame_valid_q                        : std_logic;
signal delayed_frame_valid                  : std_logic;
signal delayed_frame_valid_q                : std_logic;

signal rec_fifo_empty                       : std_logic;
signal rec_fifo_full                        : std_logic;
signal sizes_fifo_full                      : std_logic;
signal sizes_fifo_empty                     : std_logic;

signal remove_ctr                           : std_logic_vector(7 downto 0);
signal new_frame                            : std_logic;
signal new_frame_lock                       : std_logic;
signal saved_frame_type                     : std_logic_vector(15 downto 0);
signal saved_vid                            : std_logic_vector(15 downto 0);
signal saved_src_mac                        : std_logic_vector(47 downto 0);
signal saved_dest_mac                       : std_logic_vector(47 downto 0);
signal frame_type_valid                     : std_logic;
signal saved_proto                          : std_logic_vector(7 downto 0);
signal saved_src_ip                         : std_logic_vector(31 downto 0);
signal saved_dest_ip                        : std_logic_vector(31 downto 0);
signal saved_src_udp                        : std_logic_vector(15 downto 0);
signal saved_dest_udp                       : std_logic_vector(15 downto 0);

signal dump                                 : std_logic_vector(7 downto 0);
signal dump2                                : std_logic_vector(7 downto 0);

signal error_frames_ctr                     : std_logic_vector(15 downto 0);

-- debug signals
signal dbg_rec_frames                       : std_logic_vector(15 downto 0);
signal dbg_ack_frames                       : std_logic_vector(15 downto 0);
signal dbg_drp_frames                       : std_logic_vector(15 downto 0);
signal state                                : std_logic_vector(3 downto 0);
signal parsed_frames_ctr                    : std_logic_vector(15 downto 0);
signal ok_frames_ctr                        : std_logic_vector(15 downto 0);

signal ip_d, macs_d, macd_d, ip_o, macs_o, macd_o                 : std_logic_vector(71 downto 0);
signal sizes_d, sizes_o                     : std_logic_vector(31 downto 0);
signal rec_d, rec_o                         : std_logic_vector(8 downto 0);

signal read_bytes_ctr                       : unsigned(15 downto 0);

signal tcp_wr_en, tcp_rd_en, tcp_reset      : std_logic;
signal tcp_q                                : std_logic_vector(7 downto 0);
signal fifo_rd_en                           : std_logic;
signal saved_id_ip, saved_fo_ip             : std_logic_vector(15 downto 0);
signal ip_h_d, ip_h_o                       : std_logic_vector(31 downto 0);
signal previous_id                          : std_logic_vector(15 downto 0);
signal prev_udp_dst_port                    : std_logic_vector(15 downto 0);
signal prev_udp_src_port                    : std_logic_vector(15 downto 0);
signal saved_checksum                       : std_logic_vector(15 downto 0);

begin

-- new_frame is asserted when first byte of the frame arrives
NEW_FRAME_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (MAC_RX_EOF_IN = '1') then
			new_frame <= '0';
			new_frame_lock <= '0';
		elsif (new_frame_lock = '0') and (MAC_RX_EN_IN = '1') then
			new_frame <= '1';
			new_frame_lock <= '1';
		else
			new_frame <= '0';
		end if;
	end if;
end process NEW_FRAME_PROC;


FILTER_MACHINE_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			filter_current_state <= IDLE;
		else
			filter_current_state <= filter_next_state;
		end if;
	end if;
end process FILTER_MACHINE_PROC;

FILTER_MACHINE : process(filter_current_state, saved_frame_type, saved_proto, FR_REDIRECT_TRAFFIC_IN, FR_MY_MAC_IN, saved_dest_mac, remove_ctr, new_frame, MAC_RX_EOF_IN, frame_type_valid, ALLOW_RX_IN)
begin

	case filter_current_state is
		
		when IDLE =>
			state <= x"1";
			if (new_frame = '1') and (ALLOW_RX_IN = '1') then
				filter_next_state <= REMOVE_DEST;
			else
				filter_next_state <= IDLE;
			end if;
		
		-- frames arrive without preamble!
		when REMOVE_DEST =>
			state <= x"3";
			if (remove_ctr = x"03") then  -- counter starts with a delay that's why only 3
				-- destination MAC address filtering here 
				if (saved_dest_mac = FR_MY_MAC_IN) or (saved_dest_mac = x"ffffffffffff") then
					filter_next_state <= REMOVE_SRC;
				else
					filter_next_state <= DECIDE;
				end if;
			else
				filter_next_state <= REMOVE_DEST;
			end if;
		
		when REMOVE_SRC =>
			state <= x"4";
			if (remove_ctr = x"09") then
				filter_next_state <= REMOVE_TYPE;
			else
				filter_next_state <= REMOVE_SRC;
			end if;
		
		when REMOVE_TYPE =>
			state <= x"5";
			if (remove_ctr = x"0b") then
				if (saved_frame_type = x"8100") then  -- VLAN tagged frame
					filter_next_state <= REMOVE_VID;
				else  -- no VLAN tag
					-- in case the redirection is on, treat all the frames as ip and tcp
					if (saved_frame_type = x"0800") or (FR_REDIRECT_TRAFFIC_IN = '1') then  -- in case of IP continue removing headers
						filter_next_state <= REMOVE_IP;
					else
						filter_next_state <= DECIDE;
					end if;
				end if;
			else
				filter_next_state <= REMOVE_TYPE;
			end if;
			
		when REMOVE_VID =>
			state <= x"a";
			if (remove_ctr = x"0d") then
				filter_next_state <= REMOVE_VTYPE;
			else
				filter_next_state <= REMOVE_VID;
			end if;
			
		when REMOVE_VTYPE =>
			state <= x"b";
			if (remove_ctr = x"0f") then
				if (saved_frame_type = x"0800") then  -- in case of IP continue removing headers
					filter_next_state <= REMOVE_IP;
				else
					filter_next_state <= DECIDE;
				end if;
			else
				filter_next_state <= REMOVE_VTYPE;
			end if;
			
		when REMOVE_IP =>
			state <= x"c";
			if (remove_ctr = x"11") then
				-- in case the redirection is on, treat all the frames as ip and tcp
				if (saved_proto = x"11") and (FR_REDIRECT_TRAFFIC_IN = '0') then  -- in case of udp
					if (saved_fo_ip(11 downto 0) = x"000") then  -- first frame
						filter_next_state <= REMOVE_UDP;
					else  -- following fragments
						filter_next_state <= DECIDE;
					end if;
				elsif (saved_proto = x"06") or (FR_REDIRECT_TRAFFIC_IN = '1') then  -- in case of tcp
					filter_next_state <= REMOVE_TCP;
				else
					filter_next_state <= DECIDE;
				end if;
			else
				filter_next_state <= REMOVE_IP;
			end if;
			
		when REMOVE_UDP =>
			state <= x"d";
			if (remove_ctr = x"19") then
				filter_next_state <= DECIDE;
			else
				filter_next_state <= REMOVE_UDP;
			end if;
			
		--	port numbers are at the same position as in UDP, remove only them, the rest pass to protocol implementation
		when REMOVE_TCP =>
			state <= x"e";
			if (remove_ctr = x"15") then
				filter_next_state <= DECIDE;
			else
				filter_next_state <= REMOVE_TCP;
			end if;
			
		when DECIDE =>
			state <= x"6";
			if (frame_type_valid = '1') then
				filter_next_state <= SAVE_FRAME;
			else
				filter_next_state <= DROP_FRAME;
			end if;	
			
		when SAVE_FRAME =>
			state <= x"7";
			if (MAC_RX_EOF_IN = '1') then
				filter_next_state <= CLEANUP;
			else
				filter_next_state <= SAVE_FRAME;
			end if;
			
		when DROP_FRAME =>
			state <= x"8";
			if (MAC_RX_EOF_IN = '1') then
				filter_next_state <= CLEANUP;
			else
				filter_next_state <= DROP_FRAME;
			end if;
		
		when CLEANUP =>
			state <= x"9";
			filter_next_state <= IDLE;
			
		when others => null;
	
	end case;
end process;

-- counts the bytes to be removed from the ethernet headers fields
REMOVE_CTR_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = IDLE) or
			(filter_current_state = REMOVE_VTYPE and remove_ctr = x"0f") or
			(filter_current_state = REMOVE_TYPE and remove_ctr = x"0b") then
			
			remove_ctr <= (others => '1');
		elsif (MAC_RX_EN_IN = '1') and (filter_current_state /= IDLE) then
			remove_ctr <= remove_ctr + x"1";
		end if;
	end if;
end process REMOVE_CTR_PROC;

PREVIOUS_ID_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (filter_current_state = CLEANUP) then
			previous_id <= saved_id_ip;
			prev_udp_dst_port <= saved_dest_udp;
			prev_udp_src_port <= saved_src_udp;
		else
			previous_id <= previous_id;
			prev_udp_dst_port <= prev_udp_dst_port;
			prev_udp_src_port <= prev_udp_src_port;
		end if;
	end if;
end process PREVIOUS_ID_PROC;

SAVED_ID_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_id_ip <= (others => '0');
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"03") then
			saved_id_ip(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"02") then
			saved_id_ip(15 downto 8) <= MAC_RXD_IN;
		else
			saved_id_ip <= saved_id_ip;
		end if;
	end if;
end process SAVED_ID_PROC;

SAVED_FO_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_fo_ip <= (others => '0');
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"05") then
			saved_fo_ip(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"04") then
			saved_fo_ip(15 downto 8) <= MAC_RXD_IN;
		else
			saved_fo_ip <= saved_fo_ip;
		end if;
	end if;
end process SAVED_FO_PROC;

SAVED_PROTO_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_proto <= (others => '0');
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"07") and (FR_REDIRECT_TRAFFIC_IN = '0') then
			saved_proto <= MAC_RXD_IN;
		elsif (FR_REDIRECT_TRAFFIC_IN = '1') then
			saved_proto <= x"06";
		end if;
	end if;
end process SAVED_PROTO_PROC;

SAVED_SRC_IP_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_src_ip <= (others => '0');
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0a") then
			saved_src_ip(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0b") then
			saved_src_ip(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0c") then
			saved_src_ip(23 downto 16) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0d") then
			saved_src_ip(31 downto 24) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_SRC_IP_PROC;

SAVED_DEST_IP_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_dest_ip <= (others => '0');
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0e") then
			saved_dest_ip(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"0f") then
			saved_dest_ip(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"10") then
			saved_dest_ip(23 downto 16) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP) and (remove_ctr = x"11") then
			saved_dest_ip(31 downto 24) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_DEST_IP_PROC;

SAVED_SRC_UDP_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_src_udp <= (others => '0');
		elsif (filter_current_state = REMOVE_UDP or filter_current_state = REMOVE_TCP) and (remove_ctr = x"12") then
			saved_src_udp(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_UDP or filter_current_state = REMOVE_TCP) and (remove_ctr = x"13") then
			saved_src_udp(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP and remove_ctr = x"08" and saved_proto = x"11") then -- in case of ip/udp
			if (saved_fo_ip(11 downto 0) /= x"000" and saved_id_ip = previous_id) then  -- in case of following fragments use previous udp dest port
				saved_src_udp <= prev_udp_src_port;
			else
				saved_src_udp <= x"0000"; -- drop otherwise
			end if;
		end if;
	end if;
end process SAVED_SRC_UDP_PROC;

SAVED_DEST_UDP_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_dest_udp <= (others => '0');
		elsif (filter_current_state = REMOVE_UDP or filter_current_state = REMOVE_TCP) and (remove_ctr = x"14") then
			saved_dest_udp(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_UDP or filter_current_state = REMOVE_TCP) and (remove_ctr = x"15") then
			saved_dest_udp(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_IP and remove_ctr = x"08" and saved_proto = x"11") then -- in case of ip/udp
			if (saved_fo_ip(11 downto 0) /= x"000" and saved_id_ip = previous_id) then  -- in case of following fragments use previous udp dest port
				saved_dest_udp <= prev_udp_dst_port;
			else
				saved_dest_udp <= x"0000"; -- drop otherwise
			end if;
		end if;
	end if;
end process SAVED_DEST_UDP_PROC;

SAVED_UDP_CHECKSUM_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_checksum <= (others => '0');
		elsif (filter_current_state = REMOVE_UDP) and (remove_ctr = x"18") then
			saved_checksum(15 downto 8) <= MAC_RXD_IN;
			saved_checksum(7 downto 0)  <= x"00"; 
		elsif (filter_current_state = REMOVE_UDP) and (remove_ctr = x"19") then
			saved_checksum(7 downto 0) <= MAC_RXD_IN;
			saved_checksum(15 downto 8) <= saved_checksum(15 downto 8);
		else
			saved_checksum <= saved_checksum;
		end if;
	end if;
end process SAVED_UDP_CHECKSUM_PROC;

-- saves the destination mac address of the incoming frame
SAVED_DEST_MAC_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_dest_mac <= (others => '0');
		elsif (filter_current_state = IDLE) and (MAC_RX_EN_IN = '1') and (new_frame = '0') then
			saved_dest_mac(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = IDLE) and (new_frame = '1') and (ALLOW_RX_IN = '1') then
			saved_dest_mac(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_DEST) and (remove_ctr = x"FF") then
			saved_dest_mac(23 downto 16) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_DEST) and (remove_ctr = x"00") then
			saved_dest_mac(31 downto 24) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_DEST) and (remove_ctr = x"01") then
			saved_dest_mac(39 downto 32) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_DEST) and (remove_ctr = x"02") then
			saved_dest_mac(47 downto 40) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_DEST_MAC_PROC;

-- saves the source mac address of the incoming frame
SAVED_SRC_MAC_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_src_mac <= (others => '0');
		elsif (filter_current_state = REMOVE_DEST) and (remove_ctr = x"03") then
			saved_src_mac(7 downto 0) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"04") then
			saved_src_mac(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"05") then
			saved_src_mac(23 downto 16) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"06") then
			saved_src_mac(31 downto 24) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"07") then
			saved_src_mac(39 downto 32) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"08") then
			saved_src_mac(47 downto 40) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_SRC_MAC_PROC;

-- saves the frame type of the incoming frame for futher check
SAVED_FRAME_TYPE_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_frame_type <= (others => '0');
		elsif (filter_current_state = REMOVE_SRC) and (remove_ctr = x"09") then
			saved_frame_type(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_TYPE) and (remove_ctr = x"0a") then
			saved_frame_type(7 downto 0) <= MAC_RXD_IN;
		-- two more cases for VLAN tagged frame
		elsif (filter_current_state = REMOVE_VID) and (remove_ctr = x"0d") then
			saved_frame_type(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_VTYPE) and (remove_ctr = x"0e") then
			saved_frame_type(7 downto 0) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_FRAME_TYPE_PROC;

-- saves VLAN id when tagged frame spotted
SAVED_VID_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') or (filter_current_state = CLEANUP) then
			saved_vid <= (others => '0');
		elsif (filter_current_state = REMOVE_TYPE and remove_ctr = x"0b" and saved_frame_type = x"8100") then
			saved_vid(15 downto 8) <= MAC_RXD_IN;
		elsif (filter_current_state = REMOVE_VID and remove_ctr = x"0c") then
			saved_vid(7 downto 0) <= MAC_RXD_IN;
		end if;
	end if;
end process SAVED_VID_PROC;

type_validator : trb_net16_gbe_type_validator
port map(
	CLK			             => RX_MAC_CLK,	
	RESET			         => RESET,
	FRAME_TYPE_IN		     => saved_frame_type,
	SAVED_VLAN_ID_IN	     => saved_vid,	
	ALLOWED_TYPES_IN	     => FR_ALLOWED_TYPES_IN,
	VLAN_ID_IN		         => FR_VLAN_ID_IN,
	
	-- IP level
	IP_PROTOCOLS_IN		     => saved_proto,
	ALLOWED_IP_PROTOCOLS_IN	 => FR_ALLOWED_IP_IN,
	
	-- UDP level
	UDP_PROTOCOL_IN		     => saved_dest_udp,
	ALLOWED_UDP_PROTOCOLS_IN => FR_ALLOWED_UDP_IN,
	
	-- TCP level
	TCP_PROTOCOL_IN          => saved_dest_udp,
	ALLOWED_TCP_PROTOCOLS_IN => FR_ALLOWED_TCP_IN,
	
	VALID_OUT		         => frame_type_valid
);

rec_d(7 downto 0) <= MAC_RXD_IN;
rec_d(8)          <= '0';
receive_fifo : fifo_4096x9
port map( 
	din                => rec_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => fifo_wr_en,
	rd_en              => fifo_rd_en, --FR_RD_EN_IN,
	rst                => RESET,
	dout               => rec_o,
	empty              => rec_fifo_empty,
	full               => rec_fifo_full
);
FIFO_RD_EN_PROC : process(ip_o, read_bytes_ctr, FR_RD_EN_IN)
begin
	if (FR_RD_EN_IN = '1') then
		if (ip_o(71 downto 64) = x"06" and read_bytes_ctr > 37) then
			fifo_rd_en <= '1';
		elsif (ip_o(71 downto 64) /= x"06") then
			fifo_rd_en <= '1';
		else
			fifo_rd_en <= '0';
		end if;
	else
		fifo_rd_en <= '0';
	end if;
end process FIFO_RD_EN_PROC;

fifo_wr_en <= '1' when (MAC_RX_EN_IN = '1') and ((filter_current_state = SAVE_FRAME and MAC_RX_EOF_IN = '0') or 
			--( (filter_current_state = REMOVE_TYPE and remove_ctr = x"b" and saved_frame_type /= x"8100" and saved_frame_type /= x"0800") or
				((filter_current_state = REMOVE_VTYPE and remove_ctr = x"f")) or
				(filter_current_state = DECIDE and frame_type_valid = '1'))
	      else '0';
			
FR_Q_OUT_PROC : process(ip_o, read_bytes_ctr, sizes_o, tcp_q, rec_o)
begin
	-- in case its TCP load headers first
	if (ip_o(71 downto 64) = x"06") then
		if (read_bytes_ctr < 39) then
			FR_Q_OUT(7 downto 0) <= tcp_q;
		else
			FR_Q_OUT(7 downto 0) <= rec_o(7 downto 0);
		end if;
		
		if (std_logic_vector(read_bytes_ctr) = sizes_o(15 downto 0) + x"27" and sizes_o(15 downto 0) /= x"0000") then
			FR_Q_OUT(8) <= '1';
		else
			FR_Q_OUT(8) <= '0';
		end if;
	-- otherwise proceed in a normal way
	else
		FR_Q_OUT(7 downto 0) <= rec_o(7 downto 0);
		if (std_logic_vector(read_bytes_ctr) = sizes_o(15 downto 0) and sizes_o(15 downto 0) /= x"0000") then
			FR_Q_OUT(8) <= '1';
		else
			FR_Q_OUT(8) <= '0';
		end if;
	end if;
end process FR_Q_OUT_PROC;
			
READ_BYTES_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (FR_GET_FRAME_IN = '1') then
			read_bytes_ctr <= (others => '0');
		elsif (std_logic_vector(read_bytes_ctr) = sizes_o(15 downto 0) + x"27" and ip_o(71 downto 64) = x"06") then
			read_bytes_ctr <= (others => '0');
		elsif (std_logic_vector(read_bytes_ctr) = sizes_o(15 downto 0) and ip_o(71 downto 64) /= x"06") then
			read_bytes_ctr <= (others => '0');	
		elsif (FR_RD_EN_IN = '1') then
			read_bytes_ctr <= read_bytes_ctr + 1;
		end if;
	end if;
end process READ_BYTES_CTR_PROC;
	      
	      
MAC_RX_FIFO_FULL_OUT <= rec_fifo_full;

sizes_d(15 downto 0)  <= rx_bytes_ctr;
sizes_d(31 downto 16) <= saved_frame_type;
sizes_fifo : fifo_512x32
port map( 
	din                => sizes_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => frame_valid_q,
	rd_en              => FR_GET_FRAME_IN,
	rst                => RESET,
	dout               => sizes_o,
	empty              => sizes_fifo_empty,
	full               => sizes_fifo_full
);
FR_FRAME_SIZE_OUT_PROC : process(ip_o, sizes_o)
begin
	if (ip_o(71 downto 64) = x"06") then
		FR_FRAME_SIZE_OUT   <= sizes_o(15 downto 0) + x"27";
	else
		FR_FRAME_SIZE_OUT   <= sizes_o(15 downto 0);
	end if;
end process FR_FRAME_SIZE_OUT_PROC;
FR_FRAME_PROTO_OUT  <= sizes_o(31 downto 16);

macs_d(47 downto 0)  <= saved_src_mac;
macs_d(63 downto 48) <= saved_src_udp;
macs_d(71 downto 64) <= saved_checksum(7 downto 0); --(others => '0');
macs_fifo : fifo_512x72
port map( 
	din                => macs_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => frame_valid_q,
	rd_en              => FR_GET_FRAME_IN,
	rst                => RESET,
	dout               => macs_o,
	empty              => open,
	full               => open
);
FR_SRC_MAC_ADDRESS_OUT          <= macs_o(47 downto 0);
FR_SRC_UDP_PORT_OUT             <= macs_o(63 downto 48);
FR_UDP_CHECKSUM_OUT(7 downto 0) <= macs_o(71 downto 64);
  
macd_d(47 downto 0)  <= saved_dest_mac;
macd_d(63 downto 48) <= saved_dest_udp;
macd_d(71 downto 64) <= saved_checksum(15 downto 8); --(others => '0');
macd_fifo : fifo_512x72
port map( 
	din                => macd_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => frame_valid_q,
	rd_en              => FR_GET_FRAME_IN,
	rst                => RESET,
	dout               => macd_o,
	empty              => open,
	full               => open
);
FR_DEST_MAC_ADDRESS_OUT          <= macd_o(47 downto 0);
FR_DEST_UDP_PORT_OUT             <= macd_o(63 downto 48);
FR_UDP_CHECKSUM_OUT(15 downto 8) <= macd_o(71 downto 64);

ip_d(31 downto 0)  <= saved_src_ip;
ip_d(63 downto 32) <= saved_dest_ip;
ip_d(71 downto 64) <= saved_proto;
ip_fifo : fifo_512x72
port map( 
	din                => ip_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => frame_valid_q,
	rd_en              => FR_GET_FRAME_IN,
	rst                => RESET,
	dout               => ip_o,
	empty              => open,
	full               => open
);
FR_SRC_IP_ADDRESS_OUT   <= ip_o(31 downto 0);
FR_DEST_IP_ADDRESS_OUT  <= ip_o(63 downto 32);
FR_IP_PROTOCOL_OUT      <= ip_o(71 downto 64);

ip_h_d(15 downto 0)  <= saved_id_ip;
ip_h_d(31 downto 16) <= saved_fo_ip; 
ip_h_fifo : fifo_512x32
port map( 
	din                => ip_h_d,
	wr_clk             => RX_MAC_CLK,
	rd_clk             => CLK,
	wr_en              => frame_valid_q,
	rd_en              => FR_GET_FRAME_IN,
	rst                => RESET,
	dout               => ip_h_o,
	empty              => open,
	full               => open
);
FR_ID_IP_OUT <= ip_h_o(15 downto 0);
FR_FO_IP_OUT <= ip_h_o(31 downto 16);

tcp_header_fifo : fifo_1024x8
port map(
	rst     => tcp_reset,
	wr_clk  => RX_MAC_CLK,
	rd_clk  => CLK,
	din     => MAC_RXD_IN,
	wr_en   => tcp_wr_en,
	rd_en   => tcp_rd_en,
	dout    => tcp_q,
	full    => open,
	empty   => open
);
tcp_wr_en <= '1' when (MAC_RX_EN_IN = '1') and 
							((filter_current_state = REMOVE_DEST or filter_current_state = REMOVE_SRC or 
							filter_current_state = REMOVE_TYPE or filter_current_state = REMOVE_IP or
							filter_current_state = REMOVE_TCP) or 							
							((filter_current_state = IDLE) and (new_frame = '1') and (ALLOW_RX_IN = '1')) or
							((filter_current_state = IDLE) and (MAC_RX_EN_IN = '1') and (new_frame = '0'))							)
						else '0';
tcp_rd_en <= '1' when (FR_RD_EN_IN = '1' and read_bytes_ctr < 39) else '0';
tcp_reset <= '1' when (RESET = '1') or (filter_current_state = DECIDE and saved_proto /= x"06") or
							(ip_o(71 downto 64) = x"06" and fifo_rd_en = '1')
						else '0';

FRAME_VALID_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (MAC_RX_EOF_IN = '1' and ALLOW_RX_IN = '1' and frame_type_valid = '1') then
			frame_valid_q <= '1';
		else
			frame_valid_q <= '0';
		end if;
	end if;
end process FRAME_VALID_PROC;

RX_BYTES_CTR_PROC : process(RX_MAC_CLK)
begin
  if rising_edge(RX_MAC_CLK) then
    if (RESET = '1') or (delayed_frame_valid_q = '1') then
      rx_bytes_ctr <= (others => '0');
    elsif (fifo_wr_en = '1') then
      rx_bytes_ctr <= rx_bytes_ctr + x"1";
    end if;
  end if;
end process;

PARSED_FRAMES_CTR_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			parsed_frames_ctr <= (others => '0');
		elsif (filter_current_state = IDLE and new_frame = '1' and ALLOW_RX_IN = '1') then
			parsed_frames_ctr <= parsed_frames_ctr + x"1";
		end if;
	end if;
end process PARSED_FRAMES_CTR_PROC;

FRAMEOK_FRAMES_CTR_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			ok_frames_ctr <= (others => '0');
		elsif (MAC_RX_STAT_EN_IN = '1' and MAC_RX_STAT_VEC_IN(23) = '1') then
			ok_frames_ctr <= ok_frames_ctr + x"1";
		end if;
	end if;
end process FRAMEOK_FRAMES_CTR_PROC;

ERROR_FRAMES_CTR_PROC : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			error_frames_ctr <= (others => '0');
		elsif (MAC_RX_ER_IN = '1') then
			error_frames_ctr <= error_frames_ctr + x"1";
		end if;
	end if;
end process ERROR_FRAMES_CTR_PROC;


SYNC_PROC : process(RX_MAC_CLK)
begin
  if rising_edge(RX_MAC_CLK) then
    delayed_frame_valid   <= MAC_RX_EOF_IN;
    delayed_frame_valid_q <= delayed_frame_valid;
  end if;
end process SYNC_PROC;

--*****************
-- synchronization between 125MHz receive clock and 100MHz system clock
FRAME_VALID_SYNC : pulse_sync
port map(
	CLK_A_IN    => RX_MAC_CLK,
	RESET_A_IN  => RESET,
	PULSE_A_IN  => frame_valid_q,
	CLK_B_IN    => CLK,
	RESET_B_IN  => RESET,
	PULSE_B_OUT => FR_FRAME_VALID_OUT
);


-- ****
-- debug counters, to be removed later
RECEIVED_FRAMES_CTR : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			dbg_rec_frames <= (others => '0');
		elsif (MAC_RX_EOF_IN = '1') then
			dbg_rec_frames <= dbg_rec_frames + x"1";
		end if;
	end if;
end process RECEIVED_FRAMES_CTR;

ACK_FRAMES_CTR : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			dbg_ack_frames <= (others => '0');
		elsif (filter_current_state = DECIDE and frame_type_valid = '1') then
			dbg_ack_frames <= dbg_ack_frames + x"1";
		end if;
	end if;
end process ACK_FRAMES_CTR;

DROPPED_FRAMES_CTR : process(RX_MAC_CLK)
begin
	if rising_edge(RX_MAC_CLK) then
		if (RESET = '1') then
			dbg_drp_frames <= (others => '0');
		elsif (filter_current_state = DECIDE and frame_type_valid = '0') then
			dbg_drp_frames <= dbg_drp_frames + x"1";
		end if;
	end if;
end process DROPPED_FRAMES_CTR;

sync1 : signal_sync
generic map (
	WIDTH => 16,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => dbg_drp_frames,
	D_OUT => DEBUG_OUT(63 downto 48)
);

sync2 : signal_sync
generic map (
	WIDTH => 16,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => dbg_ack_frames,
	D_OUT => DEBUG_OUT(47 downto 32)
);

sync3 : signal_sync
generic map (
	WIDTH => 12,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => dbg_rec_frames(11 downto 0),
	D_OUT => DEBUG_OUT(19 downto 8)
);

sync4 : signal_sync
generic map (
	WIDTH => 12,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => parsed_frames_ctr(11 downto 0),
	D_OUT => DEBUG_OUT(31 downto 20)
);

sync5 : signal_sync
generic map (
	WIDTH => 16,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => error_frames_ctr,
	D_OUT => DEBUG_OUT(79 downto 64)
);

sync6 : signal_sync
generic map (
	WIDTH => 16,
	DEPTH => 2
)
port map (
	RESET => RESET,
	CLK0  => CLK,
	CLK1  => CLK,
	D_IN  => ok_frames_ctr,
	D_OUT => DEBUG_OUT(95 downto 80)
);

-- end of debug counters
-- ****

end trb_net16_gbe_frame_receiver;


