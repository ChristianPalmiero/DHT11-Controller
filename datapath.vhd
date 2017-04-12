library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity datapath is
  port(
       data_in  :       inout std_ulogic;
       SW0		: 	    in    std_ulogic;
       SW1		: 	    in    std_ulogic;
       SW2		: 	    in    std_ulogic;
       SW3		: 	    in    std_ulogic;
       rst		:	    in    std_ulogic;
       clk		:	    in    std_ulogic;
       BTN		:	    in    std_ulogic;
       shift_enable:    in    std_ulogic;
       busy_bit :       in    std_ulogic;
       protocol_error:  in    std_ulogic;
       final_count:     out   std_ulogic;
       data_drv :       out   std_ulogic;
       LEDs     :       out   std_ulogic_vector(3 DOWNTO 0);
       timer_out:	    out   std_ulogic_vector(5 DOWNTO 0)
  );
end entity datapath;


architecture beh of datapath is
  signal sipo_out_mux_in	:  std_ulogic_vector(31 DOWNTO 0);  
  signal checksum			:  std_ulogic_vector(7 DOWNTO 0);
  signal nib_sel_to_A		:  std_ulogic_vector(3 DOWNTO 0);
  signal checksum_ver_to_B  :  std_ulogic_vector(3 DOWNTO 0);
  signal Q					:  std_ulogic_vector(39 DOWNTO 0);
  signal cnt                :  integer range 0 to 39;
  signal timer_cnt			:  integer;

begin

  data    <= '0' when data_drv = '1' else 'H';
  data_in <= data;


  SIPO: process(clk)
  begin
    if(clk'event and clk = '1') then
      if rst = '1' then
      	Q <= (others=>'0');
      	sipo_out_mux_in <= (others=>'0');
      	checksum <= (others=>'0');
      	cnt <= 0;
      	final_count <= '0';
      elsif(shift_enable='1') then
        for i in 0 to 38 loop
           Q(i+1) <= Q(i);
        end loop;
        Q(0) <= data_in;
        cnt <= cnt + 1;        
       end if;
      
      if cnt = 38 then
        final_count <= '1';
      end if;

      if final_count = '1' then
        sipo_out_mux_in <= Q(39 DOWNTO 8);
        checksum <= Q(7 DOWNTO 0);
        final_count <= '0';
      end if;
    end if;
  end process SIPO;

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
      checksum_ver_to_B(0) = '0';
    else
      checksum_ver_to_B(0) = '1';
    end if;
  end process Checksum_controller;

  checksum_ver_to_B(1) <= busy_bit;
  checksum_ver_to_B(2) <= SW0;
  checksum_ver_to_B(3) <= protocol_error;

  MUX: process(nib_sel_to_A, checksum_ver_to_B, SW3)
  begin
    LEDs <= nib_sel_to_A when (SW3 = '1') else checksum_ver_to_B;
  end process MUX;

  TIMER: process(clk)
  begin
  end process TIMER





end architecture beh;
