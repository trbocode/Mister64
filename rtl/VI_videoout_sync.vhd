library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use STD.textio.all;

library mem;
use work.pVI.all;
use work.pFunctions.all;

entity vi_videoout_sync is
   generic
   (
      VITEST               : in  std_logic
   );
   port 
   (
      clk1x                   : in  std_logic;
      ce                      : in  std_logic;
      reset                   : in  std_logic;
      
      videoout_settings       : in  tvideoout_settings;
      videoout_reports        : out tvideoout_reports;

      videoout_request        : out tvideoout_request := ('0', (others => '0'), 0, (others => '0'));
      
      videoout_readAddr       : out unsigned(10 downto 0) := (others => '0');
      videoout_pixelRead      : in  std_logic_vector(23 downto 0);
      
      overlay_data            : in  std_logic_vector(23 downto 0);
      overlay_ena             : in  std_logic;
         
      videoout_out            : buffer tvideoout_out;
      
      SS_VI_CURRENT           : in unsigned(9 downto 0);
      SS_nextHCount           : in unsigned(11 downto 0)
   );
end entity;

architecture arch of vi_videoout_sync is
   
   -- timing
   signal lineIn           : unsigned(8 downto 0) := (others => '0');
   signal lineInNew        : std_logic := '0';
   signal nextHCount       : integer range 0 to 4095;
   signal vpos             : integer range 0 to 511;
   signal vsyncCount       : integer range 0 to 511;
   
   signal htotal           : integer range 0 to 4095;
   signal vtotal           : integer range 262 to 314;
   signal vDisplayStart    : integer range 0 to 314;
   signal vDisplayEnd      : integer range 0 to 314;
   
   -- output   
   signal pixelData_R      : std_logic_vector(7 downto 0) := (others => '0');
   signal pixelData_G      : std_logic_vector(7 downto 0) := (others => '0');
   signal pixelData_B      : std_logic_vector(7 downto 0) := (others => '0');
      
   signal clkDiv           : integer range 5 to 12 := 5; 
   signal clkCnt           : integer range 0 to 12 := 0;
   signal xmax             : integer range 0 to 1023;
      
   signal hsync_start      : integer range 0 to 4095;
   signal hsync_end        : integer range 0 to 4095;
   
   signal fetchNext : std_logic := '0';
   
begin 

   videoout_reports.VI_CURRENT <= to_unsigned(vpos, 9);

   process (clk1x)
      variable isVsync                   : std_logic;
      variable vposNew                   : integer range 0 to 511;
      variable interlacedDisplayFieldNew : std_logic;
   begin
      if rising_edge(clk1x) then
             
         videoout_reports.newLine  <= '0';
         videoout_reports.newFrame <= '0';
         
         lineInNew <= '0';
             
         videoout_reports.vsync    <= '0';
         if (vsyncCount >= 10 and vsyncCount < 13) then videoout_reports.vsync <= '1'; end if;

         if (reset = '1') then
               
            --videoout_reports.irq_VBLANK  <= '0';
               
            --videoout_reports.interlacedDisplayField   <= videoout_ss_in.interlacedDisplayField;
            nextHCount                                  <= to_integer(SS_nextHCount(11 downto 0));
            if (VITEST = '1') then
               vpos                                     <= 0;
            else
               vpos                                     <= to_integer(SS_VI_CURRENT(9 downto 1));
            end if;
            --videoout_reports.inVsync                  <= videoout_ss_in.inVsync;
            --videoout_reports.activeLineLSB            <= videoout_ss_in.activeLineLSB;
            --videoout_reports.GPUSTAT_InterlaceField   <= videoout_ss_in.GPUSTAT_InterlaceField;
            --videoout_reports.GPUSTAT_DrawingOddline   <= videoout_ss_in.GPUSTAT_DrawingOddline;
                  
         elsif (ce = '1') then
         
            --gpu timing calc
            if (videoout_settings.isPAL = '1') then
               --htotal <= (62500000 / 50 / 312); -- overwritten below
               htotal <= 4010;
               vtotal <= 312;
               --videoout_out.isPal <= '1';
            else
               --htotal <= (62500000 / 60 / 262); -- overwritten below
               htotal <= 3970;
               vtotal <= 262;
               --videoout_out.isPal <= '0';
            end if;
            
            --if (videoout_settings.vDisplayRange( 9 downto  0) < 314) then vDisplayStart <= to_integer(videoout_settings.vDisplayRange( 9 downto  0)); else vDisplayStart <= 314; end if;
            --if (videoout_settings.vDisplayRange(19 downto 10) < 314) then vDisplayEnd   <= to_integer(videoout_settings.vDisplayRange(19 downto 10)); else vDisplayEnd   <= 314; end if;
              
            vDisplayStart <= 10;
            if ((10 + to_integer(videoout_settings.videoSizeY(9 downto 1))) < 210) then
               vDisplayEnd <= 210;
            else
               vDisplayEnd <= 10 + to_integer(videoout_settings.videoSizeY(9 downto 1));
            end if;
              
            -- gpu timing count
            if (nextHCount > 1) then
               nextHCount <= nextHCount - 1;
               if (nextHCount = 3) then 
                  videoout_reports.newLine <= '1';
                  if (vpos = vDisplayStart - 3) then
                    videoout_reports.newFrame <= '1'; 
                  end if;
               end if;
            else
               
               nextHCount <= htotal;
               
               vposNew := vpos + 1;
               if (vposNew >= vtotal) then
                  vposNew := 0;
               end if;
               
               vpos <= vposNew;
               
               isVsync := '0';
               vsyncCount <= 0;
               if (vposNew < vDisplayStart or vposNew >= vDisplayEnd) then 
                  isVsync := '1'; 
                  vsyncCount <= vsyncCount + 1;
               else
                  lineIn    <= to_unsigned(vposNew - vDisplayStart, 9);
                  lineInNew <= '1';
               end if;

               interlacedDisplayFieldNew := videoout_reports.interlacedDisplayField;
               if (isVsync /= videoout_reports.inVsync) then
                  if (isVsync = '1') then
                     videoout_request.fetch      <= '0';
                     if (videoout_settings.CTRL_SERRATE = '1') then 
                        interlacedDisplayFieldNew := not videoout_reports.interlacedDisplayField;
                     else 
                        interlacedDisplayFieldNew := '0';
                     end if;
                  end if;
                  videoout_reports.inVsync <= isVsync;
               end if;
               videoout_reports.interlacedDisplayField <= interlacedDisplayFieldNew;
               
               vposNew := vposNew + 1;
               if (vposNew >= vDisplayStart and vposNew < vDisplayEnd - 1) then 
                  videoout_request.lineInNext <= to_unsigned(vposNew - vDisplayStart, 9);
                  videoout_request.fetch      <= '1';
               else
                  videoout_request.lineInNext <= (others => '0');
               end if;
              
            end if;
            
            --if (softReset = '1') then
            --   videoout_reports.GPUSTAT_InterlaceField <= '1';
            --   videoout_reports.GPUSTAT_DrawingOddline <= '0';
            --   videoout_reports.irq_VBLANK             <= '0';
            --   
            --   vpos                      <= 0;
            --   nextHCount                <= htotal;
            --   videoout_reports.inVsync  <= '0';
            --end if;

         end if;
      end if;
   end process;
   
   -- timing generation reading
   videoout_out.vsync          <= videoout_reports.vsync; 
   videoout_out.vblank         <= videoout_reports.inVsync;
   videoout_out.interlace      <= videoout_reports.interlacedDisplayField;
   
   --videoout_out.DisplayOffsetX <= videoout_settings.vramRange(9 downto 0);
   --videoout_out.DisplayOffsetY <= videoout_settings.vramRange(18 downto 10);
   --
   --videoout_out.DisplayWidthReal  <= videoout_out.DisplayWidth; 
   --videoout_out.DisplayHeightReal <= videoout_out.DisplayHeight;
   
   clkDiv <= 5;
   xmax <= 640;
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
         
         videoout_out.ce <= '0';

         if (reset = '1') then
         
            clkCnt                     <= 0;
            videoout_out.hblank        <= '1';
            videoout_request.lineDisp  <= (others => '0');
         
         elsif (ce = '1') then
            
            if (clkCnt < (clkDiv - 1)) then
               clkCnt <= clkCnt + 1;
            else
               clkCnt    <= 0;
               videoout_out.ce  <= '1';
               if (videoout_request.xpos < 1023) then
                  videoout_request.xpos <= videoout_request.xpos + 1;
               end if;
               if (videoout_request.xpos > 0 and videoout_request.xpos <= xmax) then
                  videoout_out.hblank <= '0';
                  if (overlay_ena = '1') then
                     videoout_out.r      <= overlay_data( 7 downto 0);
                     videoout_out.g      <= overlay_data(15 downto 8);
                     videoout_out.b      <= overlay_data(23 downto 16);
                  elsif (videoout_settings.CTRL_TYPE(1) = '0') then
                     videoout_out.r      <= (others => '0');
                     videoout_out.g      <= (others => '0');
                     videoout_out.b      <= (others => '0');
                  else
                     videoout_out.r      <= pixelData_R;
                     videoout_out.g      <= pixelData_G;
                     videoout_out.b      <= pixelData_B;
                  end if;
               else
                  videoout_out.hblank <= '1';
                  if (videoout_out.hblank = '0') then
                     hsync_start <= (nextHCount / 2) + (nextHCount / 4) + (nextHCount / 32);
                     hsync_end   <= (nextHCount / 2);
                  end if;
               end if;
            end if;
            
            if (lineInNew = '1') then
               videoout_request.lineDisp <= lineIn;
               videoout_readAddr         <= lineIn(0) & 10x"00";
               videoout_request.xpos     <= 0;
            end if;
            
            if (nextHCount = hsync_start) then videoout_out.hsync <= '1'; end if;
            if (nextHCount = hsync_end  ) then videoout_out.hsync <= '0'; end if;
         
            if (clkCnt >= (clkDiv - 1) and videoout_request.xpos < xmax) then
               pixelData_B                <= videoout_pixelRead( 7 downto  0);
               pixelData_G                <= videoout_pixelRead(15 downto  8);
               pixelData_R                <= videoout_pixelRead(23 downto 16);
               videoout_readAddr          <= videoout_readAddr + 1;
            end if;
         
         end if;
         
      end if;
   end process;
   
--##############################################################
--############################### export
--##############################################################
   
   -- synthesis translate_off
   goutput : if 1 = 1 generate
      signal tracecounts4    : integer := 0;
      signal export_x        : integer := 0;
      signal export_y        : integer := 0;
      signal export_hblank_1 : std_logic := '0';
   begin
   
      process
         file outfile      : text;
         variable f_status : FILE_OPEN_STATUS;
         variable line_out : line;
         variable color32  : unsigned(31 downto 0);          
      begin
   
         file_open(f_status, outfile, "R:\\vi_n64_4_sim.txt", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "R:\\vi_n64_4_sim.txt", append_mode);

         wait for 100 us;

         while (true) loop
            
            wait until rising_edge(clk1x);
            
            if (videoout_out.vsync = '1') then
               export_y <= 0;
            end if;
            if (videoout_out.hblank = '1') then
               export_x <= 0;
            end if;
            
            export_hblank_1 <= videoout_out.hblank;
            if (videoout_out.hblank = '1' and export_hblank_1 = '0') then
               export_y <= export_y + 1;
            end if;
            
            if (videoout_out.ce = '1' and videoout_out.hblank = '0') then
               write(line_out, string'(" X ")); 
               write(line_out, to_string_len(export_x, 5));
               write(line_out, string'(" Y ")); 
               write(line_out, to_string_len(export_y, 5));
               write(line_out, string'(" C "));
               color32 := 8x"0" & unsigned(videoout_out.r) & unsigned(videoout_out.g) & unsigned(videoout_out.b);
               write(line_out, to_hstring(color32));
               writeline(outfile, line_out);
               tracecounts4 <= tracecounts4 + 1;
               export_x     <= export_x + 1;
            end if;
            
         end loop;
         
      end process;
   
   end generate goutput;

   -- synthesis translate_on  

end architecture;





