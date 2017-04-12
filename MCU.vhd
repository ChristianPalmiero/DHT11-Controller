library ieee;
use ieee.std_logic_1164.all;

entity MCU is
  port(
       data_in  :    inout std_ulogic;
       SW		: 	 in    std_ulogic_vector(3 DOWNTO 0);
       rst		:	 in    std_ulogic;
       clk		:	 in    std_ulogic;
       BTN		:	 in    std_ulogic;
       data_drv :    out   std_ulogic;
       LEDs     :    out   std_ulogic_vector(3 DOWNTO 0)
  );
end entity MCU;


architecture beh of MCU is
  signal data_in:  std_ulogic;
  signal data_drv: std_ulogic;

begin
  data    <= '0' when data_drv = '1' else 'H';
  data_in <= data;
  
end architecture beh;
