
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity ll_client is
    port (

    -- LocalLink PDU Interface

            TX_D           : in std_logic_vector(0 to 31);
            TX_REM         : in std_logic_vector(0 to 1);
            TX_SRC_RDY_N   : in std_logic;
            TX_SOF_N       : in std_logic;
            TX_EOF_N       : in std_logic;
            TX_DST_RDY_N   : out std_logic;

            USER_CLK       : in std_logic
         );

end ll_client;

architecture MAPPED of ll_client is
	
begin

ll_inst : entity work.ll_aurora_test_TX_LL
	port map(TX_D         => TX_D,
		     TX_REM       => TX_REM,
		     TX_SRC_RDY_N => TX_SRC_RDY_N,
		     TX_SOF_N     => TX_SOF_N,
		     TX_EOF_N     => TX_EOF_N,
		     TX_DST_RDY_N => TX_DST_RDY_N,
		     WARN_CC      => '0',
		     DO_CC        => '0',
		     CHANNEL_UP   => '1',
		     GEN_SCP      => open,
		     GEN_ECP      => open,
		     TX_PE_DATA_V => open,
		     GEN_PAD      => open,
		     TX_PE_DATA   => open,
		     GEN_CC       => open,
		     USER_CLK     => USER_CLK); 
		     
	
end MAPPED;
