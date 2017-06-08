-- AXI4 lite wrapper around the DHT11 controller dht11_ctrl(rtl). It contains two 32-bits read-only registers:
--
-- Address                Name    Description
-- 0x00000000-0x00000003  DATA    read-only, 32-bits, data register
-- 0x00000004-0x00000007  STATUS  read-only, 32-bits, status register
-- 0x00000008-...         -       unmapped
--
-- Writing to DATA or STATUS shall be answered with a SLVERR response. Reading or writing to the unmapped address space [0x00000008,...] shall be answered with a DECERR response.
--
-- The reset value of DATA is 0xffffffff.
-- DATA(31 downto 16) = last sensed humidity level, Most Significant Bit: DATA(31).
-- DATA(15 downto 0) = last sensed temperature, MSB: DATA(15).
--
-- The reset value of STATUS is 0x00000000.
-- STATUS = (2 => PE, 1 => B, 0 => CE, others => '0'), where PE, B and CE are the protocol error, busy and checksum error flags, respectively.
--
-- After the reset has been de-asserted, the wrapper waits for 1 second and sends the first start command to the controller. Then, it waits for one more second, samples DO(39 downto 8) (the sensed values) in DATA, samples the PE and CE flags in STATUS, and sends a new start command to the controller. And so on every second, until the reset is asserted. When the reset is de-asserted, every rising edge of the clock, the B output of the DHT11 controller is sampled in the B flag of STATUS.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;

entity dht11_axi is
	generic(
		freq:       positive range 1 to 1000 -- Clock frequency (MHz)
	);
	port(
		aclk:           in  std_ulogic;  -- Clock
		aresetn:        in  std_ulogic;  -- Synchronous, active low, reset
		
		--------------------------------
		-- AXI lite slave port s0_axi --
		--------------------------------
		-- Inputs (master to slave) --
		------------------------------
		-- Read address channel
		s0_axi_araddr:  in  std_ulogic_vector(29 downto 0);
		s0_axi_arprot:  in  std_ulogic_vector(2 downto 0);
		s0_axi_arvalid: in  std_ulogic;
		-- Read data channel
		s0_axi_rready:  in  std_ulogic;
		-- Write address channel
		s0_axi_awaddr:  in  std_ulogic_vector(29 downto 0);
		s0_axi_awprot:  in  std_ulogic_vector(2 downto 0);
		s0_axi_awvalid: in  std_ulogic;
		-- Write data channel
		s0_axi_wdata:   in  std_ulogic_vector(31 downto 0);
		s0_axi_wstrb:   in  std_ulogic_vector(3 downto 0);
		s0_axi_wvalid:  in  std_ulogic;
		-- Write response channel
		s0_axi_bready:  in  std_ulogic;
		-------------------------------
		-- Outputs (slave to master) --
		-------------------------------
		-- Read address channel
		s0_axi_arready: out std_ulogic;
		-- Read data channel
		s0_axi_rdata:   out std_ulogic_vector(31 downto 0);
		s0_axi_rresp:   out std_ulogic_vector(1 downto 0);
		s0_axi_rvalid:  out std_ulogic;
		-- Write address channel
		s0_axi_awready: out std_ulogic;
		-- Write data channel
		s0_axi_wready:  out std_ulogic;
		-- Write response channel
		s0_axi_bresp:   out std_ulogic_vector(1 downto 0);
		s0_axi_bvalid:  out std_ulogic;

		data_in:        in  std_ulogic;
		data_drv:       out std_ulogic
  );
end entity dht11_axi;

architecture rtl of dht11_axi is
	signal start:            std_ulogic;
	signal pe:               std_ulogic;
	signal b:                std_ulogic;
	signal ce:               std_ulogic;
	signal do:               std_ulogic_vector(39 downto 0);
	signal data:             std_ulogic_vector(31 downto 0);
	signal status:           std_ulogic_vector(31 downto 0);
        signal awaddr_signal:    std_ulogic_vector(29 downto 0);
	signal araddr_signal:    std_ulogic_vector(29 downto 0);
        type write_state_type is (IDLE, WRITE_VALID, DEC_ERROR, SLAVE_ERROR);
        signal current_state_write, next_state_write: write_state_type;
        type read_state_type is (IDLE, DEC_ERROR, OKAY);
        signal current_state_read, next_state_read: read_state_type;
	constant mask:		std_ulogic_vector(29 downto 0) := "11" & x"FFFFFFC";
	constant base_data:	std_ulogic_vector(29 downto 0) := "00" & x"0000000";
	constant base_status:	std_ulogic_vector(29 downto 0) := "00" & x"0000004";
        signal count:		integer range 0 to freq * 1000000;
        signal signal_arready:  std_ulogic; --arready internal to sample addresses
        signal sampled_axi_araddr:   std_ulogic_vector(29 downto 0);
begin

        Checksum_controller: process(do)
        variable sum: unsigned(7 DOWNTO 0);
        variable sum_int: std_ulogic_vector(7 downto 0);
        begin
          sum:= unsigned(do(39 DOWNTO 32)) + unsigned(do(31 DOWNTO 24)) 
                + unsigned(do(23 DOWNTO 16)) + unsigned(do(15 DOWNTO 8));
          sum_int:= std_ulogic_vector(sum);
        if sum_int = do(7 downto 0) then
          ce <= '0';
        else
          ce <= '1';
        end if;
        end process Checksum_controller;   
        
        ADDRESS_SAMPLER: process(aclk)
        begin 
          if(aclk' event and aclk = '1') then
            if(aresetn = '0') then 
              sampled_axi_araddr <= (others => '0');
            elsif (signal_arready = '1') then
              sampled_axi_araddr <= s0_axi_araddr;
            end if;
           end if;
        end process;   
 
        MUX: process(sampled_axi_araddr, data, status)
        begin
            if (sampled_axi_araddr and mask) = base_data then
              s0_axi_rdata <= data;
            elsif (sampled_axi_araddr and mask) = base_status then
              s0_axi_rdata <= status;
            end if;
        end process;

        REGS: process(aclk)
        begin        
          if aclk'event and aclk='1' then
            if aresetn='0' then
              data <= (others=>'1');
              status <= (others=>'0');
            else 
              data <= do(39 downto 8);
              status <= (2=>pe, 1=>b, 0=>ce, others=>'0');
            end if;
          end if;
        end process REGS;

        awaddr_signal <= s0_axi_awaddr and mask; 
        araddr_signal <= s0_axi_araddr and mask;

        TRANSITION: process(aclk)
        begin
          if(aclk' event and aclk = '1') then
            if(aresetn = '0') then
              current_state_read  <= IDLE;
              current_state_write <= IDLE;
            else
              current_state_read  <= next_state_read;
              current_state_write <= next_state_write;
 	    end if;
          end if;
        end process TRANSITION;

       COUNTER: process(aclk)
       begin
       if(aclk'event and aclk='1') then
         start <= '0';
         if(aresetn='0') then
           count <= 0;
         else
           if(count = freq * 1000000) then   --set to -2 to compensate
	     start <= '1';            --the cc lost when set the counter
	     count <= 0;
           else
	     count <= count + 1;
           end if;
          end if;
        end if;
        end process COUNTER;
	
	WRITE_NEXT_STATE: process(current_state_write, s0_axi_wvalid, s0_axi_awvalid, s0_axi_arvalid, awaddr_signal, s0_axi_bready)
        begin
         next_state_write <= current_state_write;
         case (current_state_write) is
           when IDLE  => 
   	     if (s0_axi_wvalid = '1' and  s0_axi_awvalid = '1') then
               if (s0_axi_araddr = s0_axi_awaddr) then  -- if read and write addresses are equal, read first, write next
                 if (s0_axi_arvalid = '0') then
	           next_state_write <= WRITE_VALID;
                 else	
		   next_state_write <= IDLE;
                 end if;
               else
	         next_state_write <= WRITE_VALID;
               end if;
             else
               next_state_write <= IDLE;
             end if;
           when WRITE_VALID =>
             if (awaddr_signal = base_data or awaddr_signal = base_status) then
               next_state_write <= SLAVE_ERROR;
             else 
               next_state_write <= DEC_ERROR;
             end if;
           when SLAVE_ERROR =>
             if (s0_axi_bready = '1') then 
               next_state_write <= IDLE;
             else
	       next_state_write <= SLAVE_ERROR;
             end if;
           when DEC_ERROR =>
	     if (s0_axi_bready = '1') then
	       next_state_write <= IDLE;
	     else
	       next_state_write <= DEC_ERROR;
	     end if;
          end case;
	end process WRITE_NEXT_STATE;

        READ_NEXT_STATE: process(current_state_read, s0_axi_arvalid, araddr_signal, s0_axi_rready)
        begin
         next_state_read <= current_state_read;
         case (current_state_read) is
           when IDLE  =>
	     if (s0_axi_arvalid = '1') then
               if (araddr_signal = base_data or araddr_signal = base_status) then
                 next_state_read <= OKAY;
               else
                 next_state_read <= DEC_ERROR;
               end if;
             else
	       next_state_read <= IDLE;
             end if;
           when OKAY =>
             if (s0_axi_rready = '1') then
               next_state_read <= IDLE;
             else
               next_state_read <= OKAY;
             end if;
           when DEC_ERROR =>
             if (s0_axi_rready = '1') then
               next_state_read <= IDLE;
             else
               next_state_read <= DEC_ERROR;
             end if;
           end case;
        end process READ_NEXT_STATE;

        WRITE_OUTPUT: PROCESS(current_state_write)
  	  begin
            s0_axi_awready  <= '0';
            s0_axi_wready   <= '0';
            s0_axi_bresp    <= "00";
            s0_axi_bvalid   <= '0';
            case current_state_write  is
              when IDLE         => NULL ; 
              WHEN WRITE_VALID  => s0_axi_awready  <= '1'; s0_axi_wready  <= '1'; 
              WHEN DEC_ERROR    => s0_axi_bresp <= "11"; s0_axi_bvalid <= '1';
              WHEN SLAVE_ERROR  => s0_axi_bresp <= "10"; s0_axi_bvalid <= '1';
            END CASE;
          END PROCESS WRITE_OUTPUT;

        READ_OUTPUT: PROCESS(current_state_read)
          begin
            s0_axi_arready  <= '0';
            signal_arready  <= '0';
            s0_axi_rresp    <= "00";
            s0_axi_rvalid   <= '0';
            case current_state_read is 
              when IDLE         => s0_axi_arready <= '1'; signal_arready  <= '1'; 
              WHEN DEC_ERROR    => s0_axi_rresp <= "11"; s0_axi_rvalid <= '1';
              WHEN OKAY         => s0_axi_rresp <= "00"; s0_axi_rvalid <= '1';
            END CASE;
          END PROCESS READ_OUTPUT;

	u0: entity work.dht11_ctrl(rtl)
	generic map(
		freq => freq
	)
	port map(
		clk      => aclk,
		srstn    => aresetn,
        	start    => start,
		data_in  => data_in,
		data_drv => data_drv,
		pe       => pe,
		b        => b,
		do       => do
	);

end architecture rtl;
