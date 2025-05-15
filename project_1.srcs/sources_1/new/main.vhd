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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity main is
    Port (  
        BUTTON : in STD_LOGIC_vector(3 downto 0);
        Clock100MHz: in std_logic;
        LED : out STD_LOGIC_vector(3 downto 0);
        SPI_SCK : out std_logic;
        SPI_MOSI : out std_logic;
        SPI_SS : out std_logic;
        LDAC : out std_logic
        );
end main;

architecture Behavioral of main is

signal led_state : std_logic := '0';

component debouncer is
    port (
        clk           : in std_logic;         -- Clock input
        button_in     : in std_logic;         -- Raw button input
        pulse_out     : out std_logic;        -- Single pulse output
        hold_out      : out std_logic
    );
end component;

component spi_master is
    Port (
        clk : in std_logic;
        start : in std_logic;
        data_in : in std_logic_vector(23 downto 0);
        sck : out std_logic;
        mosi : out std_logic;
        ss : out std_logic;
        busy : out std_logic
    );
end component;

signal btn0_pulse : std_logic;
signal btn0_hold : std_logic;
signal spi_busy : std_logic;
signal spi_data_out : std_logic_vector(23 downto 0) := (others => '0');

begin

    -- Toggle LED on btn0_pulse
    process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then
            if btn0_pulse = '1' then
                led_state <= not led_state;
            end if;
        end if;
    end process;

    LED(0) <= led_state;

    -- Instantiate debouncer for BUTTON(0)
    debouncer_inst : debouncer
    port map (
        clk => Clock100MHz,
        button_in => BUTTON(0),
        pulse_out => btn0_pulse,
        hold_out => btn0_hold
    );

    -- Instantiate SPI Master
    spi_master_inst : spi_master
    Port map (
        clk => Clock100MHz,
        start => btn0_pulse,
        data_in => spi_data_out, -- Connect data to be transmitted
        sck => SPI_SCK,
        mosi => SPI_MOSI,
        ss => SPI_SS,
        busy => spi_busy
    );

    -- Example data to transmit (replace with actual data for MAX5705)
    -- For MAX5705, the data format is typically 24 bits:
    -- [Control Bits (4)] [DAC Data (16)] [Don't Care (4)]
    -- Example: Write to DAC A (0011), Data = 0x1234 (0001 0010 0011 0100), Don't Care (0000)
    -- Total 24 bits: 0011_0001_0010_0011_0100_0000
    spi_data_out <= x"312340"; -- Example data: Write to DAC A with data 0x1234


end Behavioral;
