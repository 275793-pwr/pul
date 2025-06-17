LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY lcd IS
    PORT (
        reset : IN STD_LOGIC;
        Clock100MHz : IN STD_LOGIC;
        LCD_RS : OUT STD_LOGIC;
        LCD_E : OUT STD_LOGIC;
        LCD_DATA : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
        distance_cm : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        DEBUG : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        start : IN STD_LOGIC;
        cm : IN STD_LOGIC
    );
END lcd;

ARCHITECTURE Behavioral OF lcd IS

    -------------------------------------------------------------------------
    --  Definicja stan�w maszyny stan�w (FSM)
    -------------------------------------------------------------------------
    TYPE STATE_TYPE IS (
        CONFIGURATION1, CONFIGURATION2, CONFIGURATION3, CONFIGURATION4,
        FUNC_SET, DISPLAY_OFF, DISPLAY_CLEAR, DISPLAY_ON, MODE_SET,
        SET_CURSOR_FIRST_LINE, SET_CURSOR_SECOND_LINE, WRITE_CHAR, RETURN_HOME,
        SEND_UPPER, TOGGLE_E, SEND_LOWER, TOGGLE_E2, HOLD
    );

    SIGNAL state : STATE_TYPE := CONFIGURATION1;
    SIGNAL next_command : STATE_TYPE := CONFIGURATION2;

    SIGNAL LCD_DATA_VALUE : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL lcd_clk : STD_LOGIC := '0';
    SIGNAL lcd_clk_cnt : INTEGER RANGE 0 TO 50000 := 0;

    SIGNAL char_no : unsigned(5 DOWNTO 0) := (OTHERS => '0');
    SIGNAL DOUT : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL reset_cnt : unsigned(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL znak : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ready : BOOLEAN := true;
    SIGNAL line_no : INTEGER RANGE 1 TO 2 := 1;

    -------------------------------------------------------------------------
    --  Zmienne do przetwarzania liczby na znaki ASCII
    -------------------------------------------------------------------------
    SIGNAL val_int : INTEGER RANGE 0 TO 255 := 0;
    SIGNAL last_val_int : INTEGER := - 1;
    SIGNAL update_request : STD_LOGIC := '0';

    SIGNAL setki : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dziesiatki : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL jednosci : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL init_done : STD_LOGIC := '0';

BEGIN

    -------------------------------------------------------------------------
    --  Generator zegara co 2.5 ms (do sterowania FSM)
    -------------------------------------------------------------------------
    PROCESS (Clock100MHz)
    BEGIN
        IF rising_edge(Clock100MHz) THEN
            IF reset = '1' THEN
                lcd_clk_cnt <= 0;
                lcd_clk <= '0';
            ELSE
                IF lcd_clk_cnt = 50000 THEN
                    lcd_clk_cnt <= 0;
                    lcd_clk <= NOT lcd_clk;
                ELSE
                    lcd_clk_cnt <= lcd_clk_cnt + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -------------------------------------------------------------------------
    --  Proces przekszta�caj�cy warto�� liczbow� na ASCII (co 2.5 ms)
    -------------------------------------------------------------------------
    PROCESS (lcd_clk)
    BEGIN
        IF rising_edge(lcd_clk) THEN
            val_int <= to_integer(unsigned(distance_cm));
            IF val_int /= last_val_int AND init_done = '1' THEN
                last_val_int <= val_int;
                setki <= STD_LOGIC_VECTOR(to_unsigned(48 + val_int / 100, 8));
                dziesiatki <= STD_LOGIC_VECTOR(to_unsigned(48 + (val_int / 10) MOD 10, 8));
                jednosci <= STD_LOGIC_VECTOR(to_unsigned(48 + val_int MOD 10, 8));
                update_request <= '1';
            END IF;
        END IF;
    END PROCESS;

    -------------------------------------------------------------------------
    --  FSM do obs�ugi wy�wietlacza LCD
    -------------------------------------------------------------------------
    PROCESS (lcd_clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= CONFIGURATION1;
            LCD_DATA_VALUE <= (OTHERS => '0');
            next_command <= CONFIGURATION2;
            LCD_E <= '1';
            LCD_RS <= '0';
            init_done <= '0';
            line_no <= 1;
            char_no <= (OTHERS => '0');
            update_request <= '0';
        ELSIF rising_edge(lcd_clk) THEN
            IF update_request = '1' AND state = HOLD AND init_done = '1' THEN
                update_request <= '0';
                char_no <= (OTHERS => '0');
                state <= RETURN_HOME;
                next_command <= WRITE_CHAR;
            ELSE
                DEBUG <= STD_LOGIC_VECTOR(to_unsigned(STATE_TYPE'pos(state), 8));
                CASE state IS
                    WHEN CONFIGURATION1 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        IF reset_cnt = to_unsigned(9, 4) THEN
                            next_command <= CONFIGURATION2;
                            state <= SEND_LOWER;
                        END IF;

                    WHEN CONFIGURATION2 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        IF reset_cnt = to_unsigned(11, 4) THEN
                            next_command <= CONFIGURATION3;
                            state <= SEND_LOWER;
                        END IF;

                    WHEN CONFIGURATION3 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000011";
                        reset_cnt <= reset_cnt + 1;
                        IF reset_cnt = to_unsigned(12, 4) THEN
                            next_command <= CONFIGURATION4;
                            state <= SEND_LOWER;
                        END IF;

                    WHEN CONFIGURATION4 =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000010";
                        next_command <= FUNC_SET;
                        state <= SEND_LOWER;

                    WHEN FUNC_SET =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00101000";
                        next_command <= DISPLAY_OFF;
                        state <= SEND_UPPER;

                    WHEN DISPLAY_OFF =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00001000";
                        next_command <= DISPLAY_CLEAR;
                        state <= SEND_UPPER;

                    WHEN DISPLAY_CLEAR =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000001";
                        next_command <= DISPLAY_ON;
                        state <= SEND_UPPER;

                    WHEN DISPLAY_ON =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00001100";
                        next_command <= MODE_SET;
                        state <= SEND_UPPER;

                    WHEN MODE_SET =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000110";
                        next_command <= SET_CURSOR_FIRST_LINE;
                        state <= SEND_UPPER;

                    WHEN SET_CURSOR_FIRST_LINE =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "10000000"; -- Command for first line
                        next_command <= WRITE_CHAR;
                        state <= SEND_UPPER;

                    WHEN SET_CURSOR_SECOND_LINE =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "11000000"; -- Command for second line
                        next_command <= WRITE_CHAR;
                        state <= SEND_UPPER;

                    WHEN WRITE_CHAR =>
                        LCD_RS <= '1';
                        LCD_DATA_VALUE <= DOUT;
                        char_no <= char_no + 1;
                        state <= SEND_UPPER;
                        IF char_no = 15 AND line_no = 1 THEN -- After writing 16 characters on the first line
                            next_command <= SET_CURSOR_SECOND_LINE;
                            line_no <= 2;
                            char_no <= (OTHERS => '0'); -- Reset char_no for the second line
                        ELSIF char_no = 15 AND line_no = 2 THEN -- After writing 16 characters on the second line
                            state <= HOLD;
                            next_command <= HOLD;
                            init_done <= '1';
                        ELSE
                            next_command <= WRITE_CHAR;
                        END IF;

                    WHEN RETURN_HOME =>
                        LCD_RS <= '0';
                        LCD_DATA_VALUE <= "00000010"; -- Return home command
                        next_command <= SET_CURSOR_FIRST_LINE;
                        state <= SEND_UPPER;

                    WHEN SEND_UPPER =>
                        LCD_E <= '1';
                        LCD_DATA <= LCD_DATA_VALUE(7 DOWNTO 4);
                        state <= TOGGLE_E;

                    WHEN TOGGLE_E =>
                        LCD_E <= '0';
                        state <= SEND_LOWER;

                    WHEN SEND_LOWER =>
                        LCD_E <= '1';
                        LCD_DATA <= LCD_DATA_VALUE(3 DOWNTO 0);
                        state <= TOGGLE_E2;

                    WHEN TOGGLE_E2 =>
                        LCD_E <= '0';
                        state <= HOLD;

                    WHEN HOLD =>
                        IF ready THEN
                            LCD_E <= '1';

                            IF next_command = WRITE_CHAR THEN
                                LCD_RS <= '1';
                            END IF;

                            state <= next_command;
                            ready <= false;
                        ELSE
                            ready <= true;
                        END IF;

                    WHEN OTHERS =>
                        state <= next_command;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -------------------------------------------------------------------------
    --  Znak do wy�wietlenia zale�ny od indeksu char_no
    -------------------------------------------------------------------------
    PROCESS (lcd_clk, reset, state)
    BEGIN
        IF reset = '1' THEN
            znak <= "01001000"; -- H
        ELSIF falling_edge(lcd_clk) THEN
            IF state = WRITE_CHAR THEN
                IF line_no = 1 THEN

                    IF cm = '1' THEN
                        CASE to_integer(char_no) IS
                            WHEN 0 => znak <= "01000100";
                            WHEN 1 => znak <= "01111001";
                            WHEN 2 => znak <= "01110011";
                            WHEN 3 => znak <= "01110100";
                            WHEN 4 => znak <= "01100001";
                            WHEN 5 => znak <= "01101110";
                            WHEN 6 => znak <= "01110011";
                            WHEN 7 => znak <= "00111010";

                            WHEN 9 => znak <= setki;
                            WHEN 10 => znak <= dziesiatki;
                            WHEN 11 => znak <= jednosci;

                            WHEN 12 => znak <= "01100011";
                            WHEN 13 => znak <= "01101101";
                            WHEN OTHERS => znak <= "00100000"; -- space
                        END CASE;
                    ELSE
                        CASE to_integer(char_no) IS
                            WHEN 0 => znak <= "01000100";
                            WHEN 1 => znak <= "01111001";
                            WHEN 2 => znak <= "01110011";
                            WHEN 3 => znak <= "01110100";
                            WHEN 4 => znak <= "01100001";
                            WHEN 5 => znak <= "01101110";
                            WHEN 6 => znak <= "01110011";
                            WHEN 7 => znak <= "00111010";
                            
                            WHEN 9 => znak <= setki;
                            WHEN 10 => znak <= "00101110";
                            WHEN 11 => znak <= dziesiatki;
                            WHEN 12 => znak <= jednosci;

                            WHEN 13 => znak <= "01101101";
                            WHEN OTHERS => znak <= "00100000"; -- space
                        END CASE;
                    END IF;
                ELSE

                    IF start = '1' THEN
                        CASE to_integer(char_no) IS
                            WHEN 0 => znak <= "01010011";
                            WHEN 1 => znak <= "01010100";
                            WHEN 2 => znak <= "01000001";
                            WHEN 3 => znak <= "01010010";
                            WHEN 4 => znak <= "01010100";
                            WHEN OTHERS => znak <= "00100000"; -- space
                        END CASE;
                    ELSE
                        CASE to_integer(char_no) IS
                            WHEN 0 => znak <= "01010011";
                            WHEN 1 => znak <= "01010100";
                            WHEN 2 => znak <= "01001111";
                            WHEN 3 => znak <= "01010000";
                            WHEN OTHERS => znak <= "00100000"; -- space

                        END CASE;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    DOUT <= znak;

END Behavioral;