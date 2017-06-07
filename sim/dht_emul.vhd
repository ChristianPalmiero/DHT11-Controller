--TODO
-- if falling_edge(data_dht)
--    start counter
--if rising_edge(data_dht)
--    stop counter
--if time >=18ms ok altrimenti write error
--wait for 35+-rand(5)
--data_dht<='0'
--wait for 80 us
--data_dht<='1'
--wait for 80 us
--inizio ad inviare i dati randomicamente.

use std.env.all; -- to stop the simulation
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dht_emul is
	generic(
         	freq:    positive range 1 to 1000 := 125 -- Clock frequency (MHz)
  	); 

end entity dht_emul;

architecture sim of dht_emul is
 
        signal data_dht     : std_logic;
        signal SW           : std_ulogic_vector(3 DOWNTO 0);
        signal rst	    : std_ulogic;
        signal clk          : std_ulogic;
        signal BTN	    : std_ulogic;
        signal LEDs         : std_ulogic_vector(3 DOWNTO 0);
        signal timer        : integer;
        signal data_drv     : std_ulogic;
        signal data_dht_in  : std_ulogic;

begin

      dut :  entity work.dht11_sa(rtl)
               generic map(
		    freq => freq
	       )
	       port map(
		    clk      => clk,
                    rst	     => rst,
                    BTN	     => BTN,
		    SW       => SW,
                    data_in  => data_dht,
		    data_drv => data_drv,                    
                    LED      => LEDs
               );

CLK_GEN:     process
             begin
                 clk <= '0';
                 wait for 4 ns;
                 clk <= '1';
                 wait for 4 ns;
             end process;

data_dht <= '0' when data_drv = '1' else 'H';
data_dht_in <= data_dht;

STIMULI_GEN: process
             variable seed1      : positive := 1;
             variable seed2      : positive := 1;
             variable sign_rnd   : real;
             variable rnd_number : real;
             variable int_cnt    : integer;
             begin
                 int_cnt := 0;
                 rst <= '1';
                 for i in 1 to 10 loop
                     wait until rising_edge(clk);
                 end loop;
                 rst <= '0';
                 BTN <= '0';
		 Data_dht <= 'Z';
                 SW(0) <= '0';
                 SW(1) <= '0';
                 SW(2) <= '0';
                 SW(3) <= '0';
                 for i in 1 to 4 loop
                   wait until rising_edge(clk);
                 end loop;
                 BTN <= '1';
                 for i in 1 to 2 loop
                   wait until rising_edge(clk);
                 end loop;
                 BTN <= '0';
                 for i in 1 to 124999994 loop -- wait for 1 s
                   wait until rising_edge(clk);
                 end loop;
                 BTN <= '1';              -- pressing the button
                 for i in 1 to 25000000 loop -- wait with the button pressed for 0.2 s
                   wait until rising_edge(clk);
		   if data_dht_in = '0' then
		     exit;
		   end if;
                 end loop;
                 BTN <= '0';
                 -- determine if the timing is the right one
                 -- wait for 20ms in which MCU put low the line
                 L1:for i in 1 to 2500000 loop
                      int_cnt := int_cnt + 1;
                      wait until rising_edge(clk);
                          if data_dht_in = '1' THEN
                            exit L1;
                          end if;
                      end loop L1;
                  if int_cnt /= 2249999 THEN
                    --write error
                  end if;
                  data_dht <= 'Z';
                  -- wait for 30us
                  for i in 1 to 3750 loop
                       wait until rising_edge(clk);
                           if data_dht_in /= '1' THEN
                             --write error
                           end if;
                       end loop;
                  -- put data to 0 and keep for 80 us
                  data_dht <= '0';
                  for i in 1 to 10000 loop
                    wait until rising_edge(clk);
                  end loop;
                  -- put data to 1 and keep for 80 us
                  data_dht <= 'Z';
                  for i in 1 to 10000 loop
                    wait until rising_edge(clk);
                  end loop;
                  data_dht <= '0';
                  for j in 1 to 20 loop
                    data_dht <= '0';
                    for i in 1 to 6250 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht <= 'Z';
                    for i in 1 to 3375 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht <= '0';
                    for i in 1 to 6250 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht <= 'Z';
                    for i in 1 to 8750 loop
                      wait until rising_edge(clk);
                    end loop;
                  end loop;
                  data_dht <= '0';
                  for i in 1 to 8750 loop
                    wait until rising_edge(clk);
                  end loop;
                  data_dht <= 'Z';
                  for i in 1 to 6250 loop
                    wait until rising_edge(clk);
                  end loop;

--                 for i in 1 to 40 loop
--                    uniform(seed1, seed2, rnd_number);
--                    if (rnd_number < 0.5) then
--                        sign_rnd:= real(-1);
--                    else
--                        sign_rnd:= real(1);
--                    end if;
--                    timer <= integer(rnd_number*sign_rnd*real(10));
--                    wait until rising_edge(clk);
--                 end loop;
--                 --init_enable <= '0';
--                 --en <= '0';
--                 --shift_enable <= '0';
--                 for i in 1 to 16 loop
--                   --(SW3,SW2,SW1,SW0) <= to_unsigned(i-1,4);
--                   wait until rising_edge(clk);
--                 end loop;
                 stop;
              end process;

end architecture sim;
