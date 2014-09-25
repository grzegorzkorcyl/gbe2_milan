LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;
--use work.trb_net_std.all;
--use work.trb_net_components.all;
--use work.trb_net16_hub_func.all;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

--********
-- 

entity trb_net16_gbe_response_constructor_DataRX is
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
end trb_net16_gbe_response_constructor_DataRX;


architecture trb_net16_gbe_response_constructor_DataRX of trb_net16_gbe_response_constructor_DataRX is

attribute syn_encoding	: string;
attribute keep : string;

type dissect_states is (IDLE, READ_FRAME, DECIDE, ADD_PADDING, PREP_CHECKSUM, WAIT_FOR_LOAD, LOAD_DATA, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

signal fifo_wr_en, fifo_rd_en : std_logic;
signal fifo_q : std_logic_vector(31 downto 0);
signal fifo_data : std_logic_vector(8 downto 0);
signal loaded_ctr, data_length : std_logic_vector(15 downto 0) := x"0000";
signal padding : std_logic_vector(3 downto 0);
signal frames_counter, packets_counter, valid_checksums, wrong_checksums_ctr : std_logic_vector(31 downto 0) := x"0000_0000";
signal fifo_full, fifo_empty : std_logic;
signal checksum : std_logic_vector(31 downto 0) := x"0000_0000";
signal byte_ptr : std_logic := '0';
signal prep_cs_ctr : std_logic_vector(3 downto 0);
signal saved_cs, local_ps_checksum, checksum_right : std_logic_vector(15 downto 0);
signal wrong_checksum : std_logic;


attribute keep of frames_counter, packets_counter, fifo_full, fifo_empty, valid_checksums, wrong_checksum, wrong_checksums_ctr : signal is "true";

begin

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

DISSECT_MACHINE : process(dissect_current_state, prep_cs_ctr, loaded_ctr, data_length, PS_MY_IP_IN, PS_WR_EN_IN, PS_ACTIVATE_IN, fifo_data, PS_SELECTED_IN, PS_FO_IP_IN)
begin
	case dissect_current_state is
	
		when IDLE =>
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			if (fifo_data(8) = '1') then
				dissect_next_state <= DECIDE;
			else
				dissect_next_state <= READ_FRAME;
			end if;			
			
		when DECIDE =>
			if (PS_FO_IP_IN(13) = '1') then
				dissect_next_state <= IDLE;
			else
				if (data_length(1 downto 0) = "00") then
					dissect_next_state <= PREP_CHECKSUM; --WAIT_FOR_LOAD;
				else
					dissect_next_state <= ADD_PADDING;
				end if;
			end if;
						
		when ADD_PADDING =>
			if (padding = "0001") then
				dissect_next_state <= PREP_CHECKSUM; --WAIT_FOR_LOAD;
			else
				dissect_next_state <= ADD_PADDING;
			end if;
			
		when PREP_CHECKSUM =>
			if (prep_cs_ctr = x"b") then
				dissect_next_state <= WAIT_FOR_LOAD;
			else
				dissect_next_state <= PREP_CHECKSUM;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (LL_UDP_OUT_DST_READY_N_IN = '0') then
				dissect_next_state <= LOAD_DATA;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
			
		when LOAD_DATA =>
			--if (loaded_ctr = data_length - x"4" or loaded_ctr > data_length) then
			if (loaded_ctr = data_length or loaded_ctr > data_length) then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD_DATA;
			end if;
		
		when CLEANUP =>
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

fifo : fifo_65536x8x32 --2048x8x32
  PORT map(
    rst     => RESET,
    wr_clk  => CLK,
	 rd_clk  => CLK,
    din     => fifo_data(7 downto 0),
    wr_en   => fifo_wr_en,
    rd_en   => fifo_rd_en,
    dout    => fifo_q,
    full    => fifo_full,
    empty   => fifo_empty
  );
  
FIFO_WR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (PS_ACTIVATE_IN = '1' and PS_WR_EN_IN = '1') then
			fifo_wr_en <= '1';
		elsif (dissect_current_state = ADD_PADDING) then
			fifo_wr_en <= '1';
		else
			fifo_wr_en <= '0';
		end if;
		
		if (dissect_current_state = ADD_PADDING) then
			fifo_data <= '0' & x"11";
		else
			fifo_data <= PS_DATA_IN;
		end if;
	end if;
end process FIFO_WR_PROC;

FIFO_RD_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (LL_UDP_OUT_DST_READY_N_IN = '0') then
			if ((dissect_current_state = LOAD_DATA) or (dissect_current_state = WAIT_FOR_LOAD)) then
				if (data_length /= loaded_ctr) then
					fifo_rd_en <= '1';
				else
					fifo_rd_en <= '0';
				end if;
			else
				fifo_rd_en <= '0';
			end if;
		else
			fifo_rd_en <= '0';
		end if;		
	end if;
end process FIFO_RD_PROC;

PS_RESPONSE_READY_OUT <= '0';

DATA_LENGTH_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = CLEANUP) then
			data_length <= (others => '0');
		elsif (fifo_wr_en = '1') then
			data_length <= data_length + x"1";
		else
			data_length <= data_length;
		end if;			
	end if;
end process DATA_LENGTH_PROC;

LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = WAIT_FOR_LOAD) then
			loaded_ctr <= x"0004";
		elsif (fifo_rd_en = '1') then
			loaded_ctr <= loaded_ctr + x"4";
		else
			loaded_ctr <= loaded_ctr;
		end if;
	end if;
end process LOADED_CTR_PROC;

PADDING_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = DECIDE) then
			padding <= "0100" - data_length(1 downto 0);
		elsif (dissect_current_state = ADD_PADDING) then
			padding <= padding - x"1";
		end if;
	end if;
end process PADDING_PROC;

SYNC_OUT : process(CLK)
begin
	if rising_edge(CLK) then
		LL_UDP_OUT_DATA_OUT <= fifo_q;
		
		if (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_DATA) then
			LL_UDP_OUT_SRC_READY_N_OUT <= '0';
		else
			LL_UDP_OUT_SRC_READY_N_OUT <= '1';
		end if;
		
		if (dissect_current_state = WAIT_FOR_LOAD and LL_UDP_OUT_DST_READY_N_IN = '0') then
			LL_UDP_OUT_SOF_N_OUT <= '0';
		else
			LL_UDP_OUT_SOF_N_OUT <= '1';
		end if;
		
		if (dissect_current_state = LOAD_DATA and (loaded_ctr = data_length or loaded_ctr > data_length)) then
			LL_UDP_OUT_EOF_N_OUT <= '0';
		else
			LL_UDP_OUT_EOF_N_OUT <= '1';
		end if;
		
		if (dissect_current_state = IDLE) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
		
	end if;
end process SYNC_OUT;

LL_UDP_OUT_WRITE_CLK_OUT <= CLK;
LL_UDP_OUT_REM_OUT       <= b"11";

--*********
-- CHECKSUM

CHECKSUM_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = CLEANUP) then
			checksum <= (others => '0');
			byte_ptr <= '0';
		elsif (dissect_current_state = IDLE) then
			checksum <= checksum;
			byte_ptr <= '0';
		elsif (dissect_current_state = READ_FRAME and fifo_wr_en = '1') then
			if (byte_ptr = '0') then	
				checksum <= checksum + (fifo_data(7 downto 0) & x"00");
			else
				checksum <= checksum + fifo_data(7 downto 0);
			end if;
			byte_ptr <= not byte_ptr;
		elsif (dissect_current_state = PREP_CHECKSUM) then
			case prep_cs_ctr is
				when x"0" =>
				 	checksum <= checksum + (PS_SRC_IP_ADDRESS_IN(7 downto 0) & PS_SRC_IP_ADDRESS_IN(15 downto 8));
				when x"1" =>
				 	checksum <= checksum + (PS_SRC_IP_ADDRESS_IN(23 downto 16) & PS_SRC_IP_ADDRESS_IN(31 downto 24));
			 	when x"2" =>
				 	checksum <= checksum + (PS_DEST_IP_ADDRESS_IN(7 downto 0) & PS_DEST_IP_ADDRESS_IN(15 downto 8));
			 	when x"3" =>
				 	checksum <= checksum + (PS_DEST_IP_ADDRESS_IN(23 downto 16) & PS_DEST_IP_ADDRESS_IN(31 downto 24));
				when x"4" =>
					checksum <= checksum + x"0011";
				when x"5" =>
					checksum <= checksum + PS_SRC_UDP_PORT_IN;
				when x"6" =>
					checksum <= checksum + PS_DEST_UDP_PORT_IN;
				when x"7" =>
					checksum <= checksum + data_length + x"8" + data_length + x"8"; 
				when x"8" =>
					checksum <= checksum + saved_cs;
				when x"9" =>
					checksum_right         <= checksum(31 downto 16);
					checksum(31 downto 16) <= x"0000";
				when x"a" =>
					checksum <= checksum + checksum_right;
				when x"b" =>
					checksum(15 downto 0)  <= checksum(15 downto 0) + checksum(31 downto 16);
					checksum(31 downto 16) <= checksum(31 downto 16);
				when others =>
					checksum <= checksum;
			end case;
			byte_ptr <= byte_ptr;
		else
			checksum <= checksum;
			byte_ptr <= byte_ptr;
		end if;
	end if;
end process CHECKSUM_PROC;

PREP_CS_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			prep_cs_ctr <= x"0";
		elsif (dissect_current_state = PREP_CHECKSUM) then
			prep_cs_ctr <= prep_cs_ctr + x"1";
		else
			prep_cs_ctr <= prep_cs_ctr;
		end if;
	end if;
end process PREP_CS_CTR_PROC;

SAVED_CS_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		local_ps_checksum <= PS_CHECKSUM_IN;
	
		if (dissect_current_state = IDLE and PS_FO_IP_IN(11 downto 0) = x"000") then
			saved_cs <= local_ps_checksum;
		elsif (dissect_current_state = CLEANUP) then
			saved_cs <= (others => '0');
		else
			saved_cs <= saved_cs;		
		end if;
	end if;
end process SAVED_CS_PROC;

-- debug
FRAMES_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = READ_FRAME and fifo_data(8) = '1') then
			frames_counter <= frames_counter + x"1";
		else
			frames_counter <= frames_counter;
		end if;
	end if;
end process FRAMES_CTR_PROC;

PACKETS_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = CLEANUP) then
			packets_counter <= packets_counter + x"1";
			if (checksum(15 downto 0) = x"ffff") then
				wrong_checksum <= '0';
			else
				wrong_checksum <= '1';
			end if;
		else
			wrong_checksum <= '0';
			packets_counter <= packets_counter;
		end if;
	end if;
end process PACKETS_CTR_PROC;

WRONG_CS_CTR : process(CLK)
begin
	if rising_edge(CLK) then
		if (wrong_checksum = '1') then
			wrong_checksums_ctr <= wrong_checksums_ctr + x"1";
		else
			wrong_checksums_ctr <= wrong_checksums_ctr;
		end if;
	end if;
end process WRONG_CS_CTR;

DEBUG_OUT(0) <= wrong_checksum;
DEBUG_OUT(31 downto 1) <= (others => '0');

end trb_net16_gbe_response_constructor_DataRX;


