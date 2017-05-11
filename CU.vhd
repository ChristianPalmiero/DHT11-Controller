LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY CU IS
PORT (    -- Input
	  CLK, RST              : IN STD_ULOGIC;
	  FINAL_COUNTER         : IN STD_ULOGIC;
          FINAL_CNT             : IN STD_ULOGIC;
          PULSE                 : IN STD_ULOGIC;
          OUT_DEBOUNCER         : IN STD_ULOGIC;
          OUT_COMPARATOR        : IN STD_ULOGIC;
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

  TYPE StateType IS (IDLE,PROTOCOL_ERROR_STATE,CONFIG_COUNT_1S,EN_COUNT_1S,WAIT_FOR_BUTTON,CONFIG_COUNT_18M,EN_COUNT_18M,CONFIG_COUNT_20,EN_COUNT_20,CONFIG_COUNT_80,EN_COUNT_80,CONFIG_COUNT_80_2,EN_COUNT_80_2,CONFIG_COUNT_50,EN_COUNT_50,CONFIG_COUNT_26,EN_COUNT_26,REC_0,REC_1);
  SIGNAL STATE: StateType;

BEGIN

  Transition: PROCESS(CLK)
  BEGIN
  IF (CLK 'EVENT AND CLK = '1') THEN
   IF RST= '1' THEN
     STATE <= IDLE;
   ELSE
     CASE STATE IS
       WHEN IDLE => STATE <= CONFIG_COUNT_1S;
       WHEN CONFIG_COUNT_1S => STATE <= EN_COUNT_1S;
       WHEN EN_COUNT_1S =>
         IF FINAL_CNT = '1' THEN
           STATE <= WAIT_FOR_BUTTON;
         ELSE
           STATE <= EN_COUNT_1S;
         END IF;
       WHEN WAIT_FOR_BUTTON =>
         IF OUT_DEBOUNCER = '1' THEN
           STATE <= CONFIG_COUNT_18M;
         ELSE
           STATE <= WAIT_FOR_BUTTON;
         END IF;
       WHEN CONFIG_COUNT_18M => STATE <= EN_COUNT_18M;
       WHEN EN_COUNT_18M =>
         IF FINAL_CNT = '1' THEN
	   STATE <= CONFIG_COUNT_20;
	 ELSE
	   STATE <= EN_COUNT_18M;
         END IF;
       WHEN CONFIG_COUNT_20 => STATE <= EN_COUNT_20;
       WHEN EN_COUNT_20 =>
	 IF OUT_COMPARATOR = '1' THEN
           IF PULSE = '1' THEN
             STATE <= CONFIG_COUNT_80;
           ELSE
    	     STATE <= PROTOCOL_ERROR_STATE;
           END IF;
         ELSE
           IF PULSE = '1' THEN
            STATE <= PROTOCOL_ERROR_STATE;
           ELSE
            STATE <= EN_COUNT_20;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_80 => STATE <= EN_COUNT_80;
       WHEN EN_COUNT_80 =>
         IF OUT_COMPARATOR = '1' THEN
            IF PULSE = '1' THEN
              STATE <= CONFIG_COUNT_80_2;
            ELSE
	      STATE <= PROTOCOL_ERROR_STATE;
            END IF;
         ELSE
           IF PULSE = '1' THEN
             STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             STATE <= EN_COUNT_80;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_80_2 => STATE <= EN_COUNT_80_2;
       WHEN EN_COUNT_80_2 =>
         IF OUT_COMPARATOR = '1' THEN
           IF PULSE = '1' THEN
             STATE <= CONFIG_COUNT_50;
           ELSE
             STATE <= PROTOCOL_ERROR_STATE;
           END IF;
         ELSE
           IF PULSE = '1' THEN
             STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             STATE <= EN_COUNT_80_2;
           END IF;
         END IF;
       WHEN PROTOCOL_ERROR_STATE =>
         IF OUT_DEBOUNCER='1' THEN
           STATE <= WAIT_FOR_BUTTON;
         ELSE
           STATE <= PROTOCOL_ERROR_STATE;
         END IF;
       WHEN CONFIG_COUNT_50 => STATE <= EN_COUNT_50;
       WHEN EN_COUNT_50 =>
         IF OUT_COMPARATOR = '1' THEN
           IF PULSE = '1' THEN
             STATE <= CONFIG_COUNT_26;
           ELSE
 	     STATE <= PROTOCOL_ERROR_STATE;
	   END IF;
         ELSE
	   IF PULSE = '1' THEN
	     STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             STATE <= EN_COUNT_50;
           END IF;
         END IF;
       WHEN CONFIG_COUNT_26 => STATE <= EN_COUNT_26;
       WHEN EN_COUNT_26 =>
         IF PULSE = '1' THEN
           IF OUT_COMPARATOR = '1' THEN
             IF OUT_SECOND_COMPARATOR = '1' THEN
               STATE <= REC_1;
             ELSE
               STATE <= PROTOCOL_ERROR_STATE;
             END IF;
           ELSE
             IF OUT_SECOND_COMPARATOR = '1' THEN
               STATE <= REC_0;
             ELSE 
               STATE <= PROTOCOL_ERROR_STATE;
             END IF;
           END IF;
         ELSE
           IF FINAL_CNT = '1' THEN
             STATE <= PROTOCOL_ERROR_STATE;
           ELSE
             STATE <= EN_COUNT_26;
           END IF;
         END IF;
	WHEN REC_0 =>
          IF FINAL_COUNTER = '1' THEN
 	    STATE <= WAIT_FOR_BUTTON;
          ELSE
	    STATE <= EN_COUNT_26;
          END IF;
	WHEN REC_1 =>
          IF FINAL_COUNTER = '1' THEN
            STATE <= WAIT_FOR_BUTTON;
          ELSE
            STATE <= EN_COUNT_26;
          END IF;
      END CASE;
    END IF;
  END IF;
END PROCESS;

cu_Output: PROCESS(State)
BEGIN
  EN              <= '0';
  INITIAL_ENABLE  <= '0';
  --INIT_COUNTER    <=  0;
  SHIFT_ENABLE    <= '0';
  DATA_DRV        <= '0';
  BUSY_BIT        <= '0';
  PROTOCOL_ERROR  <= '0';
  DATA            <= '0';
  INIT_COUNTER    <=  50000000;
  CASE State IS
    WHEN IDLE => NULL ;
    WHEN CONFIG_COUNT_1S => INITIAL_ENABLE <= '1'; BUSY_BIT <= '1'; INIT_COUNTER <= 50000000;
    WHEN EN_COUNT_1S => EN <= '1'; BUSY_BIT <= '1';
    WHEN WAIT_FOR_BUTTON => NULL ;
    WHEN CONFIG_COUNT_18M => INITIAL_ENABLE <= '1'; INIT_COUNTER <= 900000; DATA_DRV <= '1';
    WHEN EN_COUNT_18M => EN <= '1'; DATA_DRV <= '1';
    WHEN CONFIG_COUNT_20 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 1500; MARGIN <= 650;
    WHEN EN_COUNT_20 => EN <= '1';
    WHEN PROTOCOL_ERROR_STATE => PROTOCOL_ERROR <= '1';
    WHEN CONFIG_COUNT_80 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 4000; BUSY_BIT <= '1'; MARGIN <= 400;
    WHEN EN_COUNT_80 => EN <= '1';  BUSY_BIT <= '1';
    WHEN CONFIG_COUNT_80_2 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 4000; BUSY_BIT <= '1'; MARGIN <= 400;
    WHEN EN_COUNT_80_2 => EN <= '1';  BUSY_BIT <= '1';
    WHEN CONFIG_COUNT_50 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 2500; BUSY_BIT <= '1'; MARGIN <= 250;
    WHEN EN_COUNT_50 => EN <= '1';  BUSY_BIT <= '1';
    WHEN CONFIG_COUNT_26 => INITIAL_ENABLE <= '1'; THRESHOLD_COMP <= 2500; BUSY_BIT <= '1'; MARGIN <= 0; INIT_COUNTER <= 3850;
    WHEN EN_COUNT_26 => EN <= '1';  BUSY_BIT <= '1';
    WHEN REC_0 => INITIAL_ENABLE <= '1'; INIT_COUNTER <= 3850; BUSY_BIT <= '1'; SHIFT_ENABLE <= '1'; THRESHOLD_COMP <= 2500; MARGIN <= 0;
    WHEN REC_1 => DATA <= '1'; INITIAL_ENABLE <= '1'; INIT_COUNTER <= 3850; BUSY_BIT <= '1'; SHIFT_ENABLE <= '1'; THRESHOLD_COMP <= 2500; MARGIN <= 0;
  END CASE;
END PROCESS;

END ARCHITECTURE BEHAV;
