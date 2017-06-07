library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dht11_pkg is

	alias u_unsigned is unsigned;

	-- Delays in numbers of microseconds
	constant dht11_reset_to_start_min: natural := 1000000; -- Minimum delay between reset and start
	constant dht11_start_duration_min: natural := 18000;   -- Minimum duration of start low pulse
	constant dht11_start_to_ack_min:   natural := 20;    -- Minimum delay from start to ack
	constant dht11_start_to_ack_max:   natural := 40;    -- Maximum delay from start to ack
	constant dht11_ack_duration:       natural := 80;    -- Typical duration of ack low pulses
	constant dht11_ack_to_bit:         natural := 80;    -- Typical delay between ack and first bit
	constant dht11_bit_duration:       natural := 50;    -- Typical duration of bit low pulse
	constant dht11_bit0_to_next_min:   natural := 26;    -- Minimum delay from bit 0 to next bit
	constant dht11_bit0_to_next_max:   natural := 28;    -- Maximum delay from bit 0 to next bit
	constant dht11_bit1_to_next:       natural := 70;    -- Typical delay from bit 1 to next bit

	-- Delays in time
	constant dht11_reset_to_start_min_t: time := dht11_reset_to_start_min * 1 us;
	constant dht11_start_duration_min_t: time := dht11_start_duration_min * 1 us;
	constant dht11_start_to_ack_min_t:   time := dht11_start_to_ack_min * 1 us;
	constant dht11_start_to_ack_max_t:   time := dht11_start_to_ack_max * 1 us;
	constant dht11_ack_duration_t:       time := dht11_ack_duration * 1 us;
	constant dht11_ack_to_bit_t:         time := dht11_ack_to_bit * 1 us;
	constant dht11_bit_duration_t:       time := dht11_bit_duration * 1 us;
	constant dht11_bit0_to_next_min_t:   time := dht11_bit0_to_next_min * 1 us;
	constant dht11_bit0_to_next_max_t:   time := dht11_bit0_to_next_max * 1 us;
	constant dht11_bit1_to_next_t:       time := dht11_bit1_to_next * 1 us;

	function parity(di: std_ulogic_vector) return std_ulogic_vector;

end package dht11_pkg;

package body dht11_pkg is

	function parity(di: std_ulogic_vector) return std_ulogic_vector is
		variable res: u_unsigned(7 downto 0);
		variable val: u_unsigned(31 downto 0) := u_unsigned(di);
	begin
		res := val(31 downto 24) + val(23 downto 16) + val(15 downto 8) + val(7 downto 0);
		return std_ulogic_vector(res);
	end function parity;

end package body dht11_pkg;
