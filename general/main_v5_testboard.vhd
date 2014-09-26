library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
USE IEEE.std_logic_UNSIGNED.ALL;

library work;

use work.trb_net_gbe_components.all;
use work.trb_net_gbe_protocols.all;

entity main_v5_testboard is
port(
	fpga_0_sfp_a_rd_p_pin : in std_logic;
	fpga_0_sfp_a_rd_n_pin : in std_logic;
	fpga_0_sfp_a_td_p_pin : out std_logic;
	fpga_0_sfp_a_td_n_pin : out std_logic;
	
	clk_125_p, clk_125_n : in std_logic
);
end main_v5_testboard;

architecture Behavioral of main_v5_testboard is
	
	signal v5_clk_125 : std_logic;
	signal clk_125_ds : std_logic;
	signal reset : std_logic;
	signal gtreset : std_logic;
	signal reset_ctr : std_logic_vector(31 downto 0);
	signal reset_r : std_logic_vector(3 downto 0);
	signal rx_clk, userclk : std_logic;
	signal client_stats1 : std_logic;
	signal client_fb1 : std_logic;
	signal client_ack1 : std_logic;
	signal client_tx_dv1 : std_logic;
	signal client_txd1 : std_logic_vector(7 downto 0);
	signal client_bad_frame1 : std_logic;
	signal client_rxd1 : std_logic_vector(7 downto 0);
	signal client_rx_dv1 : std_logic;
	signal client_good_frame1 : std_logic;
	signal clk62_5_pre_bufg : std_ulogic;
	signal clk62_5 : std_ulogic;
	signal clk_125, clk125_fb : std_ulogic;
	signal clk125_o_bufg : std_ulogic;
	signal dcm_locked : std_logic;

begin
	
	clk_buf : IBUFDS port map ( I => clk_125_p, IB => clk_125_n, O => clk_125_ds );
	
	clk_buf2 : BUFG port map ( I => clk_125_ds, O => v5_clk_125);
	
	bufg_clk125 : BUFG port map(I => clk125_fb, O => clk_125);
	
	bufg_clk125_o: BUFG port map(I => v5_clk_125, O => clk125_o_bufg);
	
	--rx_clk <= v5_clk_125;
	userclk <= rx_clk; --v5_clk_125;
	
	clk62_5_dcm : DCM_BASE 
	port map 
	(CLKIN      => clk125_o_bufg,
	CLK0       => clk125_fb,
	CLK180     => open,
	CLK270     => open,
	CLK2X      => open,
	CLK2X180   => open,
	CLK90      => open,
	CLKDV      => clk62_5_pre_bufg,
	CLKFX      => open,
	CLKFX180   => open,
	LOCKED     => dcm_locked,
	CLKFB      => clk_125,
	RST        => '0');
	
	clk62_5_bufg : BUFG port map(I => clk62_5_pre_bufg, O => clk62_5);

REC1 : entity work.receiver_module
generic map(
	UDP_RECEIVER         => 1,
	UDP_TRANSMITTER      => 0,
	MAC_ADDRESS          => x"1111efbe0000"
)
port map(
	SYS_CLK              => '0',
	RESET_IN             => reset,
	CLK_125_IN           => rx_clk,
	TX_CLK_IN            => userclk,
	
	RX_DATA_IN           => client_rxd1,
	RX_DATA_DV_IN        => client_rx_dv1,
	RX_DATA_GF_IN        => client_good_frame1,
	RX_DATA_BF_IN        => client_bad_frame1,
	
	TX_DATA_OUT          => client_txd1,
	TX_DATA_DV_OUT       => client_tx_dv1,
	TX_DATA_FB_OUT       => client_fb1,
	TX_DATA_ACK_IN       => client_ack1,
	TX_DATA_STATS_VALID_IN => client_stats1,
	
	LL_UDP_OUT_DATA_OUT         => open,
	LL_UDP_OUT_REM_OUT          => open,
	LL_UDP_OUT_SOF_N_OUT        => open,
	LL_UDP_OUT_EOF_N_OUT        => open,
	LL_UDP_OUT_SRC_READY_N_OUT  => open,
	LL_UDP_OUT_DST_READY_N_IN   => '0',
	LL_UDP_OUT_FIFO_STATUS_IN   => (others => '0'),
	LL_UDP_OUT_WRITE_CLK_OUT    => open,

	LL_DATA_IN              => (others => '0'),
	LL_REM_IN               => (others => '0'),
	LL_SOF_N_IN             => '1',
	LL_EOF_N_IN             => '1',
	LL_SRC_READY_N_IN       => '1',
	LL_DST_READY_N_OUT      => open,
	LL_READ_CLK_OUT         => open	
);

v5_emac_block_inst_1 : v5_dual_mac_block
    port map (
          -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                      => rx_clk, --v5_clk_125,
      -- 125MHz clock input from BUFG
      CLK125                          => v5_clk_125,
      -- 62.5MHz clock input from BUFG
      CLK62_5                         => clk62_5,

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXD                  => client_rxd1,
      EMAC0CLIENTRXDVLD               => client_rx_dv1,
      EMAC0CLIENTRXGOODFRAME          => client_good_frame1,
      EMAC0CLIENTRXBADFRAME           => client_bad_frame1,
      EMAC0CLIENTRXFRAMEDROP          => open,
      EMAC0CLIENTRXSTATS              => open,
      EMAC0CLIENTRXSTATSVLD           => open,
      EMAC0CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXD                  => client_txd1,
      CLIENTEMAC0TXDVLD               => client_tx_dv1,
      EMAC0CLIENTTXACK                => client_ack1,
      CLIENTEMAC0TXFIRSTBYTE          => client_fb1,
      CLIENTEMAC0TXUNDERRUN           => '0',
      EMAC0CLIENTTXCOLLISION          => open,
      EMAC0CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC0TXIFGDELAY           => (others => '0'),
      EMAC0CLIENTTXSTATS              => open,
      EMAC0CLIENTTXSTATSVLD           => client_stats1,
      EMAC0CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ             => '0',
      CLIENTEMAC0PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS        => open,
      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT                => open,

      -- Clock Signals - EMAC0
      -- 1000BASE-X PCS/PMA Interface - EMAC0
      TXP_0                           => fpga_0_sfp_a_td_p_pin,
      TXN_0                           => fpga_0_sfp_a_td_n_pin,
      RXP_0                           => fpga_0_sfp_a_rd_p_pin,
      RXN_0                           => fpga_0_sfp_a_rd_n_pin,
      PHYAD_0                         => "00001",
      RESETDONE_0                     => open,

      -- EMAC1 Clocking

      -- Client Receiver Interface - EMAC1
      EMAC1CLIENTRXD                  => open,
      EMAC1CLIENTRXDVLD               => open,
      EMAC1CLIENTRXGOODFRAME          => open,
      EMAC1CLIENTRXBADFRAME           => open,
      EMAC1CLIENTRXFRAMEDROP          => open,
      EMAC1CLIENTRXSTATS              => open,
      EMAC1CLIENTRXSTATSVLD           => open,
      EMAC1CLIENTRXSTATSBYTEVLD       => open,

      -- Client Transmitter Interface - EMAC1
      CLIENTEMAC1TXD                  => (others => '0'),
      CLIENTEMAC1TXDVLD               => '0',
      EMAC1CLIENTTXACK                => open,
      CLIENTEMAC1TXFIRSTBYTE          => '0',
      CLIENTEMAC1TXUNDERRUN           => '0',
      EMAC1CLIENTTXCOLLISION          => open,
      EMAC1CLIENTTXRETRANSMIT         => open,
      CLIENTEMAC1TXIFGDELAY           => (others => '0'),
      EMAC1CLIENTTXSTATS              => open,
      EMAC1CLIENTTXSTATSVLD           => open,
      EMAC1CLIENTTXSTATSBYTEVLD       => open,

      -- MAC Control Interface - EMAC1
      CLIENTEMAC1PAUSEREQ             => '0',
      CLIENTEMAC1PAUSEVAL             => (others => '0'),

      --EMAC-MGT link status
      EMAC1CLIENTSYNCACQSTATUS        => open,
      -- EMAC1 Interrupt
      EMAC1ANINTERRUPT                => open,

      -- Clock Signals - EMAC1
      -- 1000BASE-X PCS/PMA Interface - EMAC1
      TXP_1                           => open,
      TXN_1                           => open,
      RXP_1                           => '0',
      RXN_1                           => '1',
      PHYAD_1                         => "00001",
      RESETDONE_1                     => open,

      -- 1000BASE-X PCS/PMA RocketIO Reference Clock buffer inputs
      CLK_DS                          => clk_125_ds,

      -- RocketIO Reset input
      GTRESET                         => gtreset,

      -- Asynchronous Reset
      RESET                           => reset
   );
   
   	GTRESET_PROC : process(reset, clk_125_ds)
	begin
		if (reset = '1') then
			reset_r <= "1111";
		elsif rising_edge(clk_125_ds) then
			reset_r <= reset_r(2 downto 0) & '0';
		end if;
	end process;

	gtreset <= reset_r(3);
	
	RESET_PROC : process(clk_125_ds)
	begin
		if rising_edge(clk_125_ds) then
			if (reset_ctr > x"0000_f000" and reset_ctr < x"0000_ffff") then
				reset <= '1';
			else
				if (dcm_locked = '1') then
					reset <= '1';
				else
					reset <= '0';
				end if;
			end if;
		end if;
	end process RESET_PROC;
	
	RESET_CTR_PROC : process(clk_125_ds)
	begin
		if rising_edge(clk_125_ds) then
			if (reset_ctr < x"0000_ffff") then
				reset_ctr <= reset_ctr + 1;
			end if;
		end if;
	end process RESET_CTR_PROC;
   
end Behavioral;