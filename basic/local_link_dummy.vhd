library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

entity local_link_dummy is
generic (
	DO_SIMULATION        : integer range 0 to 1 := 1
);
port (
	RESET_N               : in std_logic;
	LL_DATA_OUT           : out std_logic_vector(31 downto 0);
	LL_REM_OUT            : out std_logic_vector(1 downto 0);
	LL_SOF_N_OUT          : out std_logic;
	LL_EOF_N_OUT          : out std_logic;
	LL_SRC_READY_N_OUT    : out std_logic;
	LL_DST_READY_N_IN     : in std_logic;
	LL_LEN_OUT            : out std_logic_vector(15 downto 0);
	LL_LEN_READY_OUT      : out std_logic;
	LL_LEN_ERR_OUT        : out std_logic;
	LL_READ_CLK_IN        : in std_logic
);
end local_link_dummy;

architecture Behavioral of local_link_dummy is

attribute keep : string;

type link_states is (IDLE, TIMEOUT, GENERATE_DATA, WAIT_FOR_DST, CLEANUP);
signal link_current_state, link_next_state : link_states;

signal reset : std_logic;
signal data_ctr : std_logic_vector(31 downto 0);
signal timeout_ctr, timeout_stop_val : std_logic_vector(31 downto 0);
signal data_stop_val : std_logic_vector(31 downto 0) := x"0000_02b0";
signal packets_counter : std_logic_vector(31 downto 0) := x"0000_0000";
attribute keep of packets_counter, data_stop_val : signal is "true";

begin


imp_gen : if (DO_SIMULATION = 0) generate
	DATA_STOP_VAL_PROC : process(LL_READ_CLK_IN)
	begin
		if rising_edge(LL_READ_CLK_IN) then
			if (reset = '1') or (data_stop_val = x"0000_3a00") then
				data_stop_val <= x"0000_0001";
			elsif (link_current_state = CLEANUP) then
				data_stop_val <= data_stop_val + x"1";
			else
				data_stop_val <= data_stop_val;
			end if;
		end if;
	end process DATA_STOP_VAL_PROC;
	timeout_stop_val <= x"0010_0000";
end generate imp_gen;

sim_gen : if (DO_SIMULATION = 1) generate
process(LL_READ_CLK_IN)
begin
	if rising_edge(LL_READ_CLK_IN) then
		if (link_current_state = CLEANUP) then
			data_stop_val    <= data_stop_val + x"1";
		else
			data_stop_val <= data_stop_val;
		end if;
	end if;
end process;
	timeout_stop_val <= x"0000_1000";
end generate sim_gen;

reset <= not RESET_N;

LINK_MACHINE_PROC : process(LL_READ_CLK_IN)
begin
	if rising_edge(LL_READ_CLK_IN) then
		if (reset = '1') then
			link_current_state <= IDLE;
		else
			link_current_state <= link_next_state;
		end if;
	end if;
end process LINK_MACHINE_PROC;

LINK_MACHINE : process(link_current_state, LL_DST_READY_N_IN, timeout_ctr, data_ctr, timeout_stop_val, data_stop_val)
begin
	
	case (link_current_state) is
	
		when IDLE =>
			link_next_state <= WAIT_FOR_DST;
		
		when WAIT_FOR_DST =>
			if (LL_DST_READY_N_IN = '0') then
				link_next_state <= GENERATE_DATA;
			else
				link_next_state <= WAIT_FOR_DST;
			end if;
		
		when GENERATE_DATA =>
			if (data_ctr = data_stop_val) then
				link_next_state <= TIMEOUT;
			else
				link_next_state <= GENERATE_DATA;
			end if;
		
		when TIMEOUT =>
			if (timeout_ctr = timeout_stop_val) then
				link_next_state <= CLEANUP;
			else
				link_next_state <= TIMEOUT;
			end if;	
		
		when CLEANUP =>
			link_next_state <= IDLE;
	
	end case;

end process LINK_MACHINE;

TIMEOUT_CTR_PROC : process(LL_READ_CLK_IN)
begin
	if rising_edge(LL_READ_CLK_IN) then
		if (reset = '1' or link_current_state = IDLE) then
			timeout_ctr <= (others => '0');
		elsif (link_current_state = TIMEOUT) then
			timeout_ctr <= timeout_ctr + x"1";
		end if;
	end if;
end process TIMEOUT_CTR_PROC;

DATA_CTR_PROC : process(LL_READ_CLK_IN)
begin
	if rising_edge(LL_READ_CLK_IN) then
		if (reset = '1' or link_current_state = IDLE) then
			data_ctr <= (others => '0');
		elsif (link_current_state = GENERATE_DATA) then
			data_ctr <= data_ctr + x"1";
		end if;
	end if;
end process DATA_CTR_PROC;

LL_SOF_N_OUT       <= '0' when (link_current_state = WAIT_FOR_DST and LL_DST_READY_N_IN = '0') else '1'; --(link_current_state = TIMEOUT and timeout_ctr = timeout_stop_val) else '1';
LL_EOF_N_OUT       <= '0' when (link_current_state = GENERATE_DATA and data_ctr = data_stop_val) else '1';
LL_SRC_READY_N_OUT <= '0' when (link_current_state = GENERATE_DATA) or (link_current_state = WAIT_FOR_DST and LL_DST_READY_N_IN = '0') else '1'; -- or (link_current_state = TIMEOUT and timeout_ctr = timeout_stop_val) else '1';
LL_DATA_OUT        <= data_ctr;

PACKETS_COUNTER_PROC : process(LL_READ_CLK_IN)
begin
	if rising_edge(LL_READ_CLK_IN) then
		if (link_current_state = CLEANUP) then
			packets_counter <= packets_counter + x"1";
		else
			packets_counter <= packets_counter;
		end if;
	end if;
end process PACKETS_COUNTER_PROC;

end Behavioral;

