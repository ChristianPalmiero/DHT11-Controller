library ieee;
use ieee.std_logic_1164.all;

entity dht11_sa_top is
  generic(
    freq:    positive range 1 to 1000 -- Clock frequency (MHz)
  );
  port(
    clk:      in    std_ulogic;
    rst:      in    std_ulogic; -- Active high synchronous reset
    btn:      in    std_ulogic;
    sw:       in    std_ulogic_vector(3 downto 0); -- Slide switches
    data:     inout std_logic;
    led:      out   std_ulogic_vector(3 downto 0) -- LEDs
  );
end entity dht11_sa_top;

architecture rtl of dht11_sa_top is

  signal data_in:  std_ulogic;
  signal data_drv: std_ulogic;

begin

  data_in <= data;

  data <= '0' when data_drv = '1' else 'Z';
  
  u0: entity work.dht11_sa(rtl)
  generic map(
    freq => freq
  )
  port map(
    clk      => clk,
    rst      => rst,
    btn      => btn,
    sw       => sw,
    data_in  => data_in,
    data_drv => data_drv,
    led      => led
  );

end architecture rtl;
