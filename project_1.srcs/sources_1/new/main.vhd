----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.03.2025 15:10:32
-- Design Name: 
-- Module Name: main - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- https://wzn.pwr.edu.pl/fcp/4GBUKOQtTKlQhbx08SlkTWgJQX2o8DAoHNiwFE1xVT31BG1gnBVcoFW8SBDRKHg/96/public/pul/pul_arty_shield.txt
-- https://wzn.pwr.edu.pl/materialy-dydaktyczne/pul/pul_ie
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY main IS
    PORT (
        BUTTON : IN STD_LOGIC_VECTOR(0 DOWNTO 0); -- Only BUTTON(0) is used
        SW : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        LCD_RS : OUT STD_LOGIC;
        LCD_E : OUT STD_LOGIC;
        LCD_DB4 : OUT STD_LOGIC;
        LCD_DB5 : OUT STD_LOGIC;
        LCD_DB6 : OUT STD_LOGIC;
        LCD_DB7 : OUT STD_LOGIC;

        Clock100MHz : IN STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        SPI_SCK : OUT STD_LOGIC;
        SPI_MOSI : OUT STD_LOGIC;
        SPI_SS : OUT STD_LOGIC;
        LDAC : OUT STD_LOGIC
    );
END main;

ARCHITECTURE Behavioral OF main IS

    COMPONENT debouncer IS
        PORT (
            clk : IN STD_LOGIC; -- Clock input
            button_in : IN STD_LOGIC; -- Raw button input
            pulse_out : OUT STD_LOGIC; -- Single pulse output
            hold_out : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT lcd IS
        PORT (
            CLK : IN STD_LOGIC;
            
            -- Control signals from main module
            char_to_display : IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Data/Command to send
            send_data : IN STD_LOGIC; -- '1' to send data, '0' to send command (This port is no longer needed with trigger_pos/char)
            trigger_send : IN STD_LOGIC; -- Pulse '1' to trigger generic send (command or data)
            trigger_clear : IN STD_LOGIC; -- Pulse '1' to trigger clear command
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
    END COMPONENT;

    SIGNAL btn0_pulse : STD_LOGIC;
    SIGNAL btn0_hold : STD_LOGIC;

    -- Signals for controlling the LCD module
    SIGNAL lcd_char_data : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
    SIGNAL lcd_send_data_cmd : STD_LOGIC := '0'; -- '1' for data, '0' for command (This signal is no longer needed with trigger_pos/char)
    SIGNAL lcd_trigger_send : STD_LOGIC := '0'; -- Pulse to trigger generic send (command or data)
    SIGNAL lcd_trigger_clear : STD_LOGIC := '0'; -- Pulse to trigger clear
    SIGNAL lcd_trigger_pos : STD_LOGIC := '0'; -- Pulse to trigger set position
    SIGNAL lcd_trigger_char : STD_LOGIC := '0'; -- Pulse to trigger send character
    SIGNAL lcd_col : INTEGER RANGE 0 TO 15 := 0;
    SIGNAL lcd_row : INTEGER RANGE 0 TO 1 := 0;
    SIGNAL lcd_busy : STD_LOGIC; -- LCD busy status
    SIGNAL writing_message : STD_LOGIC := '0'; -- Signal to control message writing

    -- State machine for combined LCD control
    TYPE combined_lcd_state_type IS (
        INIT_START, INIT_CMD1, INIT_CMD2, INIT_CMD3, INIT_CMD4, INIT_CMD5, INIT_CMD6, INIT_DONE,
        CLEAR_DISPLAY, SET_CURSOR_0_0, SEND_CHAR_1, WAIT_AFTER_CHAR_1, SEND_CHAR_2, WAIT_AFTER_CHAR_2, SEND_CHAR_3, WAIT_AFTER_CHAR_3, DONE
    );
    shared variable combined_lcd_state : combined_lcd_state_type := INIT_START;
    shared variable init_delay_counter_var : INTEGER RANGE 0 TO 200000000 := 0; -- Variable for initialization delays

BEGIN

    -- Instantiate LCD
    lcd_inst : lcd
    PORT MAP (
        CLK => Clock100MHz,
        char_to_display => lcd_char_data,
        send_data => lcd_send_data_cmd, -- This port is likely unused in the updated lcd component
        trigger_send => lcd_trigger_send,
        trigger_clear => lcd_trigger_clear,
        trigger_pos => lcd_trigger_pos,
        trigger_char => lcd_trigger_char,
        col => lcd_col,
        row => lcd_row,
        LCD_RS => LCD_RS,
        LCD_E => LCD_E,
        LCD_DB4 => LCD_DB4,
        LCD_DB5 => LCD_DB5,
        LCD_DB6 => LCD_DB6,
        LCD_DB7 => LCD_DB7,
        LCD_busy => lcd_busy
    );

    -- Instantiate debouncer for BUTTON(0)
    debouncer_inst : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => btn0_pulse,
        hold_out => btn0_hold
    );

    -- Combined LCD Control Process (Initialization and Writing)
    process (Clock100MHz)
        variable char_index : integer := 0;
        constant message : string := "Hello, World!"; -- This is no longer used for "123"

    begin
        if rising_edge(Clock100MHz) then
            -- Default assignments to avoid multiple drivers
            lcd_trigger_send <= '0';
            lcd_trigger_clear <= '0';
            lcd_trigger_pos <= '0';
            lcd_trigger_char <= '0';

            case combined_lcd_state is
                WHEN INIT_START =>
                    init_delay_counter_var := 200000000; -- Wait for power-on (e.g., 200ms for 100MHz clock)
                    combined_lcd_state := INIT_CMD1;

                WHEN INIT_CMD1 =>
                    if init_delay_counter_var > 0 then
                        init_delay_counter_var := init_delay_counter_var - 1;
                    else
                        lcd_char_data <= X"02"; -- Function Set (4-bit mode)
                        lcd_trigger_send <= '1';
                        combined_lcd_state := INIT_CMD2;
                    end if;

                WHEN INIT_CMD2 =>
                    if lcd_busy = '0' then
                         lcd_char_data <= X"28"; -- Function Set (DL=0, N=1, F=0)
                         lcd_trigger_send <= '1';
                         combined_lcd_state := INIT_CMD3;
                    end if;

                WHEN INIT_CMD3 =>
                    if lcd_busy = '0' then
                         lcd_char_data <= X"0C"; -- Display Control (D=1, C=0, B=0)
                         lcd_trigger_send <= '1';
                         combined_lcd_state := INIT_CMD4;
                    end if;

                WHEN INIT_CMD4 =>
                    if lcd_busy = '0' then
                         lcd_char_data <= X"06"; -- Entry Mode Set (I/D=1, SH=0)
                         lcd_trigger_send <= '1';
                         combined_lcd_state := INIT_CMD5;
                    end if;

                WHEN INIT_CMD5 =>
                    if lcd_busy = '0' then
                         lcd_trigger_clear <= '1'; -- Clear Display
                         combined_lcd_state := INIT_CMD6;
                    end if;

                WHEN INIT_CMD6 =>
                    if lcd_busy = '0' then
                         lcd_char_data <= X"80"; -- Set DDRAM Address (Home position)
                         lcd_trigger_send <= '1';
                         combined_lcd_state := INIT_DONE;
                    end if;

                WHEN INIT_DONE =>
                    if lcd_busy = '0' then
                        combined_lcd_state := CLEAR_DISPLAY; -- Start the "123" sequence
                    end if;

                WHEN CLEAR_DISPLAY =>
                    if lcd_busy = '0' then
                        lcd_trigger_clear <= '1';
                        combined_lcd_state := SET_CURSOR_0_0;
                    end if;

                WHEN SET_CURSOR_0_0 =>
                    if lcd_busy = '0' then
                        lcd_col <= 0;
                        lcd_row <= 0;
                        lcd_trigger_pos <= '1';
                        combined_lcd_state := SEND_CHAR_1;
                    end if;

                WHEN SEND_CHAR_1 =>
                    if lcd_busy = '0' then
                        lcd_char_data <= X"31"; -- ASCII for '1'
                        lcd_trigger_char <= '1';
                        combined_lcd_state := WAIT_AFTER_CHAR_1;
                    end if;

                WHEN WAIT_AFTER_CHAR_1 =>
                    if lcd_busy = '0' then
                        combined_lcd_state := SEND_CHAR_2;
                    end if;

                WHEN SEND_CHAR_2 =>
                    if lcd_busy = '0' then
                        lcd_char_data <= X"32"; -- ASCII for '2'
                        lcd_trigger_char <= '1';
                        combined_lcd_state := WAIT_AFTER_CHAR_2;
                    end if;

                WHEN WAIT_AFTER_CHAR_2 =>
                    if lcd_busy = '0' then
                        combined_lcd_state := SEND_CHAR_3;
                    end if;

                WHEN SEND_CHAR_3 =>
                    if lcd_busy = '0' then
                        lcd_char_data <= X"33"; -- ASCII for '3'
                        lcd_trigger_char <= '1';
                        combined_lcd_state := WAIT_AFTER_CHAR_3;
                    end if;

                WHEN WAIT_AFTER_CHAR_3 =>
                    if lcd_busy = '0' then
                        combined_lcd_state := DONE; -- Finished sending "123"
                    end if;

                WHEN DONE =>
                    -- Stay in this state or transition elsewhere if needed
                    IF btn0_pulse = '1' THEN
                        combined_lcd_state := CLEAR_DISPLAY; -- Trigger the sequence again
                    ELSE
                        null; -- Do nothing, task complete
                    END IF;

            END CASE;
        end if;
    end process;


END Behavioral;
