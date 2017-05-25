# DHT11 Controller Project
## Intro
This project consist of a complete digital hardware design of a controller for the [DHT11 Humidity and Temperature Sensor](DTH11.pdf) manufactured by D-Robotics UK:
* Specification
* Architecture design
* Development of the hardware model in VHDL
* Validation by simulation
* Synthesis for the [Zybo board](zybo_rm.pdf), performance evaluation and optimization

## Authors
* [Christian Palmiero](https://github.com/ChristianPalmiero)
* Francesco Condemi
* Marco Coletta

## Detailed Specifications
### Global
- 4 ms Communication  
- 40 bits complete data (Most Significant Bits first)  

### To start:   
#### MCU drive:  
1. GND (meaning 0) at least 18 ms  
2. VCC (meaning 1) between (20-40) μs

#### DHT drive:  
1. GND for 80 μs  
2. VCC for 80 μs  

### To send data:
For every bit of data :  
  1. GND for 50 μs  
  2. VCC for 26-28 μs to send 0 OR VCC for 70 μs to send 1

### Inputs and Outputs  
#### Button:  
We use the push button to start to read for the sensor.  
But :   
  - After power up, the button should have no effect until 1 sec  
  - Use debouncing function to correct default of the button  

#### Switches:  
  - 1 switch to select the data to display : temperature or humidity (SW0). When the switch is set to 1, we read the humidity level, when it is 0, we read the temperature.  
  - 2 switches to select 4 bits out of the 16 bits (4-bit nibbles) of the data to display (SW1 and SW2).  

When SW1=0 and SW2=0, we display the 4 less significant bits of the data.  
When SW1=0 and SW2=1, we display the 5th to 8th less significant bits.  
When SW1=1 and SW2=0, we display the 5th to 8th most significant bits.  
When SW1=1 and SW2=1, we display the 4 most significant bits of the data.  

```
    SW1,SW2   SW1,SW2  SW1,SW2  SW1,SW2
     1   1     1  0     0  1     0  0
   +--------+--------+--------+--------+
   |  0101  |  0110  |  0001  |  1100  |  -> 16 bits to display
   +--------+--------+--------+--------+
```

  - 1 switch to put the LEDs in an "error/check state":  

```
      3      2      1      0    
   +------+------+------+------+
   |  PE  | SW0  |  B   |  CE  |
   +------+------+------+------+
```

PE (Protocol error): if this LED in on this means that there was an error in the protocol, for example the MCU is waiting for a bit of data that is not coming or the DTH is not doing what is expected.  
SW0: display the value of SW0 (when this bit is set, it means that the switch 0 is set).  
B (busy bit): indicates that the delay after the power up is not passed or that the sensor is currently sending data. When the bit is set,  we shouldn't try to read from the sensor.  
CE (Checksum error): if this bit is set, it means that the checksum sent and the one computed are different -> the data read from the sensor might be false.  

Remark: when the PE bit is set, we can use the other LED to display the kind of protocol error occurs but this may be not worthwhile and complicated.  

#### Overview
```
    SW0,SW1,SW2  
     1   1   1      1  1  0      1  0  1      1  0  0  |  0   1   1     0  1  0      0  0  1      0  0  0  |  not displayed
   +------------+------------+------------+------------+------------+------------+------------+------------+-----------------+
   |    1010    |    0110    |    0001    |    0100    |    0010    |    1110    |    0011    |    1100    |     01011001    |  -> 40 bits from the DHT11 sensor
   +------------+------------+------------+------------+------------+------------+------------+------------+-----------------+
                      Humidity data                    |                   Temperature                     |     CHECK SUM

```

#### LEDs :  
We use the 4 LEDs to display 4 bits of data (the 4 bits chosen by the switches SW1 and SW2 or the specific states specified above).  


```
      11     10     01     00
   +------+------+------+------+
   |  L3  |  L2  |  L1  |  L0  |
   +------+------+------+------+
```

## Architecture Design
### Common Interface

The DHT11 controller and the DHT11 sensor communicates with a one-bit communication bit with a pull-up resistor and a drive low protocol.

![alt text][top-entity]

[top-entity]: https://github.com/ChristianPalmiero/DHT11_Controller/blob/master/img/top_entity.png "Top Entity"

```vhdl
library ieee;
use ieee.std_logic_1164.all;
...

entity dht11_top is
  port(...
       data:    inout std_logic
       ...
  );
end entity dht11_top;

architecture rtl of dht11_top is
  signal data_in:  std_ulogic;
  signal data_drv: std_ulogic;
  ...
begin
  data    <= '0' when data_drv = '1' else 'H';
  data_in <= data;
  ...
end architecture rtl;
```

### DHT11 Controller Internals 

The DHT11 controller is composed of a collection of functional units, the datapath, and of a complex FSM, the control unit. 
  
#### Datapath Block Diagram
![alt text][dp]

[dp]: https://github.com/ChristianPalmiero/DHT11_Controller/blob/master/img/dp.png "Datapath"

#### Datapath Technical Details

The datapath has been designed at RT-level according to a behavioral view. It consists of the following processes:
* **SIPO**: it describes a Serial In Parallel Out register, that stores input data in a serial fashion and makes it available at the output in a parallel form. The SIPO takes as input the clock, a synchronous active high reset, an input serial data and a shift enable that enables the input serial data storage and the internal data shift. The SIPO outputs a 40-bit data signal and a final counter signal, that points out that all the 40 bits have been stored inside the register.
* **MUXES**: it describes a cascade of multiplexers that, according to the value of three input switches (SW0, SW1, SW2), outputs the corresponding 4-bit nibble of the temperature/humidity data coming from the SIPO that the user wants to display.
* **CHECKSUM_CONTROLLER**: it describes a combinational block that takes as input the the 40-bit data coming from the SIPO, computes the checksum and compares it with the one that has been computed and sent by the sensor. The checksum controller outputs the checksum error bit.
* **MUX**: it describes a multiplexer that, according to the value of SW3, either displays the 4-bit nibble output by the MUXES process (check state) or gathers together and shows some error information coming from the control unit (error state). The selected output is sent to the LEDs.
* **COUNTER** : it describes a programmable up counter that is initialised with a value generated by the control unit and that counts upwards, from 0 to the programmed value. The counter has the main purpose of establishing the correct data acquisition timing depicted on the DHT11 reference manual. The COUNTER outputs the current value and a final counter signal, that points out that the final programmed value has been reached.
* **COMPARATOR**: it describes a threshold comparator that checks whether the current counter value is in between two thresholds. The thresholds are computed by adding to and subtracting from a central value a delta (margin). The comparator main purpose is to help the control unit to detect whether a new phase of the MCU-sensor communication protocol has started not at an exact instant of time, but in between two thresholds. This behavior takes into account all the factors and the conditions affecting the accuracy of the sensor and allows the design to gain a little in term of flexibility.
* **SECOND_COMPARATOR**: it describes a threshold comparator that has exactly the same function of the previous COMPARATOR, with the only difference that it is used for the last part of the communication protocol (5.3 section on the DHT11 reference manual), that consist in receiving from the sensor either a "Data 0" or a "Data 1".
* **PULSE_GEN**: it is a multiple-stage pulse generator that detects a logic value change on the "data_in" line and generates a 1-clock cycle pulse accordingly.
* **SECOND_PULSE_GEN**: it is a multiple-stage pulse generator that detects a logic value change on the "data_drv" line and generates a 1-clock cycle pulse accordingly.

#### Control Unit Flow Diagram
![alt text][cu]

[cu]: https://github.com/ChristianPalmiero/DHT11_Controller/blob/master/img/fsm.png "Control Unit"

## Functional Validation

## Synthesis

The design has been synthesised with the Vivado tool provided by Xilinx and mapped in the programmable logic part of the Zynq core of the Zybo. 
The [dht11_sa_top-syn.tcl](https://github.com/ChristianPalmiero/DHT11_Controller/blob/master/dht11_sa_top-syn.tcl) TCL script automates the synthesis.

The primary clock "clk" comes from the 125 MHz Zynq reference clock.
The synchronous active high reset "rst" comes from the press-button BTN0 of the Zybo board, the button "btn" is the press-button BTN0. 
The four "sw" input signals are mapped to the Zybo board four slide switches.
The four "led" output signals are sent to the 4 LEDs of the Zybo board. 
Finally, the "data" inout line is mapped to the pin JE1 of the Pmod connector J.
<center>

   | Name   |  Pin | Level    |
   |:------:|:----:|:--------:|
   | clk    |  L16 | LVCMOS33 |
   | rst    |  P16 | LVCMOS33 |
   | btn    |  R18 | LVCMOS33 |
   | sw[0]  |  G15 | LVCMOS33 |
   | sw[1]  |  P15 | LVCMOS33 |
   | sw[2]  |  W13 | LVCMOS33 |
   | sw[3]  |  T16 | LVCMOS33 |
   | data   |  V12 | LVCMOS33 |
   | led[0] |  M14 | LVCMOS33 |
   | led[1] |  M15 | LVCMOS33 |
   | led[2] |  G14 | LVCMOS33 |
   | led[3] |  D18 | LVCMOS33 |

</center>
The synthesis result are in syn/top_wrapper.bit, a binary file that is used by the Zynq core to configure the programmable logic. 
The result is a boot image: syn/boot.bin.
Two important reports have also been produced: the resources usage report (syn/top_wrapper_utilization_placed.rpt);
the timing report (syn/top_wrapper_timing_summary_routed.rpt).

## Experiments on the Zybo
