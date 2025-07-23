library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MemManager is
    port (
        clk      : in  std_logic;
        en       : in  std_logic;                      
        rst      : in  std_logic;
        data_in  : in  std_logic_vector (16 downto 0);                      
        data_out : out std_logic_vector(31 downto 0);
        read_addr: out std_logic_vector(22 downto 0);
        CE       : out std_logic;
        OE       : out std_logic;
        WE       : out std_logic;
        rdy      : out std_logic                      
    );
end MemManager;

architecture Behavioral of MemManager is
  type state_type is (IDLE, STAT_READ, PICTURE_READ, NEXT_PICTURE);
  signal state : state_type := IDLE;
  
  signal read_en : std_logic := '0';
  signal read_rdy : std_logic;
  signal video_len : std_logic_vector (31 downto 0);
  signal video_len_cntr : std_logic_vector (2 downto 0) := (others => '0');
  signal address_reg : std_logic_vector (20 downto 0);
  signal read_output : std_logic_vector (15 downto 0);
  
  type array_Picture is array (0 to 255) of std_logic_vector (31 downto 0);
  signal picture_array : array_Picture;
  signal out_array : array_Picture;
  
  signal picture_rdy : std_logic := '0';
  signal px_cntr : std_logic_vector (7 downto 0);
  signal px : std_logic_vector (31 downto 0);
  signal read_cntr : std_logic_vector (1 downto 0) := (others => '0');
  signal picture_cntr : std_logic_vector (31 downto 0) := (others => '0');

  signal px_out : std_logic_vector (31 downto 0);
  
  component MemReader is 
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
  end component;
begin
  
  mr : MemReader port map(
    clk => clk,
    rst => rst,
    addr_in => address_reg,
    data_in => data_in,
    read_en => read_en,
    data_out => read_output,
    read_addr => read_addr,
    CE => CE,
    OE => OE,
    WE => WE,
    rdy => rdy
  );


  FSM: process(clk, rst)
  begin
    if (rst = '1') then
      CE <= '1';OE <= '1';
      state <= IDLE;
    elsif (rising_edge(clk)) then 
      case state is
        when IDLE =>
          if (en = '1') then
            state <= STAT_READ;
          end if;
        when STAT_READ =>
          address_reg <= (others => '0');
          read_en <= '1';
          if (read_rdy = '1') then

            if (unsigned(video_len_cntr) = 0) then
              video_len(15 downto 0) <= read_output;
            elsif (unsigned(video_len_cntr) = 1) then
              video_len(31 downto 16)<= read_output;
              state <= PICTURE_READ;
              address_reg <= std_logic_vector(unsigned(address_reg) + 1);
            end if;
            
            video_len_cntr <= std_logic_vector(unsigned(video_len_cntr) + 1); 
          end if;
        when PICTURE_READ =>
          read_en <= '1';
          if (read_rdy = '1') then

            px(16 + unsigned(read_cntr)*15 downto 0 + unsigned(read_cntr)*15) <= read_output;

            read_cntr <= std_logic_vector(unsigned(read_cntr) + 1);
            address_reg <= std_logic_vector(unsigned(address_reg) + 1);
            if (unsigned(read_cntr) >= 2) then
              read_cntr <= (others => '0');
              picture_array(unsigned(px_cntr)) = px;
              px_cntr <= std_logic_vector(unsigned(px_cntr) + 1);
              if (unsigned(px_cntr) = 255) then
                px_cntr <= (others => '0');
                picture_cntr <= std_logic_vector(unsigned(picture_cntr) + 1);
                state <= NEXT_PICTURE;
              end if;
            end if;
          end if;
        when NEXT_PICTURE => then
          read_en <= '0';
          picture_rdy <= '1';
          out_array <= picture_array;
          state <= PICTURE_READ;
          if ( unsigned(picture_cntr) >= unsigned(video_len)) then
            address_reg <= std_logic_vector(2);
          end if;
      end case;
    end if;
    
  end process;
  
  
  
end Behavioral;