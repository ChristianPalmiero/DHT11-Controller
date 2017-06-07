LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY CU IS
  generic(
    freq:    positive range 1 to 1000 -- Clock frequency (MHz)
  );
  PORT (  -- Input
	  CLK, RST              : IN STD_ULOGIC;
	  FINAL_COUNTER         : IN STD_ULOGIC;
          FINAL_CNT             : IN STD_ULOGIC;
	  RISING		: IN STD_ULOGIC;
      	  FALLING               : IN STD_ULOGIC;
          OUT_DEBOUNCER         : IN STD_ULOGIC;
          OUT_COMPARATOR        : IN STD_ULOGIC_VECTOR(1 DOWNTO 0);
          OUT_SECOND_COMPARATOR : IN STD_ULOGIC;
	  -- Output
          EN                    : OUT STD_ULOGIC;
          INITIAL_ENABLE        : OUT STD_ULOGIC;
          SHIFT_ENABLE          : OUT STD_ULOGIC;
          BUSY_BIT              : OUT STD_ULOGIC;
          PROTOCOL_ERROR        : OUT STD_ULOGIC;
          INIT_COUNTER          : OUT INTEGER;
          MARGIN                : OUT INTEGER;
          THRESHOLD_COMP        : OUT INTEGER;
          DATA		        : OUT STD_ULOGIC;
          DATA_DRV              : OUT STD_ULOGIC
     );
END ENTITY CU;

ARCHITECTURE BEHAV OF CU IS

  TYPE StateType IS (IDLE,PROTOCOL_ERROR_STATE,CONFIG_COUNT_1S,EN_COUNT_1S,WAIT_FOR_BUTTON,WAIT_FOR_BUTTON_PE,CONFIG_COUNT_18M,EN_COUNT_18M,CONFIG_COUNT_20,EN_COUNT_20,CONFIG_COUNT_80,EN_COUNT_80,CONFIG_COUNT_80_2,EN_COUNT_80_2,CONFIG_COUNT_50,EN_COUNT_50,CONFIG_COUNT_26,EN_COUNT_26,REC_0,REC_1);
  SIGNAL CURR_STATE, NEXT_STATE: StateType;

BEGIN

  Transition: PROCESS(CLK)
  BEGIN
    IF (CLK 'EVENT AND CLK = '1') THEN
      IF RST= '1' THEN
        CURR_STATE <= IDLE;
      ELSE
        CURR_STATE <= NEXT_STATE;
      END IF;
    END IF;
  END PROCESS Transition;

  P_Next_State: PROCESS(CURR_STATE, FINAL_COUNTER, FINAL_CNT, RISING, FALLING, OUT_DEBOUNCER, OUT_COMPARATOR, OUT_SECOND_COMPARATOR)
  BEGIN
    NEXT_STATE<=CURR_STATE;
    CASE CURR_STATE IS
       WHEN IDLE => NEXT_STATE <= CONFIG_COUNT_1S;
       WHEN CONFIG_COUNT_1S => NEXT_STATE <= EN_COUNT_1S;
       WHEN EN_COUNT_1S =>
         IF FINAL_CNT = '1' THEN
           NEXT_STATE <= WAIT_FOR_BUTTON;
         ELSE
           NEXT_STATE <= EN_COUNT_1S;
         END IF;
       WHEN WAIT_FOR_BUTTON =>
         IF OUT_DEBOUNCER = '1' THEN
           NEXT_STATE <= CONFIG_COUNT_18M;
         ELSE
           NEXT_STATE <= WAIT_FOR_BUTTON;
         END IF;
       WHEN CONFIG_COUNT_18M => NEXT_STATE <= EN_COUNT_18M;
       WHEN EN_COUNT_18M =>
         IF FINAL_CNT = '1' THEN
	   NEXT_STATE <= CONFIG_COUNT_20;
	 ELSE
	   NEXT_STATE <= EN_COUNT_18M;
         END IF;
       WHEN CONFIG_COUNT_20 => NEXT_STATE <= EN_COUNT_20;
       WHEN EN_COUNT_20 =>
	 IF (OUT_COMPARATOR(0) = '1') THEN
           IF FALLING = '1' THEN
             NEXT_STATE <= CONFIG_COUNT_80;
           ELSE
    	     NEXT_STATE <= EN_COUNT_20;
           END IF;
         ELSE
           IF FALLING = '1' THEN
             NEXT_STATE <= PROTOCOL_ERROR_STATE;
           ELSE
	     IF (OUT_COMPARATOR(1) = '1') THEN
	       NEXT_STATE <= PROTOCOL_ERROR_STATE;
	     ELSE
               NEXT_STATE <= EN_COUNT_20;
	     END IF;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_80 => NEXT_STATE <= EN_COUNT_80;
       WHEN EN_COUNT_80 =>
         IF (OUT_COMPARATOR(0) = '1') THEN
           IF RISING = '1' THEN
             NEXT_STATE <= CONFIG_COUNT_80_2;
           ELSE
             NEXT_STATE <= EN_COUNT_80;
           END IF;
         ELSE
           IF RISING = '1' THEN
             NEXT_STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             IF (OUT_COMPARATOR(1) = '1') THEN
               NEXT_STATE <= PROTOCOL_ERROR_STATE;
             ELSE
               NEXT_STATE <= EN_COUNT_80;
             END IF;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_80_2 => NEXT_STATE <= EN_COUNT_80_2;
       WHEN EN_COUNT_80_2 =>
         IF (OUT_COMPARATOR(0) = '1') THEN
           IF FALLING = '1' THEN
             NEXT_STATE <= CONFIG_COUNT_50;
           ELSE
             NEXT_STATE <= EN_COUNT_80_2;
           END IF;
          ELSE
           IF FALLING = '1' THEN
            NEXT_STATE <= PROTOCOL_ERROR_STATE;
           ELSE
            IF (OUT_COMPARATOR(1) = '1') THEN
              NEXT_STATE <= PROTOCOL_ERROR_STATE;
            ELSE
              NEXT_STATE <= EN_COUNT_80_2;
            END IF;
           END IF;
         END IF;
       WHEN PROTOCOL_ERROR_STATE =>
         NEXT_STATE <= WAIT_FOR_BUTTON_PE;
       WHEN WAIT_FOR_BUTTON_PE =>
         IF OUT_DEBOUNCER = '1' THEN
           NEXT_STATE <= CONFIG_COUNT_18M;
         ELSE
           NEXT_STATE <= WAIT_FOR_BUTTON_PE;
         END IF;	
       WHEN CONFIG_COUNT_50 => NEXT_STATE <= EN_COUNT_50;
       WHEN EN_COUNT_50 =>
         IF (OUT_COMPARATOR(0) = '1') THEN
           IF RISING = '1' THEN
             NEXT_STATE <= CONFIG_COUNT_26;
           ELSE
             NEXT_STATE <= EN_COUNT_50;
           END IF;
          ELSE
           IF RISING = '1' THEN
            NEXT_STATE <= PROTOCOL_ERROR_STATE;
           ELSE
            IF (OUT_COMPARATOR(1) = '1') THEN
              NEXT_STATE <= PROTOCOL_ERROR_STATE;
            ELSE
              NEXT_STATE <= EN_COUNT_50;
            END IF;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_26 => NEXT_STATE <= EN_COUNT_26;
       WHEN EN_COUNT_26 =>
         IF FALLING = '1' THEN
           IF (OUT_COMPARATOR(1) = '1') THEN
             IF OUT_SECOND_COMPARATOR = '1' THEN
               NEXT_STATE <= REC_1;
             ELSE
               NEXT_STATE <= PROTOCOL_ERROR_STATE;
             END IF;
           ELSE
             IF OUT_SECOND_COMPARATOR = '1' THEN
               NEXT_STATE <= REC_0;
             ELSE
               NEXT_STATE <= PROTOCOL_ERROR_STATE;
             END IF;
           END IF;
         ELSE
           IF FINAL_CNT = '1' THEN
             NEXT_STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             NEXT_STATE <= EN_COUNT_26;
           END IF;
         END IF;
	WHEN REC_0 =>
          IF FINAL_COUNTER = '1' THEN
 	    NEXT_STATE <= WAIT_FOR_BUTTON;
          ELSE
	    NEXT_STATE <= EN_COUNT_50;  -- if a data has been received wait until a new high state is received
          END IF;
	WHEN REC_1 =>
          IF FINAL_COUNTER = '1' THEN
            NEXT_STATE <= WAIT_FOR_BUTTON;
          ELSE
            NEXT_STATE <= EN_COUNT_50;
          END IF;
     END CASE;
  END PROCESS P_Next_State;

  CU_Output: PROCESS(CURR_STATE)
  BEGIN
    EN              <= '0';
    INITIAL_ENABLE  <= '0';
    SHIFT_ENABLE    <= '0';
    DATA_DRV        <= '0';
    BUSY_BIT        <= '0';
    PROTOCOL_ERROR  <= '0';
    DATA            <= '0';
    INIT_COUNTER    <=  50000000;
    THRESHOLD_COMP  <=  0;
    MARGIN          <=  0;
    CASE CURR_STATE IS
      WHEN IDLE => NULL ;
      WHEN CONFIG_COUNT_1S => INITIAL_ENABLE <= '1'; BUSY_BIT <= '1'; INIT_COUNTER <= 1000000*freq;
      WHEN EN_COUNT_1S => EN <= '1'; BUSY_BIT <= '1';
      WHEN WAIT_FOR_BUTTON => NULL ;
      WHEN CONFIG_COUNT_18M => INITIAL_ENABLE <= '1'; INIT_COUNTER <= 20000*freq; DATA_DRV <= '1'; BUSY_BIT <= '1';
      WHEN EN_COUNT_18M => EN <= '1'; DATA_DRV <= '1'; BUSY_BIT <= '1';
      WHEN CONFIG_COUNT_20 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 30*freq; MARGIN <= 20*freq; BUSY_BIT <= '1'; --30us +- 20us
      WHEN EN_COUNT_20 => EN <= '1'; BUSY_BIT <= '1'; THRESHOLD_COMP <= 30*freq; MARGIN <= 20*freq; 
      WHEN PROTOCOL_ERROR_STATE => PROTOCOL_ERROR <= '1';
      WHEN WAIT_FOR_BUTTON_PE => PROTOCOL_ERROR <= '1';
      WHEN CONFIG_COUNT_80 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 80*freq; BUSY_BIT <= '1'; MARGIN <= 12*freq; --relaxed margin
      WHEN EN_COUNT_80 => EN <= '1';  BUSY_BIT <= '1'; THRESHOLD_COMP <= 80*freq; MARGIN <= 12*freq;
      WHEN CONFIG_COUNT_80_2 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 80*freq; BUSY_BIT <= '1'; MARGIN <= 12*freq;
      WHEN EN_COUNT_80_2 => EN <= '1';  BUSY_BIT <= '1'; THRESHOLD_COMP <= 80*freq; MARGIN <= 12*freq;
      WHEN CONFIG_COUNT_50 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 50*freq; BUSY_BIT <= '1'; MARGIN <= 10*freq; --relaxed margin
      WHEN EN_COUNT_50 => EN <= '1';  BUSY_BIT <= '1'; THRESHOLD_COMP <= 50*freq; MARGIN <= 10*freq;
      WHEN CONFIG_COUNT_26 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 50*freq; BUSY_BIT <= '1'; INIT_COUNTER <= 77*freq;
      WHEN EN_COUNT_26 => EN <= '1';  BUSY_BIT <= '1'; THRESHOLD_COMP <= 50*freq;
      WHEN REC_0 => INITIAL_ENABLE <= '1'; BUSY_BIT <= '1'; SHIFT_ENABLE <= '1'; THRESHOLD_COMP <= 50*freq; MARGIN <= 5*freq;
      WHEN REC_1 => DATA <= '1'; INITIAL_ENABLE <= '1'; BUSY_BIT <= '1'; SHIFT_ENABLE <= '1'; THRESHOLD_COMP <= 50*freq; MARGIN <= 5*freq;
    END CASE;
  END PROCESS CU_Output;
  
END ARCHITECTURE BEHAV;
