# DHT11 Controller Project
## Intro
This project consist of a complete digital hardware design from RTL down to synthesis of a controller for the [DHT11 Humidity and Temperature Sensor](DTH11.pdf) manufactured by D-Robotics UK. 

## Authors
* Christian Palmiero
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

## Inputs and Outputs  
### Button:  


We use the push button to start to read for the sensor.  
But :   
  - After power up, the button should have no effect until 1 sec  
  - Use debouncing function to correct default of the button  

### Switches:  


  - 1 switch to select the data to display : temperature or humidity (SW0). When the switch is set to 1, we read the humidity level, when it is 0, we read the temperature.  
  - 2 switches to select 4 bits out of the 16 bits (4 bits nibbles) of the data to display (SW1 and SW2).  

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

### LEDs :  


We use the 4 LEDs to display 4 bits of data (the 4 bits chosen by the switches SW1 and SW2 or the specific states specified above).  


```
      11     10     01     00
   +------+------+------+------+
   |  L3  |  L2  |  L1  |  L0  |
   +------+------+------+------+
```

## Common Interface - Block diagram  

