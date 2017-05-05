library ieee; 
use ieee.std_logic_1164.all;

entity timer is
  generic(max:    positive);
  port(
       clk    :  in  std_ulogic;
       sresetn:  in  std_ulogic;
       fc     :  out std_ulogic
      );
end entity timer;

architecture arc of timer is

  signal cnt1: natural range 0 to max - 1;

begin

process(clk)
  begin
    if rising_edge(clk) then
      if sresetn = '0' then -- synchronous, active low, reset
	cnt1 <= max - 1;
        fc <= '0';
      else
        if cnt1 = 0 then
	--cnt1 <= max - 1;
	fc <= '1';
        else
	  cnt1 <= cnt1 - 1;
        end if;
      end if;
    end if;
  end process;

end architecture arc;

