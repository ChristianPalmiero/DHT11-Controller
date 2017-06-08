dht11_axi_sim.vhd: dht11_axi.vhd 

dht11_axi.vhd: axi_pkg.vhd dht11_ctrl.vhd

dht11_ctrl.vhd: datapath.vhd CU.vhd dht11_pkg.vhd 

dht11_ctrl_sim.vhd: datapath.vhd CU.vhd dht11_pkg.vhd dht11_ctrl.vhd 

dht11_sa.vhd: datapath.vhd CU.vhd debouncer.vhd dht11_ctrl.vhd

dht11_sa_top.vhd: dht11_sa.vhd

dht11_sa_sim.vhd: datapath.vhd CU.vhd debouncer.vhd dht11_pkg.vhd dht11_sa.vhd dht11_ctrl_sim.vhd  

