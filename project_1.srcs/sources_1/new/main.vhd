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
        LCD_DATA   : out STD_LOGIC_VECTOR (3 downto 0);
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
        TRIG: OUT STD_LOGIC;
        ECHO: in STD_LOGIC
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

    component us is
    Port (
        Clock100MHz : in  STD_LOGIC;
        TRIG        : out STD_LOGIC;
        ECHO        : in  STD_LOGIC;
        DIST_OUT    : out unsigned(19 downto 0)
    );
    end COMPONENT ;

    SIGNAL btn0_pulse : STD_LOGIC;
    SIGNAL btn0_hold : STD_LOGIC;


    signal distance : unsigned(19 downto 0);
    signal distance_cm  : STD_LOGIC_VECTOR(7 downto 0);
    signal lcd_reset    : std_logic := '0';
    
    component lcd is
        Port (
            reset       : in  STD_LOGIC;
            Clock100MHz  : in  STD_LOGIC;
            LCD_RS      : out STD_LOGIC;
            LCD_E       : out STD_LOGIC;
            LCD_DATA    : out STD_LOGIC_VECTOR (3 downto 0);
            distance_cm : in  STD_LOGIC_VECTOR(7 downto 0);
            DEBUG: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

BEGIN


    -- Instantiate debouncer for BUTTON(0)
    debouncer_inst : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => lcd_reset,
        hold_out => btn0_hold
    );

    U1: us
    port map (
        Clock100MHz => Clock100MHz,
        TRIG        => TRIG,
        ECHO        => ECHO,
        DIST_OUT    => distance
    );

    U2: lcd
    port map (
        reset       => lcd_reset,
        Clock100MHz  => Clock100MHz,
        LCD_RS      => LCD_RS,
        LCD_E       => LCD_E,
        LCD_DATA    => LCD_DATA,
        distance_cm => distance_cm,
        DEBUG => DEBUG
    );


    process(distance)
        variable tmp : integer;
    begin
        tmp := to_integer(distance) / 5882;
        if tmp > 255 then tmp := 255; end if;
        distance_cm <= std_logic_vector(to_unsigned(tmp, 8));
    end process;


END Behavioral;
