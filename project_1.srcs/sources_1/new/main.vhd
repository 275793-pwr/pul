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
    Port ( BUTTON : in STD_LOGIC_vector(3 downto 0);
        CLOCK: in std_logic;
           LED : out STD_LOGIC_vector(3 downto 0));
end main;

architecture Behavioral of main is

-- Define the debouncer component
component debouncer is
    port (
        clk           : in std_logic;
        button_in     : in std_logic;
        pulse_out    : out std_logic;
        hold_out: out std_logic
    );
end component;

-- Define signals
signal led_state: STD_LOGIC := '0';
signal btn: STD_LOGIC := '0';
signal hold_out: STD_LOGIC := '0';

begin


button_debouncer: debouncer
    port map (
        clk => CLOCK,
        button_in => BUTTON(0),
        pulse_out => btn,
        hold_out => hold_out
    );

main_proc: process(CLOCK)
begin
    if falling_edge(CLOCK) then
    
        if btn = '1' then
            led_state <= not led_state;
        end if;
        
        LED(0) <= led_state;
        LED(1) <= hold_out;
    end if;
end process main_proc;

end Behavioral;
