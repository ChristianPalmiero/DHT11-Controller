library ieee; 
use ieee.std_logic_1164.all;

entity prescaler is
  generic(max:    positive);
  port(
       clk    :  in  std_ulogic;
       sresetn:  in  std_ulogic;
       fc     :  out std_ulogic
      );
end entity prescaler;

architecture arc of prescaler is

  signal cnt1: natural range 0 to max;

begin

process(clk)
  begin
    if rising_edge(clk) then
      fc <= '0';
      if sresetn = '0' then -- synchronous, active low, reset
	cnt1 <= max;
      else
        if cnt1 = 0 then
	  cnt1 <= max;
	  fc <= '1';
        else
	  cnt1 <= cnt1 - 1;
        end if;
      end if;
    end if;
  end process;

end architecture arc;

