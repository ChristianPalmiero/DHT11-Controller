library unisim;
use unisim.vcomponents.all;


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
  signal data_drvn: std_ulogic;

begin

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

  u1 : iobuf
    generic map (
      drive => 12,
      iostandard => "lvcmos33",
      slew => "slow")
    port map (
      o  => data_in,
      io => data,
      i  => '0',
      t  => data_drvn
  );

data_drvn <= not data_drv;

end architecture rtl;
