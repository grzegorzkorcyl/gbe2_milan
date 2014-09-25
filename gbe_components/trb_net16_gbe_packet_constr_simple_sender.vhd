LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

library work;

entity trb_net16_gbe_packet_constr is
port(
	RESET                   : in    std_logic;
	CLK                     : in    std_logic;
	BUS_CLK                 : in    std_logic;
	-- ports for user logic
	PC_WR_EN_IN             : in    std_logic; -- write into queueConstr from userLogic
	PC_DATA_IN              : in    std_logic_vector(63 downto 0);
	PC_READY_OUT            : out   std_logic;
	PC_END_OF_DATA_IN       : in    std_logic;
	PC_TRANSMIT_ON_OUT	: out	std_logic;
	PC_TRANSMISSION_DONE_OUT : out std_logic;
	-- queue and subevent layer headers
	PC_DATA_SIZE_IN         : in std_logic_vector(31 downto 0);
	PC_MAX_FRAME_SIZE_IN    : in	std_logic_vector(15 downto 0); -- DO NOT SWAP
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
end trb_net16_gbe_packet_constr;

architecture trb_net16_gbe_packet_constr of trb_net16_gbe_packet_constr is


component fifo_dp is
port (
  rst : in std_logic;
  wr_clk : in std_logic;
  rd_clk : in std_logic;
  din : in std_logic_vector(63 downto 0);
  wr_en : in std_logic;
  rd_en : in std_logic;
  dout : out std_logic_vector(7 downto 0);
  full : out std_logic;
  empty : out std_logic
);
end component;

signal df_wr_en             : std_logic;
signal df_rd_en             : std_logic;
signal df_q                 : std_logic_vector(7 downto 0);
signal df_q_reg             : std_logic_vector(7 downto 0);
signal df_empty             : std_logic;
signal df_full              : std_logic;

signal fc_data              : std_logic_vector(7 downto 0);
signal fc_wr_en             : std_logic;
signal fc_sod               : std_logic;
signal fc_eod               : std_logic;
signal fc_ident             : std_logic_vector(15 downto 0); -- change this to own counter!
signal fc_flags_offset      : std_logic_vector(15 downto 0);

signal shf_data             : std_logic_vector(7 downto 0);
signal shf_wr_en            : std_logic;
signal shf_rd_en            : std_logic;
signal shf_q                : std_logic_vector(7 downto 0);
signal shf_empty            : std_logic;
signal shf_full             : std_logic;

type constructStates        is  (CIDLE, WAIT_FOR_LOAD);
signal constructCurrentState, constructNextState : constructStates;
signal constr_state         : std_logic_vector(3 downto 0);
signal all_int_ctr          : integer range 0 to 31;
signal all_ctr              : std_logic_vector(4 downto 0);

type loadStates         is  (LIDLE, WAIT_FOR_FC, PREP_DATA, LOAD_DATA, CLEANUP, DIVIDE);
signal loadCurrentState, loadNextState: loadStates;
signal load_state           : std_logic_vector(3 downto 0);

signal queue_size           : std_logic_vector(31 downto 0); -- sum of all subevents sizes plus their headers and queue headers and termination
signal actual_queue_size    : std_logic_vector(31 downto 0); -- queue size used during loading process when queue_size is no more valid
signal bytes_loaded         : std_logic_vector(15 downto 0); -- size of actual constructing frame
signal sub_size_loaded      : std_logic_vector(31 downto 0); -- size of subevent actually being transmitted
signal sub_bytes_loaded     : std_logic_vector(31 downto 0); -- amount of bytes of actual subevent sent 
signal actual_packet_size   : std_logic_vector(15 downto 0); -- actual size of whole udp packet
signal size_left            : std_logic_vector(31 downto 0);
signal fc_ip_size           : std_logic_vector(15 downto 0);
signal fc_udp_size          : std_logic_vector(15 downto 0);
signal max_frame_size       : std_logic_vector(15 downto 0);
signal divide_position      : std_logic_vector(1 downto 0); -- 00->data, 01->sub, 11->term
signal debug                : std_logic_vector(63 downto 0);
signal pc_ready             : std_logic;

signal pc_sub_size          : std_logic_vector(31 downto 0);
signal pc_trig_nr           : std_logic_vector(31 downto 0);
signal rst_after_sub_comb   : std_logic;  -- gk 08.04.10
signal rst_after_sub        : std_logic;  -- gk 08.04.10
signal load_int_ctr         : integer range 0 to 3;  -- gk 08.04.10
signal delay_ctr            : std_logic_vector(31 downto 0);  -- gk 28.04.10
signal ticks_ctr            : std_logic_vector(7 downto 0);  -- gk 28.04.10

-- gk 26.07.10
signal load_eod             : std_logic;
signal load_eod_q           : std_logic;

-- gk 07.10.10
signal df_eod               : std_logic;

-- gk 04.12.10
signal first_sub_in_multi   : std_logic;
signal from_divide_state    : std_logic;
signal disable_prep         : std_logic;

signal dump_bytes_ctr       : integer range 0 to 15;

begin



fifo : fifo_dp
port map(
  rst => RESET,
  wr_clk => BUS_CLK,
  rd_clk => CLK,
  din => PC_DATA_IN,
  wr_en => PC_WR_EN_IN,
  rd_en => df_rd_en,
  dout => df_q,
  full => open,
  empty => df_empty
);

DEBUG_OUT(0) <= df_rd_en;
DEBUG_OUT(8 downto 1) <= df_q;
DEBUG_OUT(63 downto 9) <= (others => '0');


--**************
-- RECEIVING SIDE
--**************




-- HADES SPECIFIC CODE

PC_TRANSMIT_ON_OUT <= '1' when constructCurrentState = WAIT_FOR_LOAD else '0';

max_frame_size <= PC_MAX_FRAME_SIZE_IN;
pc_ready <= '1' when (constructCurrentState = CIDLE) and (df_empty = '1') else '0';

 LOAD_EOD_PROC : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			load_eod_q <= '0';
			load_eod <= '0';
 		elsif (sub_bytes_loaded = PC_DATA_SIZE_IN - x"2") and (loadCurrentState /= LIDLE) then 
 			load_eod <= '1';
		else
			load_eod <= '0';
 		end if;
		
		load_eod_q <= load_eod;
 	end if;
 end process LOAD_EOD_PROC;
 
 df_wr_en <= '1' when ((PC_WR_EN_IN = '1') and (constructCurrentState /= WAIT_FOR_LOAD)) 
 				else '0';
 
 -- Output register for data FIFO
 dfQProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		df_q_reg <= df_q;
 	end if;
 end process dfQProc;
 
 queue_size <= PC_DATA_SIZE_IN;
 
 -- Construction state machine
 constructMachineProc : process(BUS_CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			constructCurrentState <= CIDLE;
 		else
 			constructCurrentState <= constructNextState;
 		end if;
 	end if;
 end process constructMachineProc;
 
 constructMachine : process(constructCurrentState, df_empty, PC_END_OF_DATA_IN)
 begin
 	case constructCurrentState is
 		when CIDLE =>
 			constr_state <= x"0";
 			if( PC_END_OF_DATA_IN = '1' ) then
 				constructNextState <= WAIT_FOR_LOAD;
 			else
 				constructNextState <= CIDLE;
 			end if;
 		when WAIT_FOR_LOAD =>
 			constr_state <= x"2";
 			if (df_empty = '1') then -- waits until the whole packet is transmitted
 				constructNextState <= CIDLE;
 			else
 				constructNextState <= WAIT_FOR_LOAD;
 			end if;
 		when others =>
 			constr_state <= x"f";
 			constructNextState <= CIDLE;
 	end case;
 end process constructMachine;
 
 PC_TRANSMISSION_DONE_OUT <= '1' when (constructCurrentState = WAIT_FOR_LOAD and df_empty = '1') else '0';

--***********************
--      LOAD DATA COMBINED WITH HEADERS INTO FC
--***********************

 loadMachineProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			loadCurrentState <= LIDLE;
 		else
 			loadCurrentState <= loadNextState;
 		end if;
 	end if;
 end process loadMachineProc;
 
 loadMachine : process(loadCurrentState, constructCurrentState, df_empty,
 					sub_bytes_loaded, sub_size_loaded, size_left, TC_H_READY_IN,
 					max_frame_size, bytes_loaded, divide_position,
 					delay_ctr, load_eod_q)
 begin
 	case loadCurrentState is
 		when LIDLE =>
 			load_state <= x"0";
 			if ((constructCurrentState = WAIT_FOR_LOAD) and (df_empty = '0')) then
 				loadNextState <= WAIT_FOR_FC;
 			else
 				loadNextState <= LIDLE;
 			end if;
 		when WAIT_FOR_FC =>
 			load_state <= x"1";
 			if (TC_H_READY_IN = '1') then
 				loadNextState <= PREP_DATA;
 			else
 				loadNextState <= WAIT_FOR_FC;
 			end if;
			
 		when PREP_DATA =>
 			load_state <= x"5";
			if (dump_bytes_ctr = 8) then  -- gk 09.05.12 preload first 8 words full of zeros
				loadNextState <= LOAD_DATA;
			else
				loadNextState <= PREP_DATA;
			end if;
			
 		when LOAD_DATA =>
 			load_state <= x"6";
 			if (bytes_loaded = max_frame_size - 1) then
 				loadNextState <= DIVIDE;
 			elsif (load_eod_q = '1') then
 				loadNextState <= CLEANUP;
 			else
 				loadNextState <= LOAD_DATA;
 			end if;
			
 		when DIVIDE =>
 			load_state <= x"7";
 			if (TC_H_READY_IN = '1') then
				loadNextState <= PREP_DATA;
 			else
 				loadNextState <= DIVIDE;
 			end if;
 		when CLEANUP =>
 			load_state <= x"9";
 			loadNextState <= LIDLE;
 		when others =>
 			load_state <= x"f";
 			loadNextState <= LIDLE;
 	end case;
 end process loadMachine;
 
 DUMP_BYTES_CTR_PROC : process(CLK)
 begin
	if rising_edge(CLK) then
		if (RESET = '1') or (loadCurrentState = CLEANUP) or (loadCurrentState = LIDLE) then
			dump_bytes_ctr <= 0;
		elsif (loadCurrentState = PREP_DATA) then
			dump_bytes_ctr <= dump_bytes_ctr + 1;
		end if;
	end if;
 end process DUMP_BYTES_CTR_PROC;


 fromDivideStateProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			from_divide_state <= '0';
 		elsif (loadCurrentState = DIVIDE) then
 			from_divide_state <= '1';
 		elsif (loadCurrentState = PREP_DATA) then
 			from_divide_state <= '0';
 		end if;
 	end if;
 end process fromDivideStateProc;

 dividePositionProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			divide_position <= "00";
 		elsif (bytes_loaded = max_frame_size - 1) then
 			if (loadCurrentState = LIDLE) then
 				divide_position <= "00";
 				disable_prep    <= '0';
 			elsif (loadCurrentState = LOAD_DATA) then
 				if (load_eod = '1') then
 					divide_position <= "11";
 					disable_prep    <= '0';
 				else
 					divide_position <= "00"; -- still data loaded divide on data
 					disable_prep    <= '1';
 				end if;
 			end if;
 		elsif (loadCurrentState = PREP_DATA) then  -- gk 06.12.10 reset disable_prep
 			disable_prep <= '0';
 		end if;
 
 	end if;
 end process dividePositionProc;
 
 dfRdEnProc : process(loadCurrentState, bytes_loaded, max_frame_size, sub_bytes_loaded, 
 					 sub_size_loaded, RESET, size_left, load_eod)
 begin
 	if (RESET = '1') then
 		df_rd_en <= '0';
 	elsif (loadCurrentState = LOAD_DATA) then
 		--if (bytes_loaded = max_frame_size - x"2") or (bytes_loaded = max_frame_size - x"1") then
 		--	df_rd_en <= '0';
 		--elsif (load_eod = '1') or (load_eod_q = '1') then
		if (load_eod = '1') or (load_eod_q = '1') then
 			df_rd_en <= '0';
 		else
 			df_rd_en <= '1';
 		end if;
 	elsif (loadCurrentState = PREP_DATA) then
 		df_rd_en <= '1';
 	else
 		df_rd_en <= '0';
 	end if;
 end process dfRdEnProc;

 fcWrEnProc : process(CLK, loadCurrentState, RESET)
 begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			fc_wr_en <= '0';
		elsif (loadCurrentState = LOAD_DATA and load_eod_q = '0' and (bytes_loaded /= max_frame_size - 1)) then
			fc_wr_en <= '1';
		else
			fc_wr_en <= '0';
		end if;
	end if;
 end process fcWrEnProc;

-- -- was all_int_ctr
 fcDataProc : process(loadCurrentState, df_q_reg)
 begin
 	case loadCurrentState is
 		when LIDLE          =>  fc_data <=  x"af";
 		when WAIT_FOR_FC    =>  fc_data <=  x"bf";
 		when PREP_DATA      =>  fc_data <=  df_q_reg;
 		when LOAD_DATA      =>  fc_data <=  df_q_reg;
 		when DIVIDE         =>  fc_data <=  x"cf";
 		when CLEANUP        =>  fc_data <=  x"df";
 		when others         =>  fc_data <=  x"00";
 	end case;
 end process fcDataProc;


--***********************
--      SIZE COUNTERS FOR LOADING SIDE
--***********************

 -- counts all bytes loaded to divide data into frames
 bytesLoadedProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = LIDLE) or (loadCurrentState = DIVIDE) or (loadCurrentState = CLEANUP) then
 			bytes_loaded <= x"ffff";
 		elsif (loadCurrentState = LOAD_DATA) then
 			bytes_loaded <= bytes_loaded + x"1";
 		end if;
 	end if;
 end process bytesLoadedProc;
 
 -- counts only raw data bytes being loaded
 subBytesLoadedProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = LIDLE) or (loadCurrentState = CLEANUP) then
 			sub_bytes_loaded <= x"00000000";
 		elsif (loadCurrentState = LOAD_DATA and load_eod = '0' and load_eod_q = '0' and (bytes_loaded /= max_frame_size - 1)) then
 			sub_bytes_loaded <= sub_bytes_loaded + x"1";
 		end if;
 	end if;
 end process subBytesLoadedProc;
 
 -- counts the size of the large udp packet
 actualPacketProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = LIDLE) or (loadCurrentState = CLEANUP) then
 			actual_packet_size <= x"0008";
 		elsif (fc_wr_en = '1') then
 			actual_packet_size <= actual_packet_size + x"1";
 		end if;
 	end if;
 end process actualPacketProc;
 
 actualQueueSizeProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = CLEANUP) then
 			actual_queue_size <= (others => '0');
 		elsif (loadCurrentState = LIDLE) then
 			actual_queue_size <= queue_size;
 		end if;
 	end if;
 end process actualQueueSizeProc;
 
 -- amount of bytes left to send in current packet
 sizeLeftProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = CLEANUP) then
 			size_left <= (others => '0');
 		elsif (loadCurrentState = LIDLE) then
 			size_left <= queue_size;
 		elsif (fc_wr_en = '1') then
 			size_left <= size_left - 1;
 		end if;
 	end if;
 end process sizeLeftProc;
 
 THE_FC_IDENT_COUNTER_PROC: process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			fc_ident <= (others => '0');
 		elsif (PC_END_OF_DATA_IN = '1') then
 			fc_ident <= fc_ident + 1;
 		end if;
 	end if;
 end process THE_FC_IDENT_COUNTER_PROC;

 fc_flags_offset(15 downto 14) <= "00";
 
 moreFragmentsProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = LIDLE) or (loadCurrentState = CLEANUP) then
 			fc_flags_offset(13) <= '0';
 		elsif ((loadCurrentState = DIVIDE) and (TC_READY_IN = '1')) or ((loadCurrentState = WAIT_FOR_FC) and (TC_READY_IN = '1')) then
 			if ((actual_queue_size - actual_packet_size) < max_frame_size) then
 				fc_flags_offset(13) <= '0';  -- no more fragments
 			else
 				fc_flags_offset(13) <= '1';  -- more fragments
 			end if;
 		end if;
 	end if;
 end process moreFragmentsProc;
 
 eodProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			fc_eod <= '0';
 		elsif (loadCurrentState = LOAD_DATA) and (bytes_loaded = max_frame_size - 2) then
 			fc_eod <= '1';
		elsif (loadCurrentState = LOAD_DATA) and (load_eod = '1') then
 			fc_eod <= '1';
 		else
 			fc_eod <= '0';
 		end if;
 	end if;
 end process eodProc;
 
 sodProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			fc_sod <= '0';
 		elsif (loadCurrentState = WAIT_FOR_FC) and (TC_READY_IN = '1') then
 			fc_sod <= '1';
 		elsif (loadCurrentState = DIVIDE) and (TC_READY_IN = '1') then
 			fc_sod <= '1';
 		else
 			fc_sod <= '0';
 		end if;
 	end if;
 end process sodProc;
 
 offsetProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET = '1') or (loadCurrentState = LIDLE) or (loadCurrentState = CLEANUP) then
 			fc_flags_offset(12 downto 0) <= (others => '0');
 		elsif ((loadCurrentState = DIVIDE) and (TC_READY_IN = '1')) then
 			fc_flags_offset(12 downto 0) <= actual_packet_size(15 downto 3);
 		end if;
 	end if;
 end process offsetProc;
 
 fcIPSizeProc : process(CLK)
 begin
 	if rising_edge(CLK) then
 		if (RESET= '1') then
 			fc_ip_size <= (others => '0');
 		elsif ((loadCurrentState = DIVIDE) and (TC_READY_IN = '1')) or ((loadCurrentState = WAIT_FOR_FC) and (TC_READY_IN = '1')) then
 			if (size_left >= max_frame_size) then
 				fc_ip_size <= max_frame_size;
 			else
 				fc_ip_size <= size_left(15 downto 0);
 			end if;
 		end if;
 	end if;
 end process fcIPSizeProc;
 
 fcUDPSizeProc : process(CLK)
 	begin
 	if rising_edge(CLK) then
 		if (RESET = '1') then
 			fc_udp_size <= (others => '0');
 		elsif (loadCurrentState = WAIT_FOR_FC) and (TC_READY_IN = '1') then
 			fc_udp_size <= queue_size(15 downto 0);
 		end if;
 	end if;
 end process fcUDPSizeProc;

-- outputs
 PC_READY_OUT                  <= pc_ready;
 TC_WR_EN_OUT                  <= fc_wr_en;
 TC_DATA_OUT                   <= fc_data;
 TC_IP_SIZE_OUT                <= fc_ip_size;
 TC_UDP_SIZE_OUT               <= fc_udp_size;
  --FC_IDENT_OUT(15 downto 8)     <= fc_ident(7 downto 0);
  --FC_IDENT_OUT(7 downto 0)      <= fc_ident(15 downto 8);
 TC_FLAGS_OFFSET_OUT           <= fc_flags_offset;
 TC_SOD_OUT                    <= fc_sod;
 TC_EOD_OUT                    <= fc_eod;

end trb_net16_gbe_packet_constr;