LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity trb_net16_gbe_response_constructor_Telnet is
generic ( STAT_ADDRESS_BASE : integer := 0
);
port (
	CLK			            : in	std_logic;  -- system clock
	RESET			            : in	std_logic;
	
-- INTERFACE	
	PS_DATA_IN		         : in	std_logic_vector(8 downto 0);
	PS_WR_EN_IN		         : in	std_logic;
	PS_ACTIVATE_IN		      : in	std_logic;
	PS_RESPONSE_READY_OUT	: out	std_logic;
	PS_BUSY_OUT		         : out	std_logic;
	PS_SELECTED_IN		      : in	std_logic;
	PS_SRC_MAC_ADDRESS_IN	: in	std_logic_vector(47 downto 0);
	PS_DEST_MAC_ADDRESS_IN  : in	std_logic_vector(47 downto 0);
	PS_SRC_IP_ADDRESS_IN	   : in	std_logic_vector(31 downto 0);
	PS_DEST_IP_ADDRESS_IN	: in	std_logic_vector(31 downto 0);
	PS_SRC_UDP_PORT_IN	   : in	std_logic_vector(15 downto 0);
	PS_DEST_UDP_PORT_IN	   : in	std_logic_vector(15 downto 0);
	
	PS_MY_MAC_IN            : in std_logic_vector(47 downto 0);
	PS_MY_IP_IN             : in std_logic_vector(31 downto 0);
	
	TC_RD_EN_IN		         : in	std_logic;
	TC_DATA_OUT		         : out	std_logic_vector(8 downto 0);
	TC_FRAME_SIZE_OUT	      : out	std_logic_vector(15 downto 0);
	TC_FRAME_TYPE_OUT	      : out	std_logic_vector(15 downto 0);
	TC_IP_PROTOCOL_OUT	   : out	std_logic_vector(7 downto 0);	
	TC_DEST_MAC_OUT		   : out	std_logic_vector(47 downto 0);
	TC_DEST_IP_OUT	       	: out	std_logic_vector(31 downto 0);
	TC_DEST_UDP_OUT		   : out	std_logic_vector(15 downto 0);
	TC_SRC_MAC_OUT		      : out	std_logic_vector(47 downto 0);
	TC_SRC_IP_OUT		      : out	std_logic_vector(31 downto 0);
	TC_SRC_UDP_OUT		      : out	std_logic_vector(15 downto 0);
	TC_IP_SIZE_OUT		      : out	std_logic_vector(15 downto 0);
	TC_UDP_SIZE_OUT		   : out	std_logic_vector(15 downto 0);
	TC_FLAGS_OFFSET_OUT	   : out	std_logic_vector(15 downto 0);
	TC_BUSY_IN		         : in	std_logic;
	
	STAT_DATA_OUT           : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT           : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT       : out std_logic;
	STAT_DATA_ACK_IN        : in std_logic;
		
	RECEIVED_FRAMES_OUT	   : out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		   : out	std_logic_vector(15 downto 0);
-- END OF INTERFACE

-- debug
	DEBUG_OUT		         : out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_Telnet;


architecture trb_net16_gbe_response_constructor_Telnet of trb_net16_gbe_response_constructor_Telnet is

attribute syn_encoding	: string;

type conversation_states is (IDLE, WAIT_FOR_SYN, REPLY_SYN, CLEANUP);
signal conversation_current_state, conversation_next_state : conversation_states;
attribute syn_encoding of conversation_current_state : signal is "safe,gray";

type dissect_states is (IDLE, READ_FRAME, WAIT_FOR_LOAD, LOAD_FRAME, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state : signal is "safe,gray";

type construct_states is (IDLE, PREPARE_HEADERS, WAIT_FOR_LOAD, PUT_HEADERS, CLEANUP);
signal construct_current_state, construct_next_state : construct_states;
attribute syn_encoding of construct_current_state : signal is "safe,gary";


signal state                    : std_logic_vector(3 downto 0);
signal rec_frames               : std_logic_vector(15 downto 0);
signal sent_frames              : std_logic_vector(15 downto 0);

signal data_ctr                 : integer range 1 to 1500;
signal tc_data                  : std_logic_vector(8 downto 0);

signal stat_data_temp           : std_logic_vector(31 downto 0);

-- received tcp headers
signal saved_headers            : std_logic_vector(79 downto 0);
signal seq_ident                : std_logic_vector(31 downto 0);
signal seq_ident_temp           : std_logic_vector(31 downto 0);
signal ack_ident                : std_logic_vector(31 downto 0);
signal header_len               : std_logic_vector(3 downto 0);
signal syn_flag                 : std_logic;
signal fin_flag                 : std_logic;
signal ack_flag                 : std_logic;

signal constr_data_ctr          : integer range 0 to 39;
signal outgoing_headers         : std_logic_vector(127 downto 0);
signal outgoing_flags           : std_logic_vector(5 downto 0);
signal out_syn_flag             : std_logic;
signal out_fin_flag             : std_logic;
signal out_ack_flag             : std_logic;

signal out_seq_ctr              : std_logic_vector(31 downto 0);
signal outgoing_options         : std_logic_vector(95 downto 0);

begin

CONVERSATION_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			conversation_current_state <= IDLE;
		else
			conversation_current_state <= conversation_next_state;
		end if;
	end if;
end process CONVERSATION_MACHINE_PROC;

CONVERSATION_MACHINE : process(conversation_current_state, syn_flag, construct_current_state)
begin
	
	case (conversation_current_state) is
	
		when IDLE =>
			conversation_next_state <= WAIT_FOR_SYN;
		
		when WAIT_FOR_SYN =>
			if (syn_flag = '1') then
				conversation_next_state <= REPLY_SYN;
			else
				conversation_next_state <= WAIT_FOR_SYN;
			end if;
		
		when REPLY_SYN =>
			if (construct_current_state = CLEANUP) then
				conversation_next_state <= CLEANUP;
			else
				conversation_next_state <= REPLY_SYN;
			end if;
		
		when CLEANUP =>
			conversation_next_state <= IDLE;
			
	end case;
	
end process CONVERSATION_MACHINE;



DISSECT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			dissect_current_state <= IDLE;
		else
			dissect_current_state <= dissect_next_state;
		end if;
	end if;
end process DISSECT_MACHINE_PROC;

DISSECT_MACHINE : process(dissect_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, PS_DATA_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			state <= x"1";
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			state <= x"2";
			if (PS_DATA_IN(8) = '1') then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= READ_FRAME;
			end if;
		
		when CLEANUP =>
			state <= x"5";
			dissect_next_state <= IDLE;
			
		when others => null;
	
	end case;
end process DISSECT_MACHINE;

DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = WAIT_FOR_LOAD) then
			data_ctr <= 1;
		elsif (dissect_current_state = READ_FRAME and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			data_ctr <= data_ctr + 1;
		end if;
	end if;
end process DATA_CTR_PROC;

SAVE_VALUES_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = CLEANUP) then
			saved_headers <= (others => '0');
		elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			saved_headers(79 downto 72) <= PS_DATA_IN(7 downto 0);
		elsif (dissect_current_state = READ_FRAME) then
			if (data_ctr < 11) then
				saved_headers((10 - data_ctr) * 8 - 1 downto ((10 - data_ctr) - 1) * 8) <= PS_DATA_IN(7 downto 0);
			end if;
		end if;
	end if;
end process SAVE_VALUES_PROC;

SAVE_HEADERS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (construct_current_state = CLEANUP) then
			seq_ident  <= (others => '0');
			ack_ident  <= (others => '0');
			header_len <= (others => '0');
			syn_flag   <= '0';
			ack_flag   <= '0';
			fin_flag   <= '0';
		elsif (dissect_current_state = CLEANUP) then
			seq_ident  <= saved_headers(79 downto 48);
			ack_ident  <= saved_headers(47 downto 16);
			header_len <= saved_headers(15 downto 12);
			ack_flag   <= saved_headers(4);
			syn_flag   <= saved_headers(1);
			fin_flag   <= saved_headers(0);
		end if;
	end if;
end process SAVE_HEADERS_PROC;

CONSTRUCT_MACHINE_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			construct_current_state <= IDLE;
		else
			construct_current_state <= construct_next_state;
		end if;
	end if;
end process CONSTRUCT_MACHINE_PROC;

CONSTRUCT_MACHINE : process(construct_current_state, conversation_current_state, TC_BUSY_IN, PS_SELECTED_IN, constr_data_ctr)
begin

	case (construct_current_state) is
	
		when IDLE =>
			if (conversation_current_state = REPLY_SYN) then
				construct_next_state <= PREPARE_HEADERS;
			else
				construct_next_state <= IDLE;
			end if;
			
		when PREPARE_HEADERS =>
			construct_next_state <= WAIT_FOR_LOAD;
			
		when WAIT_FOR_LOAD =>
			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
				construct_next_state <= PUT_HEADERS;
			else
				construct_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when PUT_HEADERS =>
			if (constr_data_ctr = 28) then
				construct_next_state <= CLEANUP;
			else
				construct_next_state <= PUT_HEADERS;
			end if;
		
		when CLEANUP =>
			construct_next_state <= IDLE;
			
	end case;
	
end process CONSTRUCT_MACHINE;

CONSTR_DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (construct_current_state = IDLE) then
			constr_data_ctr <= 0;
		elsif (construct_current_state = PUT_HEADERS and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			constr_data_ctr <=  constr_data_ctr + 1;
		end if;
	end if;
end process CONSTR_DATA_CTR_PROC;

OUT_SEQ_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		out_seq_ctr <= out_seq_ctr + x"1";
	end if;
end process OUT_SEQ_CTR_PROC;


out_ack_flag <= '1';
out_syn_flag <= '1';
out_fin_flag <= '0';

PREPARE_HEADERS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			outgoing_headers <= (others => '0');
		elsif (construct_current_state = PREPARE_HEADERS) then
			outgoing_headers(127 downto 96) <= out_seq_ctr;
			outgoing_headers(95 downto 64)  <= seq_ident + x"1";
			outgoing_headers(63 downto 60)  <= x"8";
			outgoing_headers(59 downto 0)   <= (others => '0');
			outgoing_headers(52)            <= out_ack_flag;
			outgoing_headers(49)            <= out_syn_flag;
			outgoing_headers(48)            <= out_fin_flag;
			outgoing_headers(47 downto 32)  <= x"16a0";
		end if;
	end if;
end process PREPARE_HEADERS_PROC;

outgoing_options(95 downto 0) <= x"0204_05b4_0103_0302_0101_0402";



TC_DATA_PROC : process(construct_current_state, constr_data_ctr)
begin
	if (construct_current_state = PUT_HEADERS) then
		tc_data(8) <= '0';
	
		if (constr_data_ctr < 16) then
			for i in 0 to 7 loop
				tc_data(i) <= outgoing_headers((15 - constr_data_ctr) * 8 + i);
			end loop;
		elsif (constr_data_ctr < 28) then
			for i in 0 to 7 loop
				tc_data(i) <= outgoing_options((27 - constr_data_ctr) * 8 + i);
			end loop;
		end if;
	else
		tc_data <= (others => '0');
	end if;
end process TC_DATA_PROC;

TC_DATA_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_DATA_OUT <= tc_data;
	end if;
end process TC_DATA_SYNC;


PS_BUSY_OUT <= '0' when (construct_current_state = IDLE) else '1';

PS_RESPONSE_READY_OUT <= '1' when (construct_current_state = WAIT_FOR_LOAD or construct_current_state = PUT_HEADERS or construct_current_state = CLEANUP) else '0';

TC_FRAME_SIZE_OUT   <= std_logic_vector(to_unsigned(28, 16));

TC_FRAME_TYPE_OUT   <= x"0008";
TC_SRC_MAC_OUT      <= PS_MY_MAC_IN;
TC_SRC_IP_OUT       <= PS_MY_IP_IN;
TC_SRC_UDP_OUT      <= x"0017";
TC_IP_PROTOCOL_OUT  <= X"06"; -- TCP
TC_IP_SIZE_OUT      <= std_logic_vector(to_unsigned(28, 16));
TC_UDP_SIZE_OUT     <= std_logic_vector(to_unsigned(28, 16));
TC_FLAGS_OFFSET_OUT <= (others => '0');

ADDR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = READ_FRAME) then
			TC_DEST_MAC_OUT <= PS_SRC_MAC_ADDRESS_IN;
			TC_DEST_IP_OUT  <= PS_SRC_IP_ADDRESS_IN;
			TC_DEST_UDP_OUT(7 downto 0) <= PS_SRC_UDP_PORT_IN(15 downto 8);
			TC_DEST_UDP_OUT(15 downto 8) <= PS_SRC_UDP_PORT_IN(7 downto 0);
		end if;
	end if;
end process ADDR_PROC;


end trb_net16_gbe_response_constructor_Telnet;


