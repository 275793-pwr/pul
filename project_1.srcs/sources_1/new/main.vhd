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
        BUTTON : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        Clock100MHz : IN STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        SPI_SCK : OUT STD_LOGIC;
        SPI_MOSI : OUT STD_LOGIC;
        SPI_SS : OUT STD_LOGIC;
        LDAC : OUT STD_LOGIC
    );
END main;

ARCHITECTURE Behavioral OF main IS

    TYPE state_type IS (IDLE, SEND_REF, SEND_POWER, RUN, END_COMM);
    SIGNAL current_state, next_state : state_type := IDLE;

    SIGNAL led_state : STD_LOGIC := '0';

    COMPONENT debouncer IS
        PORT (
            clk : IN STD_LOGIC; -- Clock input
            button_in : IN STD_LOGIC; -- Raw button input
            pulse_out : OUT STD_LOGIC; -- Single pulse output
            hold_out : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT spi_master IS
        PORT (
            clk : IN STD_LOGIC;
            start : IN STD_LOGIC;
            data_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
            sck : OUT STD_LOGIC;
            mosi : OUT STD_LOGIC;
            ss : OUT STD_LOGIC;
            busy : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL btn0_pulse : STD_LOGIC;
    SIGNAL btn0_hold : STD_LOGIC;
    SIGNAL spi_busy : STD_LOGIC;
    SIGNAL spi_data_out : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
    SIGNAL spi_start_pulse : STD_LOGIC := '0'; -- New signal for SPI start pulse

    SIGNAL ref_command : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"2D0000"; -- REF command: Internal 2.5V
    SIGNAL power_command : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"400000"; -- POWER command: Normal operation
    SIGNAL voltage_command : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"8A8A8A"; -- Set Voltage

BEGIN

    -- Toggle LED on btn0_pulse
    PROCESS (Clock100MHz)
    BEGIN
        IF rising_edge(Clock100MHz) THEN
            IF btn0_pulse = '1' THEN
                led_state <= NOT led_state;
            END IF;
        END IF;
    END PROCESS;

    LED(0) <= led_state;

    -- Instantiate debouncer for BUTTON(0)
    debouncer_inst : debouncer
    PORT MAP(
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => btn0_pulse,
        hold_out => btn0_hold
    );

    -- Instantiate SPI Master
    spi_master_inst : spi_master
    PORT MAP(
        clk => Clock100MHz,
        start => spi_start_pulse, -- Connect to the new pulse signal
        data_in => spi_data_out, -- Connect data to be transmitted
        sck => SPI_SCK,
        mosi => SPI_MOSI,
        ss => SPI_SS,
        busy => spi_busy
    );

    -- LDAC control process
    PROCESS (Clock100MHz)
    BEGIN
        IF rising_edge(Clock100MHz) THEN
            IF current_state = IDLE THEN
                LDAC <= '0';
            ELSE
                LDAC <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- State machine to send configuration commands and data
    PROCESS (Clock100MHz)
    BEGIN
        IF rising_edge(Clock100MHz) THEN
            spi_start_pulse <= '0'; -- Default to low

            CASE current_state IS
                WHEN IDLE =>
                    IF btn0_pulse = '1' THEN
                        next_state <= SEND_REF;
                    END IF;
                WHEN SEND_REF =>
                    IF spi_busy = '0' THEN
                        spi_data_out <= ref_command;
                        spi_start_pulse <= '1'; -- Start REF command
                        next_state <= SEND_POWER;
                    END IF;
                WHEN SEND_POWER =>
                    IF spi_busy = '0' THEN
                        spi_data_out <= power_command;
                        spi_start_pulse <= '1'; -- Start POWER command
                        next_state <= RUN;
                    END IF;
                WHEN RUN =>
                    IF spi_busy = '0' THEN
                        spi_data_out <= voltage_command;
                        spi_start_pulse <= '1'; -- Start DAC data transmission
                        next_state <= END_COMM;
                    END IF;
                WHEN END_COMM =>
                    IF spi_busy = '0' THEN
                        next_state <= IDLE;
                    END IF;

            END CASE;
            current_state <= next_state;
        END IF;
    END PROCESS;

END Behavioral;