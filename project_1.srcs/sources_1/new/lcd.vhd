library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd is
    PORT(
        reset        : in  STD_LOGIC;
        Clock100MHz   : in  STD_LOGIC;
        LCD_RS       : out STD_LOGIC;
        LCD_E        : out STD_LOGIC;
        LCD_DATA     : out STD_LOGIC_VECTOR (3 DOWNTO 0);
        distance_cm  : in  STD_LOGIC_VECTOR (7 DOWNTO 0);
        DEBUG: out STD_LOGIC_VECTOR(7 downto 0)
    );
end lcd;

architecture Behavioral of lcd is

    -------------------------------------------------------------------------
    --  Definicja stan�w maszyny stan�w (FSM)
    -------------------------------------------------------------------------
    TYPE STATE_TYPE IS (
        CONFIGURATION1, CONFIGURATION2, CONFIGURATION3, CONFIGURATION4,
        FUNC_SET, DISPLAY_OFF, DISPLAY_CLEAR, DISPLAY_ON, MODE_SET,
        SET_CURSOR_FIRST_LINE, WRITE_CHAR, RETURN_HOME,
        SEND_UPPER, TOGGLE_E, SEND_LOWER, TOGGLE_E2, HOLD
    );

    signal state         : STATE_TYPE := CONFIGURATION1;
    signal next_command  : STATE_TYPE := CONFIGURATION2;

    signal LCD_DATA_VALUE : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
    signal lcd_clk     : STD_LOGIC := '0';
    signal lcd_clk_cnt  : integer range 0 to 50000 := 0;

    signal char_no        : unsigned(5 downto 0) := (others => '0');
    signal DOUT           : STD_LOGIC_VECTOR (7 DOWNTO 0);
    signal reset_cnt      : unsigned(3 downto 0) := (others => '0');
    signal znak           : STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
    signal ready          : boolean := true;

    -------------------------------------------------------------------------
    --  Zmienne do przetwarzania liczby na znaki ASCII
    -------------------------------------------------------------------------
    signal val_int        : integer range 0 to 255 := 0;
    signal last_val_int   : integer := -1;
    signal update_request : STD_LOGIC := '0';

    signal setki          : STD_LOGIC_VECTOR(7 downto 0);
    signal dziesiatki     : STD_LOGIC_VECTOR(7 downto 0);
    signal jednosci       : STD_LOGIC_VECTOR(7 downto 0);

    signal init_done      : STD_LOGIC := '0';

begin

    -------------------------------------------------------------------------
    --  Generator zegara co 2.5 ms (do sterowania FSM)
    -------------------------------------------------------------------------
    process(Clock100MHz)
    begin
        if rising_edge(Clock100MHz) then
            if reset = '1' then
                lcd_clk_cnt <= 0;
                lcd_clk <= '0';
            else
                if lcd_clk_cnt = 50000 then
                    lcd_clk_cnt <= 0;
                    lcd_clk <= not lcd_clk;
                else
                    lcd_clk_cnt <= lcd_clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    --  Proces przekszta�caj�cy warto�� liczbow� na ASCII (co 2.5 ms)
    -------------------------------------------------------------------------
    process(lcd_clk)
    begin
        if rising_edge(lcd_clk) then
            val_int <= to_integer(unsigned(distance_cm));
            if val_int /= last_val_int and init_done = '1' then
                last_val_int <= val_int;
                setki      <= std_logic_vector(to_unsigned(48 + val_int / 100, 8));
                dziesiatki <= std_logic_vector(to_unsigned(48 + (val_int / 10) mod 10, 8));
                jednosci   <= std_logic_vector(to_unsigned(48 + val_int mod 10, 8));
                update_request <= '1';
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    --  FSM do obs�ugi wy�wietlacza LCD
    -------------------------------------------------------------------------
    process(lcd_clk, reset)
    begin
        if reset = '1' then
            state <= CONFIGURATION1;
            LCD_DATA_VALUE <= (others => '0');
            next_command <= CONFIGURATION2;
            LCD_E <= '1';
            LCD_RS <= '0';
            init_done <= '0';
            char_no <= (others => '0');
            update_request <= '0';
        elsif rising_edge(lcd_clk) then
            if update_request = '1' and state = HOLD and init_done = '1' then
                update_request <= '0';
                char_no <= (others => '0');
                state <= RETURN_HOME;
                next_command <= WRITE_CHAR;
            else
                DEBUG <= std_logic_vector(to_unsigned(STATE_TYPE'pos(state), 8));
                case state is
                    when CONFIGURATION1 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        if reset_cnt = to_unsigned(9, 4) then
                            next_command <= CONFIGURATION2;
                            state <= SEND_LOWER;
                        end if;

                    when CONFIGURATION2 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        if reset_cnt = to_unsigned(11, 4) then
                            next_command <= CONFIGURATION3;
                            state <= SEND_LOWER;
                        end if;

                    when CONFIGURATION3 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        if reset_cnt = to_unsigned(12, 4) then
                            next_command <= CONFIGURATION4;
                            state <= SEND_LOWER;
                        end if;

                    when CONFIGURATION4 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000010";
                        next_command <= FUNC_SET;
                        state <= SEND_LOWER;

                    when FUNC_SET =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00101000";
                        next_command <= DISPLAY_OFF;
                        state <= SEND_UPPER;

                    when DISPLAY_OFF =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00001000";
                        next_command <= DISPLAY_CLEAR;
                        state <= SEND_UPPER;

                    when DISPLAY_CLEAR =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000001";
                        next_command <= DISPLAY_ON;
                        state <= SEND_UPPER;

                    when DISPLAY_ON =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00001100";
                        next_command <= MODE_SET;
                        state <= SEND_UPPER;

                    when MODE_SET =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000110";
                        next_command <= SET_CURSOR_FIRST_LINE;
                        state <= SEND_UPPER;

                    when SET_CURSOR_FIRST_LINE =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "10000000";
                        next_command <= WRITE_CHAR;
                        state <= SEND_UPPER;

                    when WRITE_CHAR =>
                    if char_no = to_unsigned(16, 6) then
                        state <= HOLD;
                        next_command <= HOLD;
                        init_done <= '1';
                        else
                            LCD_RS <= '1';
                            LCD_DATA_VALUE <= DOUT;
                            char_no <= char_no + 1;
                            state <= SEND_UPPER;
                            next_command <= WRITE_CHAR;
                        end if;

                    when RETURN_HOME =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "10000000";
                        next_command <= WRITE_CHAR;
                        state <= SEND_UPPER;

                    when SEND_UPPER =>
                        LCD_E <= '1';
                        LCD_DATA <= LCD_DATA_VALUE(7 downto 4);
                        state <= TOGGLE_E;

                    when TOGGLE_E =>
                        LCD_E <= '0';
                        state <= SEND_LOWER;

                    when SEND_LOWER =>
                        LCD_E <= '1';
                        LCD_DATA <= LCD_DATA_VALUE(3 downto 0);
                        state <= TOGGLE_E2;

                    when TOGGLE_E2 =>
                        LCD_E <= '0';
                        state <= HOLD;

                    when HOLD =>
                        if ready then
                            LCD_E <= '1';
                            
                            if next_command = WRITE_CHAR then
                                LCD_RS <= '1';
                            end if ;
                            
                            state <= next_command;
                            ready <= false;
                        else
                            ready <= true;
                        end if;

                    when others =>
                        state <= next_command;
                end case;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    --  Znak do wy�wietlenia zale�ny od indeksu char_no
    -------------------------------------------------------------------------
    process(lcd_clk, reset)
    begin
        if reset = '1' then
            znak <= "01000010"; -- D
        elsif rising_edge(lcd_clk) then
            if state = WRITE_CHAR then
                case char_no is
                    when "000000" => znak <= "01000100"; -- D
                    when "000001" => znak <= "01000011"; -- Y
                    when "000010" => znak <= "01000010"; -- S
                    when "000011" => znak <= "01000001"; -- T
                    when "000100" => znak <= "01000001"; -- A
                    when others  => znak <= "01000100"; -- puste
                end case;
            end if;
        end if;
    end process;

    DOUT <= znak;

end Behavioral;
