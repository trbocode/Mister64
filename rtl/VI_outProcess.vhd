library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use STD.textio.all;

library mem;
use work.pVI.all;
use work.pFunctions.all;

entity VI_outProcess is
   port 
   (
      clk1x              : in  std_logic;
      reset              : in  std_logic;
      
      VI_BILINEAROFF     : in  std_logic;
      
      VI_H_VIDEO_START   : in unsigned(9 downto 0);
      VI_H_VIDEO_END     : in unsigned(9 downto 0);
      VI_X_SCALE_FACTOR  : in unsigned(11 downto 0);
      VI_X_SCALE_OFFSET  : in unsigned(11 downto 0);
      
      newFrame           : in  std_logic;
      startOut           : in  std_logic;
      fracYout           : in  unsigned(4 downto 0);
      
      filter_y           : in  std_logic;
      filterAddr         : out unsigned(10 downto 0) := (others => '0');
      filterData         : in  unsigned(23 downto 0);
      
      out_pixel          : out std_logic := '0';
      out_x              : out unsigned(9 downto 0) := (others => '0');        
      out_y              : out unsigned(9 downto 0) := (others => '0');
      out_color          : out unsigned(23 downto 0) := (others => '0')
   );
end entity;

architecture arch of VI_outProcess is

   type tstate is
   (
      IDLE,
      STARTFETCH,
      FETCH0,
      FETCH1,
      FETCH2,
      FETCH3,
      NEXTPIXEL,
      LASTPIXEL,
      NEXTY
   );
   signal state         : tstate := IDLE; 
   
   signal dx            : unsigned(9 downto 0) := (others => '0');
   signal fetchLine     : std_logic := '0';
   
   signal x_accu        : unsigned(19 downto 0) := (others => '0');
   
   signal topleft       : tcolor := (others => (others => '0'));
   signal bottomleft    : tcolor := (others => (others => '0'));
   signal topright      : tcolor := (others => (others => '0'));
   signal bottomright   : tcolor := (others => (others => '0'));
   
   signal bi_left       : tcolor := (others => (others => '0'));
   signal bi_right      : tcolor := (others => (others => '0'));
   signal bi_xfrac      : unsigned(4 downto 0) := (others => '0');
   
   type tbi_signed is array(0 to 2) of signed(8 downto 0);
   type tbi_wide is array(0 to 2) of signed(14 downto 0);
   signal bi_a          : tcolor; 
   signal bi_b          : tcolor; 
   signal bi_frac       : unsigned(4 downto 0);
   signal bi_sub        : tbi_signed;
   signal bi_mul        : tbi_wide;
   signal bi_add        : tbi_wide;
   signal bi_shift      : tbi_signed;
   signal bi_result     : tcolor;
   
   signal out_next      : std_logic := '0';
   signal out_next_1    : std_logic := '0';

begin 
   
   filterAddr <= fetchLine & (x_accu(19 downto 10) + 2) when (state = FETCH1 or state = FETCH2) else fetchLine & (x_accu(19 downto 10) + 1);
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
         
         out_pixel <= '0';
         out_next  <= '0';
         
         case (state) is
         
            when IDLE =>
               if (newFrame = '1') then
                  out_y     <= (others => '0');
               end if;
               if (startOut = '1') then
                  state     <= STARTFETCH;
                  out_x     <= (others => '0');    
                  dx        <= VI_H_VIDEO_START;
                  x_accu    <= 8x"0" & VI_X_SCALE_OFFSET;
                  fetchLine <= not filter_y;
               end if;
               
            when STARTFETCH =>
               state     <= FETCH0;
               fetchLine <= not fetchLine;
         
            when FETCH0 =>
               state       <= FETCH1;
               fetchLine   <= not fetchLine;
               topleft(0)  <= filterData( 7 downto  0);
               topleft(1)  <= filterData(15 downto  8);
               topleft(2)  <= filterData(23 downto 16);
               
            when FETCH1 =>
               state          <= FETCH2;
               fetchLine      <= not fetchLine;
               bottomleft(0)  <= filterData( 7 downto  0);
               bottomleft(1)  <= filterData(15 downto  8);
               bottomleft(2)  <= filterData(23 downto 16);
               
            when FETCH2 =>
               state     <= FETCH3;
               fetchLine <= not fetchLine;
               topright(0)  <= filterData( 7 downto  0);
               topright(1)  <= filterData(15 downto  8);
               topright(2)  <= filterData(23 downto 16);
               
            when FETCH3 =>
               state          <= NEXTPIXEL;
               x_accu         <= x_accu + VI_X_SCALE_FACTOR;
               bi_xfrac       <= x_accu(9 downto 5);
               bottomright(0) <= filterData( 7 downto  0);
               bottomright(1) <= filterData(15 downto  8);
               bottomright(2) <= filterData(23 downto 16);

            when NEXTPIXEL =>
               state          <= FETCH0;
               fetchLine      <= not fetchLine;
               out_next       <= '1';
               dx             <= dx + 1;
               if ((dx + 1) >= VI_H_VIDEO_END) then
                  state <= LASTPIXEL;
               end if;
         
            when LASTPIXEL =>
               state  <= NEXTY;
               
            when NEXTY =>
               state  <= IDLE;
               out_y  <= out_y + 1;
         
         end case;
            
         if (reset = '1') then
            state <= IDLE;
         end if;
         
         if (state = FETCH3) then
            bi_left <= bi_result;
         end if;
         if (state = NEXTPIXEL) then
            bi_right <= bi_result;
         end if;
         
         out_next_1 <= out_next;
         if (out_next = '1') then
            out_pixel      <= '1';
            --out_color      <= topleft(2) & topleft(1) & topleft(0);
            out_color <= bi_result(2) & bi_result(1) & bi_result(0);
         end if;
   
         if (out_next_1 = '1') then
            out_x <= out_x + 1;
         end if;
       
      end if;
   end process;
   
   
   process (all)
   begin
      
      if (state = FETCH3) then
         bi_a     <= topleft;
         bi_b     <= bottomleft;
         bi_frac  <= fracYout;
      elsif (state = NEXTPIXEL) then
         bi_a     <= topright;
         bi_b     <= bottomright;
         bi_frac  <= fracYout;
      else
         bi_a     <= bi_left; 
         bi_b     <= bi_right;
         bi_frac  <= bi_xfrac;
      end if;
      
      if (VI_BILINEAROFF = '1') then
         bi_frac <= (others => '0');
      end if;
   
      for i in 0 to 2 loop
         bi_sub(i)    <= signed('0' & bi_b(i)) - signed('0' & bi_a(i));
         bi_mul(i)    <= bi_sub(i) * ('0' & signed(bi_frac));
         bi_add(i)    <= bi_mul(i) + 16;
         bi_shift(i)  <= resize(bi_add(i)(14 downto 5), 9);
         bi_result(i) <= resize(unsigned(bi_shift(i)) + bi_a(i), 8); 
      end loop;
      
   end process;
   
--##############################################################
--############################### export
--##############################################################
   
   -- synthesis translate_off
   goutput : if 1 = 1 generate
      signal tracecounts3 : integer := 0;
   begin
   
      process
         file outfile      : text;
         variable f_status : FILE_OPEN_STATUS;
         variable line_out : line;
         variable color32  : unsigned(31 downto 0);         
      begin
   
         file_open(f_status, outfile, "R:\\vi_n64_3_sim.txt", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "R:\\vi_n64_3_sim.txt", append_mode);

         while (true) loop
            
            wait until rising_edge(clk1x);
            
            if (out_pixel = '1') then
               write(line_out, string'(" X ")); 
               write(line_out, to_string_len(to_integer(out_x), 5));
               write(line_out, string'(" Y ")); 
               write(line_out, to_string_len(to_integer(out_y), 5));
               write(line_out, string'(" C "));
               color32 := 8x"0" & out_color;
               write(line_out, to_hstring(color32));
               writeline(outfile, line_out);
               tracecounts3 <= tracecounts3 + 1;
            end if;
            
         end loop;
         
      end process;
   
   end generate goutput;

   -- synthesis translate_on  
   
end architecture;





