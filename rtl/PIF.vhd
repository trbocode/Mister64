library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use STD.textio.all;

library mem;

entity pif is
   port 
   (
      clk1x                : in  std_logic;
      ce                   : in  std_logic;
      reset                : in  std_logic;
      
      second_ena           : in  std_logic;
      
      ISPAL                : in  std_logic;
      CICTYPE              : in  std_logic_vector(3 downto 0);
      EEPROMTYPE           : in  std_logic_vector(1 downto 0); -- 00 -> off, 01 -> 4kbit, 10 -> 16kbit
      PADCOUNT             : in  std_logic_vector(1 downto 0); -- count - 1, todo : implement
      PADTYPE0             : in  std_logic_vector(1 downto 0); -- 00 = nothing, 01 = transfer, 10 = rumble
      PADTYPE1             : in  std_logic_vector(1 downto 0);
      PADTYPE2             : in  std_logic_vector(1 downto 0);
      PADTYPE3             : in  std_logic_vector(1 downto 0);
      CPAKFORMAT           : in  std_logic;
      
      error                : out std_logic := '0';
      
      pifrom_wraddress     : in  std_logic_vector(9 downto 0);
      pifrom_wrdata        : in  std_logic_vector(31 downto 0);
      pifrom_wren          : in  std_logic;
      
      SIPIF_ramreq         : in  std_logic := '0';
      SIPIF_addr           : in  unsigned(5 downto 0) := (others => '0');
      SIPIF_writeEna       : in  std_logic := '0'; 
      SIPIF_writeData      : in  std_logic_vector(7 downto 0);
      SIPIF_ramgrant       : out std_logic;
      SIPIF_readData       : out std_logic_vector(7 downto 0);
      
      SIPIF_writeProc      : in  std_logic;
      SIPIF_readProc       : in  std_logic;
      SIPIF_ProcDone       : out std_logic := '0';
      
      bus_addr             : in  unsigned(10 downto 0); 
      bus_dataWrite        : in  std_logic_vector(31 downto 0);
      bus_read             : in  std_logic;
      bus_write            : in  std_logic;
      bus_dataRead         : out std_logic_vector(31 downto 0) := (others => '0');
      bus_done             : out std_logic := '0';
      
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
      pad_3_analog_v       : in  std_logic_vector(7 downto 0);
      
      rumble               : out std_logic_vector(3 downto 0) := (others => '0');
      
      eeprom_addr          : in  std_logic_vector(8 downto 0);
      eeprom_wren          : in  std_logic;
      eeprom_in            : in  std_logic_vector(31 downto 0);
      eeprom_out           : out std_logic_vector(31 downto 0);
      eeprom_change        : out std_logic := '0';
      
      cpak_change          : out std_logic := '0';
      
      sdram_request        : out std_logic := '0';
      sdram_rnw            : out std_logic := '0'; 
      sdram_address        : out unsigned(26 downto 0):= (others => '0');
      sdram_burstcount     : out unsigned(7 downto 0):= (others => '0');
      sdram_writeMask      : out std_logic_vector(3 downto 0) := (others => '0'); 
      sdram_dataWrite      : out std_logic_vector(31 downto 0) := (others => '0');
      sdram_done           : in  std_logic;
      sdram_dataRead       : in  std_logic_vector(31 downto 0);
      
      SS_reset             : in  std_logic;
      loading_savestate    : in  std_logic;
      SS_DataWrite         : in  std_logic_vector(63 downto 0);
      SS_Adr               : in  unsigned(6 downto 0);
      SS_wren              : in  std_logic;
      SS_rden              : in  std_logic;
      SS_DataRead          : out std_logic_vector(63 downto 0);
      SS_idle              : out std_logic
   );
end entity;

architecture arch of pif is
   
   constant CIC_TYPE_6101 : std_logic_vector(3 downto 0) := "0000";
   constant CIC_TYPE_6102 : std_logic_vector(3 downto 0) := "0001";
   constant CIC_TYPE_7101 : std_logic_vector(3 downto 0) := "0010";
   constant CIC_TYPE_7102 : std_logic_vector(3 downto 0) := "0011";
   constant CIC_TYPE_6103 : std_logic_vector(3 downto 0) := "0100";
   constant CIC_TYPE_7103 : std_logic_vector(3 downto 0) := "0101";
   constant CIC_TYPE_6105 : std_logic_vector(3 downto 0) := "0110";
   constant CIC_TYPE_7105 : std_logic_vector(3 downto 0) := "0111";
   constant CIC_TYPE_6106 : std_logic_vector(3 downto 0) := "1000";
   constant CIC_TYPE_7106 : std_logic_vector(3 downto 0) := "1001";
   constant CIC_TYPE_8303 : std_logic_vector(3 downto 0) := "1010";
   constant CIC_TYPE_8401 : std_logic_vector(3 downto 0) := "1011";
   constant CIC_TYPE_5167 : std_logic_vector(3 downto 0) := "1100";
   constant CIC_TYPE_DDUS : std_logic_vector(3 downto 0) := "1101";
   
   signal INITDONE         : std_logic := '0';
   
   signal cic_seed         : std_logic_vector(7 downto 0);
   signal cic_version      : std_logic;
   signal cic_type         : std_logic;

   signal bus_read_rom     : std_logic := '0';
   signal bus_read_ram     : std_logic := '0';
   signal bus_write_ram    : std_logic := '0';
   
   signal pifrom_addr      : std_logic_vector(9 downto 0);
   signal pifrom_data      : std_logic_vector(31 downto 0) := (others => '0');
   signal pifrom_locked    : std_logic := '0';

   -- pif state machine
   type tState is
   (
      IDLE,
      WRITESTARTUP1,
      WRITESTARTUP2,
      WRITESTARTUP3,

      WRITECOMMAND,
      READCOMMAND,
      EVALWRITE,
      EVALREAD,
      WRITEBACKCOMMAND,
      
      CHECKDONE,
      RAMACCESS,
      
      CLEARRAM,
      CLEARREADCOMMAND,
      CLEARCOMPLETE,
      
      EXTCOMM_FETCHNEXT,
      EXTCOMM_EVALREAD,
      EXTCOMM_EVALCOMMAND,
      
      EXTCOMM_RECEIVEREAD,
      EXTCOMM_EVALRECEIVE,
      EXTCOMM_RECEIVETYPE,
      EXTCOMM_EVALTYPEGAMEPAD,
      EXTCOMM_EVALTYPEEEPROMRTC,
      
      EXTCOMM_RESPONSETYPE,
      EXTCOMM_RESPONSEPAD,
      
      EXTCOMM_PAK_READADDR1,
      EXTCOMM_PAK_READADDR2,
      EXTCOMM_PAK_READADDR3,
      
      EXTCOMM_PAKCRC,
      
      EXTCOMM_PAKREAD_READSDRAM,
      EXTCOMM_PAKREAD_WRITEPIF,
      EXTCOMM_PAKREAD_CHECKNEXT,
      
      EXTCOMM_PAKWRITE_READPIF,
      EXTCOMM_PAKWRITE_WRITESDRAM,
      EXTCOMM_PAKWRITE_CHECKNEXT,
      
      EXTCOMM_EEPROMINFO,
      
      EXTCOMM_EEPROMREAD_SETADDR,
      EXTCOMM_EEPROMREAD_READADDR,
      EXTCOMM_EEPROMREAD_DATAREAD,
      EXTCOMM_EEPROMREAD_DATAWRITE,
      
      EXTCOMM_EEPROMWRITE_READADDR,
      EXTCOMM_EEPROMWRITE_SETADDR,
      EXTCOMM_EEPROMWRITE_DATAREAD,
      EXTCOMM_EEPROMWRITE_DATAWRITE,
      
      EXTCOMM_RESPONSE_VALIDOVER,
      EXTCOMM_RESPONSE_WRITE,
      EXTCOMM_RESPONSE_END
   );
   signal state                     : tState := IDLE;
   signal startup_complete          : std_logic := '0';
   
   signal SIPIF_write_latched       : std_logic := '0';
   signal SIPIF_read_latched        : std_logic := '0';
   signal pifreadmode               : std_logic := '0';
   signal pifProcMode               : std_logic := '0';
   
   signal EXT_first                 : std_logic := '0';
   signal EXT_channel               : unsigned(5 downto 0) := (others => '0');
   signal EXT_index                 : unsigned(5 downto 0) := (others => '0');
   signal EXT_recindex              : unsigned(5 downto 0) := (others => '0');
   signal EXT_send                  : unsigned(5 downto 0) := (others => '0');
   signal EXT_receive               : unsigned(5 downto 0) := (others => '0');
   signal EXT_valid                 : std_logic := '0';
   signal EXT_over                  : std_logic := '0';
   signal EXT_skip                  : std_logic := '0';
   signal EXP_responseindex         : unsigned(2 downto 0);
   
   type t_responsedata is array(0 to 3) of std_logic_vector(7 downto 0);
   signal EXT_responsedata : t_responsedata;      
   
   signal PADTYPE                   : std_logic_vector(1 downto 0);
   
   -- PIFRAM
   signal pifram_wren               : std_logic := '0';
   signal pifram_busdata            : std_logic_vector(31 downto 0) := (others => '0');
      
   signal ram_address_b             : std_logic_vector(5 downto 0) := (others => '0');
   signal ram_data_b                : std_logic_vector(7 downto 0) := (others => '0');
   signal ram_wren_b                : std_logic := '0';   
   signal ram_q_b                   : std_logic_vector(7 downto 0); 
   
   -- PAKs
   signal pakwrite                  : std_logic;
   signal pakaddr                   : std_logic_vector(15 downto 0) := (others => '0');
   signal pakvalue                  : std_logic_vector(7 downto 0);
   
   signal pakcrc_count              : unsigned(2 downto 0);
   signal pakcrc_value              : std_logic_vector(7 downto 0);
   signal pakcrc_last               : std_logic;
   
   type tCPAKINITState is
   (
      PAKINIT_IDLE,
      PAKINIT_WRITESDRAM,
      PAKINIT_WAITSDRAM
   );
   signal PAKINITState              : tCPAKINITState := PAKINIT_IDLE;
   signal pakinit_addr              : unsigned(14 downto 0) := (others => '0');
   signal pakinit_data              : std_logic_vector(31 downto 0);
   
   -- EEPROM
   signal eeprom_addr_a             : std_logic_vector(8 downto 0);
   signal eeprom_wren_a             : std_logic := '0';
   signal eeprom_in_a               : std_logic_vector(31 downto 0);
      
   signal eeprom_addr_b             : std_logic_vector(10 downto 0) := (others => '0');
   signal eeprom_wren_b             : std_logic := '0';
   signal eeprom_in_b               : std_logic_vector(7 downto 0) := (others => '0');
   signal eeprom_out_b              : std_logic_vector(7 downto 0) := (others => '0');
   
   type tEEPROMState is
   (
      EEPROM_IDLE,
      EEPROM_CLEAR
   );
   signal EEPROMState               : tEEPROMState := EEPROM_IDLE;
   signal eeprom_addr_clear         : std_logic_vector(8 downto 0) := (others => '0');
   
begin 

   pifrom_addr <= ISPAL & std_logic_vector(bus_addr(10 downto 2));

   ipifrom : entity work.pifrom
   port map
   (
      clk       => clk1x,
      address   => pifrom_addr,
      data      => pifrom_data,

      wraddress => pifrom_wraddress,
      wrdata    => pifrom_wrdata,   
      wren      => pifrom_wren     
   );
   
   ipif_cpakinit : entity work.pif_cpakinit
   port map
   (
      clk       => clk1x,
      address   => std_logic_vector(pakinit_addr(6 downto 0)),
      data      => pakinit_data
   );
   
   iPIFRAM: entity work.dpram_dif
   generic map 
   ( 
      addr_width_a  => 4,
      data_width_a  => 32,
      addr_width_b  => 6,
      data_width_b  => 8
   )
   port map
   (
      clock_a     => clk1x,
      address_a   => std_logic_vector(bus_addr(5 downto 2)),
      data_a      => bus_dataWrite,
      wren_a      => pifram_wren,
      q_a         => pifram_busdata,
      
      clock_b     => clk1x,
      address_b   => ram_address_b,
      data_b      => ram_data_b,
      wren_b      => ram_wren_b,
      q_b         => ram_q_b
   );
   
   SIPIF_readData <= ram_q_b;
   
   SS_DataRead <= (others => '0');
   SS_idle     <= '1';
   
   
   process (CICTYPE)
   begin
      cic_seed    <= x"3F"; 
      cic_version <= '0'; 
      cic_type    <= '0';
      case (CICTYPE) is
         when CIC_TYPE_6101 => cic_seed <= x"3F"; cic_version <= '1'; cic_type <= '0';
         when CIC_TYPE_6102 => cic_seed <= x"3F"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_7101 => cic_seed <= x"3F"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_7102 => cic_seed <= x"3F"; cic_version <= '1'; cic_type <= '0';
         when CIC_TYPE_6103 => cic_seed <= x"78"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_7103 => cic_seed <= x"78"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_6105 => cic_seed <= x"91"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_7105 => cic_seed <= x"91"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_6106 => cic_seed <= x"85"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_7106 => cic_seed <= x"85"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_8303 => cic_seed <= x"DD"; cic_version <= '0'; cic_type <= '1';
         when CIC_TYPE_8401 => cic_seed <= x"DD"; cic_version <= '0'; cic_type <= '1';
         when CIC_TYPE_5167 => cic_seed <= x"3F"; cic_version <= '0'; cic_type <= '0';
         when CIC_TYPE_DDUS => cic_seed <= x"DE"; cic_version <= '0'; cic_type <= '1';
         when others => null;
      end case;
   end process;
   
   PADTYPE <= PADTYPE0 when (EXT_channel(1 downto 0) = "00") else 
              PADTYPE1 when (EXT_channel(1 downto 0) = "01") else 
              PADTYPE2 when (EXT_channel(1 downto 0) = "10") else 
              PADTYPE3;
              
   sdram_burstcount <= x"01";
              
   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         error         <= '0';
         pifram_wren   <= '0';
         eeprom_wren_b <= '0';
         sdram_request <= '0';
         cpak_change   <= '0';
         
         if (second_ena = '1' and INITDONE = '0') then
            INITDONE     <= '1';
            PAKINITState <= PAKINIT_WRITESDRAM;
            EEPROMState  <= EEPROM_CLEAR;
         end if;
         if (CPAKFORMAT = '1') then
            PAKINITState <= PAKINIT_WRITESDRAM;
            pakinit_addr <= (others => '0');
         end if;
         
         -- init eeprom
         case (EEPROMState) is
         
            when EEPROM_IDLE => null;
               
            when EEPROM_CLEAR =>
               eeprom_addr_clear <= std_logic_vector(unsigned(eeprom_addr_clear) + 1);
               if (eeprom_addr_clear = 9x"1FF") then
                   EEPROMState <= EEPROM_IDLE;
               end if;
         
         end case;
         
         -- init PAK area
         case (PAKINITState) is      
               
            when PAKINIT_IDLE => null;
            
            when PAKINIT_WRITESDRAM =>
               PAKINITState    <= PAKINIT_WAITSDRAM;
               sdram_request   <= '1';
               sdram_rnw       <= '0';
               sdram_writeMask <= "1111";
               sdram_address   <= resize(unsigned(pakinit_addr & "00"), 27) + to_unsigned(16#500000#, 27);
               if (pakinit_addr(12 downto 0) < 128) then
                  sdram_dataWrite <= pakinit_data;
               else
                  sdram_dataWrite <= (others => '0');
               end if;
               pakinit_addr    <= pakinit_addr + 1;
               if (pakinit_addr = 15x"7FFF") then
                  PAKINITState <= PAKINIT_IDLE;
               end if;

            when PAKINIT_WAITSDRAM =>
               if (sdram_done = '1') then
                  PAKINITState <= PAKINIT_WRITESDRAM;
               end if;
               
         end case;
         
         if (PADTYPE0 /= "10") then rumble(0) <= '0'; end if;
         if (PADTYPE1 /= "10") then rumble(1) <= '0'; end if;
         if (PADTYPE2 /= "10") then rumble(2) <= '0'; end if;
         if (PADTYPE3 /= "10") then rumble(3) <= '0'; end if;
      
         if (reset = '1') then
            
            bus_done             <= '0';
            bus_read_rom         <= '0';
            bus_read_ram         <= '0';
            bus_write_ram        <= '0';
                  
            pifrom_locked        <= '0';
            
            startup_complete     <= '0';
            ram_address_b        <= (others => '0');
            ram_data_b           <= (others => '0');
            
            SIPIF_ramgrant       <= '0';
            SIPIF_write_latched  <= '0';
            SIPIF_read_latched   <= '0';
            
            if (loading_savestate = '1') then
               state      <= IDLE;
               ram_wren_b <= '0';
            else
               state      <= CLEARRAM;
               ram_wren_b <= '1';
            end if;
            
            rumble <= (others => '0');
            
         elsif (ce = '1') then
         
            SIPIF_ProcDone <= '0';
            ram_wren_b     <= '0';
         
            bus_done       <= '0';
            bus_read_rom   <= '0';
            bus_dataRead   <= (others => '0');

            if (bus_read_rom = '1') then
               bus_done <= '1';
               if (pifrom_locked = '0') then
                  bus_dataRead <= pifrom_data;
               end if;
            end if;

            -- bus read
            if (bus_read = '1') then
               if (bus_addr < 16#7C0#) then
                  bus_read_rom <= '1';
               else
                  bus_read_ram <= '1';
               end if;
            end if;

            -- bus write
            if (bus_write = '1') then
               if (bus_addr < 16#7C0#) then
                  bus_done <= '1';
               else
                  bus_write_ram <= '1';
               end if;
            end if;
            
            -- pif state machine
            if (SIPIF_writeProc = '1') then SIPIF_write_latched <= '1'; end if;
            if (SIPIF_readProc  = '1') then SIPIF_read_latched  <= '1'; end if;
            
            case (state) is
            
               when IDLE =>
                  pifreadmode <= '0';
                  pifProcMode <= '0';
                  EXT_first   <= '1';
                  if (SIPIF_ramreq = '1') then
                     state          <= RAMACCESS;
                     SIPIF_ramgrant <= '1';
                  elsif (SIPIF_write_latched = '1' or SIPIF_read_latched = '1') then
                     state         <= WRITECOMMAND;
                     ram_address_b <= 6x"3F";
                     pifreadmode   <= SIPIF_read_latched;
                     pifProcMode   <= '1';
                  elsif (bus_write_ram = '1') then
                     bus_write_ram <= '0';
                     bus_done      <= '1';
                     pifram_wren   <= '1';
                     if (bus_addr(5 downto 2) = x"F") then
                        state         <= WRITECOMMAND;
                        ram_address_b <= 6x"3F";
                     end if;
                  elsif (bus_read_ram = '1') then
                     bus_read_ram <= '0';
                     bus_done     <= '1';
                     bus_dataRead <= pifram_busdata(7 downto 0) & pifram_busdata(15 downto 8) & pifram_busdata(23 downto 16) & pifram_busdata(31 downto 24);
                  end if;
            
               -- startup values
               when WRITESTARTUP1 =>
                  state          <= WRITESTARTUP2;
                  ram_address_b  <= 6x"27";
                  ram_data_b     <= x"3F";
                  ram_wren_b     <= '1';               
                  
               when WRITESTARTUP2 =>
                  state          <= WRITESTARTUP3;
                  ram_address_b  <= 6x"26";
                  ram_data_b     <= cic_seed; -- seed, depends on CIC
                  ram_wren_b     <= '1';
               
               when WRITESTARTUP3 =>
                  state            <= IDLE;  
                  ram_address_b    <= 6x"25";
                  ram_data_b       <= x"0" & cic_type & cic_version & "00"; -- version and type, depends on CIC
                  ram_wren_b       <= '1';   
                  startup_complete <= '1';
            
               -- command evaluation
               when WRITECOMMAND =>
                  state <= READCOMMAND;
            
               when READCOMMAND =>
                  if (pifreadmode = '1') then
                     state            <= EVALREAD;
                  else
                     state            <= EVALWRITE;
                  end if;
                  SIPIF_write_latched <= '0';
                  SIPIF_read_latched  <= '0';
                  
               when EVALWRITE =>
                  state     <= CHECKDONE;
                  EXT_first <= '0';
                  
                  if (unsigned(ram_q_b) > 1) then
                     if (ram_q_b(1) = '1') then -- CIC-NUS-6105 challenge/response
                        report "unimplemented PIF CIC challenge" severity warning;
                        state         <= WRITEBACKCOMMAND;
                        ram_wren_b    <= '1';
                        ram_data_b    <= ram_q_b;
                        ram_data_b(1) <= '0';
                        
                     elsif (ram_q_b(2) = '1') then -- unknown
                        report "unimplemented PIF unknown command 2" severity warning;
                        state         <= WRITEBACKCOMMAND;
                        ram_wren_b    <= '1';
                        ram_data_b    <= ram_q_b;
                        ram_data_b(2) <= '0';
                        
                     elsif (ram_q_b(3) = '1') then -- will lock up if not done
                        state         <= WRITEBACKCOMMAND;
                        ram_wren_b    <= '1';
                        ram_data_b    <= ram_q_b;
                        ram_data_b(3) <= '0';
                        
                     elsif (ram_q_b(4) = '1') then -- PIFROM locked
                        state         <= WRITEBACKCOMMAND;
                        ram_wren_b    <= '1';
                        ram_data_b    <= ram_q_b;
                        ram_data_b(4) <= '0';
                        pifrom_locked <= '1';
                        
                     elsif (ram_q_b(5) = '1') then -- init
                        state         <= WRITEBACKCOMMAND;
                        ram_wren_b    <= '1';
                        ram_data_b    <= ram_q_b;
                        ram_data_b(5) <= '0';
                        ram_data_b(7) <= '1';
                        
                     elsif (ram_q_b(6) = '1') then -- clear pif ram
                        state         <= CLEARRAM;
                        ram_address_b <= (others => '0');
                        ram_data_b    <= (others => '0');
                        ram_wren_b    <= '1';
                     end if;
                  elsif (EXT_first = '1') then
                     state         <= EXTCOMM_FETCHNEXT;
                     ram_address_b <= (others => '0');
                     EXT_channel   <= (others => '0');
                     EXT_index     <= (others => '0');
                  end if;
                  
               when EVALREAD =>
                  state <= CHECKDONE;
                  if (ram_q_b(1) = '1') then -- CIC-NUS-6105 challenge/response
                     null;
                  else
                     state         <= EXTCOMM_FETCHNEXT;
                     EXT_channel   <= (others => '0');
                     EXT_index     <= (others => '0');
                  end if;
                  
               when WRITEBACKCOMMAND =>
                  state         <= READCOMMAND;
            
               -- SI/PIF communication
               when CHECKDONE =>
                  state          <= IDLE;
                  SIPIF_ProcDone <= pifProcMode;
                  
               when RAMACCESS =>
                  if (SIPIF_ramreq = '0') then
                     state          <= IDLE;
                     SIPIF_ramgrant <= '0';
                  end if;
                  ram_address_b <= std_logic_vector(SIPIF_addr);
                  ram_data_b    <= SIPIF_writeData;
                  ram_wren_b    <= SIPIF_writeEna;
            
               -- clear
               when CLEARRAM =>
                  ram_address_b <= std_logic_vector(unsigned(ram_address_b) + 1);
                  ram_wren_b    <= '1';
                  if (ram_address_b = 6x"3E") then
                     if (startup_complete = '1') then
                        state      <= CLEARREADCOMMAND;
                        ram_wren_b <= '0';
                     else
                        state <= WRITESTARTUP1;
                     end if;
                  end if;
                  
               when CLEARREADCOMMAND =>
                  state <= CLEARCOMPLETE;
               
               when CLEARCOMPLETE =>
                  state <= WRITEBACKCOMMAND;
                  ram_wren_b    <= '1';
                  ram_data_b    <= ram_q_b;
                  ram_data_b(6) <= '0'; 
            
               -- extern communication
               when EXTCOMM_FETCHNEXT =>
                  state         <= EXTCOMM_EVALREAD;
                  ram_address_b <= std_logic_vector(EXT_index);
               
               when EXTCOMM_EVALREAD =>
                  state <= EXTCOMM_EVALCOMMAND;
                
               when EXTCOMM_EVALCOMMAND =>
                  if (EXT_index = 63 or ram_q_b = x"FE") then
                     state     <= CHECKDONE;
                     EXT_index <= (others => '0');
                     if (pifreadmode = '0') then
                        ram_wren_b    <= '1';
                        ram_address_b <= 6x"3F";
                        ram_data_b    <= (others => '0');
                     end if;
                  elsif (ram_q_b = x"00") then
                     state         <= EXTCOMM_FETCHNEXT;
                     EXT_channel   <= EXT_channel + 1;
                     EXT_index     <= EXT_index + 1;
                  elsif (ram_q_b = x"FD" or ram_q_b = x"FF") then
                     state         <= EXTCOMM_FETCHNEXT;
                     EXT_index     <= EXT_index + 1;
                  else
                     state         <= EXTCOMM_RECEIVEREAD;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);
                     EXT_send      <= unsigned(ram_q_b(5 downto 0));
                  end if;
               
               when EXTCOMM_RECEIVEREAD =>
                  state        <= EXTCOMM_EVALRECEIVE;
                  EXT_recindex <= EXT_index;
                  
               when EXTCOMM_EVALRECEIVE =>
                  if (ram_q_b = x"FE") then
                     state <= CHECKDONE;
                     if (pifreadmode = '0') then
                        ram_wren_b    <= '1';
                        ram_address_b <= 6x"3F";
                        ram_data_b    <= (others => '0');
                     end if;
                  else
                     EXT_receive   <= unsigned(ram_q_b(5 downto 0));
                     state         <= EXTCOMM_RECEIVETYPE;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);
                  end if;
                  
               when EXTCOMM_RECEIVETYPE =>
                  EXT_over      <= '0';
                  EXT_valid     <= '0';
                  EXT_skip      <= '0';
                  if (EXT_channel < 4) then
                     state <= EXTCOMM_EVALTYPEGAMEPAD;
                  else
                     state <= EXTCOMM_EVALTYPEEEPROMRTC;
                  end if;
                  
               when EXTCOMM_EVALTYPEGAMEPAD =>
                  pakcrc_value <= (others => '0');
                  if (ram_q_b = x"00" or ram_q_b = x"FF") then -- type check
                     state         <= EXTCOMM_RESPONSETYPE;
                  elsif (ram_q_b = x"01") then -- pad response
                     state <= EXTCOMM_RESPONSEPAD;
                  elsif (ram_q_b = x"02") then -- pad read
                     pakwrite      <= '0';
                     state         <= EXTCOMM_PAK_READADDR1;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);
                     if (EXT_send /= x"03" or EXT_receive /= x"21") then
                        error <= '1';
                     else
                        EXT_valid <= '1';
                        EXT_skip  <= '1';
                     end if;
                  elsif (ram_q_b = x"03") then -- pad write
                     pakwrite      <= '1';
                     state         <= EXTCOMM_PAK_READADDR1;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);
                     if (EXT_send /= x"23" or EXT_receive /= x"01") then
                        error <= '1';
                     else
                        EXT_valid <= '1';
                     end if;
                  else
                     state         <= EXTCOMM_RESPONSE_VALIDOVER;
                  end if;
               
               when EXTCOMM_EVALTYPEEEPROMRTC =>      
                  if (ram_q_b = x"00" or ram_q_b = x"FF") then
                     state         <= EXTCOMM_EEPROMINFO;
                  elsif (ram_q_b = x"04") then
                     state         <= EXTCOMM_EEPROMREAD_READADDR;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);                  
                  elsif (ram_q_b = x"05") then
                     state         <= EXTCOMM_EEPROMWRITE_READADDR;
                     EXT_index     <= EXT_index + 1;
                     ram_address_b <= std_logic_vector(EXT_index + 1);
                  else
                     state         <= EXTCOMM_RESPONSE_VALIDOVER;
                  end if;
            
               -- responses for gamepad
               when EXTCOMM_RESPONSETYPE =>
                  state               <= EXTCOMM_RESPONSE_VALIDOVER;
                  EXT_valid           <= '1';
                  EXT_responsedata(0) <= x"05";
                  EXT_responsedata(1) <= x"00";
                  if (PADTYPE = "01" or PADTYPE = "10") then
                     EXT_responsedata(2) <= x"01";
                  else
                     EXT_responsedata(2) <= x"02";
                  end if;
               
               when EXTCOMM_RESPONSEPAD =>
                  state               <= EXTCOMM_RESPONSE_VALIDOVER;
                  EXT_valid           <= '1';
                  if (EXT_receive > 4) then
                     EXT_over         <= '1';
                  end if;
                  EXT_responsedata(0)(7) <= pad_A(to_integer(EXT_channel(1 downto 0)));         
                  EXT_responsedata(0)(6) <= pad_B(to_integer(EXT_channel(1 downto 0)));         
                  EXT_responsedata(0)(5) <= pad_Z(to_integer(EXT_channel(1 downto 0)));         
                  EXT_responsedata(0)(4) <= pad_START(to_integer(EXT_channel(1 downto 0)));     
                  EXT_responsedata(0)(3) <= pad_DPAD_UP(to_integer(EXT_channel(1 downto 0)));   
                  EXT_responsedata(0)(2) <= pad_DPAD_DOWN(to_integer(EXT_channel(1 downto 0))); 
                  EXT_responsedata(0)(1) <= pad_DPAD_LEFT(to_integer(EXT_channel(1 downto 0))); 
                  EXT_responsedata(0)(0) <= pad_DPAD_RIGHT(to_integer(EXT_channel(1 downto 0)));
                  
                  EXT_responsedata(1)(7 downto 6) <= "00";      
                  EXT_responsedata(1)(5) <= pad_L(to_integer(EXT_channel(1 downto 0)));      
                  EXT_responsedata(1)(4) <= pad_R(to_integer(EXT_channel(1 downto 0)));      
                  EXT_responsedata(1)(3) <= pad_C_UP(to_integer(EXT_channel(1 downto 0)));   
                  EXT_responsedata(1)(2) <= pad_C_DOWN(to_integer(EXT_channel(1 downto 0))); 
                  EXT_responsedata(1)(1) <= pad_C_LEFT(to_integer(EXT_channel(1 downto 0))); 
                  EXT_responsedata(1)(0) <= pad_C_RIGHT(to_integer(EXT_channel(1 downto 0)));
                  
                  case (EXT_channel(1 downto 0)) is
                     when "00"   => EXT_responsedata(2) <= pad_0_analog_h; EXT_responsedata(3) <= std_logic_vector(-signed(pad_0_analog_v));
                     when "01"   => EXT_responsedata(2) <= pad_1_analog_h; EXT_responsedata(3) <= std_logic_vector(-signed(pad_1_analog_v));
                     when "10"   => EXT_responsedata(2) <= pad_2_analog_h; EXT_responsedata(3) <= std_logic_vector(-signed(pad_2_analog_v));
                     when others => EXT_responsedata(2) <= pad_3_analog_h; EXT_responsedata(3) <= std_logic_vector(-signed(pad_3_analog_v));
                  end case;
                  
               -- reponses for PAK
               when EXTCOMM_PAK_READADDR1 =>
                  state <= EXTCOMM_PAK_READADDR2;
                  EXT_send      <= EXT_send - 1;
                  EXT_index     <= EXT_index + 1;
                  ram_address_b <= std_logic_vector(EXT_index + 1);
                  
               when EXTCOMM_PAK_READADDR2 =>
                  state                <= EXTCOMM_PAK_READADDR3;
                  pakaddr(15 downto 8) <= ram_q_b;
                  EXT_send             <= EXT_send - 1;
                  if (pakwrite = '1') then
                     EXT_index         <= EXT_index + 1;
                     ram_address_b     <= std_logic_vector(EXT_index + 1);
                  end if;

               when EXTCOMM_PAK_READADDR3 =>
                  if (pakwrite = '0') then
                     state <= EXTCOMM_PAKREAD_READSDRAM;
                  else
                     state <= EXTCOMM_PAKWRITE_READPIF;
                  end if;
                  pakaddr(7 downto 5)  <= ram_q_b(7 downto 5);
                  EXT_send             <= EXT_send - 1;
                  
               -- PAK CRC
               when EXTCOMM_PAKCRC =>
                  pakcrc_count <= pakcrc_count + 1;
                  if (pakcrc_count = 7) then
                     pakcrc_last <= '0'; 
                     if (pakcrc_last = '0') then
                        if (pakwrite = '1') then
                           state <= EXTCOMM_PAKWRITE_CHECKNEXT;
                        else
                           state <= EXTCOMM_PAKREAD_CHECKNEXT;
                        end if;
                     end if;
                  end if;
                  
                  if (pakcrc_value(7) = '1') then
                     pakcrc_value <= (pakcrc_value(6 downto 0) & pakvalue(7)) xor x"85";
                  else
                     pakcrc_value <= (pakcrc_value(6 downto 0) & pakvalue(7));
                  end if;
                  pakvalue <= pakvalue(6 downto 0) & '0';
                  
               -- reponses for PAK read
               when EXTCOMM_PAKREAD_READSDRAM => 
                  state           <= EXTCOMM_PAKREAD_WRITEPIF;
                  sdram_request   <= '1';
                  sdram_rnw       <= '1';
                  sdram_address   <= resize(EXT_channel & unsigned(pakaddr(14 downto 2)) & "00", 27) + to_unsigned(16#500000#, 27);
                  
               when EXTCOMM_PAKREAD_WRITEPIF =>
                  if (sdram_done = '1') then
                     state          <= EXTCOMM_PAKCRC;
                     pakcrc_count   <= (others => '0');
                     pakcrc_last    <= '0';
                     if (pakaddr(4 downto 0) = 5x"1F") then -- last byte will need one additional round of crc with input value 00
                        pakcrc_last <= '1';
                     end if;
                     ram_wren_b     <= '1';
                     EXT_index      <= EXT_index + 1;
                     ram_address_b  <= std_logic_vector(EXT_index + 1);
                     if (PADTYPE = "10") then -- rumble
                        if (unsigned(pakaddr) >= 16#8000# and unsigned(pakaddr) < 16#9000#) then
                           ram_data_b     <= x"80";
                           pakvalue       <= x"80";
                        else
                           ram_data_b     <= x"00";
                           pakvalue       <= x"00";
                        end if;
                     else --cpak
                        if (pakaddr(15) = '1') then
                           ram_data_b     <= x"00";
                           pakvalue       <= x"00";
                        else
                           case (pakaddr(1 downto 0)) is
                              when "00" => ram_data_b <= sdram_dataRead( 7 downto  0); pakvalue <= sdram_dataRead( 7 downto  0);
                              when "01" => ram_data_b <= sdram_dataRead(15 downto  8); pakvalue <= sdram_dataRead(15 downto  8);
                              when "10" => ram_data_b <= sdram_dataRead(23 downto 16); pakvalue <= sdram_dataRead(23 downto 16);
                              when "11" => ram_data_b <= sdram_dataRead(31 downto 24); pakvalue <= sdram_dataRead(31 downto 24);
                              when others => null;
                           end case;
                        end if;
                     end if;
                     pakaddr(4 downto 0) <= std_logic_vector(unsigned(pakaddr(4 downto 0)) + 1);
                  end if;
                  
               when EXTCOMM_PAKREAD_CHECKNEXT =>
                  if (pakaddr(4 downto 0) = 5x"0") then
                     state          <= EXTCOMM_RESPONSE_VALIDOVER;
                     ram_wren_b     <= '1';
                     EXT_index      <= EXT_index + 1;
                     ram_address_b  <= std_logic_vector(EXT_index + 1);
                     ram_data_b     <= pakcrc_value;
                  else
                     state <= EXTCOMM_PAKREAD_READSDRAM;
                  end if;
                  
               -- reponses for PAK write
               when EXTCOMM_PAKWRITE_READPIF =>
                  state          <= EXTCOMM_PAKWRITE_WRITESDRAM;
                  pakvalue       <= ram_q_b;
                  EXT_index      <= EXT_index + 1;
                  ram_address_b  <= std_logic_vector(EXT_index + 1);
                  EXT_send       <= EXT_send - 1;
                  pakaddr(4 downto 0) <= std_logic_vector(unsigned(pakaddr(4 downto 0)) + 1);
                  if (PADTYPE = "10") then -- rumble
                     if (pakaddr = x"C000") then
                        rumble(to_integer(EXT_channel(1 downto 0))) <= ram_q_b(0);
                     end if;
                  else -- cpak
                     if (pakaddr(15) = '0') then
                        cpak_change     <= '1';
                        sdram_request   <= '1';
                        sdram_rnw       <= '0';
                        sdram_address   <= resize(EXT_channel & unsigned(pakaddr(14 downto 2)) & "00", 27) + to_unsigned(16#500000#, 27);
                        sdram_dataWrite <= ram_q_b & ram_q_b & ram_q_b & ram_q_b;
                        case (pakaddr(1 downto 0)) is
                           when "00" => sdram_writeMask <= "0001";
                           when "01" => sdram_writeMask <= "0010";
                           when "10" => sdram_writeMask <= "0100";
                           when "11" => sdram_writeMask <= "1000";
                           when others => null;
                        end case;
                     end if;
                  end if;
                  
               when EXTCOMM_PAKWRITE_WRITESDRAM =>
                  if (sdram_done = '1' or pakaddr(15) = '1' or PADTYPE = "10") then
                     state          <= EXTCOMM_PAKCRC;
                     pakcrc_count   <= (others => '0');
                     pakcrc_last    <= '0';
                     if (EXT_send = 0) then -- last byte will need one additional round of crc with input value 00
                        pakcrc_last <= '1';
                     end if;
                  end if;

               when EXTCOMM_PAKWRITE_CHECKNEXT =>
                  if (EXT_send = 0) then
                     state               <= EXTCOMM_RESPONSE_VALIDOVER;
                     EXT_index           <= EXT_index - 1;
                     EXT_responsedata(0) <= pakcrc_value;
                  else
                     state      <= EXTCOMM_PAKWRITE_READPIF;
                  end if;

               -- responses for EEProm/RTC
               when EXTCOMM_EEPROMINFO =>
                  state <= EXTCOMM_RESPONSE_VALIDOVER;
                  if (EEPROMTYPE = "01") then -- 4kbit
                     EXT_valid           <= '1';
                     EXT_responsedata(0) <= x"00";
                     EXT_responsedata(1) <= x"80";
                     EXT_responsedata(2) <= x"00";
                  elsif (EEPROMTYPE = "10") then -- 16kbit
                     EXT_valid           <= '1';
                     EXT_responsedata(0) <= x"00";
                     EXT_responsedata(1) <= x"C0";
                     EXT_responsedata(2) <= x"00";
                  end if;
                  
               -- eeprom read
               when EXTCOMM_EEPROMREAD_READADDR =>
                  if (EXT_receive /= 8) then
                     error <= '1';
                  end if;
                  if (EXT_send >= 2) then
                     state     <= EXTCOMM_EEPROMREAD_SETADDR;
                     EXT_valid <= '1';
                  else
                     state     <= EXTCOMM_RESPONSE_VALIDOVER;
                  end if;
                     
               when EXTCOMM_EEPROMREAD_SETADDR =>
                  state             <= EXTCOMM_EEPROMREAD_DATAREAD;
                  eeprom_addr_b     <= ram_q_b & "000";
                  EXT_skip          <= '1';
                     
               when EXTCOMM_EEPROMREAD_DATAREAD =>
                  state                     <= EXTCOMM_EEPROMREAD_DATAWRITE;
                  eeprom_addr_b(2 downto 0) <= std_logic_vector(unsigned(eeprom_addr_b(2 downto 0)) + 1);
                  
               when EXTCOMM_EEPROMREAD_DATAWRITE =>
                  if (eeprom_addr_b(2 downto 0) = "000") then
                     state <= EXTCOMM_RESPONSE_VALIDOVER;
                  else
                     state <= EXTCOMM_EEPROMREAD_DATAREAD;
                  end if;
                  ram_wren_b        <= '1';
                  EXT_index         <= EXT_index + 1;
                  ram_address_b     <= std_logic_vector(EXT_index + 1);
                  ram_data_b        <= eeprom_out_b;
                  
               -- eeprom write
               when EXTCOMM_EEPROMWRITE_READADDR =>
                  EXT_send <= EXT_send - 1;
                  if (EXT_receive /= 1) then
                     error <= '1';
                  end if;
                  if (EXT_send >= 2 and EXT_receive >= 1) then
                     state     <= EXTCOMM_EEPROMWRITE_SETADDR;
                     EXT_valid <= '1';
                  else
                     state     <= EXTCOMM_RESPONSE_VALIDOVER;
                  end if;
                     
               when EXTCOMM_EEPROMWRITE_SETADDR =>
                  state               <= EXTCOMM_EEPROMWRITE_DATAREAD;
                  eeprom_addr_b       <= ram_q_b & "111";
                  EXT_responsedata(0) <= x"00";
                  EXT_send            <= EXT_send - 1;
                  EXT_index           <= EXT_index + 1;
                  ram_address_b       <= std_logic_vector(EXT_index + 1);    
                  
               when EXTCOMM_EEPROMWRITE_DATAREAD =>
                  if (EXT_send = 0) then
                     state      <= EXTCOMM_RESPONSE_VALIDOVER;
                     EXT_index  <= EXT_index - 1;
                  else
                     state      <= EXTCOMM_EEPROMWRITE_DATAWRITE;
                     EXT_index  <= EXT_index + 1;
                  end if;
                  ram_address_b  <= std_logic_vector(EXT_index + 1);    
                  EXT_send       <= EXT_send - 1;
                  eeprom_addr_b(2 downto 0) <= std_logic_vector(unsigned(eeprom_addr_b(2 downto 0)) + 1);  
                  
               when EXTCOMM_EEPROMWRITE_DATAWRITE =>
                  state         <= EXTCOMM_EEPROMWRITE_DATAREAD;
                  eeprom_in_b   <= ram_q_b;
                  eeprom_wren_b <= '1';
                  
               -- response writeback
               when EXTCOMM_RESPONSE_VALIDOVER =>
                  if (EXT_receive > 0 and EXT_valid = '1' and EXT_skip = '0') then
                     state         <= EXTCOMM_RESPONSE_WRITE;
                  else
                     state         <= EXTCOMM_RESPONSE_END;
                  end if;
                  ram_wren_b        <= '1';
                  ram_address_b     <= std_logic_vector(EXT_recindex);
                  ram_data_b        <= (not EXT_valid) & EXT_over & std_logic_vector(EXT_receive);
                  EXP_responseindex <= (others => '0');
                                    
               when EXTCOMM_RESPONSE_WRITE =>
                  if (EXP_responseindex + 1 = EXT_receive) then
                     state <= EXTCOMM_RESPONSE_END;
                  end if;
                  ram_wren_b        <= '1';
                  EXT_index         <= EXT_index + 1;
                  ram_address_b     <= std_logic_vector(EXT_index + 1);
                  ram_data_b        <= EXT_responsedata(to_integer(EXP_responseindex(2 downto 0)));
                  EXP_responseindex <= EXP_responseindex + 1;
            
               when EXTCOMM_RESPONSE_END => 
                  state         <= EXTCOMM_FETCHNEXT;
                  EXT_channel   <= EXT_channel + 1;
                  EXT_index     <= EXT_index + 1;
            
            end case;
            
            if (EXT_index = 6x"3F" and state /= EXTCOMM_FETCHNEXT and state /= EXTCOMM_EVALREAD and state /= EXTCOMM_EVALCOMMAND and state /= IDLE) then -- safety out
               state       <= CHECKDONE;
               error       <= '1';
               EXT_index   <= (others => '0');
            end if;
            
         end if; -- ce
         
         if (SS_wren = '1') then
            ram_wren_b    <= '1';
            ram_address_b <= std_logic_vector(SS_Adr(5 downto 0));
            ram_data_b    <= SS_DataWrite(7 downto 0);
         end if;
         
      end if; -- clock
   end process;
   
--##############################################################
--############################### eeprom
--##############################################################
   
   iEEPROM: entity work.dpram_dif
   generic map 
   ( 
      addr_width_a  => 9,
      data_width_a  => 32,
      addr_width_b  => 11,
      data_width_b  => 8
   )
   port map
   (
      clock_a     => clk1x,
      address_a   => eeprom_addr_a,
      data_a      => eeprom_in_a,
      wren_a      => eeprom_wren_a,
      q_a         => eeprom_out,
      
      clock_b     => clk1x,
      address_b   => eeprom_addr_b,
      data_b      => eeprom_in_b,
      wren_b      => eeprom_wren_b,
      q_b         => eeprom_out_b
   );
   
   eeprom_change <= eeprom_wren_b;
   
   eeprom_addr_a <= eeprom_addr_clear when (EEPROMState = EEPROM_CLEAR) else eeprom_addr;
   eeprom_wren_a <= '1'               when (EEPROMState = EEPROM_CLEAR) else eeprom_wren;
   eeprom_in_a   <= x"FFFFFFFF"       when (EEPROMState = EEPROM_CLEAR) else eeprom_in;

--##############################################################
--############################### export
--##############################################################
   
   -- synthesis translate_off
   goutput : if 1 = 1 generate
      type tpifRamExport is array(0 to 63) of std_logic_vector(7 downto 0);
      signal pifRamExport : tpifRamExport;
      signal state_last   : tState := IDLE;
      signal exportCount  : integer;
   begin
   
      process
         file outfile          : text;
         variable f_status     : FILE_OPEN_STATUS;
         variable line_out     : line;
      begin
         
         for i in 0 to 63 loop
            pifRamExport(i) <= (others => '0');
         end loop;
         
         file_open(f_status, outfile, "R:\\pif_n64_sim.txt", write_mode);
         file_close(outfile);
         file_open(f_status, outfile, "R:\\pif_n64_sim.txt", append_mode);
         exportCount <= 0;
         
         while (true) loop
         
            if (reset = '1') then
               file_close(outfile);
               file_open(f_status, outfile, "R:\\pif_n64_sim.txt", write_mode);
               file_close(outfile);
               file_open(f_status, outfile, "R:\\pif_n64_sim.txt", append_mode);
               exportCount <= 0;
            end if;
            
            wait until rising_edge(clk1x);
            
            -- write from bus
            if (pifram_wren = '1') then
               pifRamExport((to_integer(bus_addr(5 downto 2)) * 4) + 0) <= bus_dataWrite( 7 downto  0);
               pifRamExport((to_integer(bus_addr(5 downto 2)) * 4) + 1) <= bus_dataWrite(15 downto  8);
               pifRamExport((to_integer(bus_addr(5 downto 2)) * 4) + 2) <= bus_dataWrite(23 downto 16);
               pifRamExport((to_integer(bus_addr(5 downto 2)) * 4) + 3) <= bus_dataWrite(31 downto 24);
            end if;
            
            -- write from pif
            if (ram_wren_b = '1') then
               pifRamExport(to_integer(unsigned(ram_address_b))) <= ram_data_b(7 downto 0);
            end if;
            
            -- start transfer
            if (state = WRITECOMMAND) then 
               wait until rising_edge(clk1x);
               if (pifreadmode = '1') then
                  write(line_out, string'("ReadIN  : "));
               else
                  write(line_out, string'("WriteIN : "));
               end if;
               for i in 0 to 63 loop
                  write(line_out, to_hstring(pifRamExport(i)));
               end loop;
               writeline(outfile, line_out);
               exportCount <= exportCount + 1;
            end if;
            
            -- end transfer
            state_last <= state;
            if (state_last = CHECKDONE) then
               if (pifreadmode = '1') then
                  write(line_out, string'("ReadOUT : "));
               else
                  write(line_out, string'("WriteOUT: "));
               end if;
               for i in 0 to 63 loop
                  write(line_out, to_hstring(pifRamExport(i)));
               end loop;
               writeline(outfile, line_out);
               exportCount <= exportCount + 1;
            end if;  
            
         end loop;
         
      end process;
   
   end generate goutput;

   -- synthesis translate_on 

end architecture;





