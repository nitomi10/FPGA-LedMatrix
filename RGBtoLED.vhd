
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RGBtoLED is
	Port(
	clk : in std_logic;
	en : in std_logic;
	reset: in std_logic;
	r: in std_logic_vector(7 downto 0);
	g: in std_logic_vector(7 downto 0);
	b: in std_logic_vector(7 downto 0);
	wr: in std_logic;
	rdy: out std_logic;
	dout: out std_logic
	);
end RGBtoLED;

architecture Behavioral of RGBtoLED is

	signal sentOne : std_logic;
	signal sendBit : std_logic;
	signal colourData : std_logic_vector (23 downto 0):= R&G&B;
	signal currentBit : std_logic:= colourData(23);
	signal sentNum : integer;
	
	
	type State_type is (idle,sending,done);
	signal State: State_type;
	
begin
	sender:entity bitSender (Behavioral)
	port map(
		clk => clk,
		en => en,
		reset => reset,
		wr => sendBit,
		input => currentBit,
		rdy => sentOne,
		output=> dout
	);

process(clk,reset)begin
	if(reset = '1') then
		sentNum <= 0;
		colourData <= G&R&B;
		currentBit <= colourData(23);
		sendBit <= '0';
	elsif(rising_edge(clk))then
		if(en = '1') then
			case State is
				when idle =>
					sentNum <= 0;
					colourData <= G&R&B;
					currentBit <= colourData(23);
					sendBit <= '0';
					if(wr = '1') then
						State<= sending; 
					end if;
				when sending =>
					if(wr = '1') then
						colourData <= G&R&B;
						currentBit <= colourData((23-sentNum));
						if(sentNum <24)then
							rdy<='0';
							sendBit<='1';
							if(sentOne='1')then
								sendBit<= '0';
								sentNum<= sentNum +1;
								currentBit<= colourData(23-sentNum);
							end if;
						else
							sendBit<='0';
							state<= done;
						end if;
					else
						sendBit<='0';
					end if;
				when done =>
					rdy <= '1';
					state <= idle;
					
				when others =>
					State <= idle;	
			end case;
		end if;
	end if;
end process;

end Behavioral;

