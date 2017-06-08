-- vim: set expandtab tabstop=4 shiftwidth=4:
--
-- Simulation environment for the AXI lite version of the DTH11 controller

-- Helper package for simulations
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.dht11_pkg.all;

package dht11_axi_sim_pkg is

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

end package dht11_axi_sim_pkg;

package body dht11_axi_sim_pkg is

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
        variable d1: std_ulogic_vector(39 downto 0);
    begin
        d1(39 downto 8) := rnd.rnd_std_ulogic_vector(32);
        d1(7 downto 0) := parity(d1(39 downto 8));
        if checksum_error /= -1 then
            d1(checksum_error) := not d1(checksum_error);
        end if;
        d := d1;
        t(0) := rnd.rnd_time(dht11_start_to_ack_min_t, dht11_start_to_ack_max_t);
        t(1) := dht11_ack_duration_t;
        t(2) := dht11_ack_to_bit_t;
        for i in 0 to 39 loop
            t(3 + 2 * i) := dht11_bit_duration_t;
            if d1(39 - i) = '0' then
                t(4 + 2 * i) := rnd.rnd_time(dht11_bit0_to_next_min_t, dht11_bit0_to_next_max_t);
            else
                t(4 + 2 * i) := dht11_bit1_to_next_t;
            end if;
        end loop;
        t(83) := dht11_bit_duration_t;
        if protocol_error /= -1 then
            t(protocol_error) := 1 ms;
        end if;
    end procedure prepare_transmission;

end package body dht11_axi_sim_pkg;

library ieee;
use ieee.std_logic_1164.all;

package std_ulogic_vector_fifo_pkg is

    generic(
        width: natural
    );

    -- w-bits FIFO
    subtype word is std_ulogic_vector(width - 1 downto 0);
    type word_fifo is protected
        procedure init;
        procedure free;
        procedure push(v: word);
        impure function pop return word;
        impure function empty return boolean;
    end protected word_fifo;

end package std_ulogic_vector_fifo_pkg;

package body std_ulogic_vector_fifo_pkg is

    type word_fifo is protected body

        type word_fifo_entry;
        type word_fifo_entry_ptr is access word_fifo_entry;
        type word_fifo_entry is record
            v: word;
            nxt, prv: word_fifo_entry_ptr;
        end record word_fifo_entry;

        variable head, tail: word_fifo_entry_ptr;
        variable cnt: natural;

        procedure init is
        begin
            if cnt /= 0 then
                free;
            end if;
            head := null;
            tail := null;
            cnt := 0;
        end procedure init;

        procedure free is
            variable r: word;
        begin
            while cnt /= 0 loop
                r := pop;
            end loop;
        end procedure free;

        procedure push(v: word) is
            variable p: word_fifo_entry_ptr;
        begin
            p := new word_fifo_entry;
            p.v := v;
            p.prv := null;
            if cnt = 0 then
                p.nxt := null;
                head := p;
                tail := p;
            else
                p.nxt := head;
                head.prv := p;
                head := p;
            end if;
            cnt := cnt + 1;
        end procedure push;

        impure function pop return word is
            variable r: word;
            variable p: word_fifo_entry_ptr;
        begin
            assert cnt /= 0 report "pop empty fifo" severity failure;
            p := tail;
            r := p.v;
            tail := p.prv;
            if tail = null then
                head := null;
            else
                tail.nxt := null;
            end if;
            deallocate(p);
            cnt := cnt - 1;
            return r;
        end function pop;

        impure function empty return boolean is
        begin
            return cnt = 0;
        end function empty;

    end protected body word_fifo;

end package body std_ulogic_vector_fifo_pkg;

-- Emulator of DHT11 sensor, with protocol error injection, checksum error injection and End Of Transmission (eot) signalling. Protocol errors are emulated with a 1 ms delay instead of the delay specified in DHT11 datasheet.
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;

use work.dht11_pkg.all;
use work.dht11_axi_sim_pkg.all;

entity dht11_sensor is
    port(
        data:           inout std_logic; -- data line
        -- debug
        srstn:          in    std_ulogic;
        protocol_error: in    integer range -1 to 83; -- index of erroneous protocol phase (-1: no error)
        checksum_error: in    integer range -1 to 39; -- index of bit flip (-1: no error)
        do:             out   std_ulogic_vector(39 downto 0);
        pe:             out   std_ulogic;
        b:              out   std_ulogic;
        ce:             out   std_ulogic;
        ignore:         out   boolean; -- ignore mismatches
        eot:            out   boolean  -- end of transmission
    );
end entity dht11_sensor;

architecture beh of dht11_sensor is

    signal data_in: x01;
    signal ignore_pe: boolean;
    signal ignore_end: boolean;

    shared variable rnd: rnd_generator;

begin

    data_in <= to_x01(data);

    ignore <= ignore_pe or ignore_end;

    process
        variable t: time;
        variable durations: time_vector(0 to 83);
        variable d: std_ulogic_vector(39 downto 0);
        variable l: line;
    begin
        data   <= 'Z';
        eot    <= false;
        do     <= (others => '0');
        pe     <= '0';
        b      <= '1';
        ce     <= '0';
        ignore_pe <= false;
        wait until srstn = '1';
        wait for dht11_reset_to_start_min_t;
        b      <= '0';
        loop
            if data_in /= '0' then
                wait until data_in = '0';
            end if;
            b <= '1';
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
                if protocol_error = 2 * i then
                    ignore_pe <= true;
                end if;
                wait for durations(2 * i);
                data <= '0';
                if protocol_error = 2 * i + 1 or i = 41 then
                    ignore_pe <= true;
                end if;
                wait for durations(2 * i + 1);
            end loop;
            data  <= 'Z';
            eot   <= true;
            do    <= d;
            pe    <= '1' when protocol_error /= -1 else '0';
            b     <= '0';
            ce    <= '1' when checksum_error /= -1 else '0';
            ignore_pe <= false;
            write(l, string'("transaction ends at "));
            write(l, to_string(now));
            writeline(output, l);
            wait until data_in = '1';
        end loop;
    end process;

    process
    begin
        ignore_end <= false;
        wait for dht11_reset_to_start_min_t;
        loop
            for i in -2 to 40 loop
                wait until falling_edge(data_in);
            end loop;
            ignore_end <= true;
            wait until rising_edge(data_in);
            ignore_end <= false after 50 us;
        end loop;
    end process;

end architecture beh;

package std_ulogic_vector_fifo_pkg_2 is new work.std_ulogic_vector_fifo_pkg generic map(width => 2);
package std_ulogic_vector_fifo_pkg_34 is new work.std_ulogic_vector_fifo_pkg generic map(width => 34);

use std.env.all;

library ieee;
use ieee.std_logic_1164.all;

use work.axi_pkg.all;
use work.dht11_pkg.all;
use work.dht11_axi_sim_pkg.all;
use work.std_ulogic_vector_fifo_pkg_2.all;
use work.std_ulogic_vector_fifo_pkg_34.all;

entity dht11_axi_sim is
    generic(
        freq:    positive range 1 to 1000 := 2 -- Clock frequency (MHz)
);
end entity dht11_axi_sim;

architecture sim of dht11_axi_sim is

    signal data:            std_logic;
    signal aclk:            std_ulogic;  -- Clock
    signal aresetn:         std_ulogic;  -- Synchronous, active low, reset
    signal s0_axi_araddr:   std_ulogic_vector(29 downto 0);
    signal s0_axi_arprot:   std_ulogic_vector(2 downto 0);
    signal s0_axi_arvalid:  std_ulogic;
    signal s0_axi_rready:   std_ulogic;
    signal s0_axi_awaddr:   std_ulogic_vector(29 downto 0);
    signal s0_axi_awprot:   std_ulogic_vector(2 downto 0);
    signal s0_axi_awvalid:  std_ulogic;
    signal s0_axi_wdata:    std_ulogic_vector(31 downto 0);
    signal s0_axi_wstrb:    std_ulogic_vector(3 downto 0);
    signal s0_axi_wvalid:   std_ulogic;
    signal s0_axi_bready:   std_ulogic;
    signal s0_axi_arready:  std_ulogic;
    signal s0_axi_rdata:    std_ulogic_vector(31 downto 0);
    signal s0_axi_rresp:    std_ulogic_vector(1 downto 0);
    signal s0_axi_rvalid:   std_ulogic;
    signal s0_axi_awready:  std_ulogic;
    signal s0_axi_wready:   std_ulogic;
    signal s0_axi_bresp:    std_ulogic_vector(1 downto 0);
    signal s0_axi_bvalid:   std_ulogic;
    signal data_in:         std_ulogic;
    signal data_drv:        std_ulogic;
    signal protocol_error:  integer range -1 to 83; -- index of erroneous protocol phase (-1: no error)
    signal checksum_error:  integer range -1 to 39; -- index of bit flip (-1: no error)
    signal ignore:          boolean;
    signal eot:             boolean;
    signal do:              std_ulogic_vector(39 downto 0);
    signal pe:              std_ulogic;
    signal b:               std_ulogic;
    signal ce:              std_ulogic;

    constant valid_address: std_ulogic_vector(29 downto 3) := (others => '0');
    constant period: time := (1.0e3 * 1 ns) / real(freq);

begin

    -- clock
    process
    begin
        aclk <= '0';
        wait for period / 2.0;
        aclk <= '1';
        wait for period / 2.0;
    end process;

    -- data line
    data <= '0' when data_drv = '1' else 'H';
    data_in <= to_x01(data);

    -- design under test
    dut: entity work.dht11_axi(rtl)
    generic map(
        freq => freq
    )
    port map(
        aclk           => aclk,
        aresetn        => aresetn,
        s0_axi_araddr  => s0_axi_araddr,
        s0_axi_arprot  => s0_axi_arprot,
        s0_axi_arvalid => s0_axi_arvalid,
        s0_axi_rready  => s0_axi_rready,
        s0_axi_awaddr  => s0_axi_awaddr,
        s0_axi_awprot  => s0_axi_awprot,
        s0_axi_awvalid => s0_axi_awvalid,
        s0_axi_wdata   => s0_axi_wdata,
        s0_axi_wstrb   => s0_axi_wstrb,
        s0_axi_wvalid  => s0_axi_wvalid,
        s0_axi_bready  => s0_axi_bready,
        s0_axi_arready => s0_axi_arready,
        s0_axi_rdata   => s0_axi_rdata,
        s0_axi_rresp   => s0_axi_rresp,
        s0_axi_rvalid  => s0_axi_rvalid,
        s0_axi_awready => s0_axi_awready,
        s0_axi_wready  => s0_axi_wready,
        s0_axi_bresp   => s0_axi_bresp,
        s0_axi_bvalid  => s0_axi_bvalid,
        data_in        => data_in,
        data_drv       => data_drv
    );

    -- Sensor instance.
    -- protocol_error used to inject protocol error at phase #protocol_error (no error if protocol_error = -1).
    -- checksum_error used to inject checksum errors at bit #checksum_error (no error if checksum_error = -1).
    -- eot asserted at end of data sending.
    u0: entity work.dht11_sensor(beh)
    port map(
        data           => data,
        -- debug
        srstn          => aresetn,
        protocol_error => protocol_error,
        checksum_error => checksum_error,
        do             => do,
        pe             => pe,
        b              => b,
        ce             => ce,
        ignore         => ignore,
        eot            => eot
    );

    -- protocol and checksum errors
    process
    begin
        protocol_error <= -1;
        checksum_error <= -1;
        for i in 1 to 1 loop
            wait until rising_edge(aclk) and eot;
            wait until rising_edge(aclk) and (not eot);
        end loop;
        for i in 0 to 83 loop
            protocol_error <= i;
            wait until rising_edge(aclk) and eot;
            wait until rising_edge(aclk) and (not eot);
        end loop;
        protocol_error <= -1;
        for i in 0 to 39 loop
            checksum_error <= i;
            wait until rising_edge(aclk) and eot;
            wait until rising_edge(aclk) and (not eot);
        end loop;
        checksum_error <= -1;
        wait for 1 sec;
        finish;
    end process;

    -- write address
    process(aclk)
        variable rnd: rnd_generator;
        type states is (idle, waiting);
        variable state: states;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                s0_axi_awaddr  <= (others => '0');
                s0_axi_awprot  <= "010";
                s0_axi_awvalid <= '0';
                state := idle;
            else
                if state = waiting and s0_axi_awready = '1' then
                    s0_axi_awvalid <= '0';
                    state := idle;
                end if;
                if state = idle and rnd.rnd_integer(1, 3) = 1 then
                    s0_axi_awaddr <= rnd.rnd_std_ulogic_vector(30);
                    if rnd.rnd_boolean then -- Valid address
                        s0_axi_awaddr(29 downto 3) <= valid_address;
                    end if;
                    s0_axi_awvalid <= '1';
                    state := waiting;
                end if;
            end if;
        end if;
    end process;

    -- write data
    process(aclk)
        variable rnd: rnd_generator;
        type states is (idle, waiting);
        variable state: states;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                s0_axi_wdata  <= (others => '0');
                s0_axi_wstrb  <= (others => '0');
                s0_axi_wvalid <= '0';
                state := idle;
            else
                if state = waiting and s0_axi_wready = '1' then
                    s0_axi_wvalid <= '0';
                    state := idle;
                end if;
                if state = idle and rnd.rnd_integer(1, 3) = 1 then
                    s0_axi_wdata <= rnd.rnd_std_ulogic_vector(32);
                    s0_axi_wstrb <= rnd.rnd_std_ulogic_vector(4);
                    s0_axi_wvalid <= '1';
                    state := waiting;
                end if;
            end if;
        end if;
    end process;

    -- write response
    process(aclk)
        variable rnd: rnd_generator;
        variable rsp: std_ulogic_vector(1 downto 0);
        variable rsp_fifo: work.std_ulogic_vector_fifo_pkg_2.word_fifo;
        variable rsp_fifo_tmp: work.std_ulogic_vector_fifo_pkg_2.word_fifo;
        variable awcnt: natural;
        variable wcnt: natural;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                s0_axi_bready <= '0';
                rsp_fifo.init;
                rsp_fifo_tmp.init;
                awcnt := 0;
                wcnt := 0;
            else
                s0_axi_bready <= rnd.rnd_std_ulogic;
                if s0_axi_awvalid = '1' and s0_axi_awready = '1' then
                    if s0_axi_awaddr(29 downto 3) = valid_address then
                        rsp_fifo_tmp.push(axi_resp_slverr);
                    else
                        rsp_fifo_tmp.push(axi_resp_decerr);
                    end if;
                    awcnt := awcnt + 1;
                end if;
                if s0_axi_wvalid = '1' and s0_axi_wready = '1' then
                    wcnt := wcnt + 1;
                end if;
                if awcnt > 0 and wcnt > 0 then
                    rsp := rsp_fifo_tmp.pop;
                    rsp_fifo.push(rsp);
                    awcnt := awcnt - 1;
                    wcnt := wcnt - 1;
                end if;
                if s0_axi_bvalid = '1' and s0_axi_bready = '1' then
                    assert not rsp_fifo.empty report "write response before write request" severity failure;
                    rsp := rsp_fifo.pop;
                    assert rsp = s0_axi_bresp report "unexpected write response: " & to_string(s0_axi_bresp) & " (expected " & to_string(rsp) & ")" severity warning;
                end if;
            end if;
        end if;
    end process;

    -- aresetn
    process
    begin
        aresetn <= '0';
        wait until rising_edge(aclk) and aresetn = '0';
        wait for 1 ms;
        aresetn <= '1';
        wait;
    end process;

    -- read address
    process(aclk)
        variable rnd: rnd_generator;
        type states is (idle, waiting);
        variable state: states;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                s0_axi_araddr  <= (others => '0');
                s0_axi_arprot  <= "010";
                s0_axi_arvalid <= '0';
                state := idle;
            else
                if state = waiting and s0_axi_arready = '1' then
                    s0_axi_arvalid <= '0';
                    state := idle;
                end if;
                if state = idle and rnd.rnd_integer(1, 3) = 1 then
                    s0_axi_araddr <= rnd.rnd_std_ulogic_vector(30);
                    if rnd.rnd_boolean then -- Valid address
                        s0_axi_araddr(29 downto 3) <= valid_address;
                    end if;
                    s0_axi_arvalid <= '1';
                    state := waiting;
                end if;
            end if;
        end if;
    end process;

    -- read response
    process(aclk)
        variable rnd: rnd_generator;
        variable rsp: std_ulogic_vector(33 downto 0);
        variable rsp_fifo: work.std_ulogic_vector_fifo_pkg_34.word_fifo;
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                s0_axi_rready <= '0';
                rsp_fifo.init;
            else
                s0_axi_rready <= rnd.rnd_std_ulogic;
                if s0_axi_arvalid = '1' and s0_axi_arready = '1' then
                    if s0_axi_araddr(29 downto 3) = valid_address then
                        if s0_axi_araddr(2) = '0' then
                            rsp_fifo.push(axi_resp_okay & do(39 downto 8));
                        else
                            rsp_fifo.push(axi_resp_okay & x"0000000" & '0' & pe & b & ce);
                        end if;
                    else
                        rsp_fifo.push(axi_resp_decerr & x"00000000");
                    end if;
                end if;
                if s0_axi_rvalid = '1' and s0_axi_rready = '1' then
                    assert not rsp_fifo.empty report "read response before read request" severity failure;
                    rsp := rsp_fifo.pop;
                    assert rsp(33 downto 32) = s0_axi_rresp report "unexpected read response: " & to_string(s0_axi_rresp) & " (expected " & to_string(rsp(33 downto 32)) & ")" severity failure;
                    assert ignore or pe = '1' or s0_axi_rresp /= axi_resp_okay or rsp(31 downto 0) = s0_axi_rdata report "unexpected read data: " & to_string(s0_axi_rdata) & " (expected " & to_string(rsp(31 downto 0)) & ")" severity failure;
                end if;
            end if;
        end if;
    end process;

end architecture sim;

