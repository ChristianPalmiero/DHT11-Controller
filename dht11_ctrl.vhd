-- DTH11 controller

library ieee;
use ieee.std_logic_1164.all;

-- Read data (do) format:
-- do(39 downto 24): relative humidity (do(39) = MSB)
-- do(23 downto 8):  temperature (do(23) = MSB)
-- do(7 downto 0):   check-sum = (do(39 downto 32)+do(31 downto 24)+do(23 downto 16)+do(15 downto 8)) mod 256
entity dht11_ctrl is
	generic(
		freq:    positive range 1 to 1000 -- Clock frequency (MHz)
	);
	port(
		clk:      in  std_ulogic;
		srstn:    in  std_ulogic; -- Active low synchronous reset
		start:    in  std_ulogic;
		data_in:  in  std_ulogic;
		data_drv: out std_ulogic;
		pe:       out std_ulogic; -- Protocol error
		b:        out std_ulogic; -- Busy
		do:       out std_ulogic_vector(39 downto 0) -- Read data
	);
end entity dht11_ctrl;

architecture rtl of dht11_ctrl is

begin

end architecture rtl;
