library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

entity VI_gammatable is
   port 
   (
      clk     : in  std_logic;
      addr    : in  unsigned(7 downto 0);
      data    : out unsigned(7 downto 0) := (others => '0')
   );
end entity;

architecture arch of VI_gammatable is
         
   type t_lookup is array(0 to 255) of unsigned(7 downto 0);  
   signal table : t_lookup := 
   (
      x"00", x"10", x"17", x"1c", x"20", x"24", x"27", x"2a", x"2d", x"30", x"33", x"35", x"37", x"3a", x"3c", x"3e",
      x"40", x"42", x"44", x"46", x"48", x"49", x"4b", x"4d", x"4e", x"50", x"52", x"53", x"55", x"56", x"58", x"59",
      x"5b", x"5c", x"5d", x"5f", x"60", x"61", x"63", x"64", x"65", x"66", x"68", x"69", x"6a", x"6b", x"6d", x"6e",
      x"6f", x"70", x"71", x"72", x"73", x"74", x"76", x"77", x"78", x"79", x"7a", x"7b", x"7c", x"7d", x"7e", x"7f",
      x"80", x"81", x"82", x"83", x"84", x"85", x"86", x"87", x"88", x"89", x"8a", x"8b", x"8b", x"8c", x"8d", x"8e",
      x"8f", x"90", x"91", x"92", x"93", x"94", x"94", x"95", x"96", x"97", x"98", x"99", x"99", x"9a", x"9b", x"9c",
      x"9d", x"9e", x"9e", x"9f", x"a0", x"a1", x"a2", x"a2", x"a3", x"a4", x"a5", x"a6", x"a6", x"a7", x"a8", x"a9",
      x"a9", x"aa", x"ab", x"ac", x"ac", x"ad", x"ae", x"af", x"af", x"b0", x"b1", x"b1", x"b2", x"b3", x"b4", x"b4",
      x"b5", x"b6", x"b6", x"b7", x"b8", x"b9", x"b9", x"ba", x"bb", x"bb", x"bc", x"bd", x"bd", x"be", x"bf", x"bf",
      x"c0", x"c1", x"c1", x"c2", x"c3", x"c3", x"c4", x"c5", x"c5", x"c6", x"c7", x"c7", x"c8", x"c8", x"c9", x"ca",
      x"ca", x"cb", x"cc", x"cc", x"cd", x"ce", x"ce", x"cf", x"cf", x"d0", x"d1", x"d1", x"d2", x"d2", x"d3", x"d4",
      x"d4", x"d5", x"d5", x"d6", x"d7", x"d7", x"d8", x"d8", x"d9", x"da", x"da", x"db", x"db", x"dc", x"dd", x"dd",
      x"de", x"de", x"df", x"df", x"e0", x"e1", x"e1", x"e2", x"e2", x"e3", x"e3", x"e4", x"e5", x"e5", x"e6", x"e6",
      x"e7", x"e7", x"e8", x"e8", x"e9", x"ea", x"ea", x"eb", x"eb", x"ec", x"ec", x"ed", x"ed", x"ee", x"ee", x"ef",
      x"ef", x"f0", x"f1", x"f1", x"f2", x"f2", x"f3", x"f3", x"f4", x"f4", x"f5", x"f5", x"f6", x"f6", x"f7", x"f7",
      x"f8", x"f8", x"f9", x"f9", x"fa", x"fa", x"fb", x"fb", x"fc", x"fc", x"fd", x"fd", x"fe", x"fe", x"ff", x"ff"
   );  
   attribute ramstyle : string;
   attribute ramstyle of table : signal is "M9K";
  
begin 

   process (clk)
   begin
      if (rising_edge(clk)) then
      
         data <= table(to_integer(addr));
         
      end if;
   end process;
   
end architecture;





