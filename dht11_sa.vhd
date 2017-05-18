-- DTH11 controller wrapper, standalone version

library ieee;
use ieee.std_logic_1164.all;

entity dht11_sa is
	generic(
		freq:    positive range 1 to 1000 -- Clock frequency (MHz)
	);
	port(
		clk:      in  std_ulogic;
		rst:      in  std_ulogic; -- Active high synchronous reset
		btn:      in  std_ulogic;
		sw:       in  std_ulogic_vector(3 downto 0); -- Slide switches
		data_in:  in  std_ulogic;
		data_drv: out std_ulogic;
		led:      out std_ulogic_vector(3 downto 0) -- LEDs
	);
end entity dht11_sa;

architecture rtl of dht11_sa is

	signal srstn: std_ulogic;
	signal start: std_ulogic;
	signal pe:    std_ulogic;
	signal b:     std_ulogic;
	signal do:    std_ulogic_vector(39 downto 0);

begin

	srstn <= not rst;

	

	deb: entity work.debouncer(rtl)
	port map(
		clk   => clk,
		srstn => srstn,
		d     => btn,
		q     => open,
		r     => start,
		f     => open,
		a     => open
	);

	u0: entity work.dht11_ctrl(rtl)
	generic map(
		freq => freq
	)
	port map(
		clk      => clk,
		srstn    => srstn,
		start    => start,
		data_in  => data_in,
		data_drv => data_drv,
		pe       => pe,
		b        => b,
		do       => do
	);

	 MUXes: process(sipo_out_mux_in, SW0, SW1, SW2)
  	begin
   	nib_sel_to_A <= sipo_out_mux_in(3 DOWNTO 0) when SW0='0' and SW1='0' and SW2='0' else
      	sipo_out_mux_in(7 DOWNTO 4) when SW0='0' and SW1='0' and SW2='1' else
      	sipo_out_mux_in(11 DOWNTO 8) when SW0='0' and SW1='1' and SW2='0' else
      	sipo_out_mux_in(15 DOWNTO 12) when SW0='0' and SW1='1' and SW2='1' else
      	sipo_out_mux_in(19 DOWNTO 16) when SW0='1' and SW1='0' and SW2='0' else
     	sipo_out_mux_in(23 DOWNTO 20) when SW0='1' and SW1='0' and SW2='1' else
      	sipo_out_mux_in(27 DOWNTO 24) when SW0='1' and SW1='1' and SW2='0' else
      	sipo_out_mux_in(31 DOWNTO 28) when SW0='1' and SW1='1' and SW2='1';
  end process MUXes;

  Checksum_controller: process(checksum, sipo_out_mux_in)
  variable sum: std_ulogic_vector(7 DOWNTO 0);
  begin
    sum:= sipo_out_mux_in(31 DOWNTO 24) + sipo_out_mux_in(23 DOWNTO 16) + sipo_out_mux_in(15 DOWNTO 8) + sipo_out_mux_in(7 DOWNTO 0);
    if sum = checksum then
      checksum_ver_to_B(0) <= '0';
    else
      checksum_ver_to_B(0) <= '1';
    end if;
  end process Checksum_controller;

  checksum_ver_to_B(1) <= busy_bit;
  checksum_ver_to_B(2) <= SW0;
  checksum_ver_to_B(3) <= protocol_error;

  MUX: process(nib_sel_to_A, checksum_ver_to_B, SW3)
  begin
    LEDs <= nib_sel_to_A when (SW3 = '1') else checksum_ver_to_B;
  end process MUX;

end architecture rtl;
