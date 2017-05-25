dht11_axi.vhd: axi_pkg.vhd dht11_ctrl.vhd

dht11_ctrl.vhd: dht11_pkg.vhd

dht11_ctrl_sim.vhd: dht11_pkg.vhd dht11_ctrl.vhd

dht11_sa.vhd: debouncer.vhd dht11_ctrl.vhd

dht11_sa_top.vhd: dht11_sa.vhd

dht11_sa_sim.vhd: debouncer.vhd dht11_pkg.vhd dht11_sa.vhd dht11_ctrl_sim.vhd

