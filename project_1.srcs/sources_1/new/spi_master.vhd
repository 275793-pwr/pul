LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY spi_master IS
    PORT (
        clk : IN STD_LOGIC;
        start : IN STD_LOGIC;
        data_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        sck : OUT STD_LOGIC;
        mosi : OUT STD_LOGIC;
        ss : OUT STD_LOGIC;
        busy : OUT STD_LOGIC
    );
END spi_master;

ARCHITECTURE Behavioral OF spi_master IS

    TYPE state_type IS (IDLE, START_TX, SEND_BIT, END_TX);
    SIGNAL current_state, next_state : state_type := IDLE;
    SIGNAL bit_count : INTEGER RANGE 0 TO 24 := 0;
    SIGNAL spi_sck_int : STD_LOGIC := '0';
    SIGNAL spi_mosi_int : STD_LOGIC := '0';
    SIGNAL spi_ss_int : STD_LOGIC := '1';
    SIGNAL busy_int : STD_LOGIC := '0';
    SIGNAL data_buffer : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
    SIGNAL clk_div_counter : INTEGER RANGE 0 TO 255000 := 0; -- Counter for clock division by 8

BEGIN

    sck <= spi_sck_int;
    mosi <= spi_mosi_int;
    ss <= spi_ss_int;
    busy <= busy_int;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            current_state <= next_state;
            CASE current_state IS
                WHEN IDLE =>
                    IF start = '1' THEN
                        next_state <= START_TX;
                        data_buffer <= data_in;
                        busy_int <= '1';
                    ELSE
                        clk_div_counter <= 0;
                        next_state <= IDLE;
                        busy_int <= '0';
                    END IF;
                    spi_ss_int <= '1'; -- Ensure SS is high in IDLE
                    spi_sck_int <= '0'; -- Ensure SCK is low in IDLE
                    clk_div_counter <= 0;

                WHEN START_TX =>
                    spi_ss_int <= '0'; -- Assert SS low
                    spi_sck_int <= '0'; -- Start with SCK low
                    bit_count <= 0;
                    clk_div_counter <= 0;
                    next_state <= SEND_BIT;

                WHEN SEND_BIT =>
                    IF bit_count < 24 THEN

                        IF clk_div_counter = 20 THEN -- Toggle SCK every 8 clock cycles
                            -- spi_sck_int <= not spi_sck_int;
                            IF spi_sck_int = '0' THEN -- Data is valid on the rising edge of SCK
                                spi_mosi_int <= data_buffer(23 - bit_count); -- Send MSB first
                            END IF;
                            IF spi_sck_int = '1' THEN -- Data is sampled on the falling edge of SCK
                                bit_count <= bit_count + 1;
                            END IF;
                        END IF;

                        IF clk_div_counter = 250 THEN -- Toggle SCK every 8 clock cycles
                            clk_div_counter <= 0;
                            spi_sck_int <= NOT spi_sck_int;
                        END IF;
                        clk_div_counter <= clk_div_counter + 1;
                        next_state <= SEND_BIT;

                    ELSE
                        next_state <= END_TX;
                        clk_div_counter <= 0;
                    END IF;

                WHEN END_TX =>
                    spi_ss_int <= '1'; -- Deassert SS high
                    spi_sck_int <= '0'; -- Ensure SCK is low
                    IF clk_div_counter = 250000 THEN
                        next_state <= IDLE;
                    END IF;
                    clk_div_counter <= clk_div_counter + 1;

            END CASE;
        END IF;
    END PROCESS;

END Behavioral;