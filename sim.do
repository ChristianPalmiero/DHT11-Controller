vsim work.dht_sim -t 10ps
add wave -position insertpoint sim:/dht_sim/dut/*
run -all
