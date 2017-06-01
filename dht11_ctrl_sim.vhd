-- This source file contains:
-- * dht11_sim_pkg: a utility package for simulation (random numbers generator, durations checkers, data checkers...).
-- * dht11(beh): the VHDL model of the DHT11 sensor. Its protocol_error and checksum_error input signals are used to instruct the sensor to introduce protocol and checksum errors. Its eot output signals the End Of a Transmission (after the last 50 us low level delay).
-- * dht11_ctrl_ref(beh): the VHDL model of a reference DHT11 controller (same as the dht11_ctrl.vhd but too high level for synthesis). Its abort_on_protocol_errors generic parameter decides whether the reference DHT11 controller aborts a transmission when it detects a protocol error or continues until the end. Its margin generic parameter sets the tolerance for protocol error detection.
-- * dht11_ctrl_sim(sim): a simulation environment that instantiates the sensor, the reference DHT11 controller and the DHT11 controller to validate. It runs a series of 10 nominal transmissions, followed by 83 transmissions with a protocol error and 40 transmissions with a checksum error. It also checks that the controller to validate has the same outputs as the reference controller.

-- Helper package for simulations
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.dht11_pkg.all;

package dht11_sim_pkg is

	-- random generator
	type rnd_generator is protected
		procedure rnd_init(seed1, seed2: integer);
        	impure function rnd_boolean return boolean;
        	impure function rnd_bit return bit;
        	impure function rnd_bit_vector(size: positive) return bit_vector;
        	impure function rnd_std_ulogic return std_ulogic;
        	impure function rnd_std_ulogic_vector(size: positive) return std_ulogic_vector;
        	impure function rnd_integer(min, max: integer) return integer;
        	impure function rnd_time(min, max: time) return time;
	end protected rnd_generator;

	-- check that v = v_expected. consider that don't care values ('-') always match. raise an assertion on mismatches.
	procedure check(v: std_ulogic; v_expected: std_ulogic; name: string);
	procedure check(v: std_ulogic_vector; v_expected: std_ulogic_vector; name: string);

	-- return true if min * (1.0 - margin) <= t <= max * (1.0 - margin), else false
	function check(t, min, max: time; margin: real) return boolean;

	-- prepare a transmission (bit values and delays. if 0 <= protocol_error <= 83, inject a protocol error at step #protocol_error. if 0 <= checksum_error <= 39, flip bit #checksum_error.
	procedure prepare_transmission(rnd: inout rnd_generator; protocol_error: integer range -1 to 83; checksum_error: integer range -1 to 39; d: out std_ulogic_vector(39 downto 0); t: out time_vector(0 to 83));

end package dht11_sim_pkg;

package body dht11_sim_pkg is

	type rnd_generator is protected body

		variable s1:  integer := 1;
		variable s2:  integer := 1;
		variable rnd: real;

		procedure throw is
		begin
			uniform(s1, s2, rnd);
		end procedure throw;

		procedure rnd_init(seed1, seed2: integer) is
		begin
			s1 := seed1;
			s2 := seed2;
		end procedure rnd_init;

		impure function rnd_boolean return boolean is
		begin
			throw;
			return rnd < 0.5;
		end function rnd_boolean;

		impure function rnd_bit return bit is
			variable res: bit := '0';
		begin
			if rnd_boolean then
				res := '1';
			end if;
			return res;
		end function rnd_bit;
	
		impure function rnd_bit_vector(size: positive) return bit_vector is
			variable res: bit_vector(1 to size);
		begin
			for i in 1 to size loop
				res(i) := rnd_bit;
			end loop;
			return res;
		end function rnd_bit_vector;

		impure function rnd_std_ulogic return std_ulogic is
		begin
			return to_stdulogic(rnd_bit);
		end function rnd_std_ulogic;
	
		impure function rnd_std_ulogic_vector(size: positive) return std_ulogic_vector is
		begin
			return to_stdulogicvector(rnd_bit_vector(size));
		end function rnd_std_ulogic_vector;

		impure function rnd_integer(min, max: integer) return integer is
		begin
			throw;
			return min + integer(real(max - min + 1) * rnd - 0.5);
		end function rnd_integer;

		impure function rnd_time(min, max: time) return time is
			variable res: time;
		begin
			throw;
			return min + (max - min) * rnd;
		end function rnd_time;

	end protected body rnd_generator;

	procedure check(v: std_ulogic; v_expected: std_ulogic; name: string) is
	begin
		assert v = v_expected or v_expected = '-' report "mismatch: " & name & "=" & to_string(v) & ", should be " & to_string(v_expected) severity warning;
	end procedure check;

	procedure check(v: std_ulogic_vector; v_expected: std_ulogic_vector; name: string) is
		variable ok: boolean := true;
		constant n: natural := v'length;
		variable v1: std_ulogic_vector(n-1 downto 0) := v;
		variable v2: std_ulogic_vector(n-1 downto 0) := v_expected;
	begin
		for i in 0 to n-1 loop
			if v1(i) /= v2(i) and v2(i) /= '-' then
				ok := false;
				exit;
			end if;
		end loop;
		assert ok report "mismatch: " & name & "=" & to_string(v) & ", should be " & to_string(v_expected) severity warning;
	end procedure check;

	function check(t, min, max: time; margin: real) return boolean is
	begin
		return (t >= min * (1.0 - margin)) and (t <= max * (1.0 + margin));
	end function check;

	procedure prepare_transmission(rnd: inout rnd_generator; protocol_error: integer range -1 to 83; checksum_error: integer range -1 to 39; d: out std_ulogic_vector(39 downto 0); t: out time_vector(0 to 83)) is
		variable min_durations: time_vector(0 to 83);
		variable max_durations: time_vector(0 to 83);
		variable t1: time_vector(0 to 83);
		variable d1: std_ulogic_vector(39 downto 0);
	begin
		d1(39 downto 8) := rnd.rnd_std_ulogic_vector(32);
		d1(7 downto 0) := parity(d1(39 downto 8));
		if checksum_error /= -1 then
			d1(checksum_error) := not d1(checksum_error);
		end if;
		d := d1;
		min_durations(0) := dht11_start_to_ack_min_t;
		max_durations(0) := dht11_start_to_ack_max_t;
		min_durations(1) := dht11_ack_duration_t;
		max_durations(1) := dht11_ack_duration_t;
		min_durations(2) := dht11_ack_to_bit_t;
		max_durations(2) := dht11_ack_to_bit_t;
		for i in 0 to 39 loop
			min_durations(3 + 2 * i) := dht11_bit_duration_t;
			max_durations(3 + 2 * i) := dht11_bit_duration_t;
			if d1(39 - i) = '0' then
				min_durations(4 + 2 * i) := dht11_bit0_to_next_min_t;
				max_durations(4 + 2 * i) := dht11_bit0_to_next_max_t;
			else
				min_durations(4 + 2 * i) := dht11_bit1_to_next_t;
				max_durations(4 + 2 * i) := dht11_bit1_to_next_t;
			end if;
		end loop;
		min_durations(83) := dht11_bit_duration_t;
		max_durations(83) := dht11_bit_duration_t;
		for i in 0 to 83 loop
			if protocol_error = i then
				if rnd.rnd_boolean then
					t1(i) := min_durations(i) * 0.5;
				else
					t1(i) := max_durations(i) * 1.5;
				end if;
			else
				t1(i) := rnd.rnd_time(min_durations(i), max_durations(i));
			end if;
		end loop;
		t := t1;
	end procedure prepare_transmission;

end package body dht11_sim_pkg;

-- Emulator of DHT11 sensor, with protocol error injection, checksum error injection and End Of Transmission (eot) signalling.
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;

use work.dht11_pkg.all;
use work.dht11_sim_pkg.all;

entity dht11 is
	port(
		data:           inout std_logic; -- data line
		-- debug
		protocol_error: in    integer range -1 to 83; -- index of erroneous protocol phase (-1: no error)
		checksum_error: in    integer range -1 to 39; -- index of bit flip (-1: no error)
		eot:            out   boolean -- end of transmission
	);
end entity dht11;

architecture beh of dht11 is

	signal data_in: x01;

	shared variable rnd: rnd_generator;

begin

	data_in <= to_x01(data);

	process
		variable t: time;
		variable durations: time_vector(0 to 83);
		variable d: std_ulogic_vector(39 downto 0);
		variable l: line;
	begin
		data     <= 'Z';
		eot    <= false;
		wait for dht11_reset_to_start_min_t;
		loop
			if data_in /= '0' then
				wait until data_in = '0';
			end if;
			t := now;
			eot <= false;
			wait until data_in = '1';
			assert now - t >= dht11_start_duration_min_t report "Invalid start signal duration: " & to_string(now - t) severity failure;
			prepare_transmission(rnd, protocol_error, checksum_error, d, durations);
			write(l, string'("transaction start at "));
			write(l, to_string(now));
			write(l, string'(": data="));
			write(l, to_string(d));
			if protocol_error /= -1 then
				write(l, string'(", inject protocol error at phase "));
				write(l, to_string(protocol_error));
			end if;
			if checksum_error /= -1 then
				write(l, string'(", inject checksum error at bit "));
				write(l, to_string(checksum_error));
			end if;
			writeline(output, l);
			for i in 0 to 41 loop
				data <= 'Z';
				wait for durations(2 * i);
				data <= '0';
				wait for durations(2 * i + 1);
			end loop;
			data  <= 'Z';
			eot   <= true;
			write(l, string'("transaction ends at "));
			write(l, to_string(now));
			writeline(output, l);
			wait until data_in = '1';
		end loop;
	end process;

end architecture beh;

-- Reference (behavioural) model of DHT11 controller.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dht11_pkg.all;
use work.dht11_sim_pkg.all;

-- Read data (do) format:
-- do(39 downto 24): relative humidity (do(39) = MSB)
-- do(23 downto 8):  temperature (do(23) = MSB)
-- do(7 downto 0):   check-sum = (do(39 downto 32)+do(31 downto 24)+do(23 downto 16)+do(15 downto 8)) mod 256
entity dht11_ctrl_ref is
	generic(
		abort_on_protocol_errors: boolean;                 -- Set to true to abort when a protocol error is detected
		margin:                   real;                    -- when detecting protocol errors, use (1-margin)*minimum and (1-margin)*maximum
		freq:                     positive range 1 to 1000 -- clock frequency (MHz)
	);
	port(
		clk:      in  std_ulogic;
		srstn:    in  std_ulogic; -- active low synchronous reset
		start:    in  std_ulogic;
		data_in:  in  std_ulogic;
		data_drv: out std_ulogic;
		pe:       out std_ulogic; -- protocol error
		b:        out std_ulogic; -- busy
		do:       out std_ulogic_vector(39 downto 0) -- read data
	);
end entity dht11_ctrl_ref;

architecture beh of dht11_ctrl_ref is

	constant period: time := (1.0e3 * 1 ns) / real(freq);
	constant check_margin: time := 5.0 * period; -- extra margin used in the "wait ... for ..." clauses

	signal r: std_ulogic_vector(39 downto 0);	-- shift register of received bits
	signal data_in_synchronizer: std_ulogic_vector(0 to 2); -- data_in resynchronizer
	signal di, re, fe: std_ulogic; -- synchronized data_in, and edge detectors

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if srstn = '0' then
				data_in_synchronizer <= (others => '0');
			else
				data_in_synchronizer <= data_in & data_in_synchronizer(0 to 1);
			end if;
		end if;
	end process;

	di <= data_in_synchronizer(1);
	re <= (not data_in_synchronizer(2)) and data_in_synchronizer(1);
	fe <= data_in_synchronizer(2) and (not data_in_synchronizer(1));

	process
		variable t: time;
	begin
		-- assume we always start with a reset phase
		if not (rising_edge(clk) and srstn = '0') then
			wait until rising_edge(clk) and srstn = '0';
		end if;
		data_drv <= '0';
		pe       <= '0';
		b        <= '0';
		do       <= (others => '0');
		wait until rising_edge(clk) and srstn = '1';
		b        <= '1';
		-- let reset-to-ready delay elapse
		wait until rising_edge(clk) and srstn = '0' for dht11_reset_to_start_min_t;
		l1: loop
			exit l1 when srstn = '0';
			b        <= '0';
			wait until rising_edge(clk) and (srstn = '0' or start = '1');
			exit l1 when srstn = '0';
			data_drv <= '1';
			pe       <= '0';
			b        <= '1';
			-- let start duration plus margin elapse
			wait until rising_edge(clk) and srstn = '0' for dht11_start_duration_min_t * (1.0 + margin);
			exit l1 when srstn = '0';
			data_drv <= '0';
			-- wait until data goes high
			wait until rising_edge(clk) and (srstn = '0' or re = '1') for check_margin;
			exit l1 when srstn = '0';
			if re /= '1' then
				pe <= '1';
				next l1 when abort_on_protocol_errors;
			end if;
			t := now;
			-- wait until data goes low (acknowledge low phase) but no more than max start-to-acknowledge plus margin
			wait until rising_edge(clk) and (srstn = '0' or fe = '1') for dht11_start_to_ack_max_t * (1.0 + margin) + check_margin;
			exit l1 when srstn = '0';
			if not check(now - t, dht11_start_to_ack_min_t, dht11_start_to_ack_max_t, margin) then
				pe <= '1';
				next l1 when abort_on_protocol_errors;
			end if;
			t := now;
			-- wait until data goes high (acknowledge high phase) but no more than max acknowledge duration plus margin
			wait until rising_edge(clk) and (srstn = '0' or re = '1') for dht11_ack_duration_t * (1.0 + margin) + check_margin;
			exit l1 when srstn = '0';
			if not check(now - t, dht11_ack_duration_t, dht11_ack_duration_t, margin) then
				pe <= '1';
				next l1 when abort_on_protocol_errors;
			end if;
			t := now;
			-- wait until data goes low (first bit low level) but no more than max acknowledge-to-first-bit plus margin
			wait until rising_edge(clk) and (srstn = '0' or fe = '1') for dht11_ack_to_bit_t * (1.0 + margin) + check_margin;
			exit l1 when srstn = '0';
			if not check(now - t, dht11_ack_to_bit_t, dht11_ack_to_bit_t, margin) then
				pe <= '1';
				next l1 when abort_on_protocol_errors;
			end if;
			-- loop over 40 bits
			l2: for i in 0 to 39 loop
				t := now;
				-- wait until data goes high (bit high level) but no more than max bit-low-level-duration plus margin
				wait until rising_edge(clk) and (srstn = '0' or re = '1') for dht11_bit_duration_t * (1.0 + margin) + check_margin;
				exit l1 when srstn = '0';
				if not check(now - t, dht11_bit_duration_t, dht11_bit_duration_t, margin) then
					pe <= '1';
					next l1 when abort_on_protocol_errors;
				end if;
				t := now;
				-- wait until data goes low (bit low level) but no more than max bit-one-high-level-duration plus margin
				wait until rising_edge(clk) and (srstn = '0' or fe = '1') for dht11_bit1_to_next_t * (1.0 + margin) + check_margin;
				exit l1 when srstn = '0';
				-- if bit zero
				if check(now - t, dht11_bit0_to_next_min_t, dht11_bit0_to_next_max_t, margin) then
					r <= r(38 downto 0) & '0';
				-- if bit one
				elsif check(now - t, dht11_bit1_to_next_t, dht11_bit1_to_next_t, margin) then
					r <= r(38 downto 0) & '1';
				else
					pe <= '1';
					next l1 when abort_on_protocol_errors;
				end if;
			end loop l2;
			t := now;
			-- wait until data goes high (bit high level) but no more than max bit-low-level-duration plus margin
			wait until rising_edge(clk) and (srstn = '0' or re = '1') for dht11_bit_duration_t * (1.0 + margin) + check_margin;
			exit l1 when srstn = '0';
			if not check(now - t, dht11_bit_duration_t, dht11_bit_duration_t, margin) then
				pe <= '1';
				next l1 when abort_on_protocol_errors;
			end if;
			do <= r;
			b  <= '0';
		end loop l1;
	end process;

end architecture beh;

-- Simulation environment for the standalone version of the DTH11 controller. Instantiates the DHT11 sensor, the DTH11 controller under test and the DTH11 reference controller.
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dht11_pkg.all;
use work.dht11_sim_pkg.all;

entity dht11_ctrl_sim is
	generic(
-- Set to true to abort when a protocol error is detected
		abort_on_protocol_errors: boolean:= TRUE;
-- extra margin for reset-to-start delay and protocol error detection
		margin:  real:= 0.1;
-- Clock frequency (MHz)
		freq:    positive range 1 to 1000:= 1
	);
end entity dht11_ctrl_sim;

architecture sim of dht11_ctrl_sim is

	signal data:           std_logic;
	signal clk:            std_ulogic;
	signal srstn:          std_ulogic;
	signal start:          std_ulogic;
	signal data_in:        std_ulogic;
	signal data_drv:       std_ulogic;
	signal pe:             std_ulogic;
	signal b:              std_ulogic;
	signal do:             std_ulogic_vector(39 downto 0);

	signal data_drv_ref:   std_ulogic;
	signal pe_ref:         std_ulogic;
	signal b_ref:          std_ulogic;
	signal do_ref:         std_ulogic_vector(39 downto 0);

	signal protocol_error: integer range -1 to 83; -- index of erroneous protocol phase (-1: no error)
	signal checksum_error: integer range -1 to 39; -- index of bit flip (-1: no error)
	signal eot:            boolean;
	signal srstn1:         std_ulogic;
	signal srstn2:         std_ulogic;

	shared variable rnd: rnd_generator;

	constant period: time := (1.0e3 * 1 ns) / real(freq);
	constant check_margin: time := 10.0 * period; -- margin when comparing with reference

begin

	-- Clock generator
	process
	begin
		clk <= '0';
		wait for period / 2.0;
		clk <= '1';
		wait for period / 2.0;
	end process;

	-- Tri-states buffer.
	data <= '0' when data_drv = '1' else 'H';

	-- Convert data line to 'X', '0', '1'
	data_in <= to_x01(data);

	-- Design Under Test instance
	dut: entity work.dht11_ctrl(rtl)
	generic map(
		freq => freq
	)
	port map(
		clk      => clk,
		srstn    => srstn2,
		start    => start,
		data_in  => data_in,
		data_drv => data_drv,
		pe       => pe,
		b        => b,
		do       => do
	);

	-- Reference instance
	ref: entity work.dht11_ctrl_ref(beh)
	generic map(
		abort_on_protocol_errors => abort_on_protocol_errors,
		margin => margin,
		freq => freq
	)
	port map(
		clk      => clk,
		srstn    => srstn2,
		start    => start,
		data_in  => data_in,
		data_drv => data_drv_ref,
		pe       => pe_ref,
		b        => b_ref,
		do       => do_ref
	);

	-- Sensor instance.
	-- protocol_error used to inject protocol error at phase #protocol_error (no error if protocol_error = -1).
	-- checksum_error used to inject checksum errors at bit #checksum_error (no error if checksum_error = -1).
	-- data_ref, pe_ref and ce_ref set at beginning of data sending.
	-- eot asserted at end of data sending.
	u0: entity work.dht11(beh)
	port map(
		data           => data,
		-- debug
		protocol_error => protocol_error,
		checksum_error => checksum_error,
		eot            => eot
	);

	-- Active low synchronous reset. Always asserted around falling clock edges to verify synchronism.
	srstn2 <= srstn1 and srstn;

	process
	begin
		srstn1 <= '1';
		loop
			wait until rising_edge(clk);
			wait for period / 4.0;
			srstn1 <= '0';
			wait for period / 2.0;
			srstn1 <= '1';
		end loop;
	end process;

	-- Start generator
	process
		variable t: time;
	begin
		srstn          <= '0';
		start          <= '0';
		protocol_error <= -1;
		checksum_error <= -1;
		for i in 1 to 10 loop
			wait until rising_edge(clk);
		end loop;
		srstn <= '1';
		wait for dht11_reset_to_start_min_t * (1.0 + margin);
		wait until rising_edge(clk);
		for i in 1 to 10 loop
			start <= '1';
			wait until rising_edge(clk);
			start <= '0';
			wait until rising_edge(clk) and eot;
			for j in 1 to rnd.rnd_integer(10, 50) loop
				wait until rising_edge(clk);
			end loop;
		end loop;
		for i in 0 to 83 loop
			protocol_error <= i;
			wait until rising_edge(clk);
			start <= '1';
			wait until rising_edge(clk);
			start <= '0';
			wait until rising_edge(clk) and eot;
			for j in 1 to rnd.rnd_integer(10, 50) loop
				wait until rising_edge(clk);
			end loop;
		end loop;
		protocol_error <= -1;
		for i in 0 to 39 loop
			checksum_error <= i;
			wait until rising_edge(clk);
			start <= '1';
			wait until rising_edge(clk);
			start <= '0';
			wait until rising_edge(clk) and eot;
			for j in 1 to rnd.rnd_integer(10, 50) loop
				wait until rising_edge(clk);
			end loop;
		end loop;
		checksum_error <= -1;
		finish;
	end process;

	-- check that, when data_drv or data_drv_ref changes, the other also changes for the same new value in less than check_margin
	data_drv_check: process
	begin
		if not data_drv'event then
			wait on data_drv for check_margin;
		elsif not data_drv_ref'event then
			wait on data_drv_ref for check_margin;
		end if;
		check(data_drv, data_drv_ref, "data_drv");
		wait on data_drv, data_drv_ref;
	end process data_drv_check;

	-- check that, when b or b_ref changes, the other also changes for the same new value in less than check_margin
	b_check: process
	begin
		if not b'event then
			wait on b for check_margin;
		elsif not b_ref'event then
			wait on b_ref for check_margin;
		end if;
		check(b, b_ref, "b");
		wait on b, b_ref;
	end process b_check;

	-- check that, when pe or pe_ref changes, the other also changes for the same new value in less than check_margin
	pe_check: process
	begin
		if not pe'event then
			wait on pe for check_margin;
		elsif not pe_ref'event then
			wait on pe_ref for check_margin;
		end if;
		check(pe, pe_ref, "pe");
		wait on pe, pe_ref;
	end process pe_check;

	-- check that, when do or do_ref changes, the other also changes for the same new value in less than check_margin. don't check if pe_ref asserted
	do_check: process
	begin
		if not do'event then
			wait on do for check_margin;
		elsif not do_ref'event then
			wait on do_ref for check_margin;
		end if;
		if pe_ref /= '1' then
			check(do, do_ref, "do");
		end if;
		wait on do, do_ref;
	end process do_check;

end architecture sim;
