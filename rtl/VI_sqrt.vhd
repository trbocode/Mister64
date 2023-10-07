library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;    

entity VI_sqrt is
   port 
   (
      clk               : in  std_logic;
      start             : in  std_logic;
      val_in            : in  unsigned(13 downto 0);
      val_out           : out unsigned(7 downto 0) := (others => '0')
   );
end entity;

architecture arch of VI_sqrt is
   
   signal step1_op      : unsigned(13 downto 0) := (others => '0'); 
   signal step1_result  : unsigned(13 downto 0) := (others => '0');
   signal step1_one     : unsigned(13 downto 0) := (others => '0');   
   signal step1_res     : unsigned(13 downto 0) := (others => '0');   
   
   signal step2_op      : unsigned(13 downto 0) := (others => '0'); 
   signal step2_result  : unsigned(13 downto 0) := (others => '0');
   signal step2_one     : unsigned(13 downto 0) := (others => '0');    
   signal step2_res     : unsigned(13 downto 0) := (others => '0');
   
   signal save_op       : unsigned(13 downto 0) := (others => '0'); 
   signal save_result   : unsigned(13 downto 0) := (others => '0');
   signal save_one      : unsigned(13 downto 0) := (others => '0');   
   
begin 

   val_out <= step2_result(6 downto 0) & '0';
   
   -- step1
   process (all)
   begin
      
      step1_res <= save_result;
      
      if (start = '1') then
            
         step1_op     <= val_in;
         step1_one    <= "01" & 12x"0";
         step1_result <= (others => '0');
         
      else
      
         step1_op  <= save_op;
         if (save_op >= (save_result or save_one)) then
            step1_op  <= save_op - (save_result or save_one);
            step1_res <= save_result or (save_one(12 downto 0) & '0');
         end if;
         step1_result <= '0' & step1_res(13 downto 1);
         step1_one    <= "00" & save_one(13 downto 2);

      end if;
   
   end process;
   
   -- step 2
   process (all)
   begin
      step2_res <= step1_result;
      step2_op  <= step1_op;
      if (step1_op >= (step1_result or step1_one)) then
         step2_op  <= step1_op - (step1_result or step1_one);
         step2_res <= step1_result or (step1_one(12 downto 0) & '0');
      end if;
      step2_result <= '0' & step2_res(13 downto 1);
      step2_one    <= "00" & step1_one(13 downto 2);
   end process;
   
   
  -- save
   process (clk)
   begin
      if rising_edge(clk) then
         save_op     <= step2_op;    
         save_result <= step2_result;
         save_one    <= step2_one;
      end if;
   end process;

end architecture;
