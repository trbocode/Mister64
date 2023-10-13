library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

entity Gamepad is
   port 
   (
      clk1x                : in  std_logic;
      reset                : in  std_logic;
     
      PADCOUNT             : in  std_logic_vector(1 downto 0); -- count - 1
      PADTYPE0             : in  std_logic_vector(1 downto 0); -- 00 = nothing, 01 = transfer, 10 = rumble
      PADTYPE1             : in  std_logic_vector(1 downto 0);
      PADTYPE2             : in  std_logic_vector(1 downto 0);
      PADTYPE3             : in  std_logic_vector(1 downto 0);
      PADDPADSWAP          : in  std_logic;
      CPAKFORMAT           : in  std_logic;
      PADSLOW              : in  std_logic;
      
      command_start        : in  std_logic;                    -- high for 1 clock cycle when a new command is issued from PIF. toPad_ena will also be high, sending the first byte with data containing the command ID 
      command_padindex     : in  unsigned(1 downto 0);         -- pad number 0..3
      command_sendCnt      : in  unsigned(5 downto 0);         -- amount of bytes to be sent to the pad. First byte is the command, then follows payload
      command_receiveCnt   : in  unsigned(5 downto 0);         -- amount of bytes expected to be read back to PIF after sending all bytes
   
      toPad_ena            : in  std_logic;                    -- high for 1 cycle when a new byte is to be written to the pad
      toPad_data           : in  std_logic_vector(7 downto 0); -- byte written to pad
      toPad_ready          : out std_logic := '0';             -- can be used to tell the PIF it has to wait before sending more data to the pad
                           
      toPIF_timeout        : out std_logic := '0';                                  -- set to 1 for one cycle when no pad is connected/detected
      toPIF_ena            : out std_logic := '0';                                  -- set to 1 for one cycle when new data is send to PIF
      toPIF_data           : out std_logic_vector(7 downto 0) := (others => '0');   -- byte from controller send back to PIF

      pad_A                : in  std_logic_vector(3 downto 0);
      pad_B                : in  std_logic_vector(3 downto 0);
      pad_Z                : in  std_logic_vector(3 downto 0);
      pad_START            : in  std_logic_vector(3 downto 0);
      pad_DPAD_UP          : in  std_logic_vector(3 downto 0);
      pad_DPAD_DOWN        : in  std_logic_vector(3 downto 0);
      pad_DPAD_LEFT        : in  std_logic_vector(3 downto 0);
      pad_DPAD_RIGHT       : in  std_logic_vector(3 downto 0);
      pad_L                : in  std_logic_vector(3 downto 0);
      pad_R                : in  std_logic_vector(3 downto 0);
      pad_C_UP             : in  std_logic_vector(3 downto 0);
      pad_C_DOWN           : in  std_logic_vector(3 downto 0);
      pad_C_LEFT           : in  std_logic_vector(3 downto 0);
      pad_C_RIGHT          : in  std_logic_vector(3 downto 0);
      pad_0_analog_h       : in  std_logic_vector(7 downto 0);
      pad_0_analog_v       : in  std_logic_vector(7 downto 0);      
      pad_1_analog_h       : in  std_logic_vector(7 downto 0);
      pad_1_analog_v       : in  std_logic_vector(7 downto 0);      
      pad_2_analog_h       : in  std_logic_vector(7 downto 0);
      pad_2_analog_v       : in  std_logic_vector(7 downto 0);      
      pad_3_analog_h       : in  std_logic_vector(7 downto 0);
      pad_3_analog_v       : in  std_logic_vector(7 downto 0)
      
      --rumble               : out std_logic_vector(3 downto 0) := (others => '0');
      
      --cpak_change          : out std_logic := '0';
      --
      --sdram_request        : out std_logic := '0';
      --sdram_rnw            : out std_logic := '0'; 
      --sdram_address        : out unsigned(26 downto 0):= (others => '0');
      --sdram_burstcount     : out unsigned(7 downto 0):= (others => '0');
      --sdram_writeMask      : out std_logic_vector(3 downto 0) := (others => '0'); 
      --sdram_dataWrite      : out std_logic_vector(31 downto 0) := (others => '0');
      --sdram_done           : in  std_logic;
      --sdram_dataRead       : in  std_logic_vector(31 downto 0);
   );
end entity;

architecture arch of Gamepad is

   type tState is
   (
      IDLE,
      TRANSMITWAIT0,
      
      RESPONSETYPE0,
      RESPONSETYPE1,
      RESPONSETYPE2,
      
      RESPONSEPAD0,
      RESPONSEPAD1,
      RESPONSEPAD2,
      RESPONSEPAD3,
      
      SENDEMPTY
   );
   signal state                     : tState := IDLE;
   
   signal slowcnt                   : unsigned(11 downto 0) := (others => '0');
   signal slowNextByteEna           : std_logic;
   signal receivecount              : unsigned(5 downto 0) := (others => '0');
   
   signal PADTYPE                   : std_logic_vector(1 downto 0);
   
   signal pad_muxed_A               : std_logic;
   signal pad_muxed_B               : std_logic;
   signal pad_muxed_C               : std_logic;
   signal pad_muxed_START           : std_logic;
   signal pad_muxed_DPAD_UP         : std_logic;
   signal pad_muxed_DPAD_DOWN       : std_logic;
   signal pad_muxed_DPAD_LEFT       : std_logic;
   signal pad_muxed_DPAD_RIGHT      : std_logic;
   signal pad_muxed_L               : std_logic;
   signal pad_muxed_R               : std_logic;
   signal pad_muxed_C_UP            : std_logic;
   signal pad_muxed_C_DOWN          : std_logic;
   signal pad_muxed_C_LEFT          : std_logic;
   signal pad_muxed_C_RIGHT         : std_logic;
                                   
   signal pad_muxed_analogH         : std_logic_vector(7 downto 0);
   signal pad_muxed_analogV         : std_logic_vector(7 downto 0);
   
begin 

   PADTYPE <= PADTYPE0 when (command_padindex = "00") else 
              PADTYPE1 when (command_padindex = "01") else 
              PADTYPE2 when (command_padindex = "10") else 
              PADTYPE3;
              
   pad_muxed_A          <= pad_A(to_integer(command_padindex));         
   pad_muxed_B          <= pad_B(to_integer(command_padindex));         
   pad_muxed_C          <= pad_Z(to_integer(command_padindex));         
   pad_muxed_START      <= pad_START(to_integer(command_padindex));     
   pad_muxed_DPAD_UP    <= pad_DPAD_UP(to_integer(command_padindex));   
   pad_muxed_DPAD_DOWN  <= pad_DPAD_DOWN(to_integer(command_padindex)); 
   pad_muxed_DPAD_LEFT  <= pad_DPAD_LEFT(to_integer(command_padindex)); 
   pad_muxed_DPAD_RIGHT <= pad_DPAD_RIGHT(to_integer(command_padindex));
   pad_muxed_L          <= pad_L(to_integer(command_padindex));      
   pad_muxed_R          <= pad_R(to_integer(command_padindex));      
   pad_muxed_C_UP       <= pad_C_UP(to_integer(command_padindex));   
   pad_muxed_C_DOWN     <= pad_C_DOWN(to_integer(command_padindex)); 
   pad_muxed_C_LEFT     <= pad_C_LEFT(to_integer(command_padindex)); 
   pad_muxed_C_RIGHT    <= pad_C_RIGHT(to_integer(command_padindex));
   
   process (all)
   begin
      case (command_padindex) is
         when "00"   => pad_muxed_analogH <= pad_0_analog_h; pad_muxed_analogV <= std_logic_vector(-signed(pad_0_analog_v));
         when "01"   => pad_muxed_analogH <= pad_1_analog_h; pad_muxed_analogV <= std_logic_vector(-signed(pad_1_analog_v));
         when "10"   => pad_muxed_analogH <= pad_2_analog_h; pad_muxed_analogV <= std_logic_vector(-signed(pad_2_analog_v));
         when others => pad_muxed_analogH <= pad_3_analog_h; pad_muxed_analogV <= std_logic_vector(-signed(pad_3_analog_v));
      end case;   
   end process;
              
   slowNextByteEna <= slowcnt(slowcnt'left) when (PADSLOW = '1') else slowcnt(2);
               
   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         toPIF_timeout <= '0';
         toPIF_ena     <= '0';
         
         if (slowNextByteEna = '1') then
            slowcnt <= (others => '0');
         else
            slowcnt <= slowcnt + 1;
         end if;
      
         case (state) is
            
            when IDLE =>
               toPad_ready <= '1';
               if (command_start = '1') then
                  state       <= TRANSMITWAIT0;
                  toPad_ready <= '0';
                  slowcnt     <= (others => '0');
               end if;
               
            when TRANSMITWAIT0 =>
               if (slowNextByteEna = '1') then
                  if (command_padindex > unsigned(PADCOUNT)) then
                     toPIF_timeout <= '1';
                     state         <= IDLE;
                  else
                     if (toPad_data = x"00" or toPad_data = x"FF") then -- type check
                        state <= RESPONSETYPE0;
                     elsif (toPad_data = x"01") then -- pad response
                        state <= RESPONSEPAD0;
                     end if;
                  end if;
               end if;
             
----------------------------- type -------------------------------
            when RESPONSETYPE0 =>
               if (slowNextByteEna = '1') then
                  if (command_receiveCnt > 1) then
                     state <= RESPONSETYPE1;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
               
               toPIF_data <= x"05";
               
            
            when RESPONSETYPE1 =>   
               if (slowNextByteEna = '1') then
                  if (command_receiveCnt > 2) then
                     state <= RESPONSETYPE2;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
               
               toPIF_data <= x"00";
               
            
            when RESPONSETYPE2 => 
               if (slowNextByteEna = '1') then
                  receivecount <= to_unsigned(4, receivecount'length);
                  if (command_receiveCnt > 3) then
                     state <= SENDEMPTY;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
               
               if (PADTYPE = "01" or PADTYPE = "10") then
                  toPIF_data <= x"01";
               else
                  toPIF_data <= x"02";
               end if;
            
----------------------------- pad buttons/axis -------------------------------
            when RESPONSEPAD0 =>  
               if (slowNextByteEna = '1') then
                  if (command_receiveCnt > 1) then
                     state <= RESPONSEPAD1;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
            
               toPIF_data(7) <= pad_muxed_A;         
               toPIF_data(6) <= pad_muxed_B;         
               toPIF_data(5) <= pad_muxed_C;         
               toPIF_data(4) <= pad_muxed_START;     
               toPIF_data(3) <= pad_muxed_DPAD_UP;   
               toPIF_data(2) <= pad_muxed_DPAD_DOWN; 
               toPIF_data(1) <= pad_muxed_DPAD_LEFT; 
               toPIF_data(0) <= pad_muxed_DPAD_RIGHT;
               
               if (PADDPADSWAP = '1') then
                  toPIF_data(3) <= '0';
                  toPIF_data(2) <= '0';
                  toPIF_data(1) <= '0';
                  toPIF_data(0) <= '0';
                  if (signed(pad_muxed_analogH) >=  64) then toPIF_data(0) <= '1'; end if;
                  if (signed(pad_muxed_analogH) <= -64) then toPIF_data(1) <= '1'; end if;
                  if (signed(pad_muxed_analogV) >=  64) then toPIF_data(3) <= '1'; end if;
                  if (signed(pad_muxed_analogV) <= -64) then toPIF_data(2) <= '1'; end if;
               end if;
            
            
            when RESPONSEPAD1 => 
               if (slowNextByteEna = '1') then
                  if (command_receiveCnt > 2) then
                     state <= RESPONSEPAD2;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
            
               toPIF_data(7 downto 6) <= "00";      
               toPIF_data(5) <= pad_muxed_L;      
               toPIF_data(4) <= pad_muxed_R;      
               toPIF_data(3) <= pad_muxed_C_UP;   
               toPIF_data(2) <= pad_muxed_C_DOWN; 
               toPIF_data(1) <= pad_muxed_C_LEFT; 
               toPIF_data(0) <= pad_muxed_C_RIGHT;

            when RESPONSEPAD2 => 
               if (slowNextByteEna = '1') then
                  if (command_receiveCnt > 3) then
                     state <= RESPONSEPAD3;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
            
               toPIF_data <= pad_muxed_analogH;
            
               if (PADDPADSWAP = '1') then
                  if    (pad_muxed_DPAD_LEFT  = '1' and pad_muxed_DPAD_UP = '0' and pad_muxed_DPAD_DOWN = '0') then toPIF_data <= std_logic_vector(to_signed(-85,8));
                  elsif (pad_muxed_DPAD_RIGHT = '1' and pad_muxed_DPAD_UP = '0' and pad_muxed_DPAD_DOWN = '0') then toPIF_data <= std_logic_vector(to_signed(85,8));
                  elsif (pad_muxed_DPAD_LEFT  = '1')                                                           then toPIF_data <= std_logic_vector(to_signed(-69,8));
                  elsif (pad_muxed_DPAD_RIGHT = '1')                                                           then toPIF_data <= std_logic_vector(to_signed(69,8));
                  else toPIF_data <= (others => '0'); end if;
               end if;
            
            when RESPONSEPAD3 =>  
               if (slowNextByteEna = '1') then
                  receivecount <= to_unsigned(5, receivecount'length);
                  if (command_receiveCnt > 4) then
                     state <= SENDEMPTY;
                  else
                     state <= IDLE;
                  end if;
                  toPIF_ena  <= '1';
               end if;
            
               toPIF_data <= pad_muxed_analogV;
            
               if (PADDPADSWAP = '1') then
                  if    (pad_muxed_DPAD_UP   = '1' and pad_muxed_DPAD_LEFT = '0' and pad_muxed_DPAD_RIGHT = '0') then toPIF_data <= std_logic_vector(to_signed(85,8));
                  elsif (pad_muxed_DPAD_DOWN = '1' and pad_muxed_DPAD_LEFT = '0' and pad_muxed_DPAD_RIGHT = '0') then toPIF_data <= std_logic_vector(to_signed(-85,8));
                  elsif (pad_muxed_DPAD_UP   = '1')                                                              then toPIF_data <= std_logic_vector(to_signed(69,8));
                  elsif (pad_muxed_DPAD_DOWN = '1')                                                              then toPIF_data <= std_logic_vector(to_signed(-69,8));
                  else toPIF_data <= (others => '0'); end if;
               end if;
            
----------------------------- error case of too much data requested -------------------------------
            when SENDEMPTY =>
               if (slowNextByteEna = '1') then
                  toPIF_ena  <= '1';
                  receivecount <= receivecount + 1;
                  if (receivecount >= command_receiveCnt) then
                     state <= IDLE;
                  end if;
               end if;
               
               toPIF_data <= x"00";

         end case;
      
         if (reset = '1') then
            state <= IDLE;
         end if;
         
      end if; -- clock
   end process;
   
end architecture;





