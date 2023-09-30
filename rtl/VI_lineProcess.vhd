library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

library mem;
use work.pVI.all;
use work.pFunctions.all;

entity VI_lineProcess is
   port 
   (
      clk1x              : in  std_logic;
      reset              : in  std_logic;
      
      VI_CTRL_TYPE       : in unsigned(1 downto 0);
      VI_WIDTH           : in unsigned(11 downto 0);
      
      newFrame           : in  std_logic;
      doubleProc         : in  std_logic;
      startProc          : in  std_logic;
      
      fetchAddr          : out unsigned(11 downto 0) := (others => '0');
      fetchdata          : in  unsigned(31 downto 0);
      
      proc_pixel         : out std_logic := '0';
      proc_border        : out std_logic := '0';
      proc_x             : out unsigned(9 downto 0) := (others => '0');        
      proc_y             : out unsigned(9 downto 0) := (others => '0');
      proc_pixel_Mid     : out tfetchelement;
      proc_pixels_AA     : out tfetcharray_AA;
      proc_pixels_DD     : out tfetcharray_DD
   );
end entity;

architecture arch of VI_lineProcess is

   type tstate is
   (
      IDLE,
      FETCH0,
      FETCH1,
      FETCH2,
      FETCH3,
      NEXTPIXEL
   );
   signal state         : tstate := IDLE; 
   
   signal fetchHigh     : unsigned(1 downto 0) := (others => '0');
   
   signal firstword16   : std_logic := '0';     
   signal prefetch      : integer range 0 to 5 := 0;     
   
   signal fetchshift0   : tfetchshift := (others => (others => (others => '0')));
   signal fetchshift1   : tfetchshift := (others => (others => (others => '0')));
   signal fetchshift2   : tfetchshift := (others => (others => (others => '0')));
   
   signal fetchelement  : tfetchelement;
   signal fetchdata16   : unsigned(15 downto 0);
   
   signal lineEnd       : std_logic;

begin 
  
   fetchdata16 <= byteswap16(fetchdata(15 downto 0)) when (firstword16 = '1') else byteswap16(fetchdata(31 downto 16));
  
   process (all)
   begin
      if (VI_CTRL_TYPE = "11") then
         fetchelement.r <= fetchdata( 7 downto  0);
         fetchelement.g <= fetchdata(15 downto  8);
         fetchelement.b <= fetchdata(23 downto 16);
         fetchelement.c <= fetchdata(26 downto 24);
      else
         fetchelement.r <= fetchdata16(15 downto 11) & "000";
         fetchelement.g <= fetchdata16(10 downto  6) & "000";
         fetchelement.b <= fetchdata16( 5 downto  1) & "000";
         fetchelement.c <= fetchdata16(0) & "00";
      end if;
   end process;
   
   proc_pixel_Mid    <= fetchshift1(2);
   
   proc_pixels_AA(0) <= fetchshift0(1);
   proc_pixels_AA(1) <= fetchshift0(3);
   proc_pixels_AA(2) <= fetchshift1(0);
   proc_pixels_AA(3) <= fetchshift1(4);
   proc_pixels_AA(4) <= fetchshift2(1);
   proc_pixels_AA(5) <= fetchshift2(3);
   
   proc_pixels_DD(0) <= fetchshift0(1);
   proc_pixels_DD(1) <= fetchshift0(2);
   proc_pixels_DD(2) <= fetchshift0(3);
   proc_pixels_DD(3) <= fetchshift1(1);
   proc_pixels_DD(4) <= fetchshift1(3);
   proc_pixels_DD(5) <= fetchshift2(1);
   proc_pixels_DD(6) <= fetchshift2(2);
   proc_pixels_DD(7) <= fetchshift2(3);
   
   lineEnd <= '1' when (proc_x > VI_WIDTH + 1) else '0';
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
         
         proc_pixel <= '0';
         
         if (reset = '1') then
         
            state <= IDLE;
         
         else
         
            case (state) is
            
               when IDLE =>
                  if (newFrame = '1') then
                     proc_y    <= (others => '0');
                     fetchHigh <= "00";
                  end if;
                  if (startProc = '1') then
                     fetchAddr   <= fetchHigh & 10x"0";
                     firstword16 <= '1';
                     state       <= FETCH0;
                     proc_x      <= (others => '0');    
                     prefetch    <= 5;
                     proc_border <= '1';
                  end if;
            
               when FETCH0 =>
                  state <= FETCH1;
                  fetchAddr(11 downto 10) <= fetchAddr(11 downto 10) + 1;
                  
               when FETCH1 =>
                  state <= FETCH2;
                  fetchAddr(11 downto 10) <= fetchAddr(11 downto 10) + 1;
                  for i in 0 to 3 loop
                     fetchshift0(i) <= fetchshift0(i + 1);
                  end loop;
                  fetchshift0(4) <= fetchelement;
                  
               when FETCH2 =>
                  state <= FETCH3;
                  fetchAddr(11 downto 10) <= fetchHigh;
                  for i in 0 to 3 loop
                     fetchshift1(i) <= fetchshift1(i + 1);
                  end loop;
                  fetchshift1(4) <= fetchelement;
                  
               when FETCH3 =>
                  if (prefetch > 0) then
                     prefetch <= prefetch - 1;
                     state    <= FETCH0;
                  else
                     proc_pixel  <= '1';
                     state       <= NEXTPIXEL;
                     if (lineEnd = '1') then
                        proc_border <= '1';
                     end if;
                  end if;
                  
                  firstword16 <= not firstword16;
                  if (VI_CTRL_TYPE = "11" or firstword16 = '0') then
                     fetchAddr(9 downto 0) <= fetchAddr(9 downto 0) + 1;
                  end if;
                  
                  for i in 0 to 3 loop
                     fetchshift2(i) <= fetchshift2(i + 1);
                  end loop;
                  fetchshift2(4) <= fetchelement;
            
               when NEXTPIXEL =>
                  state       <= FETCH0;
                  proc_x      <= proc_x + 1;
                  proc_border <= '0';
                  if (lineEnd = '1') then
                     state     <= IDLE;
                     proc_y    <= proc_y + 1;
                     if (doubleProc = '1') then
                        fetchHigh <= fetchHigh + 2;
                     else 
                        fetchHigh <= fetchHigh + 1;
                     end if;
                  end if;
            
            end case;
            
         end if;
   
      end if;
   end process;
   
end architecture;





