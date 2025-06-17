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
        BUTTON : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Only BUTTON(0) is used
        SW : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        LCD_RS : OUT STD_LOGIC;
        LCD_E : OUT STD_LOGIC;
        LCD_DATA : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        -- LCD_DB4 : OUT STD_LOGIC;
        -- LCD_DB5 : OUT STD_LOGIC;
        -- LCD_DB6 : OUT STD_LOGIC;
        -- LCD_DB7 : OUT STD_LOGIC;

        Clock100MHz : IN STD_LOGIC;
        DEBUG : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        SPI_SCK : OUT STD_LOGIC;
        SPI_MOSI : OUT STD_LOGIC;
        SPI_SS : OUT STD_LOGIC;
        LDAC : OUT STD_LOGIC;
        TRIG : OUT STD_LOGIC;
        ECHO : IN STD_LOGIC
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

    COMPONENT us IS
        PORT (
            Clock100MHz : IN STD_LOGIC;
            TRIG : OUT STD_LOGIC;
            ECHO : IN STD_LOGIC;
            DIST_OUT : OUT unsigned(19 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL btn0_pulse : STD_LOGIC;
    SIGNAL btn0_hold : STD_LOGIC;

    SIGNAL btn1_pulse : STD_LOGIC;
    SIGNAL btn1_hold : STD_LOGIC;

    SIGNAL btn2_pulse : STD_LOGIC;
    SIGNAL btn2_hold : STD_LOGIC;

    SIGNAL distance : unsigned(19 DOWNTO 0);
    SIGNAL distance_cm : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL lcd_reset : STD_LOGIC := '0';
    SIGNAL start : STD_LOGIC := '0';
    SIGNAL cm : STD_LOGIC := '0';

    SIGNAL lcd_clk_cnt : INTEGER RANGE 0 TO 200000000 := 0;

    COMPONENT lcd IS
        PORT (
            reset : IN STD_LOGIC;
            Clock100MHz : IN STD_LOGIC;
            LCD_RS : OUT STD_LOGIC;
            LCD_E : OUT STD_LOGIC;
            LCD_DATA : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            distance_cm : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            DEBUG : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            start : IN STD_LOGIC;
            cm : IN STD_LOGIC
        );
    END COMPONENT;

BEGIN
    -- Instantiate debouncer for BUTTON(0)
    prog_reset : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => btn0_pulse,
        hold_out => btn0_hold
    );
    unit_selector : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(1),
        pulse_out => btn1_pulse,
        hold_out => btn1_hold
    );
    us_trigger : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(2),
        pulse_out => btn2_pulse,
        hold_out => btn2_hold
    );

    U1 : us
    PORT MAP(
        Clock100MHz => Clock100MHz,
        TRIG => TRIG,
        ECHO => ECHO,
        DIST_OUT => distance
    );

    U2 : lcd
    PORT MAP(
        reset => lcd_reset,
        Clock100MHz => Clock100MHz,
        LCD_RS => LCD_RS,
        LCD_E => LCD_E,
        LCD_DATA => LCD_DATA,
        distance_cm => distance_cm,
        DEBUG => DEBUG,
        start => start,
        cm => cm
    );
    PROCESS (distance)
        VARIABLE tmp : INTEGER;
    BEGIN
        tmp := to_integer(distance) / 5882;
        IF tmp > 255 THEN
            tmp := 255;
        END IF;
        if start = '1' then
            distance_cm <= STD_LOGIC_VECTOR(to_unsigned(tmp, 8));
        end if ;
    END PROCESS;

    identifier : PROCESS (Clock100MHz)
    BEGIN
        IF rising_edge(Clock100MHz) THEN
            IF btn2_pulse = '1' THEN
                IF start = '1' THEN
                    start <= '0';
                ELSE
                    start <= '1';
                END IF;
            END IF;
            IF btn1_pulse = '1' THEN
                IF cm = '1' THEN
                    cm <= '0';
                ELSE
                    cm <= '1';
                END IF;
            END IF;

            IF lcd_clk_cnt > 50000000 THEN
                lcd_reset <= '1';
                lcd_clk_cnt <= 0;
            ELSE
                lcd_reset <= '0';
            END IF;
            lcd_clk_cnt <= lcd_clk_cnt + 1;

        END IF;
    END PROCESS; -- identifier

END Behavioral;