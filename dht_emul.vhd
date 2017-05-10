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
end entity dht_emul;

architecture sim of dht_emul is
        signal data_dht     : std_logic;
        signal SW           : std_ulogic_vector(3 DOWNTO 0);
        signal rst		      : std_ulogic;
        signal clk		      : std_ulogic;
        signal BTN		      : std_ulogic;
        signal LEDs         : std_ulogic_vector(3 DOWNTO 0);
        signal timer        : integer;
        signal data_dht_drv : std_ulogic;
        signal data_dht_in  : std_ulogic;


begin

      dut :  entity work.dht11_top(beh)
               port map(
                    data_dht => data_dht,
                    SW       => SW,
                    rst		   => rst,
                    clk		   => clk,
                    BTN		   => BTN,
                    LEDs     => LEDs
               );

CLK_GEN:     process
             begin
                 clk <= '0';
                 wait for 10 ns;
                 clk <= '1';
                 wait for 10 ns;
             end process;

data_dht <= '0' when data_dht_drv = '0' else 'H';
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
                 for i in 1 to 49994 loop -- wait for 1 s
                   wait until rising_edge(clk);
                 end loop;
                 BTN <= '1';              -- pressing the button
                 for i in 1 to 250000 loop
                   wait until rising_edge(clk);
                 end loop;
                 BTN <= '0';
                 -- determine if the timing is the right one

                 L1:for i in 1 to 900000 loop
                      int_cnt := int_cnt + 1;
                      wait until rising_edge(clk);
                          if data_dht_in = '1' THEN
                            exit L1;
                          end if;
                      end loop L1;
                  if int_cnt /= 899999 THEN
                    --write error
                  end if;
                  data_dht_drv <= '1';
                  for i in 1 to 1500 loop
                       wait until rising_edge(clk);
                           if data_dht_in /= '1' THEN
                             --write error
                           end if;
                       end loop;
                  data_dht_drv <= '0';
                  for i in 1 to 4000 loop
                    wait until rising_edge(clk);
                  end loop;
                  data_dht_drv <= '1';
                  for i in 1 to 4000 loop
                    wait until rising_edge(clk);
                  end loop;
                  data_dht_drv <= '0';
                  for j in 1 to 20 loop
                    data_dht_drv <= '0';
                    for i in 1 to 2500 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht_drv <= '1';
                    for i in 1 to 1350 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht_drv <= '0';
                    for i in 1 to 2500 loop
                      wait until rising_edge(clk);
                    end loop;
                    data_dht_drv <= '1';
                    for i in 1 to 3500 loop
                      wait until rising_edge(clk);
                    end loop;
                  end loop;
                  for i in 1 to 3500 loop
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
