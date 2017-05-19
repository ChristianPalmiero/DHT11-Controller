set part "xc7z010clg400-1"
set board "digilentinc.com:zybo:part0:1.0"
set frequency 50
array set ios {
  "clk"           { "E7" "LVCMOS33" }
  "rst"           { "" "LVCMOS33" }
  "btn"           { "R18" "LVCMOS33" }
  "sw[3]"         { "G15" "LVCMOS33" }
  "sw[2]"         { "P15" "LVCMOS33" }
  "sw[1]"         { "W13" "LVCMOS33" }
  "sw[0]"         { "T16" "LVCMOS33" }
  "data_in"       { "" "LVCMOS33" }
  "data_drv"      { "" "LVCMOS33" }
  "led[0]"        { "M14" "LVCMOS33" }
  "led[1]"        { "M15" "LVCMOS33" }
  "led[2]"        { "G14" "LVCMOS33" }
  "led[3]"        { "D18" "LVCMOS33" }
}

puts "*********************************************"
puts "Summary of build parameters"
puts "*********************************************"
puts "Board: $board"
puts "Part: $part"
puts "Frequency: $frequency MHz"
puts "*********************************************"

#####################
# Create DHT11 project #
#####################
create_project -part $part -force dht11_sa dht11_sa
add_files datapath.vhd debouncer.vhd CU.vhd dht11_ctrl.vhd dht11_sa.vhd
import_files -force -norecurse
ipx::package_project -root_dir dht11_sa -vendor www.telecom-paristech.fr -library DHT11_SA -force dht11_sa
close_project

############################
## Create top level design #
############################
set top top
create_project -part $part -force $top .
set_property board_part $board [current_project]
set_property ip_repo_paths { ./dht11_sa } [current_fileset]
update_ip_catalog
create_bd_design "$top"
set ps7 [create_bd_cell -type ip -vlnv [get_ipdefs *xilinx.com:ip:processing_system7:*] ps7]
set dht11_sa [create_bd_cell -type ip -vlnv [get_ipdefs *www.telecom-paristech.fr:DHT11_SA:dht11_sa:*] dht11_sa]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } $ps7
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {0}] $ps7
set_property -dict [list CONFIG.freq $frequency] $dht11_sa

# Interconnections
# Primary IOs
create_bd_port -dir I -type clk clk
connect_bd_net [get_bd_pins /dht11_sa/clk] [get_bd_ports clk]
create_bd_port -dir I -type rst rst
connect_bd_net [get_bd_pins /dht11_sa/rst] [get_bd_ports rst]
create_bd_port -dir I -type data btn
connect_bd_net [get_bd_pins /dht11_sa/btn] [get_bd_ports btn]
create_bd_port -dir I -type data -from 3 -to 0 sw
connect_bd_net [get_bd_pins /dht11_sa/sw] [get_bd_ports sw]
create_bd_port -dir I -type data data_in
connect_bd_net [get_bd_pins /dht11_sa/data_in] [get_bd_ports data_in]
create_bd_port -dir O -type data data_drv
connect_bd_net [get_bd_pins /dht11_sa/data_drv] [get_bd_ports data_drv]
create_bd_port -dir O -type data -from 3 -to 0 led
connect_bd_net [get_bd_pins /dht11_sa/led] [get_bd_ports led]

# Synthesis flow
validate_bd_design
set files [get_files *$top.bd]
generate_target all $files
add_files -norecurse -force [make_wrapper -files $files -top]
save_bd_design
set run [get_runs synth*]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none $run
launch_runs $run
wait_on_run $run
open_run $run

# IOs
foreach io [ array names ios ] {
  set pin [ lindex $ios($io) 0 ]
  set std [ lindex $ios($io) 1 ]
  set_property package_pin $pin [get_ports $io]
  set_property iostandard $std [get_ports [list $io]]
}

# Clocks and timing
create_clock -name clk -period [expr 1000.0 / $frequency] [get_ports clk]
#set_false_path -from clk -to [get_ports led[*]]
#set_false_path -from [get_ports areset] -to clk

# Implementation
save_constraints
set run [get_runs impl*]
reset_run $run
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true $run
launch_runs -to_step write_bitstream $run
wait_on_run $run

# Messages
set rundir $top.runs/$run
puts ""
puts "\[VIVADO\]: done"
puts "  bitstream in $rundir/${top}_wrapper.bit"
puts "  resource utilization report in $rundir/${top}_wrapper_utilization_placed.rpt"
puts "  timing report in $rundir/${top}_wrapper_timing_summary_routed.rpt"
