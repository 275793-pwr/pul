library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity spi_master is
    Port (
        clk : in std_logic;
        start : in std_logic;
        data_in : in std_logic_vector(23 downto 0);
        sck : out std_logic;
        mosi : out std_logic;
        ss : out std_logic;
        busy : out std_logic
    );
end spi_master;

architecture Behavioral of spi_master is

    type state_type is (IDLE, START_TX, SEND_BIT, END_TX);
    signal current_state, next_state : state_type := IDLE;
    signal bit_count : integer range 0 to 24 := 0;
    signal spi_sck_int : std_logic := '0';
    signal spi_mosi_int : std_logic := '0';
    signal spi_ss_int : std_logic := '1';
    signal busy_int : std_logic := '0';
    signal data_buffer : std_logic_vector(23 downto 0) := (others => '0');
    signal clk_div_counter : std_logic_vector(8 downto 0) := (others => '0');

begin

    sck <= spi_sck_int;
    mosi <= spi_mosi_int;
    ss <= spi_ss_int;
    busy <= busy_int;

    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
            case current_state is
                when IDLE =>
                    if start = '1' then
                        next_state <= START_TX;
                        data_buffer <= data_in;
                        busy_int <= '1';
                    else
                        next_state <= IDLE;
                        busy_int <= '0';
                    end if;
                    spi_ss_int <= '1'; -- Ensure SS is high in IDLE
                    spi_sck_int <= '0'; -- Ensure SCK is low in IDLE
                    clk_div_counter <= (others => '0');

                when START_TX =>
                    spi_ss_int <= '0'; -- Assert SS low
                    spi_sck_int <= '0'; -- Start with SCK low
                    bit_count <= 0;
                    clk_div_counter <= (others => '0');
                    next_state <= SEND_BIT;

                when SEND_BIT =>
                    if bit_count < 24 then
                        if clk_div_counter = 255 then -- Toggle SCK every 8 clock cycles
                            spi_sck_int <= not spi_sck_int;
                            clk_div_counter <= (others => '0');
                            if spi_sck_int = '0' then -- Data is valid on the rising edge of SCK
                                spi_mosi_int <= data_buffer(23 - bit_count); -- Send MSB first
                            end if;
                            if spi_sck_int = '1' then -- Data is sampled on the falling edge of SCK
                                bit_count <= bit_count + 1;
                            end if;
                        end if;
                        clk_div_counter <= clk_div_counter + 1;
                        next_state <= SEND_BIT;

                    else
                        next_state <= END_TX;
                    end if;

                when END_TX =>
                    spi_ss_int <= '1'; -- Deassert SS high
                    spi_sck_int <= '0'; -- Ensure SCK is low
                    busy_int <= '0';
                    clk_div_counter <= (others => '0');
                    next_state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
