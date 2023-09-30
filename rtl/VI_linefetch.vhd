library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

library mem;
use work.pVI.all;

entity VI_linefetch is
   port 
   (
      clk1x              : in  std_logic;
      clk2x              : in  std_logic;
      reset              : in  std_logic;
      
      VI_CTRL_TYPE       : in unsigned(1 downto 0);
      VI_CTRL_SERRATE    : in std_logic;
      VI_ORIGIN          : in unsigned(23 downto 0);
      VI_WIDTH           : in unsigned(11 downto 0);
      VI_X_SCALE_FACTOR  : in unsigned(11 downto 0);
      VI_Y_SCALE_FACTOR  : in unsigned(11 downto 0);
      VI_Y_SCALE_OFFSET  : in unsigned(11 downto 0);
      
      newFrame           : in  std_logic;
      lineNr             : in  unsigned(8 downto 0);
      fetch              : in  std_logic;
      
      doubleProc         : out std_logic := '0';
      startProc          : out std_logic := '0';
      startOut           : out std_logic := '0';
      fracYout           : out unsigned(4 downto 0);
      
      rdram_request      : out std_logic := '0';
      rdram_rnw          : out std_logic := '0'; 
      rdram_address      : out unsigned(27 downto 0):= (others => '0');
      rdram_burstcount   : out unsigned(9 downto 0):= (others => '0');
      rdram_granted      : in  std_logic;
      rdram_done         : in  std_logic;
      ddr3_DOUT_READY    : in  std_logic;
      rdram_store        : out std_logic := '0';
      rdram_storeAddr    : out unsigned(10 downto 0) := (others => '0')
   );
end entity;

architecture arch of VI_linefetch is

   type tstate is
   (
      IDLE,
      REQUESTLINE,
      WAITDONE
   );
   signal state            : tstate := IDLE;

   signal lineAct          : unsigned(8 downto 0) := (others => '0');
   signal lineInCnt        : unsigned(1 downto 0) := (others => '0');
   signal lineInFetched    : unsigned(2 downto 0) := (others => '0');   
   signal lineFirst        : std_logic := '0';
   
   signal line_prefetch    : integer range 0 to 8;   
   signal lineWidth        : unsigned(13 downto 0);
   signal y_accu_new       : unsigned(19 downto 0);
   signal y_accu           : unsigned(19 downto 0) := (others => '0');
   signal y_diff           : unsigned(9 downto 0);
   
   signal out_wait         : integer range 0 to 127 := 0;
   
begin 
  
   doubleProc    <= VI_Y_SCALE_FACTOR(11);
   
   line_prefetch <= 8 when (VI_CTRL_TYPE = "11") else 4;
   
   lineWidth     <= VI_WIDTH & "00" when (VI_CTRL_TYPE = "11") else '0' & VI_WIDTH & '0';
  
   y_accu_new    <= y_accu + VI_Y_SCALE_FACTOR; 
   
   y_diff        <= y_accu_new(y_accu_new'left downto 10) - y_accu(y_accu'left downto 10);
   
   rdram_rnw <= '1';
   
   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         rdram_request <= '0';
         startProc     <= '0';
         startOut      <= '0';
         
         if (VI_CTRL_TYPE = "10") then
            if (VI_X_SCALE_FACTOR > x"200") then -- hack for 320/640 pixel width
               rdram_burstcount <= 10x"B0";
            else
               rdram_burstcount <= 10x"60";
            end if;
         elsif (VI_CTRL_TYPE = "11") then
            if (VI_X_SCALE_FACTOR > x"200") then -- hack for 320/640 pixel width
               rdram_burstcount <= 10x"150";
            else
               rdram_burstcount <= 10x"B0";
            end if;
         end if;
         
         if (out_wait > 0) then
            out_wait <= out_wait - 1;
            if (out_wait = 1) then
               startOut <= '1';
               fracYout <= y_accu(9 downto 5);
            end if;
         end if;
         
         if (reset = '1') then
         
            state         <= IDLE;
            lineInFetched <= "111";
         
         else
         
            case (state) is
            
               when IDLE =>
                  if (newFrame = '1') then
                     rdram_address <= ("0000" & VI_ORIGIN) - to_integer(lineWidth * 2) - line_prefetch;
                     y_accu        <= 8x"0" & VI_Y_SCALE_OFFSET;
                     lineInFetched <= "000";
                     lineInCnt     <= "00";
                     lineFirst     <= '1';
                  end if;
                  lineAct  <= lineNr;
                  if (lineNr /= lineAct and fetch = '1') then
                     if (lineFirst = '1') then
                        lineInFetched(2) <= '0';
                        if (y_diff > 1) then
                           lineInFetched(1) <= '0';
                        end if;
                        lineFirst        <= '0';
                     else
                        y_accu <= y_accu_new; 
                        if (y_diff > 0) then
                           lineInFetched(2) <= '0';
                           if (y_diff > 1) then
                              lineInFetched(1) <= '0';
                           end if;
                        else
                           out_wait   <= 127;
                        end if;
                     end if;
                  end if;
                  if (lineInFetched /= "111") then
                     state <= REQUESTLINE;
                  end if;
                  
               when REQUESTLINE =>
                  rdram_address <= rdram_address + lineWidth;
                  if (VI_CTRL_TYPE = "10") then
                     state            <= WAITDONE;
                     rdram_request    <= '1';
                  elsif (VI_CTRL_TYPE = "11") then
                     state            <= WAITDONE;
                     rdram_request    <= '1';
                  else 
                     state <= IDLE;
                  end if;
                 
               when WAITDONE  => 
                  if (rdram_done = '1') then
                     state          <= IDLE;
                     lineInCnt      <= lineInCnt + 1;   
                     lineInFetched  <= lineInFetched(1 downto 0) & '1';    
                     if (lineInFetched(1 downto 0) = "11") then
                        startProc <= '1';
                        if (lineFirst = '0') then
                           out_wait  <= 127;
                        end if;
                     end if;
                  end if;
            
            end case;
            
         end if;
   
      end if;
   end process;
   
   
   process (clk2x)
   begin
      if rising_edge(clk2x) then
      
         if (rdram_granted = '1') then
            rdram_store       <= '1';
            rdram_storeAddr   <= lineInCnt & 9x"000";
         end if;
         
          if (ddr3_DOUT_READY = '1') then
             rdram_storeAddr <= rdram_storeAddr + 1;
          end if;
          
          if (rdram_done = '1') then
            rdram_store  <= '0';
          end if;

      end if;
   end process;
   
   
end architecture;





