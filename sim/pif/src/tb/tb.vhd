library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     
use IEEE.std_logic_textio.all; 
library STD;    
use STD.textio.all;

library n64;
use n64.pSDRAM.all;

entity etb  is
end entity;

architecture arch of etb is

   signal clk1x               : std_logic := '1';
   signal reset               : std_logic := '1';
   
   signal command_start        : std_logic;
   signal command_padindex     : unsigned(1 downto 0);
   signal command_sendCnt      : unsigned(5 downto 0);
   signal command_receiveCnt   : unsigned(5 downto 0);

   signal toPad_ena            : std_logic;   
   signal toPad_data           : std_logic_vector(7 downto 0);          
   signal toPad_ready          : std_logic;  
   
   signal toPIF_ena            : std_logic;   
   signal toPIF_data           : std_logic_vector(7 downto 0);
         
   signal SIPIF_ramreq        : std_logic := '0';
   signal SIPIF_addr          : unsigned(5 downto 0) := (others => '0');
   signal SIPIF_writeEna      : std_logic := '0'; 
   signal SIPIF_writeData     : std_logic_vector(7 downto 0);
   signal SIPIF_ramgrant      : std_logic;
   
   signal SIPIF_writeProc     : std_logic := '0';
   signal SIPIF_readProc      : std_logic := '0';
   signal SIPIF_ProcDone      : std_logic := '0';
   
   signal sdramMux_request    : tSDRAMSingle;
   signal sdramMux_rnw        : tSDRAMSingle;    
   signal sdramMux_address    : tSDRAMReqAddr;
   signal sdramMux_burstcount : tSDRAMBurstcount;  
   signal sdramMux_writeMask  : tSDRAMBwriteMask;  
   signal sdramMux_dataWrite  : tSDRAMBwriteData;
   signal sdramMux_granted    : tSDRAMSingle;
   signal sdramMux_done       : tSDRAMSingle;
   signal sdramMux_dataRead   : std_logic_vector(31 downto 0);
   
   signal sdram_dataWrite     : std_logic_vector(31 downto 0);
   signal sdram_dataRead      : std_logic_vector(31 downto 0);
   signal sdram_Adr           : std_logic_vector(26 downto 0);
   signal sdram_be            : std_logic_vector(3 downto 0);
   signal sdram_rnw           : std_logic;
   signal sdram_ena           : std_logic;
   signal sdram_done          : std_logic;    
   signal sdram_reqprocessed  : std_logic;    
   
   -- testbench
   signal cmdCount            : integer := 0;


begin

   clk1x <= not clk1x after 8 ns;
   reset <= '0' after 3 ms;
 
   iPIF: entity N64.pif
   port map
   (
      clk1x                => clk1x,
      ce                   => '1',
      reset                => reset,
      
      second_ena           => '1',
      
      ISPAL                => '0',
      EEPROMTYPE           => "01",
      CICTYPE              => "0000",
      PADCOUNT             => "11",
      PADTYPE0             => "01",
      PADTYPE1             => "00",
      PADTYPE2             => "00",
      PADTYPE3             => "00",
      PADDPADSWAP          => '0',
      CPAKFORMAT           => '0',
                           
      command_start        => command_start,     
      command_padindex     => command_padindex,  
      command_sendCnt      => command_sendCnt,   
      command_receiveCnt   => command_receiveCnt,                
      toPad_ena            => toPad_ena,         
      toPad_data           => toPad_data,                              
      toPad_ready          => toPad_ready,                              
      toPIF_ena            => toPIF_ena,         
      toPIF_data           => toPIF_data, 
                           
      pifrom_wraddress     => 10x"0",
      pifrom_wrdata        => 32x"0",
      pifrom_wren          => '0',
                           
      SIPIF_ramreq         => SIPIF_ramreq,   
      SIPIF_addr           => SIPIF_addr,     
      SIPIF_writeEna       => SIPIF_writeEna, 
      SIPIF_writeData      => SIPIF_writeData,
      SIPIF_ramgrant       => SIPIF_ramgrant,
      SIPIF_readData       => open,
                            
      SIPIF_writeProc      => SIPIF_writeProc,
      SIPIF_readProc       => SIPIF_readProc, 
      SIPIF_ProcDone       => SIPIF_ProcDone, 
                           
      bus_addr             => 11x"0",
      bus_dataWrite        => 32x"0",
      bus_read             => '0',
      bus_write            => '0',
      bus_dataRead         => open,
      bus_done             => open,
      
      eeprom_addr          => 9x"0",
      eeprom_wren          => '0',
      eeprom_in            => 32x"0",
      
      sdram_request        => sdramMux_request(SDRAMMUX_PIF),   
      sdram_rnw            => sdramMux_rnw(SDRAMMUX_PIF),       
      sdram_address        => sdramMux_address(SDRAMMUX_PIF),   
      sdram_burstcount     => sdramMux_burstcount(SDRAMMUX_PIF),
      sdram_writeMask      => sdramMux_writeMask(SDRAMMUX_PIF), 
      sdram_dataWrite      => sdramMux_dataWrite(SDRAMMUX_PIF), 
      sdram_done           => sdramMux_done(SDRAMMUX_PIF),      
      sdram_dataRead       => sdramMux_dataRead,
      
      SS_reset             => '0',
      loading_savestate    => '0',
      SS_DataWrite         => 64x"0",
      SS_Adr               => 7x"0",
      SS_wren              => '0',
      SS_rden              => '0',
      SS_DataRead          => open,
      SS_idle              => open
   );
   
   iGamepad : entity N64.Gamepad
   port map
   (
      clk1x                => clk1x,
      reset                => reset,
     
      PADCOUNT             => "11",
      PADTYPE0             => "01",
      PADTYPE1             => "00",
      PADTYPE2             => "00",
      PADTYPE3             => "00",
      PADDPADSWAP          => '0',
      CPAKFORMAT           => '0',
      PADSLOW              => '1',
      
      command_start        => command_start,     
      command_padindex     => command_padindex,  
      command_sendCnt      => command_sendCnt,   
      command_receiveCnt   => command_receiveCnt,
                       
      toPad_ena            => toPad_ena,         
      toPad_data           => toPad_data,        
      toPad_ready          => toPad_ready,        
                                
      toPIF_ena            => toPIF_ena,         
      toPIF_data           => toPIF_data,        

      pad_A                => "0000",
      pad_B                => "0000",
      pad_Z                => "0000",
      pad_START            => "0000",
      pad_DPAD_UP          => "0000",
      pad_DPAD_DOWN        => "0000",
      pad_DPAD_LEFT        => "0000",
      pad_DPAD_RIGHT       => "0000",
      pad_L                => "0000",
      pad_R                => "0000",
      pad_C_UP             => "0000",
      pad_C_DOWN           => "0000",
      pad_C_LEFT           => "0000",
      pad_C_RIGHT          => "0000",
      pad_0_analog_h       => x"00",
      pad_0_analog_v       => x"00",
      pad_1_analog_h       => x"00",
      pad_1_analog_v       => x"00",
      pad_2_analog_h       => x"00",
      pad_2_analog_v       => x"00",
      pad_3_analog_h       => x"00",
      pad_3_analog_v       => x"00"
   );
   
   iSDRamMux : entity n64.SDRamMux
   port map
   (
      clk1x                => clk1x,
                           
      error                => open,
                           
      sdram_ena            => sdram_ena,      
      sdram_rnw            => sdram_rnw,      
      sdram_Adr            => sdram_Adr,      
      sdram_be             => sdram_be,       
      sdram_dataWrite      => sdram_dataWrite,
      sdram_done           => sdram_done,     
      sdram_reqprocessed   => sdram_reqprocessed,     
      sdram_dataRead       => sdram_dataRead, 
                           
      sdramMux_request     => sdramMux_request,   
      sdramMux_rnw         => sdramMux_rnw,       
      sdramMux_address     => sdramMux_address,   
      sdramMux_burstcount  => sdramMux_burstcount,
      sdramMux_writeMask   => sdramMux_writeMask, 
      sdramMux_dataWrite   => sdramMux_dataWrite, 
      sdramMux_granted     => sdramMux_granted,   
      sdramMux_done        => sdramMux_done,      
      sdramMux_dataRead    => sdramMux_dataRead,
      
      rdp9fifo_reset       => '0',   
      rdp9fifo_Din         => 50x"0",     
      rdp9fifo_Wr          => '0',      
      
      rdp9fifoZ_reset      => '0',   
      rdp9fifoZ_Din        => 50x"0",     
      rdp9fifoZ_Wr         => '0'    
   );
   
   sdramMux_request(0) <= '0';
   sdramMux_request(2 to 3) <= "00";
   
   isdram_model : entity work.sdram_model
   generic map
   (
      DOREFRESH         => '0',
      INITFILE          => "NONE",
      SCRIPTLOADING     => '1',
      FILELOADING       => '0'
   )
   port map
   (
      clk               => clk1x,
      addr              => sdram_Adr,
      req               => sdram_ena,
      rnw               => sdram_rnw,
      be                => sdram_be,
      di                => sdram_dataWrite,
      do                => sdram_dataRead,
      reqprocessed      => sdram_reqprocessed,
      done              => sdram_done,
      fileSize          => open
   );
   
   process
      file infile          : text;
      variable f_status    : FILE_OPEN_STATUS;
      variable inLine      : LINE;
      variable para_data8  : std_logic_vector(7 downto 0);
      variable char        : character;
      variable command     : string(1 to 10);
   begin
      
      wait until reset = '0';
         
      file_open(f_status, infile, "R:\pif_FPGN64.txt", read_mode);
      
      while (not endfile(infile)) loop
         
         cmdCount <= cmdCount + 1;
         wait until rising_edge(clk1x);
         
         readline(infile,inLine);
         
         Read(inLine, command);
         if (command = "WriteIN : " or command = "ReadIN  : ") then
            SIPIF_ramreq <= '1';
            wait until SIPIF_ramgrant = '1';
            for i in 0 to 63 loop
               HREAD(inLine, para_data8);
               SIPIF_addr      <= to_unsigned(i, 6);
               SIPIF_writeEna  <= '1';
               SIPIF_writeData <= para_data8;
               wait until rising_edge(clk1x);
            end loop;
            SIPIF_writeEna <= '0';
            SIPIF_ramreq   <= '0';
            wait until SIPIF_ramgrant = '0';
         end if;
         
         if (command = "WriteOUT: ") then
            SIPIF_writeProc <= '1';
            wait until rising_edge(clk1x);
            SIPIF_writeProc <= '0';
            wait until rising_edge(clk1x);
            wait until SIPIF_ProcDone = '1';
         end if;
         
         if (command = "ReadOUT : ") then
            SIPIF_readProc <= '1';
            wait until rising_edge(clk1x);
            SIPIF_readProc <= '0';
            wait until rising_edge(clk1x);
            wait until SIPIF_ProcDone = '1';
         end if;

         for i in 0 to 999 loop
            wait until rising_edge(clk1x);
         end loop;
      end loop;
      
      file_close(infile);
      
      wait for 10 us;
      
      if (cmdCount >= 0) then
         report "DONE" severity failure;
      end if;
      
   end process;
   
   
end architecture;


