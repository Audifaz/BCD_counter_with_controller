----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2019 08:20:20 AM
-- Design Name: 
-- Module Name: Main - Behavioral
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
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Main is
Port (     S : in STD_LOGIC_VECTOR(8 downto 0);
           clock_100Mhz : in STD_LOGIC;-- 100Mhz clock on Basys 3 FPGA board
           reset : in STD_LOGIC; -- start
           Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
           LED_out : out STD_LOGIC_VECTOR (6 downto 0);
           Operate: out STD_LOGIC);
end Main;

architecture Behavioral of Main is
signal one_second_counter: STD_LOGIC_VECTOR (27 downto 0);
-- counter for generating 1-second clock enable
signal one_second_enable: std_logic;
-- one second enable for counting numbers
-- counting decimal number to be displayed on 4-digit 7-segment display
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
Signal BCD,counter: STD_LOGIC_VECTOR(3 downto 0);
Signal enable:STD_LOGIC;
-- creating 10.5ms refresh period
signal LED_activating_counter: std_logic_vector(1 downto 0);
-- the other 2-bit for creating 4 LED-activating signals
-- count         0    ->  1  ->  2  ->  3
-- activates    LED1    LED2   LED3   LED4
-- and repeat

component encoder    
Port ( Decimal : in STD_LOGIC_VECTOR(8 downto 0);
    BiCD: out STD_LOGIC_VECTOR(3 downto 0));
end component;

component Comparator
    Port ( X,Y : in STD_LOGIC_VECTOR(3 downto 0);
    Equal: out STD_LOGIC);
end component;




begin
--copy machine

DecToBCD: encoder port map(Decimal=>S, BiCD=>BCD);

process(clock_100Mhz,reset,BCD,counter,enable)
begin
    if  (reset = '0') then
        counter <= "0000";
        enable <= '1';
    elsif (clock_100Mhz'event and clock_100Mhz = '1') then
        if enable = '1' then
            -- START BCD_COMPARATOR :
            if (counter = BCD) then
                enable <= '0';  
            elsif (one_second_enable='1') then 
                counter <= counter + 1;
            end if;
            -- END BCD_COMPARATOR
        else
            counter <= counter;
        end if;
    end if;
end process;
--END BCD_COUNTER 
Operate<=enable;


-- VHDL code for BCD to 7-segment decoder
-- Cathode patterns of the 7-segment LED display 
process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => LED_out <= "0000001"; -- "0"     
    when "0001" => LED_out <= "1001111"; -- "1" 
    when "0010" => LED_out <= "0010010"; -- "2" 
    when "0011" => LED_out <= "0000110"; -- "3" 
    when "0100" => LED_out <= "1001100"; -- "4" 
    when "0101" => LED_out <= "0100100"; -- "5" 
    when "0110" => LED_out <= "0100000"; -- "6" 
    when "0111" => LED_out <= "0001111"; -- "7" 
    when "1000" => LED_out <= "0000000"; -- "8"     
    when "1001" => LED_out <= "0000100"; -- "9" 
    when "1010" => LED_out <= "1100010"; -- "o" 
    when "1011" => LED_out <= "1101010"; -- "n" 
    when "1100" => LED_out <= "0111000"; -- "f"    
    when others => LED_out <= "1111111"; -- nada
    end case;
end process;
-- 7-segment display controller
-- generate refresh period of 10.5ms
process(clock_100Mhz,reset)
begin 
    if(reset='0') then
        refresh_counter <= (others => '0');
    elsif(rising_edge(clock_100Mhz)) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;
 LED_activating_counter <= refresh_counter(19 downto 18);
-- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
process(LED_activating_counter,counter,enable)
begin
    case LED_activating_counter is
    when "00" =>
        Anode_Activate <= "0111"; 
        -- activate LED1 and Deactivate LED2, LED3, LED4
        LED_BCD<="1010";--o
        -- the first hex digit of the 16-bit number
    when "01" =>
        Anode_Activate <= "1011"; 
        -- activate LED2 and Deactivate LED1, LED3, LED4
        if (enable='1') then
        LED_BCD<="1011";--n
        else
        LED_BCD<="1100";--f       
        end if;
        -- the second hex digit of the 16-bit number
    when "10" =>
        Anode_Activate <= "1101"; 
        -- activate LED3 and Deactivate LED2, LED1, LED4
        if (enable='1') then
        LED_BCD<="1111"; --nada       
        else  
        LED_BCD<="1100";--f     
        end if;
        -- the third hex digit of the 16-bit number
    when "11" =>
        Anode_Activate <= "1110"; 
        -- activate LED4 and Deactivate LED2, LED3, LED1
        LED_BCD <= counter;
        -- the fourth hex digit of the 16-bit number    
    end case;
end process;
-- Counting the number to be displayed on 4-digit 7-segment Display 
-- on Basys 3 FPGA board
process(clock_100Mhz, reset)
begin
        if(reset='0') then
            one_second_counter <= (others => '0');
        elsif(rising_edge(clock_100Mhz)) then
            if(one_second_counter>=x"5F5E0FF") then
                one_second_counter <= (others => '0');
            else
                one_second_counter <= one_second_counter + "0000001";
            end if;
        end if;
end process;
one_second_enable <= '1' when one_second_counter=x"5F5E0FF" else '0';
end Behavioral;
