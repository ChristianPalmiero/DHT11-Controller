library ieee;
use ieee.std_logic_1164.all;

-- Read data (do) format:
-- do(39 downto 24): relative humidity (do(39) = MSB)
-- do(23 downto 8):  temperature (do(23) = MSB)
-- do(7 downto 0):   check-sum = (do(39 downto 32)+do(31 downto 24)+do(23 downto 16)+do(15 downto 8)) mod 256
entity dht11_ctrl is
	generic(
		freq:    positive range 1 to 1000 -- Clock frequency (MHz)
	);
	port(
		clk:      in  std_ulogic;
		rst:      in  std_ulogic;
		start:    in  std_ulogic;
		data_in:  in  std_ulogic;
		data_drv: out std_ulogic;
		pe:       out std_ulogic; -- Protocol error
		b:        out std_ulogic; -- Busy
		do:       out std_ulogic_vector(39 downto 0) -- Read data
	);
end entity dht11_ctrl;

architecture rtl of dht11_ctrl is

  signal pulse, en, init_enable, shift_enable, data, final_cnt, final_count, out_second_comparator : std_ulogic;
  signal out_comparator : std_ulogic_vector(1 DOWNTO 0);
  signal init_counter, margin, threshold_comp : integer;

  begin

    dp: entity work.datapath(beh)
    port map(
      data_in               => data_in,    
      data_drv              => data_drv,               
      rst                   => rst,  	               
      clk	           	  => clk,
      en                    => en,
      init_enable           => init_enable,
      shift_enable          => shift_enable,
      init_counter          => init_counter,
      margin                => margin,
      threshold_comp        => threshold_comp,
      data                  => data,
      final_cnt	          => final_cnt,
      final_count	          => final_count,
      pulse		  => pulse,
      out_comparator        => out_comparator,
      out_second_comparator => out_second_comparator,
      do                    => do
    );

    CU: entity work.CU(behav)
    port map(
      CLK	                   => clk,
      RST                    => rst,
      FINAL_COUNTER          => final_count,
      FINAL_CNT              => final_cnt,
      PULSE                  => pulse,
      OUT_DEBOUNCER          => start,
      OUT_COMPARATOR         => out_comparator,
      OUT_SECOND_COMPARATOR  => out_second_comparator,
      EN                     => en,
      INITIAL_ENABLE         => init_enable,
      SHIFT_ENABLE           => shift_enable,
      BUSY_BIT               => b,
      PROTOCOL_ERROR         => pe,
      INIT_COUNTER           => init_counter,
      MARGIN                 => margin,
      THRESHOLD_COMP         => threshold_comp,
      DATA	           => data,
      DATA_DRV               => data_drv
    );

end architecture rtl;
