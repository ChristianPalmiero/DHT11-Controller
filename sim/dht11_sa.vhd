library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dht11_sa is
  generic(
    freq:    positive range 1 to 1000 -- Clock frequency (MHz)
  );
  port(
    clk:      in  std_ulogic;
    rst:      in  std_ulogic;                    -- Active high synchronous reset
    btn:      in  std_ulogic;
    sw:       in  std_ulogic_vector(3 downto 0); -- Slide switches
    data_in:  in  std_ulogic;
    data_drv: out std_ulogic;
    led:      out std_ulogic_vector(3 downto 0)  -- LEDs
  );
end entity dht11_sa;

architecture rtl of dht11_sa is

  signal start             : std_ulogic;
  signal pe                : std_ulogic;
  signal b		   : std_ulogic;
  signal do                : std_ulogic_vector(39 downto 0);
  signal sipo_out_mux_in   : std_ulogic_vector(31 downto 0);
  signal checksum          : std_ulogic_vector(7 downto 0);
  signal checksum_ver_to_B : std_ulogic_vector(3 downto 0);
  signal nib_sel_to_A      : std_ulogic_vector(3 downto 0);
  signal srstn		   : std_ulogic;
begin
	
  srstn <= NOT(rst);

  deb: entity work.debouncer(rtl)
  port map(
    clk   => clk,
    rst   => rst,
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

  sipo_out_mux_in <= do(39 DOWNTO 8);
  checksum <= do(7 DOWNTO 0);

  MUXes: process(sipo_out_mux_in, sw)
  begin
    if SW(0)='0' and SW(1)='0' and SW(2)='0' then
      nib_sel_to_A <= sipo_out_mux_in(3 DOWNTO 0);
    elsif SW(0)='0' and SW(1)='0' and SW(2)='1' then
      nib_sel_to_A <= sipo_out_mux_in(7 DOWNTO 4);
    elsif SW(0)='0' and SW(1)='1' and SW(2)='0' then
      nib_sel_to_A <= sipo_out_mux_in(11 DOWNTO 8);
    elsif SW(0)='0' and SW(1)='1' and SW(2)='1' then
      nib_sel_to_A <= sipo_out_mux_in(15 DOWNTO 12);
    elsif SW(0)='1' and SW(1)='0' and SW(2)='0' then
      nib_sel_to_A <= sipo_out_mux_in(19 DOWNTO 16);
    elsif SW(0)='1' and SW(1)='0' and SW(2)='1' then
      nib_sel_to_A <= sipo_out_mux_in(23 DOWNTO 20);
    elsif SW(0)='1' and SW(1)='1' and SW(2)='0' then
      nib_sel_to_A <= sipo_out_mux_in(27 DOWNTO 24);
    elsif SW(0)='1' and SW(1)='1' and SW(2)='1' then
      nib_sel_to_A <= sipo_out_mux_in(31 DOWNTO 28);
    end if;
  end process MUXes;

  Checksum_controller: process(checksum, sipo_out_mux_in)
  variable sum: unsigned(7 DOWNTO 0);
  variable sum_int: std_ulogic_vector(7 downto 0);
  begin
    sum:= unsigned(sipo_out_mux_in(31 DOWNTO 24)) + unsigned(sipo_out_mux_in(23 DOWNTO 16)) + unsigned(sipo_out_mux_in(15 DOWNTO 8)) + unsigned(sipo_out_mux_in(7 DOWNTO 0));
    sum_int:= std_ulogic_vector(sum);
    if sum_int = checksum then
      checksum_ver_to_B(0) <= '0';
    else
      checksum_ver_to_B(0) <= '1';
    end if;
  end process Checksum_controller;

  checksum_ver_to_B(1) <= b;
  checksum_ver_to_B(2) <= SW(0);
  checksum_ver_to_B(3) <= pe;

  MUX: process(nib_sel_to_A, checksum_ver_to_B, SW(3))
  begin
    if SW(3) = '1' then
      led <= nib_sel_to_A;
    else 
      led <= checksum_ver_to_B;
    end if;
  end process MUX;

end architecture rtl;
