LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

--********
-- controls the work of the whole gbe in both directions
-- multiplexes the output between data stream and output slow control packets based on priority
-- reacts to incoming gbe slow control commands
-- 


entity trb_net16_gbe_main_control is
generic (
	DO_SIMULATION           : integer range 0 to 1 := 0;
	UDP_RECEIVER         : integer range 0 to 1;
	UDP_TRANSMITTER      : integer range 0 to 1;
	MAC_ADDRESS          : std_logic_vector(47 downto 0)
);
port (
	CLK			            : in	std_logic;
	RESET			            : in	std_logic;

-- signals to/from receive controller
	RC_FRAME_WAITING_IN	   : in	std_logic;
	RC_LOADING_DONE_OUT	   : out	std_logic;
	RC_DATA_IN		         : in	std_logic_vector(8 downto 0);
	RC_RD_EN_OUT		      : out	std_logic;
	RC_FRAME_SIZE_IN	      : in	std_logic_vector(15 downto 0);
	RC_FRAME_PROTO_IN	      : in	std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

	RC_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	RC_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	RC_SRC_IP_ADDRESS_IN	   : in	std_logic_vector(31 downto 0);
	RC_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	RC_SRC_UDP_PORT_IN	   : in	std_logic_vector(15 downto 0);
	RC_DEST_UDP_PORT_IN	   : in	std_logic_vector(15 downto 0);
	
	RC_ID_IP_IN            : in std_logic_vector(15 downto 0);
	RC_FO_IP_IN            : in std_logic_vector(15 downto 0);
	RC_CHECKSUM_IN         : in std_logic_vector(15 downto 0);

-- signals to/from transmit controller
	TC_TRANSMIT_CTRL_OUT	   : out	std_logic;  -- slow control frame is waiting to be built and sent
	TC_TRANSMIT_DATA_OUT	   : out	std_logic;
	TC_DATA_OUT		         : out	std_logic_vector(8 downto 0);
	TC_RD_EN_IN		         : in	std_logic;
	TC_FRAME_SIZE_OUT	      : out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	      : out	std_logic_vector(15 downto 0);
	
	TC_DEST_MAC_OUT		   : out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT		      : out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		   : out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		      : out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT	       	: out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT	      	: out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	   : out	std_logic_vector(7 downto 0);
	TC_IDENT_OUT		      : out	std_logic_vector(15 downto 0);
	TC_CHECKSUM_OUT		      : out	std_logic_vector(15 downto 0);
	TC_TRANSMIT_DONE_IN	   : in	std_logic;
	
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
end trb_net16_gbe_main_control;


architecture trb_net16_gbe_main_control of trb_net16_gbe_main_control is

signal tsm_ready                            : std_logic;
signal tsm_reconf                           : std_logic;
signal tsm_haddr                            : std_logic_vector(7 downto 0);
signal tsm_hdata                            : std_logic_vector(7 downto 0);
signal tsm_hcs_n                            : std_logic;
signal tsm_hwrite_n                         : std_logic;
signal tsm_hread_n                          : std_logic;

type link_states is (WAIT_FOR_BOOT, ACTIVE, INACTIVE, ENABLE_MAC, TIMEOUT, FINALIZE, GET_ADDRESS);
signal link_current_state, link_next_state : link_states;

signal link_down_ctr                 : std_logic_vector(15 downto 0);
signal link_down_ctr_lock            : std_logic;
signal link_ok                       : std_logic;
signal link_ok_timeout_ctr           : std_logic_vector(15 downto 0);

signal mac_control_debug             : std_logic_vector(63 downto 0);

type flow_states is (IDLE, START_TRANSMISSION, TRANSMIT_CTRL, WAIT_FOR_FC, CLEANUP);
signal flow_current_state, flow_next_state : flow_states;

signal state                        : std_logic_vector(3 downto 0);
signal link_state                   : std_logic_vector(3 downto 0);
signal redirect_state               : std_logic_vector(3 downto 0);

signal ps_wr_en                     : std_logic;
signal ps_response_ready            : std_logic;
signal ps_busy                      : std_logic_vector(c_MAX_PROTOCOLS -1 downto 0);
signal rc_rd_en                     : std_logic;
signal first_byte                   : std_logic;
signal first_byte_q                 : std_logic;
signal first_byte_qq                : std_logic;
signal proto_select                 : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal loaded_bytes_ctr             : std_Logic_vector(15 downto 0);

signal dhcp_start                   : std_logic;
signal dhcp_done                    : std_logic;
signal wait_ctr                     : std_logic_vector(31 downto 0) := x"0000_0000";

signal rc_data_local                : std_logic_vector(8 downto 0);

-- debug
signal frame_waiting_ctr            : std_logic_vector(15 downto 0);
signal ps_busy_q                    : std_logic_vector(c_MAX_PROTOCOLS - 1 downto 0);
signal rc_frame_proto_q             : std_Logic_vector(c_MAX_PROTOCOLS - 1 downto 0);

type redirect_states is (IDLE, CHECK_TYPE, DROP, CHECK_BUSY, LOAD, BUSY, FINISH, CLEANUP);
signal redirect_current_state, redirect_next_state : redirect_states;

signal frame_type                   : std_logic_vector(15 downto 0);
signal disable_redirect, ps_wr_en_q : std_logic;

signal my_mac                       : std_logic_vector(47 downto 0);
signal my_ip                        : std_logic_vector(31 downto 0);
signal my_ip_dhcp                   : std_logic_vector(31 downto 0);
signal dest_udp_mac                 : std_logic_vector(47 downto 0);
signal dest_udp_ip                  : std_logic_vector(31 downto 0);
signal dest_udp_port                : std_logic_vector(15 downto 0);
signal redirect_traffic             : std_logic;

signal tc_data                      : std_logic_vector(8 downto 0);

signal mc_busy                      : std_logic;

attribute keep : string;
attribute keep of state, redirect_state, link_state, dhcp_start, rc_data_local : signal is "true";

begin

my_mac           <= MAC_ADDRESS;
my_ip            <= my_ip_dhcp;

MC_MY_MAC_OUT           <= my_mac;
MC_REDIRECT_TRAFFIC_OUT <= '0';
--

protocol_selector : trb_net16_gbe_protocol_selector
generic map(
	DO_SIMULATION        => DO_SIMULATION,
	UDP_RECEIVER         => UDP_RECEIVER,
	UDP_TRANSMITTER      => UDP_TRANSMITTER
	)
port map(
	CLK			            => CLK,
	RESET			            => RESET,
	
	PS_DATA_IN		         => rc_data_local, -- RC_DATA_IN,
	PS_WR_EN_IN		         => ps_wr_en_q, --ps_wr_en,
	PS_PROTO_SELECT_IN	   => proto_select,
	PS_BUSY_OUT		         => ps_busy,
	PS_FRAME_SIZE_IN	      => RC_FRAME_SIZE_IN,
	PS_RESPONSE_READY_OUT	=> ps_response_ready,

	PS_SRC_MAC_ADDRESS_IN	=> RC_SRC_MAC_ADDRESS_IN,
	PS_DEST_MAC_ADDRESS_IN  => RC_DEST_MAC_ADDRESS_IN,
	PS_SRC_IP_ADDRESS_IN	   => RC_SRC_IP_ADDRESS_IN,
	PS_DEST_IP_ADDRESS_IN	=> RC_DEST_IP_ADDRESS_IN,
	PS_SRC_UDP_PORT_IN	   => RC_SRC_UDP_PORT_IN,
	PS_DEST_UDP_PORT_IN	   => RC_DEST_UDP_PORT_IN,
	
	PS_ID_IP_IN            => RC_ID_IP_IN,
	PS_FO_IP_IN            => RC_FO_IP_IN,
	PS_CHECKSUM_IN         => RC_CHECKSUM_IN,
	
	PS_MY_MAC_IN            => my_mac,
	PS_MY_IP_IN             => my_ip,
	PS_MY_IP_OUT            => my_ip_dhcp,
	
	MC_BUSY_IN               => mc_busy,
	
	TC_DATA_OUT		         => tc_data,
	TC_RD_EN_IN		         => TC_RD_EN_IN,
	TC_FRAME_SIZE_OUT	      => TC_FRAME_SIZE_OUT,
	TC_FRAME_TYPE_OUT	      => TC_FRAME_TYPE_OUT,
	TC_IP_PROTOCOL_OUT	   => TC_IP_PROTOCOL_OUT,
	
	TC_DEST_MAC_OUT		   => TC_DEST_MAC_OUT,
	TC_DEST_IP_OUT		      => TC_DEST_IP_OUT,
	TC_DEST_UDP_OUT		   => TC_DEST_UDP_OUT,
	TC_SRC_MAC_OUT		      => TC_SRC_MAC_OUT,
	TC_SRC_IP_OUT		      => TC_SRC_IP_OUT,
	TC_SRC_UDP_OUT		      => TC_SRC_UDP_OUT,
	
	TC_IDENT_OUT           => TC_IDENT_OUT,
	TC_CHECKSUM_OUT        => TC_CHECKSUM_OUT,
	
	RECEIVED_FRAMES_OUT	   => open,
	SENT_FRAMES_OUT		   => open,
	PROTOS_DEBUG_OUT	      => open,
	
	-- add here connections between external logic and protocols
	DHCP_START_IN		      => dhcp_start,
	DHCP_DONE_OUT		      => dhcp_done,
	
	LL_DATA_IN              => LL_DATA_IN,
	LL_REM_IN               => LL_REM_IN,
	LL_SOF_N_IN             => LL_SOF_N_IN,
	LL_EOF_N_IN             => LL_EOF_N_IN,
	LL_SRC_READY_N_IN       => LL_SRC_READY_N_IN,
	LL_DST_READY_N_OUT      => LL_DST_READY_N_OUT,
	LL_READ_CLK_OUT         => LL_READ_CLK_OUT,
	
	-- interface to provide tcp data to kernel
	LL_UDP_OUT_DATA_OUT         => LL_UDP_OUT_DATA_OUT,
	LL_UDP_OUT_REM_OUT          => LL_UDP_OUT_REM_OUT,
	LL_UDP_OUT_SOF_N_OUT        => LL_UDP_OUT_SOF_N_OUT,
	LL_UDP_OUT_EOF_N_OUT        => LL_UDP_OUT_EOF_N_OUT,
	LL_UDP_OUT_SRC_READY_N_OUT  => LL_UDP_OUT_SRC_READY_N_OUT,
	LL_UDP_OUT_DST_READY_N_IN   => LL_UDP_OUT_DST_READY_N_IN,
	LL_UDP_OUT_FIFO_STATUS_IN   => LL_UDP_OUT_FIFO_STATUS_IN,
	LL_UDP_OUT_WRITE_CLK_OUT    => LL_UDP_OUT_WRITE_CLK_OUT,
	
	DEBUG_OUT		         => DEBUG_OUT
);

TC_DATA_OUT <= tc_data;

mc_busy <= '1' when flow_current_state = TRANSMIT_CTRL or flow_current_state = WAIT_FOR_FC else '0';

-- gk 07.11.11
-- do not select any response constructors when dropping a frame
proto_select <= RC_FRAME_PROTO_IN when disable_redirect = '0' else (others => '0');

-- gk 07.11.11
DISABLE_REDIRECT_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			disable_redirect <= '0';
			-- gk 16.11.11
--		elsif (redirect_current_state = IDLE and RC_FRAME_WAITING_IN = '1' and link_current_state /=ACTIVE and link_current_state /= GET_ADDRESS) then
--			disable_redirect <= '1';
--		elsif (redirect_current_state = IDLE and RC_FRAME_WAITING_IN = '1' and link_current_state = GET_ADDRESS and RC_FRAME_PROTO_IN /= "10") then
--			disable_redirect <= '1';
--		elsif (redirect_current_state = IDLE and RC_FRAME_WAITING_IN = '0') then
--			disable_redirect <= '0';
		elsif (redirect_current_state = CHECK_TYPE) then
			if (link_current_state /= ACTIVE and link_current_state /= GET_ADDRESS) then
				disable_redirect <= '1';
			elsif (link_current_state = GET_ADDRESS and RC_FRAME_PROTO_IN /= "10") then
				disable_redirect <= '1';
			else
				disable_redirect <= '0';
			end if;
		end if;
	end if;
end process DISABLE_REDIRECT_PROC;

SYNC_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		rc_data_local <= RC_DATA_IN;
	end if;
end process SYNC_PROC;

REDIRECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			redirect_current_state <= IDLE;
		else
			redirect_current_state <= redirect_next_state;
		end if;
	end if;
end process REDIRECT_MACHINE_PROC;

REDIRECT_MACHINE : process(redirect_current_state, link_current_state, RC_FRAME_PROTO_IN, RC_FRAME_WAITING_IN, RC_DATA_IN, ps_busy, RC_FRAME_PROTO_IN, ps_wr_en, loaded_bytes_ctr, RC_FRAME_SIZE_IN)
begin
	case redirect_current_state is
	
		when IDLE =>
			redirect_state <= x"1";
			if (RC_FRAME_WAITING_IN = '1') then
				redirect_next_state <= CHECK_TYPE;
			else
				redirect_next_state <= IDLE;
			end if;
			
		when CHECK_TYPE =>
			if (link_current_state = ACTIVE) then
				redirect_next_state <= CHECK_BUSY;
			elsif (link_current_state = GET_ADDRESS and RC_FRAME_PROTO_IN = "10") then
				redirect_next_state <= CHECK_BUSY;
			else
				redirect_next_state <= DROP;
			end if;			
			
		when DROP =>
			redirect_state <= x"7";
			if (loaded_bytes_ctr = RC_FRAME_SIZE_IN - x"1") then
				redirect_next_state <= FINISH;
			else
				redirect_next_state <= DROP;
			end if;
						
		when CHECK_BUSY =>
			redirect_state <= x"6";
			if (or_all(ps_busy and RC_FRAME_PROTO_IN) = '0') then
				redirect_next_state <= LOAD;
			else
				redirect_next_state <= BUSY;
			end if;
		
		when LOAD =>
			redirect_state <= x"2";
			if (loaded_bytes_ctr = RC_FRAME_SIZE_IN - x"1") then
				redirect_next_state <= FINISH;
			else
				redirect_next_state <= LOAD;
			end if;
		
		when BUSY =>
			redirect_state <= x"3";
			if (or_all(ps_busy and RC_FRAME_PROTO_IN) = '0') then
				redirect_next_state <= LOAD;
			else
				redirect_next_state <= BUSY;
			end if;
		
		when FINISH =>
			redirect_state <= x"4";
			redirect_next_state <= CLEANUP;
		
		when CLEANUP =>
			redirect_state <= x"5";
			redirect_next_state <= IDLE;
	
	end case;
end process REDIRECT_MACHINE;

rc_rd_en <= '1' when redirect_current_state = LOAD or redirect_current_state = DROP else '0';
RC_RD_EN_OUT <= rc_rd_en;

LOADING_DONE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			RC_LOADING_DONE_OUT <= '0';
		elsif (RC_DATA_IN(8) = '1' and ps_wr_en = '1') then
			RC_LOADING_DONE_OUT <= '1';
		else
			RC_LOADING_DONE_OUT <= '0';
		end if;
	end if;
end process LOADING_DONE_PROC;

PS_WR_EN_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		ps_wr_en <= rc_rd_en;
		ps_wr_en_q <= ps_wr_en;
	end if;
end process PS_WR_EN_PROC;

LOADED_BYTES_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (redirect_current_state = IDLE) then
			loaded_bytes_ctr <= (others => '0');
		elsif (redirect_current_state = LOAD or redirect_current_state = DROP) and (rc_rd_en = '1') then
			loaded_bytes_ctr <= loaded_bytes_ctr + x"1";
		end if;
	end if;
end process LOADED_BYTES_CTR_PROC;

FIRST_BYTE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		first_byte_q  <= first_byte;
		first_byte_qq <= first_byte_q;
		
		if (RESET = '1') then
			first_byte <= '0';
		elsif (redirect_current_state = IDLE) then
			first_byte <= '1';
		else
			first_byte <= '0';
		end if;
	end if;
end process FIRST_BYTE_PROC;

--*********************
--	DATA FLOW CONTROL

FLOW_MACHINE_PROC : process(CLK)
begin
  if rising_edge(CLK) then
    if (RESET = '1') then
      flow_current_state <= IDLE;
    else
      flow_current_state <= flow_next_state;
    end if;
  end if;
end process FLOW_MACHINE_PROC;

FLOW_MACHINE : process(flow_current_state, TC_TRANSMIT_DONE_IN, tc_data, ps_response_ready)
begin
  case flow_current_state is

		when IDLE =>
			state <= x"1";
			if (ps_response_ready = '1') then
				flow_next_state <= START_TRANSMISSION; --TRANSMIT_CTRL;
			else
				flow_next_state <= IDLE;
			end if;
			
		when START_TRANSMISSION =>
			flow_next_state <= TRANSMIT_CTRL;

		when TRANSMIT_CTRL =>
			state <= x"3";
			if (tc_data(8) = '1') then
				flow_next_state <= WAIT_FOR_FC;
			else
				flow_next_state <= TRANSMIT_CTRL;
			end if;

		when WAIT_FOR_FC =>
			state <= x"2";
			if (TC_TRANSMIT_DONE_IN = '1') then
				flow_next_state <= CLEANUP;
			else
				flow_next_state <= WAIT_FOR_FC;
			end if;

		when CLEANUP =>
			state <= x"4";
			flow_next_state <= IDLE;

  end case;
end process FLOW_MACHINE;

TC_TRANSMIT_CTRL_OUT <= '1' when (flow_current_state = START_TRANSMISSION) else '0';


--***********************
--	LINK STATE CONTROL
--
LINK_STATE_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			if (DO_SIMULATION = 0) then
				link_current_state <= ACTIVE; --WAIT_FOR_BOOT;
			elsif (DO_SIMULATION = 1) then
				link_current_state <= ACTIVE;
			end if;
		else
			link_current_state <= link_next_state;
		end if;
	end if;
end process;

LINK_STATE_MACHINE : process(link_current_state, dhcp_done, wait_ctr, PCS_AN_COMPLETE_IN, tsm_ready, link_ok_timeout_ctr)
begin
	case link_current_state is

		when ACTIVE =>
			link_state <= x"1";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				link_next_state <= ACTIVE;
			end if;

		when INACTIVE =>
			link_state <= x"2";
			if (PCS_AN_COMPLETE_IN = '1') then
				link_next_state <= TIMEOUT;
			else
				link_next_state <= INACTIVE;
			end if;

		when TIMEOUT =>
			link_state <= x"3";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (link_ok_timeout_ctr = x"ffff") then
					link_next_state <= ENABLE_MAC; --FINALIZE;
				else
					link_next_state <= TIMEOUT;
				end if;
			end if;

		when ENABLE_MAC =>
			link_state <= x"4";
			if (PCS_AN_COMPLETE_IN = '0') then
			  link_next_state <= INACTIVE;
			elsif (tsm_ready = '1') then
			  link_next_state <= FINALIZE; --INACTIVE;
			else
			  link_next_state <= ENABLE_MAC;
			end if;

		when FINALIZE =>
			link_state <= x"5";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				link_next_state <= WAIT_FOR_BOOT;
			end if;
			
		when WAIT_FOR_BOOT =>
			link_state <= x"6";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (wait_ctr = x"1000_0000") then
					link_next_state <= GET_ADDRESS;
				else
					link_next_state <= WAIT_FOR_BOOT;
				end if;
			end if;
		
		when GET_ADDRESS =>
			link_state <= x"7";
			if (PCS_AN_COMPLETE_IN = '0') then
				link_next_state <= INACTIVE;
			else
				if (dhcp_done = '1') then
					link_next_state <= ACTIVE;
				else
					link_next_state <= GET_ADDRESS;
				end if;
			end if;

	end case;
end process LINK_STATE_MACHINE;

LINK_OK_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (link_current_state /= TIMEOUT) then
			link_ok_timeout_ctr <= (others => '0');
		elsif (link_current_state = TIMEOUT) then
			link_ok_timeout_ctr <= link_ok_timeout_ctr + x"1";
		end if;
	end if;
end process LINK_OK_CTR_PROC;

link_ok <= '1' when (link_current_state = ACTIVE) or (link_current_state = GET_ADDRESS) or (link_current_state = WAIT_FOR_BOOT) else '0';

WAIT_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (link_current_state = INACTIVE) then
			wait_ctr <= (others => '0');
		elsif (link_current_state = WAIT_FOR_BOOT) then
			wait_ctr <= wait_ctr + x"1";
		end if;
	end if;
end process WAIT_CTR_PROC;

dhcp_start <= '1' when link_current_state = GET_ADDRESS else '0';


-- **** debug
FRAME_WAITING_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			frame_waiting_ctr <= (others => '0');
		elsif (RC_FRAME_WAITING_IN = '1') then
			frame_waiting_ctr <= frame_waiting_ctr + x"1";
		end if;
	end if;
end process FRAME_WAITING_CTR_PROC;

SAVE_VALUES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			ps_busy_q <= (others => '0');
			rc_frame_proto_q <= (others => '0');
		elsif (redirect_current_state = IDLE and RC_FRAME_WAITING_IN = '1') then
			ps_busy_q <= ps_busy;
			rc_frame_proto_q <= RC_FRAME_PROTO_IN;
		end if;
	end if;
end process SAVE_VALUES_PROC;


-- ****



end trb_net16_gbe_main_control;


