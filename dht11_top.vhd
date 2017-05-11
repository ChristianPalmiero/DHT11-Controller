library ieee;
use ieee.std_logic_1164.all;

entity dht11_top is
  port(
       data_dht :    inout    std_ulogic;
       SW	:    in    std_ulogic_vector(3 DOWNTO 0);
       rst	:    in    std_ulogic;
       clk	:    in    std_ulogic;
       BTN	:    in    std_ulogic;
     --data_drv :    out   std_ulogic;
       LEDs     :    out   std_ulogic_vector(3 DOWNTO 0)
  );
end entity dht11_top;


architecture beh of dht11_top is
  signal data_in, data_drv : std_ulogic;
  signal pulse, en, init_enable, shift_enable, busy_bit, protocol_error, data, final_cnt, final_count, fall_edge : std_ulogic;
  signal init_counter : integer;

begin

  data_dht <= '0' when data_drv = '1' else 'H';
  data_in <= data_dht;

  DP: entity work.datapath(beh)
    generic map(
      with_prescaler  => false
    )
    port map(
      data_in         => data_in,
      data_drv        => data_drv,
      SW0             => SW(0),
      SW1	      => SW(1),
      SW2	      => SW(2),
      SW3	      => SW(3),
      rst	      => rst,
      master_clk      => clk,
      en              => en,
      init_enable     => init_enable,
      BTN	      => BTN,
      shift_enable    => shift_enable,
      busy_bit        => busy_bit,
      protocol_error  => protocol_error,
      init_counter    => init_counter,
      data            => data,
      final_cnt       => final_cnt,
      final_count     => final_count,
      pulse	      => pulse,
      fall_edge	      => fall_edge,
      LEDs            => LEDs
    );

    CU: entity work.CU(behav)
    port map(
      CLK	      => clk,
      RST             => rst,
      FINAL_COUNTER   => final_count,
      FINAL_CNT       => final_cnt,
      PULSE           => pulse,
      OUT_DEBOUNCER   => fall_edge,
      EN              => en,
      INITIAL_ENABLE  => init_enable,
      SHIFT_ENABLE    => shift_enable,
      BUSY_BIT        => busy_bit,
      PROTOCOL_ERROR  => protocol_error,
      INIT_COUNTER    => init_counter,
      DATA	      => data,
      DATA_DRV        => data_drv
    );

end architecture beh;
