--TODO
-- if falling_edge(data_in)
--    start counter
--if rising_edge(data_in)
--    stop counter
--if time >=18ms ok altrimenti write error
--wait for 35+-rand(5)
--data_in<='0'
--wait for 80 us
--data_in<='1'
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
        signal data_in   : std_ulogic;
        signal SW        : std_ulogic;
        signal rst		   : std_ulogic;
        signal clk		   : std_ulogic;
        signal BTN		   : std_ulogic;
        signal data_drv  : std_ulogic;
        signal LEDs      : std_ulogic_vector(3 DOWNTO 0);
        signal timer     : integer;

begin

--      dut :  entity work.MCU(beh)
--               port map(
--                    data_in  => data_in,
--                    SW       => SW,
--                    rst		   => rst,
--                    clk		   => clk,
--                    BTN		   => BTN,
--                    data_drv => data_drv,
--                    LEDs     => LEDs
--               );

CLK_GEN:     process
             begin
                 clk <= '0';
                 wait for 10 ns;
                 clk <= '1';
                 wait for 10 ns;
             end process;

STIMULI_GEN: process
             variable seed1      : positive := 1;
             variable seed2      : positive := 1;
             variable sign_rnd   : real;
             variable rnd_number : real;
             begin
                 rst <= '1';
                 for i in 1 to 10 loop
                     wait until rising_edge(clk);
                 end loop;
                 rst <='0';
                 --shift_enable <= '1';
                 for i in 1 to 40 loop
                    uniform(seed1, seed2, rnd_number);
                    if (rnd_number < 0.5) then
                        sign_rnd:= real(-1);
                    else
                        sign_rnd:= real(1);
                    end if;
                    timer <= integer(rnd_number*sign_rnd*real(10));
                    wait until rising_edge(clk);
                 end loop;
                 --init_enable <= '0';
                 --en <= '0';
                 --shift_enable <= '0';
                 for i in 1 to 16 loop
                   --(SW3,SW2,SW1,SW0) <= to_unsigned(i-1,4);
                   wait until rising_edge(clk);
                 end loop;
                 stop;
              end process;

end architecture sim;
