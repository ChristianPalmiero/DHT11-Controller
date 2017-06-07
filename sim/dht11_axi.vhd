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
        type write_state_type is (IDLE, WRITE_VALID, DEC_ERROR, SLAVE_ERROR);
        type current_state_write, next_state_write: write_state_type;
        type read_state_type is (IDLE, DEC_ERROR, OKAY);
        type current_state_read, next_state_read: read_state_type;
	constant mask:		std_ulogic_vector(29 downto 0) := x"FFFFFFFC";
	constant base_data:	std_ulogic_vector(29 downto 0) := x"00000000";
	constant base_status:	std_ulogic_vector(29 downto 0) := x"00000004";
   
begin
        
        

        awaddr_signal <= s0_axi_awaddr and mask; 
        
        TRANSITION: process(clk)
        begin
          if(clk' event and clk = '1') then
            if(rst = '1') then
              current_state_read  <= IDLE;
              current_state_write <= IDLE;
            else
              current_state_read  <= next_state_read;
              current_state_write <= next_state_write;
 	    end if;
          end if;
        end process TRANSITION;
	
	WRITE_NEXT_STATE: process(current_state_write, s0_axi_wvalid, s0_axi_awvalid, s0_axi_arvalid, awaddr_signal, s0_axi_bready)
        begin
         next_state_write <= current_state_write;
         case (current_state_write) is
           when IDLE  => 
   	     if (s0_axi_wvalid = '1' and  s0_axi_awvalid = '1' and  s0_axi_arvalid = '0') then
	       next_state_write <= WRITE_VALID;
             else
               next_state_write <= IDLE;
             end if;
           when WRITE_VALID =>
             if (awaddr_signal = base_data or awaddr_signal = base_status) then
               next_state_write <= SLAVE_ERROR;
             else 
               next_state_write <= DEC_ERROR;
             end if;
    




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
