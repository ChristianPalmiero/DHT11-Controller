library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity datapath is
  generic(
    freq:    positive range 1 to 1000 -- Clock frequency (MHz)
  );
  port(
       data_in                :           in    std_ulogic;
       data_drv               :           in    std_ulogic;
       rst	              :	          in    std_ulogic;
       clk	              :	          in    std_ulogic;
       en                     :           in    std_ulogic;
       init_enable            :           in    std_ulogic;    -- when enabled, the COUNTER process threshold is initialised to the init_counter value
       shift_enable           :           in    std_ulogic;
       init_counter           :           in    integer;
       margin                 :           in    integer;
       threshold_comp         :           in    integer;
       data                   :           in    std_ulogic;    -- sent by the control unit after a change in the data has been detected in data_in by the two PULSE_GEN processes
       final_cnt	      :           out   std_ulogic;
       final_count	      :           out   std_ulogic;
       rising		      :           out   std_ulogic;
       falling                :           out   std_ulogic;
       out_comparator         :           out   std_ulogic_vector(1 DOWNTO 0);
       out_second_comparator  :           out   std_ulogic;
       do                     : 	  out 	std_ulogic_vector(39 DOWNTO 0)
  );
end entity datapath;


architecture beh of datapath is

  signal Q			:  std_ulogic_vector(39 DOWNTO 0);
  signal cnt                    :  integer range 0 to 40;
  signal count                  :  integer;
  signal threshold              :  integer;
  signal dp             	:  std_ulogic_vector(2 downto 0);
  signal out_comparator_local   :  std_ulogic_vector(1 DOWNTO 0);

begin
  
  SIPO: process(clk)
  variable Q_var:  std_ulogic_vector(39 DOWNTO 0);
  begin
    if(clk'event and clk = '1') then
      if rst = '1' then
      	Q <= (others=>'0');
      	cnt <= 0;
        final_count <= '0';
	do <= (others=>'0');
      elsif(shift_enable='1') then
        final_count <= '0';
        if cnt < 38 then
          -- Left shift
          Q <= Q(38 downto 0) & data;
          cnt <= cnt + 1;
        elsif (cnt = 38) then
          Q <= Q(38 downto 0) & data;
          cnt <= cnt + 1;
          final_count <= '1';
        else
          final_count <= '0';
          cnt <= 0;
          Q_var := Q(38 downto 0) & data;
          do <= Q_var(39 DOWNTO 0);
         end if;
       end if;
    end if;
  end process SIPO;

  COUNTER: process(clk)
  begin
    if(clk'event and clk='1') then
      final_cnt <= '0';
      if(rst='1') then
        count <= 0;
      elsif(init_enable = '1') then
        threshold <= init_counter;
        count <= 0; --To be decided if reset or not
      elsif(en = '1') then
        if(count = threshold - 2) then   --set to -2 to compensate
          final_cnt <= '1';            --the cc lost when set the counter
          count <= 0;
        else
           count <= count + 1;
        end if;
      end if;
    end if;
  end process COUNTER;

  PULSE_GEN: process(clk)
  begin
    if(clk' event and clk='1') then
      if (rst='1') then
        dp <= (others=>'0');
      else
        dp <= data_in & dp(2 downto 1);
      end if;
    end if;
  end process PULSE_GEN;
  rising  <= dp(1) and not(dp(0));
  falling <= not(dp(1)) and dp(0);

  COMPARATOR: process(threshold_comp, margin, count)
  begin
    if threshold_comp /= 0 then
      if count <= threshold_comp+margin and count >= threshold_comp-margin then
        out_comparator_local(0) <= '1';
      else
        out_comparator_local(0) <= '0';
        if count > threshold_comp + margin then
          out_comparator_local(1) <= '1';   -- above the top margin
        else
          out_comparator_local(1) <= '0';   -- below the bottom margin
        end if;
      end if;
    end if;
  end process COMPARATOR;

  out_comparator <= out_comparator_local;

  SECOND_COMPARATOR: process(out_comparator_local(1), threshold_comp, count)
  begin
    out_second_comparator <= '0';
    if out_comparator_local(1) = '1' then  -- if count > 50 see if it falls in 1's range
      if count <= 75*freq and count >= 65*freq then     -- 67-73 us --relaxed 65-75 us
        out_second_comparator <= '1';
      else
        out_second_comparator <= '0';
      end if;
    else                              -- if count < 50 see if it falls in 0's range
      if count <= 35*freq and count >= 20*freq then     -- 24-30 us --relaxed 20-35 us
        out_second_comparator <= '1';
      else
        out_second_comparator <= '0';
      end if;
    end if;
  end process SECOND_COMPARATOR;

end architecture beh;
