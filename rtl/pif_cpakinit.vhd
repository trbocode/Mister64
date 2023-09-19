library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pif_cpakinit is
   port
   (
      clk       : in std_logic;
      address   : in std_logic_vector(6 downto 0);
      data      : out std_logic_vector(31 downto 0)
   );
end entity;

architecture arch of pif_cpakinit is

   type t_rom is array(0 to 127) of std_logic_vector(31 downto 0);
   signal rom : t_rom :=
   ( 
      x"03020181", 
      x"07060504", 
      x"0B0A0908",
      x"0F0E0D0C", 
      x"13121110", 
      x"17161514",
      x"1B1A1918", 
      x"1F1E1D1C", 
      x"FFFFFFFF",
      x"135F1A05", 
      x"00000000", 
      x"00000000",
      x"FFFFFFFF", 
      x"FFFFFFFF", 
      x"FF01FFFF",
      x"CD992566", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"FFFFFFFF", 
      x"135F1A05", 
      x"00000000",
      x"00000000", 
      x"FFFFFFFF", 
      x"FFFFFFFF",
      x"FF01FFFF", 
      x"CD992566", 
      x"FFFFFFFF",
      x"135F1A05", 
      x"00000000", 
      x"00000000",
      x"FFFFFFFF", 
      x"FFFFFFFF", 
      x"FF01FFFF",
      x"CD992566", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"FFFFFFFF", 
      x"135F1A05", 
      x"00000000",
      x"00000000", 
      x"FFFFFFFF", 
      x"FFFFFFFF",
      x"FF01FFFF", 
      x"CD992566", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00000000", 
      x"00000000",
      x"00000000", 
      x"00007100", 
      x"00000000",
      x"03000000", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"03000300", 
      x"03000300", 
      x"03000300",
      x"00000000",
      x"00000000",
      x"00000000",
      x"00000000",
      x"00000000",
      x"00000000",
      x"00000000",
      x"00000000"
   );

begin

   process (clk) 
   begin
      if rising_edge(clk) then
         data <= rom(to_integer(unsigned(address)));
      end if;
   end process;

end architecture;
