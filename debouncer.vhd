--
-- Copyright (C) Telecom ParisTech
--
-- This file must be used under the terms of the CeCILL. This source
-- file is licensed as described in the file COPYING, which you should
-- have received as part of this distribution. The terms are also
-- available at:
-- http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
--

-- The debouncer takes a bouncing one-bit input (e.g. from a press button), synchronizes it and filters out the bounces. It outputs the synchronized and
-- debounced signal, plus a rising edge detector, a falling edge detector and an any edge detector. The edge detected output signals are active during one clock
-- period. Two generic parameters - n0 and n1 - specify the maximum values of two counters. n0 is the wrapping value of the sampling counter: when the counter
-- wraps around n0 a tick is generated. n1 is the maximum value of the debouncing counter. The debouncing counter increments on ticks of the sampling counter
-- where the re-synchronized input signal is asserted. When it reaches n1 it stops incrementing and the output is asserted. When the re-synchronized input
-- signal is de-asserted the debouncing counter is reset.

library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic(
    n0: positive := 50000; -- sampling counter wrapping value
    n1: positive := 10     -- debouncing counter maximum value
  );
  port(
    clk:   in  std_ulogic; -- clock
    rst:   in  std_ulogic; -- synchronous active high reset
    d:     in  std_ulogic; -- input bouncing signal
    q:     out std_ulogic; -- output synchronized and debounced signal
    r:     out std_ulogic; -- rising edge detector
    f:     out std_ulogic; -- falling edge detector
    a:     out std_ulogic  -- any edge detector
  );
end entity debouncer;

architecture rtl of debouncer is

  signal cnt0: natural range 0 to n0;     -- sampling counter
  signal cnt1: natural range 0 to n1;     -- debouncing counter
  signal sync: std_ulogic_vector(0 to 1); -- re-synchronizer
  signal l:    std_ulogic;                -- local copy of output
  signal lp:   std_ulogic;                -- previous value of l

begin

  l <= '1' when cnt1 = n1 else '0';
  q <= l;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt0 <= 0;
        cnt1 <= 0;
        sync <= (others => '0');
        r    <= '0';
        f    <= '0';
        a    <= '0';
        lp   <= '0';
      else
        if sync(1) = '0' then
          cnt1 <= 0;
        elsif cnt0 = n0 and sync(1) = '1' and cnt1 < n1 then
          cnt1 <= cnt1 + 1;
        end if;
        if cnt0 = n0 then
          cnt0 <= 0;
        else
          cnt0 <= cnt0 + 1;
        end if;
        sync <= d & sync(0);
        r    <= (not lp) and l;
        f    <= lp and (not l);
        a    <= lp xor l;
        lp   <= l;
      end if;
    end if;
  end process;

end architecture rtl;
