library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use STD.textio.all;

library mem;
use work.pVI.all;
use work.pFunctions.all;

entity VI_filter is
   port 
   (
      clk1x              : in  std_logic;
      reset              : in  std_logic;
      
      proc_pixel         : in  std_logic;
      proc_border        : in  std_logic;
      proc_x             : in  unsigned(9 downto 0);        
      proc_y             : in  unsigned(9 downto 0);
      proc_pixel_Mid     : in  tfetchelement;
      proc_pixels_AA     : in  tfetcharray_AA;
      proc_pixels_DD     : in  tfetcharray_DD;
      
      filter_pixel       : out std_logic := '0';
      filter_x_out       : out unsigned(9 downto 0) := (others => '0');        
      filter_y_out       : out unsigned(9 downto 0) := (others => '0');
      filter_color       : out tfetchelement
   );
end entity;

architecture arch of VI_filter is

   
begin 
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         filter_pixel <= '0';
      
         if (reset = '1') then
         
           
         
         else
         
            if (proc_pixel = '1') then
               filter_pixel <= '1';
               filter_x_out <= proc_x;
               filter_y_out <= proc_y;
               filter_color <= proc_pixel_Mid;
               if (proc_border = '1') then
                  filter_color <= (others => (others => '0'));
               end if;
            end if;
            
         end if;
   
      end if;
   end process;

--##############################################################
--############################### export
--##############################################################
   
   -- synthesis translate_off
   goutput : if 1 = 1 generate
      signal tracecounts : integer := 0;
   begin
   
      process
         file outfile      : text;
         variable f_status : FILE_OPEN_STATUS;
         variable line_out : line;
         variable color32  : unsigned(31 downto 0);         
      begin
   
         file_open(f_status, outfile, "R:\\vi_n64_1_sim.txt", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "R:\\vi_n64_1_sim.txt", append_mode);

         while (true) loop
            
            wait until rising_edge(clk1x);
            
            if (filter_pixel = '1') then
               write(line_out, string'(" X ")); 
               write(line_out, to_string_len(to_integer(filter_x_out), 5));
               write(line_out, string'(" Y ")); 
               write(line_out, to_string_len(to_integer(filter_y_out), 5));
               write(line_out, string'(" C "));
               color32 := 5x"0" & proc_pixel_Mid.c & proc_pixel_Mid.r & proc_pixel_Mid.g & proc_pixel_Mid.b;
               write(line_out, to_hstring(color32));
               writeline(outfile, line_out);
               tracecounts <= tracecounts + 1;
            end if;
            
         end loop;
         
      end process;
   
   end generate goutput;

   goutput2 : if 1 = 1 generate
      signal tracecounts2 : integer := 0;
   begin
   
      process
         file outfile      : text;
         variable f_status : FILE_OPEN_STATUS;
         variable line_out : line;
         variable color32  : unsigned(31 downto 0);         
      begin
   
         file_open(f_status, outfile, "R:\\vi_n64_2_sim.txt", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "R:\\vi_n64_2_sim.txt", append_mode);

         while (true) loop
            
            wait until rising_edge(clk1x);
            
            if (filter_pixel = '1') then
               write(line_out, string'(" X ")); 
               write(line_out, to_string_len(to_integer(filter_x_out), 5));
               write(line_out, string'(" Y ")); 
               write(line_out, to_string_len(to_integer(filter_y_out), 5));
               write(line_out, string'(" C "));
               color32 := 5x"0" & filter_color.c & filter_color.r & filter_color.g & filter_color.b;
               write(line_out, to_hstring(color32));
               writeline(outfile, line_out);
               tracecounts2 <= tracecounts2 + 1;
            end if;
            
         end loop;
         
      end process;
   
   end generate goutput2;

   -- synthesis translate_on  
   
   
end architecture;





