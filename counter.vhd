library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity counter is
port (
      init_counter : in  integer;
      clk          : in  std_ulogic;
      rst          : in  std_ulogic;
      en           : in  std_ulogic;
      init_enable  : in  std_ulogic;    --when enabled final count is set to the value present on init_counter
      final_count  : out std_ulogic
);
end entity counter;

architecture beh of counter is
      signal count : integer;
      signal threshold : integer;
begin
      CNT : process(clk)
      begin
        if(clk' event and clk = '1') then
            final_count <= '0';
            if(rst='0') then
                count <= 0;
            elsif(init_enable = '1') then
                threshold <= init_counter;
                count <= 0; --To be decided if reset or not
            elsif(en = '1') then
                if(count = threshold - 1) then
                    final_count <= '1';
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            end if;
          end if;
      end process CNT;
  end architecture beh;
