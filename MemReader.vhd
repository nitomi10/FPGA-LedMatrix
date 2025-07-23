
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MemReader is
    port (
        clk      : in  std_logic;                      
        rst      : in  std_logic;                      
        addr_in  : in  std_logic_vector(20 downto 0);  
        data_in  : in  std_logic_vector(15 downto 0);
        read_en  : in  std_logic; 
        data_out : out std_logic_vector(15 downto 0);
        read_addr: out std_logic_vector(23 downto 0);
        CE       : out std_logic;
        OE       : out std_logic;
        WE       : out std_logic;
        rdy      : out std_logic                      
    );
end MemReader;
architecture Behavioral of MemReader is
  type state_type is (IDLE, READ, HOLD);
  signal state : state_type := IDLE;
  signal read_addr_reg : std_logic_vector(23 downto 0);
  signal first_read    : std_logic:= '1';
  signal cur_addr      : std_logic_vector(20 downto 0):= (others => '0');
  signal data_reg      : std_logic_vector(15 downto 0):= (others => '0');
  
  signal addr_cntr     : std_logic_vector(2 downto 0):= (others => '0');
  signal firstrd_cntr  : std_logic_vector(2 downto 0):= (others => '0');
  signal hold_cntr     : std_logic_vector(1 downto 0):= (others => '0');
begin
 
  
  
  R_FSM: process(clk, rst)
  begin
    if (rst = '0') then
      CE <= '1';OE <= '1';
      state <= IDLE;
    elsif (rising_edge(clk)) then
      case state is
        when IDLE =>
          if(read_en = '1') then
            cur_addr <= addr_in;
            first_read <= '1';
            state <= READ;
          end if;
        when READ =>
          CE <= '0'; OE <= '0';
          read_addr_reg <= cur_addr & addr_cntr;
          if (first_read = '1') then
            if (unsigned(firstrd_cntr) = 7 ) then
                firstrd_cntr <= (others => '0');
                first_read <= '0';
                state <= HOLD;
            else
                firstrd_cntr <= std_logic_vector(unsigned(firstrd_cntr) + 1);
            end if;
          else
            state <= HOLD;
          end if;
        when HOLD =>
          data_reg <= data_in;
          if (unsigned(hold_cntr) = 3) then
            rdy <= '0';
            if(unsigned(addr_cntr) = 7) then
              state <= IDLE;
              addr_cntr <= (others => '0');
            else
              state <= READ;
              addr_cntr <= std_logic_vector(unsigned(addr_cntr) + 1);
            end if;
          elsif (unsigned(hold_cntr) = 1) then
            rdy <= '1';
            hold_cntr <= std_logic_vector(unsigned(hold_cntr) + 1);
          else
            hold_cntr <= std_logic_vector(unsigned(hold_cntr) + 1);
          end if;
      end case;
    end if;
  end process;
  
  WE <= '1';
  read_addr <= read_addr_reg;
  data_out <= data_reg;
end Behavioral;