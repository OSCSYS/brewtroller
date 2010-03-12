












//*****************************************************************************************************************************
//1.3 To Do:
//Add NOUI support for checkconfig
//*****************************************************************************************************************************













/*  
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

    This file is part of BrewTroller.

    BrewTroller is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    BrewTroller is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with BrewTroller.  If not, see <http://www.gnu.org/licenses/>.


BrewTroller - Open Source Brewing Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/


#include <avr/eeprom.h>
#include <EEPROM.h>

void loadSetup() {
  //**********************************************************************************
  //TSensors: HLT (0-7), MASH (8-15), KETTLE (16-23), H2OIN (24-31), H2OOUT (32-39),
  //          BEEROUT (40-47), AUX1 (48-55), AUX2 (56-63)
  //**********************************************************************************
  for (byte i = TS_HLT; i <= TS_AUX2; i++) PROMreadBytes(i * 8, tSensor[i], 8);
 
  ///64-71 ***OPEN***

  //**********************************************************************************
  //PID Enabled (72); Bit 1 = HLT, Bit 2 = Mash, Bit 3 = Kettle, Bit 4 = Steam
  //PIDp HLT (73), Mash (78), Kettle (83), Steam (88)
  //PIDi HLT (74), Mash (79), Kettle (84), Steam (89)
  //PIDd HLT (75), Mash (80), Kettle (85), Steam (90)
  //PIDCycle HLT (76), Mash (81), Kettle (86), Steam (91)
  //Hysteresis HLT (77), Mash (82), Kettle (87), Steam (92)
  //**********************************************************************************
  {
    byte options = EEPROM.read(72);
    for (byte i = VS_HLT; i <= VS_STEAM; i++) {
      PIDEnabled[i] = bitRead(options, i);
      PIDCycle[i] = EEPROM.read(76 + i * 5);
      hysteresis[i] = EEPROM.read(77 + i * 5);
    }
  }
  
  //**********************************************************************************
  //boilPwr (112)
  //**********************************************************************************
  boilPwr = EEPROM.read(112);
  //**********************************************************************************
  //steamZero (114)
  //**********************************************************************************
  steamZero = PROMreadInt(114);
  //**********************************************************************************
  //steamPSens (117-118)
  //**********************************************************************************
  steamPSens = PROMreadInt(117);

  //**********************************************************************************
  //calibVols HLT (119-158), Mash (159-198), Kettle (199-238)
  //calibVals HLT (239-258), Mash (259-278), Kettle (279-298)
  //**********************************************************************************
  for (byte vessel = VS_HLT; vessel <= VS_KETTLE; vessel++) {
    for (byte slot = 0; slot < 10; slot++) {
      calibVols[vessel][slot] = PROMreadLong(119 + vessel * 40 + slot * 4);
      calibVals[vessel][slot] = PROMreadInt(239 + vessel * 20 + slot * 2);
    }
  }

  //**********************************************************************************
  //setpoints (299-301)
  //**********************************************************************************
  for (byte i=TS_HLT; i<=TS_KETTLE; i++) { setpoint[i] = EEPROM.read(299 + i); }
  
  //**********************************************************************************
  //timers (302-305)
  //**********************************************************************************
  for (byte i=TIMER_MASH; i<=TIMER_BOIL; i++) { timerValue[i] = PROMreadInt(302 + i * 2) * 60000; }

  //**********************************************************************************
  //Timer/Alarm Status (306)
  //**********************************************************************************
  {
    byte options = EEPROM.read(306);
    for (byte i = TIMER_MASH; i <= TIMER_BOIL; i++) {
      timerStatus[i] = bitRead(options, i);
      lastTime[i] = millis();
    }
    alarmStatus = bitRead(options, 2);
  }

  //**********************************************************************************
  //Step (313-327) NUM_BREW_STEPS (15)
  //**********************************************************************************
  for(byte brewStep = 0; brewStep < NUM_BREW_STEPS; brewStep++) { stepProgram[brewStep] = EEPROM.read(313 + brewStep); }

  //**********************************************************************************
  //401-452 Valve Profiles
  //**********************************************************************************
  for (byte profile = VLV_FILLHLT; profile <= VLV_DRAIN; profile++) vlvConfig[profile] = PROMreadLong(401 + profile * 4);

}


//*****************************************************************************************************************************
// Individual EEPROM Get/Set Variable Functions
//*****************************************************************************************************************************

//**********************************************************************************
//TSensors: HLT (0-7), MASH (8-15), KETTLE (16-23), H2OIN (24-31), H2OOUT (32-39), 
//          BEEROUT (40-47), AUX1 (48-55), AUX2 (56-63)
//**********************************************************************************
void setTSAddr(byte sensor, byte addr[8]) {
  for (byte i = 0; i<8; i++) tSensor[sensor][i] = addr[i];
  PROMwriteBytes(sensor * 8, addr, 8);
}

//**********************************************************************************
//64-71 ***OPEN*** (Reserved for Additional Temp Sensor Address)
//**********************************************************************************

//**********************************************************************************
//PID Enabled (72); Bit 1 = HLT, Bit 2 = Mash, Bit 3 = Kettle, Bit 4 = Steam
//**********************************************************************************
void setPIDEnabled(byte vessel, boolean setting) {
  PIDEnabled[vessel] = setting;
  byte options = EEPROM.read(72);
  bitWrite(options, vessel, setting);
  EEPROM.write(72, options);
}


//**********************************************************************************
//PIDp HLT (73), Mash (78), Kettle (83), Steam (88)
//**********************************************************************************
void setPIDp(byte vessel, byte value) {
  pid[vessel].SetTunings(value, pid[vessel].GetI_Param(), pid[vessel].GetD_Param());
  EEPROM.write(73 + vessel * 5, value);
}
byte getPIDp(byte vessel) { return EEPROM.read(73 + vessel * 5); }

//**********************************************************************************
//PIDi HLT (74), Mash (79), Kettle (84), Steam (89)
//**********************************************************************************
void setPIDi(byte vessel, byte value) {
  pid[vessel].SetTunings(pid[vessel].GetP_Param(), value, pid[vessel].GetD_Param());
  EEPROM.write(74 + vessel * 5, value);
}
byte getPIDi(byte vessel) { return EEPROM.read(74 + vessel * 5); }

//**********************************************************************************
//PIDd HLT (75), Mash (80), Kettle (85), Steam (90)
//**********************************************************************************
void setPIDd(byte vessel, byte value) {
  pid[vessel].SetTunings(pid[vessel].GetP_Param(), pid[vessel].GetI_Param(), value);
  EEPROM.write(75 + vessel * 5, value);
}
byte getPIDd(byte vessel) { return EEPROM.read(75 + vessel * 5); }

//**********************************************************************************
//PIDCycle HLT (76), Mash (81), Kettle (86), Steam (91)
//**********************************************************************************
void setPIDCycle(byte vessel, byte value) {
  PIDCycle[vessel] = value;
  EEPROM.write(76 + vessel * 5, value);
}

//**********************************************************************************
//Hysteresis HLT (77), Mash (82), Kettle (87), Steam (92)
//**********************************************************************************
void setHysteresis(byte vessel, byte value) {
  hysteresis[vessel] = value;
  EEPROM.write(77 + vessel * 5, value);
}

//**********************************************************************************
//Capacity HLT (93-96), Mash (97-100), Kettle (101-104)
//**********************************************************************************
void setCapacity(byte vessel, unsigned long value) {
  PROMwriteLong(93 + vessel * 4, value);
}
unsigned long getCapacity(byte vessel) { return PROMreadLong(93 + vessel * 4); }

//**********************************************************************************
//volLoss HLT (105-106), Mash (107-108), Kettle (109-110)
//**********************************************************************************
void setVolLoss(byte vessel, unsigned int value) {
  PROMwriteInt(105 + vessel * 2, value);
}
unsigned int getVolLoss(byte vessel) { return PROMreadInt(105 + vessel * 2); }

//**********************************************************************************
//Boil Temp (111)
//**********************************************************************************
byte getBoilTemp() { return EEPROM.read(111); }
void setBoilTemp(byte boilTemp) { EEPROM.write(111, boilTemp); }

//**********************************************************************************
//Boil Power (112)
//**********************************************************************************
void setBoilPwr(byte value) { 
  boilPwr = value;
  EEPROM.write(112, value); 
}

//**********************************************************************************
//evapRate (113)
//**********************************************************************************
void setEvapRate(byte value) {
  EEPROM.write(113, value);
}
byte getEvapRate() { return EEPROM.read(113); }

//**********************************************************************************
//steamZero (114-115)
//**********************************************************************************
void setSteamZero(unsigned int value) {
  steamZero = value;
  PROMwriteInt(114, value);
}

//**********************************************************************************
//steamTgt (116)
//**********************************************************************************
byte getSteamTgt() { return EEPROM.read(116); }
void setSteamTgt(byte value) {
  EEPROM.write(116, value);
}

//**********************************************************************************
//steamPSens (117-118)
//**********************************************************************************
void setSteamPSens(unsigned int value) {
  steamPSens = value;
  PROMwriteInt(117, value);
}

//**********************************************************************************
//calibVols HLT (119-158), Mash (159-198), Kettle (199-238)
//calibVals HLT (239-258), Mash (259-278), Kettle (279-298)
//**********************************************************************************
void setVolCalib(byte vessel, byte slot, unsigned int value, unsigned long vol) {
  calibVols[vessel][slot] = vol;
  calibVals[vessel][slot] = value;
  PROMwriteLong(119 + vessel * 40 + slot * 4, vol);
  PROMwriteInt(239 + vessel * 20 + slot * 2, value);
}

//*****************************************************************************************************************************
// Power Loss Recovery Functions
//*****************************************************************************************************************************

//**********************************************************************************
//setpoints (299-301)
//**********************************************************************************
void setSetpoint(byte vessel, byte value) { 
  setpoint[vessel] = value;
  EEPROM.write(299 + vessel, value);
}

//**********************************************************************************
//timers (302-305)
//**********************************************************************************
void setTimerRecovery(byte timer, unsigned int newMins) { PROMwriteInt(302 + timer * 2, newMins); }

//**********************************************************************************
//Timer/Alarm Status (306)
//**********************************************************************************
void setTimerStatus(byte timer, boolean value) {
  timerStatus[timer] = value;
  byte options = EEPROM.read(306);
  bitWrite(options, timer, value);
  EEPROM.write(306, options);
}
void setAlarmStatus(boolean value) {
  alarmStatus = value;
  byte options = EEPROM.read(306);
  bitWrite(options, 2, value);
  EEPROM.write(306, options);
}



//**********************************************************************************
//Triggered Boil Addition Alarms (307-308)
//**********************************************************************************
unsigned int getBoilAddsTrig() { return PROMreadInt(307); }
void setBoilAddsTrig(unsigned int adds) { PROMwriteInt(307, adds); }

//**********************************************************************************
//Valves (309-312)
//**********************************************************************************
unsigned long getValveRecovery() { return PROMreadLong(309); }
void setValveRecovery(unsigned long value) { PROMwriteLong(309, value); }

//**********************************************************************************
//Step (313-327) NUM_BREW_STEPS (15)
//**********************************************************************************
void setProgramStep(byte brewStep, byte actPgm) {
  stepProgram[brewStep] = actPgm;
  EEPROM.write(313 + brewStep, actPgm); 
}

//**********************************************************************************
//Reserved (328-399)
//**********************************************************************************

//**********************************************************************************
//Delay Start (Mins) (398-399)
//**********************************************************************************
unsigned int getDelayMins() { return PROMreadInt(398); }
void setDelayMins(unsigned int mins) { PROMwriteInt(398, mins); }

//**********************************************************************************
//Grain Temp (400)
//**********************************************************************************
void setGrainTemp(byte grainTemp) { EEPROM.write(400, grainTemp); }
byte getGrainTemp() { return EEPROM.read(400); }

//*****************************************************************************************************************************
// Valve Profile Configuration (401-452; 453-500 Reserved)
//*****************************************************************************************************************************
void setValveCfg(byte profile, unsigned long value) {
  vlvConfig[profile] = value;
  PROMwriteLong(401 + profile * 4, value);
}

//*****************************************************************************************************************************
// Program Load/Save Functions (501- 1760)
//*****************************************************************************************************************************
#define PROGRAM_SIZE 60
#define PROGRAM_START_ADDR 501

//**********************************************************************************
//Program Name (P:0-20)
//**********************************************************************************
void setProgName(byte preset, char name[20]) {
  for (byte i = 0; i < 19; i++) EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + i, name[i]);
}

void getProgName(byte preset, char name[20]) {
  for (byte i = 0; i < 19; i++) name[i] = EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + i);
  name[19] = '\0';
}

//**********************************************************************************
//Sparge Temp (P:21)
//**********************************************************************************
void setProgSparge(byte preset, byte sparge) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 21, sparge); }
byte getProgSparge(byte preset) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 21); }

//**********************************************************************************
//Boil Mins (P:22-23)
//**********************************************************************************
void setProgBoil(byte preset, unsigned int boilMins) { PROMwriteInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 22, boilMins); }
unsigned int getProgBoil(byte preset) { return PROMreadInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 22); }

//**********************************************************************************
//Mash Ratio (P:24-25)
//**********************************************************************************
void setProgRatio(byte preset, unsigned int ratio) { PROMwriteInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 24, ratio); }
unsigned int getProgRatio(byte preset) { return PROMreadInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 24); }

//**********************************************************************************
//Mash Temps (P:26-31)
//**********************************************************************************
void setProgMashTemp(byte preset, byte mashStep, byte mashTemp) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 26 + mashStep, mashTemp); }
byte getProgMashTemp(byte preset, byte mashStep) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 26 + mashStep); }

//**********************************************************************************
//Mash Times (P:32-37)
//**********************************************************************************
void setProgMashMins(byte preset, byte mashStep, byte mashMins) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 32 + mashStep, mashMins); }
byte getProgMashMins(byte preset, byte mashStep) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 32 + mashStep); }

//**********************************************************************************
//Batch Vol (P:38-41)
//**********************************************************************************
unsigned long getProgBatchVol(byte preset) { return PROMreadLong(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 38); }
void setProgBatchVol (byte preset, unsigned long vol) { PROMwriteLong(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 38, vol); }

//**********************************************************************************
//Mash Liquor Heat Source (P:42)
//**********************************************************************************
void setProgMLHeatSrc(byte preset, byte vessel) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 42, vessel); }
byte getProgMLHeatSrc(byte preset) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 42); }

//**********************************************************************************
//HLT Temp (P:43)
//**********************************************************************************
void setProgHLT(byte preset, byte HLT) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 43, HLT); }
byte getProgHLT(byte preset) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 43); }

//**********************************************************************************
//Pitch Temp (P:44)
//**********************************************************************************
void setProgPitch(byte preset, byte pitch) { EEPROM.write(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 44, pitch); }
byte getProgPitch(byte preset) { return EEPROM.read(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 44); }

//**********************************************************************************
//Boil Addition Alarms (P:45-46)
//**********************************************************************************
void setProgAdds(byte preset, unsigned int adds) { PROMwriteInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 45, adds); }
unsigned int getProgAdds(byte preset) { return PROMreadInt(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 45); }

//**********************************************************************************
//Grain Weight (P:47-50)
//**********************************************************************************
void setProgGrain(byte preset, unsigned long grain) { PROMwriteLong(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 47, grain); }
unsigned long getProgGrain(byte preset) { return PROMreadLong(PROGRAM_START_ADDR + preset * PROGRAM_SIZE + 47); }

//**********************************************************************************
//OPEN (P:51-59)
//**********************************************************************************


//**********************************************************************************
//***OPEN*** (1761-2045)
//**********************************************************************************

//**********************************************************************************
//BrewTroller Fingerprint (2046)
//**********************************************************************************

//**********************************************************************************
//EEPROM Version (2047)
//**********************************************************************************


//*****************************************************************************************************************************
// Check/Update/Format EEPROM
//*****************************************************************************************************************************
void checkConfig() {
/*  byte cfgVersion = EEPROM.read(2047);
  byte BTFinger = EEPROM.read(2046);
  
#ifdef DEBUG
  logStart_P(LOGDEBUG);
  logField_P(PSTR("CFGVER"));
  logFieldI(cfgVersion);
  logEnd();
#endif

  //If the cfgVersion is newer than 6 and the BT fingerprint is missing force a init of EEPROM
  //FermTroller will bump to a cfgVersion starting at 7
  if (BTFinger != 254 && cfgVersion > 6) cfgVersion = 0;
  if (cfgVersion == 255) cfgVersion = 0;
  switch(cfgVersion) {
    case 0:
      {
        logString_P(LOGSYS, PSTR("INIT_EEPROM"));
        //Format EEPROM to 0's
        for (int i=0; i<2048; i++) EEPROM.write(i, 0);
        {
          //Default Output Settings: p: 3, i: 4, d: 2, cycle: 4s, Hysteresis 0.3C(0.5F)
          #ifdef USEMETRIC
            byte defOutputSettings[5] = {3, 4, 2, 4, 3};
          #else
            byte defOutputSettings[5] = {3, 4, 2, 4, 5};
          #endif
          PROMwriteBytes(49, defOutputSettings, 5);
          PROMwriteBytes(54, defOutputSettings, 5);
          PROMwriteBytes(59, defOutputSettings, 5);
        }
      }
      //Set cfgVersion = 1
      EEPROM.write(2047, 1);
    case 1:
      //Default Grain Temp = 60F/16C
      //If F else C
      #ifdef USEMETRIC
        EEPROM.write(156, 16);
      #else
        EEPROM.write(156, 60);
      #endif
      EEPROM.write(2047, 2);
    case 2:
      //Default Programs
#ifdef MODULE_DEFAULTABPROGS
      {
        setProgName(0, "Single Infusion");
        #ifdef USEMETRIC
          byte temps[4] = {0, 0, 67, 0};
          byte mins[4] = {0, 0, 60, 0};
          setProgSchedule(0, temps, mins);
          setProgSparge(0, 76);
          setProgHLT(0, 82);
          setProgRatio(0, 277);
          setProgPitch(0, 21);
        #else
          byte temps[4] = {0, 0, 153, 0};
          byte mins[4] = {0, 0, 60, 0};
          setProgSchedule(0, temps, mins);
          setProgSparge(0, 168);
          setProgHLT(0, 180);
          setProgRatio(0, 133);
          setProgPitch(0, 70);
        #endif
        setProgBoil(0, 60);
        setProgGrain(0, 0);
        setProgDelay(0, 0);
        setProgMLHeatSrc(0, 0);
        setProgAdds(0, 0);
      }
      {
        setProgName(1, "Multi-Rest");
        #ifdef USEMETRIC
          byte temps[4] = {40, 50, 67, 0};
          byte mins[4] = {20, 20, 60, 0};
          setProgSchedule(1, temps, mins);
          setProgSparge(1, 76);
          setProgHLT(1, 82);
          setProgRatio(1, 277);
          setProgPitch(1, 21);
        #else
          byte temps[4] = {104, 122, 153, 0};
          byte mins[4] = {20, 20, 60, 0};
          setProgSchedule(1, temps, mins);
          setProgSparge(1, 168);
          setProgHLT(1, 180);
          setProgRatio(1, 133);
          setProgPitch(1, 70);
        #endif

        setProgBoil(1, 60);
        setProgGrain(1, 0);
        setProgDelay(1, 0);
        setProgMLHeatSrc(1, 0);
        setProgAdds(1, 0);
      }
#endif
      EEPROM.write(2047, 3);
    case 3:
      //Move Valve Configs from old 2-Byte EEPROM (136-151) to new 4-Byte Locations
      for (byte profile = VLV_FILLHLT; profile <= VLV_CHILLBEER; profile ++) PROMwriteLong(1806 + (profile) * 4, PROMreadInt(136 + profile * 2));
      EEPROM.write(2047, 4);
    case 4:
      //Default Steam Output Settings
      EEPROM.write(88, 3);
      EEPROM.write(89, 4);
      EEPROM.write(90, 2);
      EEPROM.write(91, 4);
      #ifdef USEMETRIC
        EEPROM.write(93, 3);
      #else
        EEPROM.write(93, 5);
      #endif
      EEPROM.write(2047, 5);
    case 5:
      //Set Default Boil temp 212F/100C
      #ifdef USEMETRIC
        setBoilTemp(100);
      #else
        setBoilTemp(212);
      #endif
      EEPROM.write(2047, 6);
    case 6:
      //Add BT Fingerprint (254)
      EEPROM.write(2046, 254);
      EEPROM.write(2047, 7);
    case 7:
      //Move Profiles 6 & 7 +12 
      PROMwriteLong(1846, PROMreadLong(1834));
      PROMwriteLong(1842, PROMreadLong(1830));
      //Move Profiles 2 - 5 +4
      PROMwriteLong(1830, PROMreadLong(1826));
      PROMwriteLong(1826, PROMreadLong(1822));
      PROMwriteLong(1822, PROMreadLong(1818));
      PROMwriteLong(1818, PROMreadLong(1814));
      //Zero out new profiles
      PROMwriteLong(1814, 0);
      PROMwriteLong(1834, 0);
      PROMwriteLong(1838, 0);
      EEPROM.write(2047, 8);
    case 8:
      setBoilPwr(100);
      EEPROM.write(2047, 9);
    case 9:
      setMLHeatSrc(VS_MASH);
      //Zero out unused program tgtvol bytes and set MLHeatSrc for each program to Mash Tun
      for (byte preset = 0; preset < 20; preset++) {
        EEPROM.write(preset * 55 + 198, 1);
        for (byte i = 199; i <= 205; i++) EEPROM.write(preset * 55 + i, 0);
      }
      EEPROM.write(2047, 10);
    case 10:
      //Zero Out Aux1/AUX2 TSensor Addresses
      for (byte i = 118; i <= 125; i++) EEPROM.write(i, 0);
      for (unsigned int i = 1850; i <= 1857; i++) EEPROM.write(i, 0);
      EEPROM.write(2047, 11);
    case 11: 
      //Swap P/V 3&4 in existing Valve Profiles
      for (byte i = VLV_FILLHLT; i <= VLV_CHILLBEER; i++) {
        unsigned long vlvs = PROMreadLong(1806 + i * 4);
        vlvs = (vlvs & 0xFFFFFFF3) | ((vlvs>>1) & B100) | ((vlvs<<1) & B1000);
        PROMwriteLong(1806 + i * 4, vlvs);
      }
      EEPROM.write(2047, 12);
      
    case 12: 
      //Zero Out Boil Recirc Profile
      PROMwriteLong(1802, 0);
      EEPROM.write(2047, 13);
      
    case 13:
      //Add Clean Program
      {
        setProgName(20, "Clean");
        #ifdef USEMETRIC
          byte temps[4] = {0, 0, 60, 0};
          byte mins[4] = {0, 0, 5, 0};
          setProgSchedule(20, temps, mins);
          setProgSparge(20, 76);
          setProgHLT(20, 82);
          setProgRatio(20, 277);
          setProgPitch(20, 21);
          setProgGrainT(20, 16);
        #else
          byte temps[4] = {0, 0, 140, 0};
          byte mins[4] = {0, 0, 5, 0};
          setProgSchedule(20, temps, mins);
          setProgSparge(20, 168);
          setProgHLT(20, 180);
          setProgRatio(20, 133);
          setProgPitch(20, 70);
          setProgGrainT(20, 60);
        #endif

        setProgBoil(20, 0);
        setProgGrain(20, 0);
        setProgDelay(20, 0);
        setProgMLHeatSrc(20, 0);
        setProgAdds(20, 0);
      }
      EEPROM.write(2047, 14);
    default:
      //No EEPROM Upgrade Required
      return;
  }
*/
}

//*****************************************************************************************************************************
// EEPROM Type Read/Write Functions
//*****************************************************************************************************************************
long PROMreadLong(int address) {
  long out;
  eeprom_read_block((void *) &out, (unsigned char *) address, 4);
  return out;
}

void PROMwriteLong(int address, long value) {
  eeprom_write_block((void *) &value, (unsigned char *) address, 4);
}

int PROMreadInt(int address) {
  int out;
  eeprom_read_block((void *) &out, (unsigned char *) address, 2);
  return out;
}

void PROMwriteInt(int address, int value) {
  eeprom_write_block((void *) &value, (unsigned char *) address, 2);
}

void PROMwriteBytes(int addr, byte bytes[], byte numBytes) {
  for (byte i = 0; i < numBytes; i++) {
    EEPROM.write(addr + i, bytes[i]);
  }
}

void PROMreadBytes(int addr, byte bytes[], byte numBytes) {
  for (byte i = 0; i < numBytes; i++) {
    bytes[i] = EEPROM.read(addr + i);
  }
}

