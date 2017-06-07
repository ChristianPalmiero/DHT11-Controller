-- DTH11 controller wrapper, AXI lite version, top level

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity dht11_axi_top is
	generic(
		freq:    positive range 1 to 1000 -- Clock frequency (MHz)
	);
	port(
		aclk:           in  std_ulogic;  
		aresetn:        in  std_ulogic;  
		s0_axi_araddr:  in  std_ulogic_vector(29 downto 0);
		s0_axi_arprot:  in  std_ulogic_vector(2 downto 0);
		s0_axi_arvalid: in  std_ulogic;
		s0_axi_rready:  in  std_ulogic;
		s0_axi_awaddr:  in  std_ulogic_vector(29 downto 0);
		s0_axi_awprot:  in  std_ulogic_vector(2 downto 0);
		s0_axi_awvalid: in  std_ulogic;
		s0_axi_wdata:   in  std_ulogic_vector(31 downto 0);
		s0_axi_wstrb:   in  std_ulogic_vector(3 downto 0);
		s0_axi_wvalid:  in  std_ulogic;
		s0_axi_bready:  in  std_ulogic;
		s0_axi_arready: out std_ulogic;
		s0_axi_rdata:   out std_ulogic_vector(31 downto 0);
		s0_axi_rresp:   out std_ulogic_vector(1 downto 0);
		s0_axi_rvalid:  out std_ulogic;
		s0_axi_awready: out std_ulogic;
		s0_axi_wready:  out std_ulogic;
		s0_axi_bresp:   out std_ulogic_vector(1 downto 0);
		s0_axi_bvalid:  out std_ulogic;
		data:           inout std_logic
	);
end entity dht11_axi_top;

architecture rtl of dht11_axi_top is

	signal data_in:   std_ulogic;
	signal data_drv:  std_ulogic;
	signal data_drvn: std_ulogic;

begin

	u0: entity work.dht11_axi(rtl)
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

	u1 : iobuf
	generic map (
		drive => 12,
		iostandard => "lvcmos33",
		slew => "slow")
	port map (
		o  => data_in,
		io => data,
		i  => '0',
		t  => data_drvn
	);

	data_drvn <= not data_drv;

end architecture rtl;
