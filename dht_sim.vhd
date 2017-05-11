use std.env.all; -- to stop the simulation
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dht_sim is
end entity dht_sim;

architecture sim of dht_sim is

        signal data_in        : std_ulogic;
        signal rst            : std_ulogic;
        signal SW0            : std_ulogic;
        signal SW1            : std_ulogic;
        signal SW2            : std_ulogic;
        signal SW3            : std_ulogic;
        signal en             : std_ulogic;
        signal master_clk     : std_ulogic;
        signal init_enable    : std_ulogic;    --when enabled final count is set to the value present on init_counter
        signal BTN	      : std_ulogic;
        signal shift_enable   : std_ulogic;
        signal busy_bit       : std_ulogic;
        signal protocol_error : std_ulogic;
        signal init_counter   : integer;
        signal pulse          : std_ulogic;
        signal start	      :	std_ulogic;
        signal data_drv       : std_ulogic;
        signal LEDs           : std_ulogic_vector(3 DOWNTO 0);
        signal timer_out      : std_ulogic_vector(5 DOWNTO 0);

begin

      dut :  entity work.datapath(beh)
             port map(
             pulse            =>   pulse,
             data_in          =>   data_in,
             master_clk       =>   master_clk,
             rst              =>   rst,
             SW0	      =>   SW0,
             SW1              =>   SW1,
             SW2              =>   SW2,
             SW3              =>   SW3,
             en               =>   en,
             init_enable      =>   init_enable,
             BTN	      =>   BTN,
             shift_enable     =>   shift_enable,
             busy_bit         =>   busy_bit,
             protocol_error   =>   protocol_error,
             init_counter     =>   init_counter,
             start            =>   start,
             data_drv         =>   data_drv,
             LEDs             =>   LEDs,
             timer_out        =>   timer_out
             );

CLK_GEN:     process
             begin
                 master_clk <= '0';
                 wait for 10 ns;
                 master_clk <= '1';
                 wait for 10 ns;
             end process;

STIMULI_GEN: process
             variable seed1      : positive := 1;
             variable seed2      : positive := 1;
             variable rnd_number : real;
             begin
                 rst <= '1';
                 for i in 1 to 10 loop
                     wait until rising_edge(master_clk);
                 end loop;
                 rst <='0';
                 shift_enable <= '1';
                 for i in 1 to 40 loop
                    if (i=1) then
                        init_counter <= 35;
                    --elsif (i=2) then
                        init_enable <= '1';
                        en <= '0';
                    else
                        init_enable <= '0';
                        en <= '1';
                    end if;
                    --uniform(seed1, seed2, rnd_number);
                    --data_in <= to_unsigned(integer(floor(rnd_number)), 1);
                    if(i<38) then
                      data_in <= '1' when (i mod 2 = 1 )else '0';
                    else
                      data_in <= '0';
                    end if;
                    wait until rising_edge(master_clk);
                 end loop;
                 init_enable <= '0';
                 en <= '0';
                 shift_enable <= '0';
                 for i in 1 to 16 loop
                   (SW3,SW2,SW1,SW0) <= to_unsigned(i-1,4);
                   wait until rising_edge(master_clk);
                 end loop;
                 stop;
              end process;

end architecture sim;
