library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bitSender is
	Port(
	clk : in std_logic;
	en : in std_logic;
	reset: in std_logic;
	wr: in std_logic;
	input: in std_logic;
	rdyOut: out std_logic;
	output: out std_logic
	);
end bitSender;

architecture Behavioral of bitSender is

type State_type is (idle,one,send,zero,done);
	signal State: State_type;
	signal prevState: State_type;

signal switchState : std_logic:= '0';
signal delayCounter : integer range 0 to 21 := 0;
signal rdy : std_logic:='0';
signal rdy_ff : std_logic:='0'; 

begin


rdyOut <= not(rdy) and rdy_ff;
rdy<= '1' when State=one
	else '0';

process(clk,reset)
begin
	if(falling_edge(reset))then
		State <= idle;
	elsif rising_edge(clk) then
		if(en = '1') then
			if(switchState = '1') then
				prevState <= State;
				case State is
					when idle =>
						output <='0';
						if(wr = '1') then
							State <= one;
						end if;
						
					when one =>
						output <= '1';
						State <= send;
						
					when send =>
						if(input = '1') then
							output <= '1';
						elsif(input = '0') then
							output <= '0';
						end if;
						State <= zero;
						
					when zero =>
						output <= '0';
						if (wr = '1') then
							State <= one;
						else
							State <= idle;
						end if;
						
					when others =>
						State <= idle;
						
				end case;
			end if;
		end if;
		if(prevState /= idle)then
		rdy_ff <= rdy;
		end if;
	end if;
end process;

process(clk,reset)
begin
	if(falling_edge(reset))then
		delayCounter <= 0;
	elsif rising_edge(clk) then
		if(delayCounter < 20) then
			delayCounter<= delayCounter + 1;
			switchState<= '0';
		else
			delayCounter<= 0;
			switchState<= '1';
		end if;
	end if;
	
end process;

end Behavioral;

