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
  type state_type is (IDLE, STAT_READ, PICTURE_READ, READ_WAIT);
  signal state : state_type := IDLE;
  
  type out_state_type is (WAITING, OUTPUTING);
  signal out_state : out_state_type := WAITING;

  signal read_en : std_logic := '0';
  signal read_rdy : std_logic;
  signal video_len : std_logic_vector (31 downto 0);
  signal video_len_cntr : std_logic_vector (2 downto 0) := (others => '0');
  signal address_reg : std_logic_vector (20 downto 0);
  signal read_output : std_logic_vector (15 downto 0);
    
  signal px_cntr : std_logic_vector (7 downto 0);
  signal read_cntr : std_logic_vector (2 downto 0) := (others => '0');
  signal picture_cntr : std_logic_vector (31 downto 0) := (others => '0');
  signal read_wait_cntr: std_logic_vector (2 downto 0) := (others => '0');
  signal output_cntr: std_logic_vector (2 downto 0) := (others => '0');

  
  signal px : std_logic_vector (31 downto 0);
  signal px_buffer    : std_logic_vector (31 downto 0);
  signal px_out    : std_logic_vector (31 downto 0);
  signal px_rdy : std_logic := '0';
  

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
    rdy => read_rdy
  );


  READ_FSM: process(clk, rst)
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
            elsif (unsigned(video_len_cntr) >= 7) then
              state <= PICTURE_READ;
              address_reg <= std_logic_vector(unsigned(address_reg) + 1);
            end if;
            
            video_len_cntr <= std_logic_vector(unsigned(video_len_cntr) + 1); 
          end if;
        when PICTURE_READ =>
          read_en <= '1';
          if (read_rdy = '1') then
            state <= READ_WAIT;

            if(unsigned(read_cntr) mod 2 = 0) then
              px(31  downto 16 ) <= read_output;
            else then
              px(16  downto 0 ) <= read_output;
              px_buffer <= px;
              px_ready <= '1';
              if (px(7) = '1') then
                picture_cntr <= std_logic_vector(unsigned(picture_cntr) + 1);
              end if;  
            end if;
              
            read_cntr <= std_logic_vector(unsigned(read_cntr) + 1);

          end if;
        when READ_WAIT =>
          read_en <= '1';
          if ( unsigned(read_wait_cntr) >= 3) then
            state <= PICTURE_READ;
            read_wait_cntr <= (others => '0');
          end if;
          if (unsigned(read_cntr) >= 7) then
              read_cntr <= (others => '0');
              if(unsigned(picture_cntr) < unsigned(video_len)) then
                address_reg <= std_logic_vector(unsigned(address_reg) + 1);
              else
                address_reg <= std_logic_vector(1);
              end if;
              
          end if
          read_wait_cntr <= std_logic_vector(unsigned(read_wait_cntr) + 1);
      end case;
    end if;
    
  end process;
  
  OUT_FSM: process(clk, rst)
  begin
    if (rst = '1') then
      CE <= '1';OE <= '1';
    elsif (rising_edge(clk)) then 
      case out_state is
        when WAITING =>
          if(px_ready = '1') then
            px_ready <= '0';
            px_out <= px_buffer;
            out_state <= OUTPUTING;
          end if;
        when OUTPUTING =>
          if(unsigned(output_cntr) = 1)then
            rdy <= '1';
          elsif (unsigned(output_cntr) >= 2) then
            rdy <= '0';
            output_cntr <= (others => '0');
            out_state <= WAITING;
          end if;
          output_cntr <= std_logic_vector(unsigned(output_cntr) + 1);
          
      end case;
    end if;
  end process;
  
  
end Behavioral;