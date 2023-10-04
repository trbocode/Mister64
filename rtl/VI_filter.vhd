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
      clk1x                            : in  std_logic;
      reset                            : in  std_logic;
      
      VI_DEDITHEROFF                   : in  std_logic;
      VI_AAOFF                         : in  std_logic;
      
      VI_CTRL_AA_MODE                  : in  unsigned(1 downto 0);
      VI_CTRL_DEDITHER_FILTER_ENABLE   : in  std_logic;
      
      proc_pixel                       : in  std_logic;
      proc_border                      : in  std_logic;
      proc_x                           : in  unsigned(9 downto 0);        
      proc_y                           : in  unsigned(9 downto 0);
      proc_pixel_Mid                   : in  tfetchelement := (others => (others => '0'));
      proc_pixels_AA                   : in  tfetcharray_AA := (others => (others => (others => '0')));
      proc_pixels_DD                   : in  tfetcharray_DD := (others => (others => (others => '0')));
                     
      filter_pixel                     : out std_logic := '0';
      filter_x_out                     : out unsigned(9 downto 0) := (others => '0');        
      filter_y_out                     : out unsigned(9 downto 0) := (others => '0');
      filter_color                     : out tfetchelement := (others => (others => '0'))
   );
end entity;

architecture arch of VI_filter is

   signal mid_color        : tcolor := (others => (others => '0'));
   signal mid_color_1      : tcolor := (others => (others => '0'));

   -- dedither
   type t_dedithercolor is array(0 to 7) of tcolor;
   signal dedithercolor    : t_dedithercolor := (others => (others => (others => '0')));

   type t_deditheradd is array(0 to 2) of integer range -8 to +8;
   signal dedither_add     : t_deditheradd;
   
   type t_dedither_result is array(0 to 2) of integer range -8 to 263;
   signal dedither_result  : t_dedither_result;
   signal dedither_clamp   : t_dedither_result;
   
   signal dedither_out     : tcolor := (others => (others => '0'));
   
   -- Anti Aliasing
   signal penmin           : tcolor := (others => (others => '0'));
   signal penmax           : tcolor := (others => (others => '0'));
   
   signal penmin_1         : tcolor := (others => (others => '0'));
   signal penmax_1         : tcolor := (others => (others => '0'));
   
   type t_pendiff is array(0 to 2) of signed(9 downto 0);   
   signal pendiff          : t_pendiff := (others => (others => '0'));
   
   signal inv_c            : unsigned(2 downto 0);
   
   type tdiff_mul is array(0 to 2) of signed(12 downto 0);      
   signal diff_mul         : tdiff_mul := (others => (others => '0'));
   signal diff_add4        : tdiff_mul := (others => (others => '0'));
   
   signal AA_result        : tcolor := (others => (others => '0'));
   
   -- pipelining
   signal stage0_ena       : std_logic := '0';
   signal stage0_border    : std_logic := '0';
   signal stage0_x         : unsigned(9 downto 0) := (others => '0');        
   signal stage0_y         : unsigned(9 downto 0) := (others => '0');
   signal stage0_Mid       : tfetchelement := (others => (others => '0'));
   
begin 

   mid_color(0) <= proc_pixel_Mid.r;
   mid_color(1) <= proc_pixel_Mid.g;
   mid_color(2) <= proc_pixel_Mid.b;   
   
   mid_color_1(0) <= stage0_Mid.r;
   mid_color_1(1) <= stage0_Mid.g;
   mid_color_1(2) <= stage0_Mid.b;

   -- dedither
   process(all)
      variable dither_calc : integer range -8 to +8;
   begin
      
      for i in 0 to 7 loop
         dedithercolor(i)(0) <= proc_pixels_DD(i).r;
         dedithercolor(i)(1) <= proc_pixels_DD(i).g;
         dedithercolor(i)(2) <= proc_pixels_DD(i).b;
      end loop;

      for c in 0 to 2 loop
         dither_calc := 0;
         for i in 0 to 7 loop
            if (dedithercolor(i)(c)(7 downto 3) > mid_color(c)(7 downto 3)) then
               dither_calc := dither_calc + 1;
            elsif (dedithercolor(i)(c)(7 downto 3) < mid_color(c)(7 downto 3)) then
               dither_calc := dither_calc - 1;
            end if;
         end loop;
         dedither_add(c) <= dither_calc;
      end loop;
      
      for c in 0 to 2 loop
         dedither_result(c) <= to_integer(mid_color(c)) + dedither_add(c);
         if (dedither_result(c) > 255) then
            dedither_clamp(c) <= 255;
         else
            dedither_clamp(c) <= dedither_result(c);
         end if;
      end loop;
      
   end process;
   
   -- Anti Aliasing
   iVI_filter_pen : entity work.VI_filter_pen 
   port map
   (
      proc_pixels_AA   => proc_pixels_AA,
      mid_color        => mid_color,
      penmin           => penmin,        
      penmax           => penmax        
   );
   
   process(all)
   begin
      
      for i in 0 to 2 loop
         
         pendiff(i) <= ("00" & signed(penmin_1(i))) + ("00" & signed(penmax_1(i))) - ('0' & signed(mid_color_1(i)) & '0');
         
         diff_mul(i) <= to_signed(to_integer(pendiff(i)) * to_integer(inv_c), 13);
         
         diff_add4(i) <= diff_mul(i) + 4;
         
         AA_result(i) <= mid_color_1(i) + unsigned(diff_add4(i)(10 downto 3));

      end loop;

   end process;
   
   
   
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         -- stage 0
         stage0_ena     <= proc_pixel;
         stage0_border  <= proc_border;
         stage0_x       <= proc_x;
         stage0_y       <= proc_y;
         stage0_Mid     <= proc_pixel_Mid;
         
         for i in 0 to 2 loop
            dedither_out(i) <= to_unsigned(dedither_clamp(i), 8);
            
            penmin_1(i) <= penmin(i);
            penmax_1(i) <= penmax(i);
         end loop;
             
         inv_c <= to_unsigned(7, 3) - proc_pixel_Mid.c;
         
         -- stage 1
         filter_pixel <= stage0_ena;
         filter_x_out <= stage0_x;
         filter_y_out <= stage0_y;
         filter_color <= stage0_Mid;
         if (stage0_border = '1') then
            filter_color <= (others => (others => '0'));
         elsif (stage0_Mid.c = 7 and VI_CTRL_DEDITHER_FILTER_ENABLE = '1' and VI_DEDITHEROFF = '0') then
            filter_color.r <= dedither_out(0);
            filter_color.g <= dedither_out(1);
            filter_color.b <= dedither_out(2);
         elsif (stage0_Mid.c < 7 and VI_CTRL_AA_MODE(1) = '0' and VI_AAOFF = '0') then
            filter_color.r <= AA_result(0);
            filter_color.g <= AA_result(1);
            filter_color.b <= AA_result(2);
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
               color32 := 5x"0" & filter_color.c & filter_color.r & filter_color.g & filter_color.b;
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





