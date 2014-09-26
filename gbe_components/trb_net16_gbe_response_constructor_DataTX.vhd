LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;


entity trb_net16_gbe_response_constructor_DataTX is
generic ( STAT_ADDRESS_BASE : integer := 0
);
	port (
		CLK			            : in	std_logic;  -- system clock
		RESET			            : in	std_logic;
		
	-- INTERFACE	
		PS_DATA_IN		         : in	std_logic_vector(8 downto 0);
		PS_WR_EN_IN		         : in	std_logic;
		PS_ACTIVATE_IN	      	: in	std_logic;
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
		TC_DEST_IP_OUT		      : out	std_logic_vector(31 downto 0);
		TC_DEST_UDP_OUT		   : out	std_logic_vector(15 downto 0);
		TC_SRC_MAC_OUT		      : out	std_logic_vector(47 downto 0);
		TC_SRC_IP_OUT		      : out	std_logic_vector(31 downto 0);
		TC_SRC_UDP_OUT		      : out	std_logic_vector(15 downto 0);
		TC_IDENT_OUT		      : out	std_logic_vector(15 downto 0);
 
		STAT_DATA_OUT           : out std_logic_vector(31 downto 0);
		STAT_ADDR_OUT           : out std_logic_vector(7 downto 0);
		STAT_DATA_RDY_OUT       : out std_logic;
		STAT_DATA_ACK_IN        : in std_logic;
		
		RECEIVED_FRAMES_OUT   	: out	std_logic_vector(15 downto 0);
		SENT_FRAMES_OUT	   	: out	std_logic_vector(15 downto 0);
	-- END OF INTERFACE
	
	-- protocol specific ports
		UDP_CHECKSUM_OUT        : out std_logic_vector(15 downto 0);
			
		SCTRL_DEST_MAC_IN       : in std_logic_vector(47 downto 0);
		SCTRL_DEST_IP_IN        : in std_logic_vector(31 downto 0);
		SCTRL_DEST_UDP_IN       : in std_logic_vector(15 downto 0);
	
		LL_DATA_IN              : in std_logic_vector(31 downto 0);
		LL_REM_IN               : in std_logic_vector(1 downto 0);
		LL_SOF_N_IN             : in std_logic;
		LL_EOF_N_IN             : in std_logic;
		LL_SRC_READY_N_IN       : in std_logic;
		LL_DST_READY_N_OUT      : out std_logic;
		LL_READ_CLK_OUT         : out std_logic;		
	-- end of protocol specific ports
	
	-- debug
		DEBUG_OUT		         : out	std_logic_vector(31 downto 0)
	);
end entity trb_net16_gbe_response_constructor_DataTX;

architecture RTL of trb_net16_gbe_response_constructor_DataTX is

attribute syn_encoding	: string;

type dissect_states is (IDLE, PREP_CHECKSUM, SAVE_DATA, PREP_CHECKSUM2, PREP_CHECKSUM3, PREP_CHECKSUM4, PREP_CHECKSUM5, PREP_CHECKSUM6, LOAD_FRAME, WAIT_FOR_TC, WAIT_FOR_LOAD, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

type stats_states is (IDLE, LOAD_RECEIVED, LOAD_REPLY, CLEANUP);
signal stats_current_state, stats_next_state : stats_states;
attribute syn_encoding of stats_current_state : signal is "safe,gray";

signal saved_target_ip          : std_logic_vector(31 downto 0);
signal data_ctr                 : integer range 0 to 30;
signal state                    : std_logic_vector(3 downto 0);


signal stat_data_temp           : std_logic_vector(31 downto 0);
signal rec_frames               : std_logic_vector(15 downto 0);

signal rx_fifo_q                : std_logic_vector(17 downto 0);
signal rx_fifo_wr, rx_fifo_rd   : std_logic;
signal tx_eod, rx_eod           : std_logic;

signal tx_fifo_q                : std_logic_vector(7 downto 0);
signal tx_fifo_wr, tx_fifo_rd   : std_logic;
signal tx_fifo_reset            : std_logic;
signal gsc_reply_read           : std_logic;
signal gsc_init_dataready       : std_logic;

signal tx_data_ctr              : std_logic_vector(15 downto 0);
signal tx_loaded_ctr            : std_logic_vector(15 downto 0);
signal tx_frame_loaded          : std_logic_vector(15 downto 0);

signal packet_num               : std_logic_vector(2 downto 0);
	
signal init_ctr, reply_ctr      : std_logic_vector(15 downto 0);
signal rx_empty, tx_empty       : std_logic;

signal rx_full, tx_full         : std_logic;

signal size_left                : std_logic_vector(15 downto 0);

signal reset_detected           : std_logic := '0';
signal make_reset               : std_logic := '0';


attribute syn_preserve : boolean;
attribute syn_keep : boolean;
attribute syn_keep of tx_data_ctr, tx_loaded_ctr, state : signal is true;
attribute syn_preserve of tx_data_ctr, tx_loaded_ctr, state : signal is true;

signal temp_ctr                : std_logic_vector(7 downto 0);

signal gsc_init_read_q         : std_logic;
signal fifo_rd_q               : std_logic;

signal too_much_data           : std_logic;

signal rx_fifo_data            : std_logic_vector(8 downto 0);

signal local_ll_data, local_ll_data_q : std_logic_vector(31 downto 0);
signal local_ll_sof, local_ll_eof, local_ll_src_ready, local_ll_dst_ready, local_ll_dst_ready_q : std_logic;
signal tc_data                 : std_logic_vector(8 downto 0);

signal udp_checksum            : std_logic_vector(31 downto 0);
signal prep_cs_ctr             : std_logic_vector(3 downto 0);
signal udp_checksum_right      : std_logic_vector(15 downto 0);

begin

LL_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		local_ll_data        <= LL_DATA_IN;
		local_ll_data_q      <= local_ll_data;
		local_ll_sof         <= not LL_SOF_N_IN;
		local_ll_eof         <= not LL_EOF_N_IN;
		local_ll_src_ready   <= not LL_SRC_READY_N_IN;
		LL_DST_READY_N_OUT   <= not local_ll_dst_ready;
		local_ll_dst_ready_q <= local_ll_dst_ready;
	end if;
end process LL_SYNC;

LL_READ_CLK_OUT <= CLK;

DST_READY_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = PREP_CHECKSUM and prep_cs_ctr = x"7") then
			local_ll_dst_ready <= '1';
		elsif (dissect_current_state = SAVE_DATA) then
			local_ll_dst_ready <= '1';
		else
			local_ll_dst_ready <= '0';
		end if;
	end if;
end process DST_READY_PROC;
--local_ll_dst_ready <= '1' when dissect_current_state = IDLE or dissect_current_state = SAVE_DATA else '0';

transmit_fifo : fifo_65536x32x8
PORT map(
	rst              => tx_fifo_reset,
	wr_clk           => CLK,
	rd_clk           => CLK,
	din              => local_ll_data_q,
	wr_en            => tx_fifo_wr,
	rd_en            => tx_fifo_rd,
	dout             => tx_fifo_q,
	full             => tx_full,
	empty            => tx_empty
);


FIFO_WR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (local_ll_src_ready = '1' and local_ll_dst_ready_q = '1') then
			if (dissect_current_state = SAVE_DATA) then
				tx_fifo_wr <= '1';
			elsif (dissect_current_state = PREP_CHECKSUM and prep_cs_ctr = x"7") then
				tx_fifo_wr <= '1';
			else
				tx_fifo_wr <= '0';
			end if;
		else
			tx_fifo_wr <= '0';
		end if;
	end if;
end process FIFO_WR_PROC;

TX_FIFO_RESET_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			tx_fifo_reset <= '1';
		elsif (too_much_data = '1' and dissect_current_state = CLEANUP) then
			tx_fifo_reset <= '1';
		else
			tx_fifo_reset <= '0';
		end if;
	end if;
end process TX_FIFO_RESET_PROC;
--tx_fifo_reset  <= '1' when (RESET = '1') or (too_much_data = '1' and dissect_current_state = CLEANUP) else '0';
tx_fifo_rd     <= '1' when (TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') else '0';

--TC_DATA_PROC : process(dissect_current_state, tx_loaded_ctr, tx_data_ctr, tx_frame_loaded, g_MAX_FRAME_SIZE)
--begin
--	if (dissect_current_state = LOAD_FRAME) then
--	
--		tc_data(7 downto 0) <= tx_fifo_q(7 downto 0);
--		
--		if (tx_loaded_ctr = tx_data_ctr or tx_frame_loaded = g_MAX_FRAME_SIZE - x"1") then
--			tc_data(8) <= '1';
--		else
--			tc_data(8) <= '0';
--		end if;
--	else
--		tc_data <= (others => '0');
--	end if;
--end process TC_DATA_PROC;

TC_DATA_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_DATA_OUT(7 downto 0) <= tx_fifo_q; --tc_data;
		if (tx_loaded_ctr = tx_data_ctr - x"1") then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
	end if;
end process TC_DATA_SYNC;
--TC_DATA_OUT <= tc_data;

-- counter of data received from TRBNet hub
TX_DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			tx_data_ctr <= x"0000";
		elsif (tx_fifo_wr = '1') then
			tx_data_ctr(15 downto 2) <= tx_data_ctr(15 downto 2) + x"1";
		end if;
	end if;
end process TX_DATA_CTR_PROC;

TOO_MUCH_DATA_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) then
			too_much_data <= '0';
		elsif (dissect_current_state = SAVE_DATA) and (tx_data_ctr = x"fa00") then
			too_much_data <= '1';
		end if;
	end if;
end process TOO_MUCH_DATA_PROC;

-- total counter of data transported to frame constructor
TX_LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			tx_loaded_ctr <= (others => '0');
		--elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1' and (tx_frame_loaded /= g_MAX_FRAME_SIZE)) then
		elsif (TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
			tx_loaded_ctr <= tx_loaded_ctr + x"1";
		end if;
	end if;
end process TX_LOADED_CTR_PROC;

						
PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (too_much_data = '0') then
			if (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME or dissect_current_state = CLEANUP) then
				PS_RESPONSE_READY_OUT <= '1';
			else
				PS_RESPONSE_READY_OUT <= '0';
			end if;
		end if;
		
		if (dissect_current_state = IDLE or dissect_current_state = SAVE_DATA) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
	end if;	
end process PS_RESPONSE_SYNC;

--FRAME_SIZE_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1' or dissect_current_state = IDLE) then
--			TC_FRAME_SIZE_OUT <= (others => '0');
--			TC_IP_SIZE_OUT    <= (others => '0');
--		elsif (dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = DIVIDE) then
--			if  (size_left >= g_MAX_FRAME_SIZE) then
--				TC_FRAME_SIZE_OUT <= g_MAX_FRAME_SIZE;
--				TC_IP_SIZE_OUT    <= g_MAX_FRAME_SIZE;
--			else
--				TC_FRAME_SIZE_OUT <= size_left(15 downto 0);
--				TC_IP_SIZE_OUT    <= size_left(15 downto 0);
--			end if;
--		end if;
--	end if;
--end process FRAME_SIZE_PROC;

--TC_UDP_SIZE_OUT     <= tx_data_ctr;


--TC_FLAGS_OFFSET_OUT(15 downto 14) <= "00";
--MORE_FRAGMENTS_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = CLEANUP) then
--			TC_FLAGS_OFFSET_OUT(13) <= '0';
--		elsif ((dissect_current_state = DIVIDE and TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') or (dissect_current_state = WAIT_FOR_LOAD)) then
--			if ((tx_data_ctr - tx_loaded_ctr) < g_MAX_FRAME_SIZE) then
--				TC_FLAGS_OFFSET_OUT(13) <= '0';  -- no more fragments
--			else
--				TC_FLAGS_OFFSET_OUT(13) <= '1';  -- more fragments
--			end if;
--		elsif (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr) then
--			TC_FLAGS_OFFSET_OUT(13) <= '0';
--		end if;
--	end if;
--end process MORE_FRAGMENTS_PROC;

--OFFSET_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = CLEANUP) then
--			TC_FLAGS_OFFSET_OUT(12 downto 0) <= (others => '0');
--		elsif (dissect_current_state = DIVIDE and TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
--			TC_FLAGS_OFFSET_OUT(12 downto 0) <= tx_loaded_ctr(15 downto 3) + x"1";
--		end if;
--	end if;
--end process OFFSET_PROC;

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

DISSECT_MACHINE : process(dissect_current_state, prep_cs_ctr, local_ll_src_ready, local_ll_sof, local_ll_eof, too_much_data, PS_SELECTED_IN, tx_loaded_ctr, tx_data_ctr)
begin
	case dissect_current_state is
	
		when IDLE =>
			state <= x"1";
			dissect_next_state <= PREP_CHECKSUM;
--			if (local_ll_sof = '1' and local_ll_src_ready = '1') then
--				dissect_next_state <= SAVE_DATA;
--			else
--				dissect_next_state <= IDLE;
--			end if;
			
		when PREP_CHECKSUM =>
			state <= x"2";
			if (prep_cs_ctr = x"7") then
				if (local_ll_sof = '1' and local_ll_src_ready = '1') then
					dissect_next_state <= SAVE_DATA;
				else
					dissect_next_state <= PREP_CHECKSUM;
				end if;
			else
				dissect_next_state <= PREP_CHECKSUM;
			end if;
			
		when SAVE_DATA =>
			state <= x"6";
			if (local_ll_eof = '1') then
				if (too_much_data = '0') then
					dissect_next_state <= PREP_CHECKSUM2; --WAIT_FOR_LOAD;
				else
					dissect_next_state <= CLEANUP;
				end if;
			else
				dissect_next_state <= SAVE_DATA;
			end if;
			
		when PREP_CHECKSUM2 =>
			dissect_next_state <= PREP_CHECKSUM3;
			
		when PREP_CHECKSUM3 =>
			dissect_next_state <= PREP_CHECKSUM4;
			
		when PREP_CHECKSUM4 =>
			dissect_next_state <= PREP_CHECKSUM5;
			
		when PREP_CHECKSUM5 =>
			dissect_next_state <= PREP_CHECKSUM6;
			
		when PREP_CHECKSUM6 =>
			dissect_next_state <= WAIT_FOR_LOAD;
			
		when WAIT_FOR_LOAD =>
			state <= x"7";
			if (PS_SELECTED_IN = '1') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD_FRAME =>
			state <= x"8";
			if (tx_loaded_ctr = tx_data_ctr) then
				dissect_next_state <= CLEANUP;
--			elsif (tx_frame_loaded = g_MAX_FRAME_SIZE) then
--				dissect_next_state <= DIVIDE;
			else
				dissect_next_state <= LOAD_FRAME;
			end if;

--		when DIVIDE =>
--			state <= x"c";
--			if (TC_BUSY_IN = '0' and PS_SELECTED_IN = '1') then
--				dissect_next_state <= LOAD_FRAME;
--			else
--				dissect_next_state <= DIVIDE;
--			end if;
		
		when CLEANUP =>
			state <= x"9";
			dissect_next_state <= IDLE;
			
		when others =>
			state <= x"1"; 
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;


--*********
-- CHECKSUM CALCULATION

PREP_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			prep_cs_ctr <= x"0";
		elsif (dissect_current_state = PREP_CHECKSUM and prep_cs_ctr /= x"7") then
			prep_cs_ctr <= prep_cs_ctr + x"1";
		else
			prep_cs_ctr <= prep_cs_ctr;
		end if;			
	end if;
end process PREP_CTR_PROC;

UDP_CHECKSUM_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (dissect_current_state = IDLE) then
			udp_checksum       <= (others => '0');
			udp_checksum_right <= (others => '0');
		elsif (dissect_current_state = PREP_CHECKSUM) then
		
			case prep_cs_ctr is
				when x"0" =>
				 	udp_checksum(15 downto 0)  <= (PS_MY_IP_IN(7 downto 0) & PS_MY_IP_IN(15 downto 8));
				 	udp_checksum(31 downto 16) <= x"0000";
				when x"1" =>
				 	udp_checksum <= udp_checksum + (PS_MY_IP_IN(23 downto 16) & PS_MY_IP_IN(31 downto 24));
			 	when x"2" =>
				 	udp_checksum <= udp_checksum + (SCTRL_DEST_IP_IN(7 downto 0) & SCTRL_DEST_IP_IN(15 downto 8));
			 	when x"3" =>
				 	udp_checksum <= udp_checksum + (SCTRL_DEST_IP_IN(23 downto 16) & SCTRL_DEST_IP_IN(31 downto 24));
				when x"4" =>
					udp_checksum <= udp_checksum + x"0011";
				when x"5" =>
					udp_checksum <= udp_checksum + x"61a8";
				when x"6" =>
					udp_checksum <= udp_checksum + (SCTRL_DEST_UDP_IN(7 downto 0) & SCTRL_DEST_UDP_IN(15 downto 8));
				when others =>
					udp_checksum <= udp_checksum;
			end case;
			
		elsif (tx_fifo_wr = '1') then
			udp_checksum <= udp_checksum + local_ll_data_q(15 downto 0) + local_ll_data_q(31 downto 16);
		elsif (dissect_current_state = PREP_CHECKSUM3) then
			udp_checksum <= udp_checksum + tx_data_ctr + x"8" + tx_data_ctr + x"8";
		elsif (dissect_current_state = PREP_CHECKSUM4) then
			udp_checksum_right         <= udp_checksum(31 downto 16);
			udp_checksum(31 downto 16) <= (others => '0');
			--udp_checksum(15 downto 0) <= udp_checksum(15 downto 0) + udp_checksum(31 downto 16);
		elsif (dissect_current_state = PREP_CHECKSUM5) then
			udp_checksum <= udp_checksum + udp_checksum_right;
		elsif (dissect_current_state = PREP_CHECKSUM6) then
			udp_checksum(15 downto 0) <= udp_checksum(15 downto 0) + udp_checksum(31 downto 16);
		else
			udp_checksum <= udp_checksum;
		end if;
	end if;
end process UDP_CHECKSUM_PROC;




TC_FRAME_TYPE_OUT  <= x"0008";  -- ip
TC_DEST_MAC_OUT    <= x"986c2ff31800";
TC_DEST_IP_OUT     <= x"64d9fea9";
TC_DEST_UDP_OUT    <= x"a861";
TC_SRC_MAC_OUT     <= PS_MY_MAC_IN;
TC_SRC_IP_OUT      <= PS_MY_IP_IN;
TC_SRC_UDP_OUT     <= x"a861";
TC_IP_PROTOCOL_OUT <= x"11";  -- udp

TC_FRAME_SIZE_OUT  <= tx_data_ctr;
TC_IDENT_OUT       <= x"4" & reply_ctr(11 downto 0);

UDP_CHECKSUM_OUT   <= not udp_checksum(15 downto 0);

-- counter of bytes of currently constructed frame
--FRAME_LOADED_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1' or dissect_current_state = DIVIDE or dissect_current_state = IDLE) then
--			tx_frame_loaded <= (others => '0');
--		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1') then
--			tx_frame_loaded <= tx_frame_loaded + x"1";
--		end if;
--	end if;
--end process FRAME_LOADED_PROC;

-- counter down to 0 of bytes that have to be transmitted for a given packet
--SIZE_LEFT_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1' or dissect_current_state = SAVE_DATA) then
--			size_left <= (others => '0');
--		elsif (dissect_current_state = WAIT_FOR_LOAD) then
--			size_left <= tx_data_ctr;
--		elsif (dissect_current_state = LOAD_FRAME and TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1' and (tx_frame_loaded /= g_MAX_FRAME_SIZE)) then
--			size_left <= size_left - x"1";
--		end if;
--	end if;
--end process SIZE_LEFT_PROC;











-- statistics
--REC_FRAMES_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			rec_frames <= (others => '0');
--		elsif (dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
--			rec_frames <= rec_frames + x"1";
--		end if;
--	end if;
--end process REC_FRAMES_PROC;
--
REPLY_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			reply_ctr <= (others => '0');
		elsif (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr) then
			reply_ctr <= reply_ctr + x"1";
		end if;
	end if;
end process REPLY_CTR_PROC;
--
--
--STATS_MACHINE_PROC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (RESET = '1') then
--			stats_current_state <= IDLE;
--		else
--			stats_current_state <= stats_next_state;
--		end if;
--	end if;
--end process STATS_MACHINE_PROC;
--
--STATS_MACHINE : process(stats_current_state, PS_WR_EN_IN, PS_ACTIVATE_IN, dissect_current_state, tx_loaded_ctr, tx_data_ctr)
--begin
--
--	case (stats_current_state) is
--	
--		when IDLE =>
--			if ((dissect_current_state = IDLE and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') or (dissect_current_state = LOAD_FRAME and tx_loaded_ctr = tx_data_ctr)) then
--				stats_next_state <= LOAD_RECEIVED;
--			else
--				stats_next_state <= IDLE;
--			end if;
--		
--		when LOAD_RECEIVED =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= LOAD_REPLY;
--			else
--				stats_next_state <= LOAD_RECEIVED;
--			end if;
--			
--		when LOAD_REPLY =>
--			if (STAT_DATA_ACK_IN = '1') then
--				stats_next_state <= CLEANUP;
--			else
--				stats_next_state <= LOAD_REPLY;
--			end if;		
--		
--		when CLEANUP =>
--			stats_next_state <= IDLE;
--	
--	end case;
--
--end process STATS_MACHINE;
--
--SELECTOR : process(CLK)
--begin
--	if rising_edge(CLK) then
--		case(stats_current_state) is
--			
--			when LOAD_RECEIVED =>
--				stat_data_temp <= x"0502" & rec_frames;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE, 8));
--			
--			when LOAD_REPLY =>
--				stat_data_temp <= x"0503" & reply_ctr;
--				STAT_ADDR_OUT  <= std_logic_vector(to_unsigned(STAT_ADDRESS_BASE + 1, 8));
--				
--			when others =>
--				stat_data_temp <= (others => '0');
--				STAT_ADDR_OUT  <= (others => '0');
--		
--		end case;
--	end if;	
--end process SELECTOR;
--
--STAT_DATA_OUT(7 downto 0)   <= stat_data_temp(31 downto 24);
--STAT_DATA_OUT(15 downto 8)  <= stat_data_temp(23 downto 16);
--STAT_DATA_OUT(23 downto 16) <= stat_data_temp(15 downto 8);
--STAT_DATA_OUT(31 downto 24) <= stat_data_temp(7 downto 0);
--
--STAT_SYNC : process(CLK)
--begin
--	if rising_edge(CLK) then
--		if (stats_current_state /= IDLE and stats_current_state /= CLEANUP) then
--			STAT_DATA_RDY_OUT <= '1';
--		else
--			STAT_DATA_RDY_OUT <= '0';
--		end if;
--	end if;
--end process STAT_SYNC;

-- end of statistics

end architecture RTL;
