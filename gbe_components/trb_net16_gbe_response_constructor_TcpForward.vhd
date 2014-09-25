LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity trb_net16_gbe_response_constructor_TcpForward is
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
	TC_IDENT_OUT		      : out	std_logic_vector(15 downto 0);
	
	STAT_DATA_OUT           : out std_logic_vector(31 downto 0);
	STAT_ADDR_OUT           : out std_logic_vector(7 downto 0);
	STAT_DATA_RDY_OUT       : out std_logic;
	STAT_DATA_ACK_IN        : in std_logic;
		
	RECEIVED_FRAMES_OUT	   : out	std_logic_vector(15 downto 0);
	SENT_FRAMES_OUT		   : out	std_logic_vector(15 downto 0);
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
	DEBUG_OUT		         : out	std_logic_vector(31 downto 0)
);
end trb_net16_gbe_response_constructor_TcpForward;


architecture trb_net16_gbe_response_constructor_TcpForward of trb_net16_gbe_response_constructor_TcpForward is

attribute syn_encoding	: string;

type dissect_states is (IDLE, READ_FRAME, PAD_ZEROS, WAIT_FOR_LOAD, LOAD_FRAME, CLEANUP);
signal dissect_current_state, dissect_next_state : dissect_states;
attribute syn_encoding of dissect_current_state: signal is "safe,gray";

--type construct_states is (IDLE, READ_FRAME, WAIT_FOR_LOAD, LOAD_FRAME, CLEANUP);
signal construct_current_state, construct_next_state : dissect_states;
attribute syn_encoding of construct_current_state: signal is "safe,gray";

signal fifo_wr_en, fifo_rd_en         : std_logic;
signal fifo_q                         : std_logic_vector(31 downto 0);
signal tx_fifo_wr_en, tx_fifo_rd_en   : std_logic;
signal tx_fifo_q                      : std_logic_vector(7 downto 0);

signal data_ctr                 : integer range 1 to 1500;
signal loaded_ctr               : integer range 0 to 1500;
signal data_length              : integer range 1 to 1500;
signal tx_data_ctr              : integer range 1 to 1500;
signal tx_data_length           : integer range 1 to 1500;

signal temp_data_ctr            : std_logic_vector(15 downto 0);

attribute keep : string;
attribute keep of temp_data_ctr : signal is "TRUE";

begin

-- FROM TCP TO KERNEL

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

DISSECT_MACHINE : process(dissect_current_state, temp_data_ctr, PS_WR_EN_IN, LL_TCP_OUT_DST_READY_N_IN, PS_ACTIVATE_IN, PS_DATA_IN, data_ctr, data_length, loaded_ctr)
begin
	case dissect_current_state is
	
		when IDLE =>
			if (PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
				dissect_next_state <= READ_FRAME;
			else
				dissect_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			if (PS_DATA_IN(8) = '1') then
				if (temp_data_ctr(1 downto 0) = b"00") then
					dissect_next_state <= WAIT_FOR_LOAD;
				else
					dissect_next_state <= PAD_ZEROS;
				end if;
			else
				dissect_next_state <= READ_FRAME;
			end if;
			
		when PAD_ZEROS =>
			if (temp_data_ctr(1 downto 0) = b"00") then
				dissect_next_state <= WAIT_FOR_LOAD;
			else
				dissect_next_state <= PAD_ZEROS;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (LL_TCP_OUT_DST_READY_N_IN = '0') then
				dissect_next_state <= LOAD_FRAME;
			else
				dissect_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD_FRAME =>
			--if (data_ctr = data_length + 2) then
			if (loaded_ctr = data_length or loaded_ctr > data_length) then
				dissect_next_state <= CLEANUP;
			else
				dissect_next_state <= LOAD_FRAME;
			end if;
		
		when CLEANUP =>
			dissect_next_state <= IDLE;
	
	end case;
end process DISSECT_MACHINE;

temp_data_ctr <= std_logic_vector(to_unsigned(data_ctr, 16));

LL_TCP_OUT_SRC_READY_N_OUT <= '0' when dissect_current_state = WAIT_FOR_LOAD or dissect_current_state = LOAD_FRAME else '1';
LL_TCP_OUT_SOF_N_OUT       <= '0' when dissect_current_state = WAIT_FOR_LOAD and LL_TCP_OUT_DST_READY_N_IN = '0'   else '1';
LL_TCP_OUT_EOF_N_OUT       <= '0' when (dissect_current_state = LOAD_FRAME and (loaded_ctr = data_length or loaded_ctr > data_length)) else '1';
LL_TCP_OUT_REM_OUT         <= b"11";
LL_TCP_OUT_DATA_OUT        <= fifo_q;
LL_TCP_OUT_WRITE_CLK_OUT   <= CLK;

DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (dissect_current_state = IDLE) or (dissect_current_state = WAIT_FOR_LOAD) then
			data_ctr <= 2;
		elsif (dissect_current_state = READ_FRAME and PS_WR_EN_IN = '1' and PS_ACTIVATE_IN = '1') then
			data_ctr <= data_ctr + 1;
		elsif (dissect_current_state = PAD_ZEROS) then
			data_ctr <= data_ctr + 1;
		end if;
	end if;
end process DATA_CTR_PROC;

DATA_LENGTH_PROC: process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') then
			data_length <= 1;
		elsif (dissect_current_state = READ_FRAME) then
			data_length <= data_ctr;
		elsif (dissect_current_state = PAD_ZEROS) then
			data_length <= data_ctr;
		end if;
	end if;
end process DATA_LENGTH_PROC;

LOADED_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or dissect_current_state = IDLE) then
			loaded_ctr <= 0;
		elsif (fifo_rd_en = '1') then
			loaded_ctr <= loaded_ctr + 4;
		end if;
	end if;
end process LOADED_CTR_PROC;

fifo : fifo_2048x8x32
  PORT map(
    rst     => RESET,
    wr_clk  => CLK,
	 rd_clk  => CLK,
    din     => PS_DATA_IN(7 downto 0),
    wr_en   => fifo_wr_en,
    rd_en   => fifo_rd_en,
    dout    => fifo_q,
    full    => open,
    empty   => open
  );
fifo_wr_en <= '1' when (PS_ACTIVATE_IN = '1' and PS_WR_EN_IN = '1') or (dissect_current_state = PAD_ZEROS) else '0';
fifo_rd_en <= '1' when ((LL_TCP_OUT_DST_READY_N_IN = '0') and ((dissect_current_state = LOAD_FRAME) or (dissect_current_state = WAIT_FOR_LOAD))) or
								(dissect_current_state = READ_FRAME and PS_DATA_IN(8) = '1')  -- preload first word
							else '0';


-- FROM KERNEL TO TCP


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

CONSTRUCT_MACHINE : process(construct_current_state, LL_TCP_IN_SRC_READY_N_IN, LL_TCP_IN_SOF_N_IN, LL_TCP_IN_EOF_N_IN, PS_WR_EN_IN, LL_TCP_OUT_DST_READY_N_IN, PS_ACTIVATE_IN, PS_DATA_IN, PS_SELECTED_IN, tx_data_ctr, tx_data_length)
begin
	case construct_current_state is
	
		when IDLE =>
			if (LL_TCP_IN_SOF_N_IN = '0') and (LL_TCP_IN_SRC_READY_N_IN = '0') then  -- gk changed 15/10/2012
				construct_next_state <= READ_FRAME;
			else
				construct_next_state <= IDLE;
			end if;
		
		when READ_FRAME =>
			if (LL_TCP_IN_EOF_N_IN = '0') then
				construct_next_state <= WAIT_FOR_LOAD;
			else
				construct_next_state <= READ_FRAME;
			end if;
			
		when WAIT_FOR_LOAD =>
			if (PS_SELECTED_IN = '1') then
				construct_next_state <= LOAD_FRAME;
			else
				construct_next_state <= WAIT_FOR_LOAD;
			end if;
		
		when LOAD_FRAME =>
			if (tx_data_ctr = tx_data_length) then
				construct_next_state <= CLEANUP;
			else
				construct_next_state <= LOAD_FRAME;
			end if;
		
		when CLEANUP =>
			construct_next_state <= IDLE;
			
		when others => null;
	
	end case;
end process CONSTRUCT_MACHINE;

LL_TCP_IN_DST_READY_N_OUT <= '0' when construct_current_state = IDLE or construct_current_state = READ_FRAME else '1';

LL_TCP_IN_READ_CLK_OUT <= CLK;

TX_DATA_LENGTH_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1' or construct_current_state = IDLE) then
			tx_data_length <= 4;
		elsif (tx_fifo_wr_en = '1') then
			tx_data_length <= tx_data_length + 4;
		end if;
	end if;	
end process TX_DATA_LENGTH_PROC;	

TX_DATA_CTR_PROC : process(CLK)
begin
	if rising_edge(CLK) then
		if (RESET = '1') or (construct_current_state = IDLE) then
			tx_data_ctr <= 1;
		elsif (PS_SELECTED_IN = '1' and TC_RD_EN_IN = '1' and construct_current_state = LOAD_FRAME) then
			tx_data_ctr <= tx_data_ctr + 1;
		end if;
	end if;
end process TX_DATA_CTR_PROC;

tx_fifo : fifo_2048x32x8
port map(
	rst     => RESET,
	wr_clk  => CLK,
	rd_clk  => CLK,
	din     => LL_TCP_IN_DATA_IN,
	wr_en   => tx_fifo_wr_en,
	rd_en   => tx_fifo_rd_en,
	dout    => tx_fifo_q,
	full    => open,
	empty   => open
);

tx_fifo_wr_en <= '1' when (construct_current_state = READ_FRAME and LL_TCP_IN_SRC_READY_N_IN = '0') or
									(construct_current_state = IDLE and LL_TCP_IN_SOF_N_IN = '0' and LL_TCP_IN_SRC_READY_N_IN = '0')  -- gk changed 15/10/2012
							else '0';
							
tx_fifo_rd_en <= '1' when (TC_RD_EN_IN = '1' and PS_SELECTED_IN = '1')
							else '0';

PS_RESPONSE_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		if (construct_current_state = WAIT_FOR_LOAD or construct_current_state = LOAD_FRAME or construct_current_state = CLEANUP) then
			PS_RESPONSE_READY_OUT <= '1';
		else
			PS_RESPONSE_READY_OUT <= '0';
		end if;
		
		if (dissect_current_state = IDLE) then
			PS_BUSY_OUT <= '0';
		else
			PS_BUSY_OUT <= '1';
		end if;
	end if;	
end process PS_RESPONSE_SYNC;

TC_DATA_SYNC : process(CLK)
begin
	if rising_edge(CLK) then
		TC_DATA_OUT(7 downto 0) <= tx_fifo_q; --tc_data;
		if (tx_data_ctr = tx_data_length - 1) then
			TC_DATA_OUT(8) <= '1';
		else
			TC_DATA_OUT(8) <= '0';
		end if;
	end if;
end process TC_DATA_SYNC;

TC_FRAME_SIZE_OUT <= std_logic_vector(to_unsigned(tx_data_length, 16));
TC_FRAME_TYPE_OUT <= x"ffff";  -- special type to bypass all the construction process

end trb_net16_gbe_response_constructor_TcpForward;


