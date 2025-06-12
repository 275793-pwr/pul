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

    -- COMPONENT lcd IS
    --     PORT (
    --         CLK : IN STD_LOGIC;
            
    --         -- Control signals from main module
    --         char_to_display : IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Data/Command to send
    --         send_data : IN STD_LOGIC; -- '1' to send data, '0' to send command (This port is no longer needed with trigger_pos/char)
    --         trigger_send : IN STD_LOGIC; -- Pulse '1' to trigger generic send (command or data)
    --         trigger_clear : IN STD_LOGIC; -- Pulse '1' to trigger clear command
    --         trigger_pos : IN STD_LOGIC;
    --         trigger_char : IN STD_LOGIC;
    --         col : IN INTEGER RANGE 0 TO 15;
    --         row : IN INTEGER RANGE 0 TO 1;
            
    --         -- LCD Interface signals
    --         LCD_RS : OUT STD_LOGIC;
    --         LCD_E : OUT STD_LOGIC;
    --         LCD_DB4 : OUT STD_LOGIC;
    --         LCD_DB5 : OUT STD_LOGIC;
    --         LCD_DB6 : OUT STD_LOGIC;
    --         LCD_DB7 : OUT STD_LOGIC;
        
    --         LCD_busy : OUT STD_LOGIC -- '1' when LCD is busy processing
    --     );
    -- END COMPONENT;

    SIGNAL btn0_pulse : STD_LOGIC;
    SIGNAL btn0_hold : STD_LOGIC;


    signal distance_val : unsigned(19 downto 0);
    signal distance_cm  : STD_LOGIC_VECTOR(7 downto 0);
    signal lcd_reset    : std_logic := '0';
    
    component lcd
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

    -- Instantiate LCD
    -- lcd_inst : lcd
    -- PORT MAP (
    --     CLK => Clock100MHz,
    --     char_to_display => lcd_char_data,
    --     send_data => lcd_send_data_cmd, -- This port is likely unused in the updated lcd component
    --     trigger_send => lcd_trigger_send,
    --     trigger_clear => lcd_trigger_clear,
    --     trigger_pos => lcd_trigger_pos,
    --     trigger_char => lcd_trigger_char,
    --     col => lcd_col,
    --     row => lcd_row,
    --     LCD_RS => LCD_RS,
    --     LCD_E => LCD_E,
    --     LCD_DB4 => LCD_DB4,
    --     LCD_DB5 => LCD_DB5,
    --     LCD_DB6 => LCD_DB6,
    --     LCD_DB7 => LCD_DB7,
    --     LCD_busy => lcd_busy
    -- );

    -- Instantiate debouncer for BUTTON(0)
    debouncer_inst : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => lcd_reset,
        hold_out => btn0_hold
    );

    -- process(Clock100MHz)
    -- begin
    --     if rising_edge(Clock100MHz) then
    --         if pulse_out = '1' then
    --             lcd_reset <= '1';
    --         else
    --             lcd_reset <= '0';
    --         end if;
    --     end if;
    -- end process;

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


END Behavioral;
