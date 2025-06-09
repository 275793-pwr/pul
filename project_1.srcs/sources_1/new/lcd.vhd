----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.03.2025 15:10:32
-- Design Name: 
-- Module Name: lcd - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: VHDL module for controlling an HD44780 compatible LCD in 4-bit mode.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY lcd IS
    PORT (
        CLK : IN STD_LOGIC;
        
        -- Control signals from main module
        char_to_display : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        send_data : IN STD_LOGIC;
        trigger_send : IN STD_LOGIC;
        trigger_clear : IN STD_LOGIC;
        trigger_pos : IN STD_LOGIC;
        trigger_char : IN STD_LOGIC;
        col : IN INTEGER RANGE 0 TO 15;
        row : IN INTEGER RANGE 0 TO 1;
        
        -- LCD Interface signals
        LCD_RS : OUT STD_LOGIC;
        LCD_E : OUT STD_LOGIC;
        LCD_DB4 : OUT STD_LOGIC;
        LCD_DB5 : OUT STD_LOGIC;
        LCD_DB6 : OUT STD_LOGIC;
        LCD_DB7 : OUT STD_LOGIC;
        
        LCD_busy : OUT STD_LOGIC -- '1' when LCD is busy processing
    );
END lcd;

ARCHITECTURE Behavioral OF lcd IS

    -- State machine for LCD communication
    TYPE lcd_state_type IS (
        IDLE,
        SEND_UPPER_NIBBLE,
        PULSE_EN_UPPER,
        WAIT_AFTER_UPPER,
        SEND_LOWER_NIBBLE,
        PULSE_EN_LOWER,
        WAIT_AFTER_LOWER,
        WAIT_LONG_COMMAND, -- For commands like clear and return home
        BUSY
    );
    SIGNAL current_state : lcd_state_type := IDLE;

    -- Internal signals
    SIGNAL data_to_send : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
    SIGNAL is_data : STD_LOGIC := '0';
    SIGNAL en_pulse : STD_LOGIC := '0';
    SIGNAL busy_internal : STD_LOGIC := '0';

    -- Clock divider for delays (adjust frequency based on CLK)
    -- Assuming 100MHz clock, 2us delay requires 200 clock cycles.
    -- 200us delay requires 20000 clock cycles.
    -- 2ms delay requires 200000 clock cycles.
    SIGNAL delay_counter : INTEGER RANGE 0 TO 5000000 := 0;
    SIGNAL delay_done : STD_LOGIC := '0';
    SIGNAL long_delay_active : STD_LOGIC := '0';

    -- Constants for delay counters (assuming 100MHz clock)
    CONSTANT delay_2us : INTEGER := 200;
    CONSTANT delay_200us : INTEGER := 20000;
    CONSTANT delay_2ms : INTEGER := 200000;
    CONSTANT delay_20ms : INTEGER := 2000000;

    -- State machine for command execution
    TYPE cmd_state_type IS (
        STATE_IDLE,
        STATE_0,
        STATE_1,
        STATE_2,
        STATE_3,
        STATE_4
    );
    SIGNAL cmd_state : cmd_state_type := STATE_IDLE;
    SIGNAL command_byte : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
    SIGNAL command_active : STD_LOGIC := '0';
    SIGNAL cmd_trigger : STD_LOGIC := '0';

    -- Master state machine for orchestrating commands
    TYPE master_cmd_state_type IS (
        MASTER_IDLE,
        MASTER_CLEAR,
        MASTER_HOME,
        MASTER_SEND,
        MASTER_SEND_WAIT,
        MASTER_POS,
        MASTER_CHAR
    );
    SIGNAL master_cmd_state : master_cmd_state_type := MASTER_IDLE;

BEGIN

    -- LCD Command Process (Executes a single command)
    cmd_proc : process(CLK)
    begin
        IF rising_edge(CLK) THEN
            -- Default assignments
            delay_done <= '0';
            command_active <= '0'; -- Reset command_active at the start of the cycle

            CASE cmd_state IS
                WHEN STATE_IDLE =>
                    IF cmd_trigger = '1' THEN
                        command_active <= '1';
                        cmd_state <= STATE_0;
                    END IF;

                WHEN STATE_0 =>
                    LCD_DB4 <= command_byte(7);
                    LCD_DB5 <= command_byte(6);
                    LCD_DB6 <= command_byte(5);
                    LCD_DB7 <= command_byte(4);
                    -- LCD_RS is set by the master process
                    LCD_E <= '1';
                    delay_counter <= 0;
                    cmd_state <= STATE_1;

                WHEN STATE_1 =>
                    IF delay_counter < delay_2us THEN
                        delay_counter <= delay_counter + 1;
                    ELSE
                        LCD_E <= '0';
                        delay_counter <= 0;
                        cmd_state <= STATE_2;
                    END IF;

                WHEN STATE_2 =>
                    IF delay_counter < delay_200us THEN
                        delay_counter <= delay_counter + 1;
                    ELSE
                        LCD_DB4 <= command_byte(3);
                        LCD_DB5 <= command_byte(2);
                        LCD_DB6 <= command_byte(1);
                        LCD_DB7 <= command_byte(0);
                        LCD_E <= '1';
                        delay_counter <= 0;
                        cmd_state <= STATE_3;
                    END IF;

                WHEN STATE_3 =>
                    IF delay_counter < delay_2us THEN
                        delay_counter <= delay_counter + 1;
                    ELSE
                        LCD_E <= '0';
                        delay_counter <= 0;
                        cmd_state <= STATE_4;
                    END IF;

                WHEN STATE_4 =>
                    IF delay_counter < delay_2ms THEN
                        delay_counter <= delay_counter + 1;
                    ELSE
                        cmd_state <= STATE_IDLE;
                        -- command_active remains '0' from default assignment
                    END IF;

                WHEN OTHERS =>
                    cmd_state <= STATE_IDLE;
            END CASE;
        END IF;
    end process cmd_proc;

    -- Master Command Orchestration Process
    master_cmd_proc : process(CLK)
    begin
        IF rising_edge(CLK) THEN
            cmd_trigger <= '0'; -- Default to no trigger
            LCD_RS <= '0'; -- Default to command mode

            CASE master_cmd_state IS
                WHEN MASTER_IDLE =>
                    IF trigger_clear = '1' THEN
                        command_byte <= "00000001"; -- Clear Display Command
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_CLEAR;
                    ELSIF trigger_pos = '1' THEN
                         IF row = 0 THEN
                            command_byte <= '1' & "0" & STD_LOGIC_VECTOR(to_unsigned(col, 6)); -- Set DDRAM Address command for row 0
                         ELSE
                            command_byte <= '1' & "1" & STD_LOGIC_VECTOR(to_unsigned(col, 6)); -- Set DDRAM Address command for row 1
                         END IF;
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_SEND_WAIT;
                    ELSIF trigger_char = '1' THEN
                        command_byte <= char_to_display;
                        LCD_RS <= '1'; -- Data mode
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_SEND_WAIT;
                    ELSIF trigger_send = '1' THEN
                        command_byte <= char_to_display;
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_SEND_WAIT;
                    END IF;

                WHEN MASTER_CLEAR =>
                    IF command_active = '0' THEN
                        command_byte <= "00001110"; -- Cursor On, Blinking Off (Common after clear/home)
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_HOME;
                    END IF;

                WHEN MASTER_HOME =>
                     IF command_active = '0' THEN
                        command_byte <= "00000010"; -- Return Home Command
                        cmd_trigger <= '1';
                        master_cmd_state <= MASTER_SEND_WAIT; -- Wait for home command to finish
                    END IF;

                WHEN MASTER_SEND_WAIT =>
                    IF command_active = '0' THEN
                        master_cmd_state <= MASTER_IDLE;
                    END IF;

                WHEN OTHERS =>
                    master_cmd_state <= MASTER_IDLE;
            END CASE;
        END IF;
    end process master_cmd_proc;

    -- Process to determine LCD_busy status
    lcd_busy_proc : process(busy_internal, master_cmd_state)
    begin
        IF busy_internal = '1' OR master_cmd_state /= MASTER_IDLE THEN
            LCD_busy <= '1';
        ELSE
            LCD_busy <= '0';
        END IF;
    end process lcd_busy_proc;

    init_proc : process( CLK )
    begin
        
    end process ;

    

END Behavioral;
