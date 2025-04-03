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
        SevenSegmens: out STD_LOGIC_vector(7 downto 0);
        SevenSegmentDigits: out STD_LOGIC_vector(3 downto 0)
        );
end main;

architecture Behavioral of main is


function integer_to_bcd (integer_val : natural) return STD_LOGIC_vector is
    variable bcd_val : STD_LOGIC_vector(15 downto 0) := (others => '0');
    variable temp_val : natural := integer_val;
    variable digit : natural;
begin
    for i in 0 to 3 loop
        digit := temp_val mod 10;
        temp_val := temp_val / 10;
        bcd_val(i*4+3 downto i*4) := std_logic_vector(to_unsigned(digit, 4));
    end loop;
    return bcd_val;
end function;


signal data_bcd : STD_LOGIC_vector(15 downto 0) := (others => '0');

signal segment_digit: STD_LOGIC_vector(3 downto 0) := (others => '0');
signal selected_segment: UNSIGNED(1 downto 0) := (others => '0');
signal segments: STD_LOGIC_vector(7 downto 0) := (others => '0');
signal digits : STD_LOGIC_vector (3 downto 0) := (others => '0');

signal timer : UNSIGNED(31 downto 0) := (others => '0');
signal timer_seconds : UNSIGNED(15 downto 0) := (others => '0');

signal digit_showing_timer : UNSIGNED(31 downto 0) := (others => '0');

begin


    RUN_TIMER : process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then
            if timer < 100000000 then
                timer <= timer + 1;
            else
                timer <= (others => '0');
                timer_seconds <= timer_seconds + 1;
            end if;
        end if;
    end process;


    RUN_DIGIT_TIMER : process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then
            if digit_showing_timer < 100000 then
                digit_showing_timer <= digit_showing_timer + 1;
                
                if selected_segment = "00" then
                    segment_digit <= data_bcd(3 downto 0);
                elsif selected_segment = "01" then
                    segment_digit <= data_bcd(7 downto 4);
                elsif selected_segment = "10" then
                    segment_digit <= data_bcd(11 downto 8);
                elsif selected_segment = "11" then
                    segment_digit <= data_bcd(15 downto 12);
                end if;
            else
                digit_showing_timer <= (others => '0');
                if selected_segment = "11" then
                    selected_segment <= "00";
                else
                    selected_segment <= selected_segment + 1;
                end if;

            end if;
        end if;
    end process;


    seven_seg : process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then

            if segment_digit = x"0" then
                segments <= "11000000";
            elsif segment_digit = x"1" then
                segments <= "11111001";
            elsif segment_digit = x"2" then
                segments <= "10100100";
            elsif segment_digit = x"3" then
                segments <= "10110000";
            elsif segment_digit = x"4" then
                segments <= "10011001";
            elsif segment_digit = x"5" then
                segments <= "10010010";
            elsif segment_digit = x"6" then
                segments <= "10000010";
            elsif segment_digit = x"7" then
                segments <= "11111000";
            elsif segment_digit = x"8" then
                segments <= "10000000";
            elsif segment_digit = x"9" then
                segments <= "10010000";
            end if;
            
        end if;
    end process ; -- seven_seg
    

    digit_selector : process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then
            case selected_segment is
            
                when "00" =>
                    digits <= "1110";
            
                when "01" =>
                    digits <= "1101";
            
                when "10" =>
                    digits <= "1011";
            
                when "11" =>
                    digits <= "0111";
            
                when others =>
                    digits <= "1111";
            
            end case;
        end if;
    end process;


    
    main_proc: process(Clock100MHz)
    begin
        if falling_edge(Clock100MHz) then
        
            SevenSegmens <= segments;
            SevenSegmentDigits <= digits;
            data_bcd <= integer_to_bcd(to_integer(timer_seconds));
            
        end if;
    end process main_proc;

end Behavioral;
