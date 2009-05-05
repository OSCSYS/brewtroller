#include <avr/EEPROM.h>
#include <EEPROM.h>

void saveSetup() {
  //Walk through the 6 tSensor elements and store 8-byte address of each
  //HLT (0-7), MASH (8-15), KETTLE (16-23), H2OIN (24-31), H2OOUT (32-39), BEEROUT (40-47)
  for (int i = TS_HLT; i <= TS_BEEROUT; i++) PROMwriteBytes(i * 8, tSensor[i], 8);

  //Option Array (48)
  byte options = B00000000;
  if (unit) options |= 1;
  if (PIDEnabled[TS_HLT]) options |= 2;
  if (PIDEnabled[TS_MASH]) options |= 4;
  if (PIDEnabled[TS_KETTLE]) options |= 8;
  EEPROM.write(48, options);
  
  //Output Settings for HLT (49-53), MASH (54 - 58) and KETTLE (59 - 63)
  //Volume Settings for HLT (64-71), MASH (72 - 79) and KETTLE (80 - 87)
  for (int i = TS_HLT; i <= TS_KETTLE; i++) {
    EEPROM.write(i * 5 + 49, PIDp[i]);
    EEPROM.write(i * 5 + 50, PIDi[i]);
    EEPROM.write(i * 5 + 51, PIDd[i]);
    EEPROM.write(i * 5 + 52, PIDCycle[i]);
    EEPROM.write(i * 5 + 53, hysteresis[i]);
    PROMwriteLong(i * 8 + 64, capacity[i]);
    PROMwriteLong(i * 8 + 68, volLoss[i]);
  }
  //88-91 ***OPEN***
  EEPROM.write(92, evapRate);
  EEPROM.write(93, encMode);

  //94 - 127 Reserved for Power Recovery
  //128-130 ***OPEN***
  //131 - 135 Reserved for Power Recovery
  //136-151 Reserved for Valve Profiles 
  //152-154 Power Recovery
  //155 System Type (Direct, HERMS, Steam)
  EEPROM.write(155, sysType);
  //156-1805 Saved Programs
  //1861-2040 Volume Calibrations
  //2041-2046 Zero Volumes
  //2047 EEPROM Version
}

void loadSetup() {
  //Walk through the 6 tSensor elements and load 8-byte address of each
  //HLT (0-7), MASH (8-15), KETTLE (16-23), H2OIN (24-31), H2OOUT (32-39), BEEROUT (40-47)
  for (int i = TS_HLT; i <= TS_BEEROUT; i++) PROMreadBytes(i * 8, tSensor[i], 8);
 
  //Option Array (48)
  byte options = EEPROM.read(48);
  if (options & 1) unit = 1;
  if (options & 2) PIDEnabled[TS_HLT] = 1;
  if (options & 4) PIDEnabled[TS_MASH] = 1;
  if (options & 8) PIDEnabled[TS_KETTLE] = 1;
  
  //Output Settings for HLT (49-53), MASH (54 - 58) and KETTLE (59 - 63)
  //Volume Settings for HLT (64-71), MASH (72 - 79) and KETTLE (80 - 87)
  for (int i = TS_HLT; i <= TS_KETTLE; i++) {
    PIDp[i] = EEPROM.read(i * 5 + 49);
    PIDi[i] = EEPROM.read(i * 5 + 50);
    PIDd[i] = EEPROM.read(i * 5 + 51);
    PIDCycle[i] = EEPROM.read(i * 5 + 52);
    hysteresis[i] = EEPROM.read(i * 5 + 53);
    capacity[i] = PROMreadLong(i * 8 + 64);
    volLoss[i] = PROMreadLong(i * 8 + 68);
  }
  //88-91 ***OPEN***
  evapRate = EEPROM.read(92);
  encMode = EEPROM.read(93);

  //94 - 127 Reserved for Power Recovery
  //128-130 ***OPEN***
  //131 - 135 Reserved for Power Recovery
  //136-151 Reserved for Valve Profiles 
  //152-154 Power Recovery
  //155 System Type (Direct, HERMS, Steam)
  sysType = EEPROM.read(155);
  //156-1805 Saved Programs
  //1861-2040 Volume Calibrations
  //2041-2046 Zero Volumes
  //2047 EEPROM Version
}

void PROMwriteBytes(int addr, byte bytes[], int numBytes) {
  for (int i = 0; i < numBytes; i++) {
    EEPROM.write(addr + i, bytes[i]);
  }
}

void PROMreadBytes(int addr, byte bytes[], int numBytes) {
  for (int i = 0; i < numBytes; i++) {
    bytes[i] = EEPROM.read(addr + i);
  }
}

void checkConfig() {
  byte cfgVersion = EEPROM.read(2047);
  if (cfgVersion == 255) cfgVersion = 0;
  switch(cfgVersion) {
    case 0:
      initEncoder();
      clearLCD();
      printLCD_P(0, 0, PSTR("System Configuration"));
      printLCD_P(1, 0, PSTR("Version Check Failed"));
      {
        char choices[2][19] = {"Initialize EEPROM ", "  Ignore Version  "};
        if (!getChoice(choices, 2, 3)) {
          clearLCD();
          printLCD_P(1, 0, PSTR("Initializing EEPROM "));
          printLCD_P(2, 0, PSTR("   Please Wait...   "));
          //Format EEPROM to 0's
          for (int i=0; i<2048; i++) EEPROM.write(i, 0);
          {
            //Default Output Settings: p: 3, i: 4, d: 2, cycle: 4s, Hysteresis 0.3C(0.5F)
            byte defOutputSettings[5] = {3, 4, 2, 4, 3};
            PROMwriteBytes(49, defOutputSettings, 5);
            PROMwriteBytes(54, defOutputSettings, 5);
            PROMwriteBytes(59, defOutputSettings, 5);
          }
        }
      }
      //Set cfgVersion = 1
      EEPROM.write(2047, 1);
    case 1:
      //Default Grain Temp = 60F/16C
      if(EEPROM.read(48) & 1) EEPROM.write(156, 60); else EEPROM.write(156, 16);
      EEPROM.write(2047, 2);
    case 2:
      //Default Programs
      setProgName(0, "Single Infusion");
      if (EEPROM.read(48) & 1) {
        byte temps[4] = {0, 0, 153, 0};
        byte mins[4] = {0, 0, 60, 0};
        setProgSchedule(0, temps, mins);
        setProgSparge(0, 168);
        setProgHLT(0, 180);
        setProgRatio(0, 133);
        setProgPitch(0, 70);
        setProgGrainT(0, 60);
      } else {
        byte temps[4] = {0, 0, 67, 0};
        byte mins[4] = {0, 0, 60, 0};
        setProgSchedule(0, temps, mins);
        setProgSparge(0, 76);
        setProgHLT(0, 82);
        setProgRatio(0, 277);
        setProgPitch(0, 21);
        setProgGrainT(0, 16);
      }
      setProgBoil(0, 60);
      setProgGrain(0, 0);
      setProgDelay(0, 0);
      {
        unsigned long vols[3] = {0, 0, 0};
        setProgVols(0, vols);
      }
      setProgAdds(0, 0);

            
      setProgName(1, "Multi-Rest");
      if (EEPROM.read(48) & 1) {
        byte temps[4] = {104, 122, 153, 0};
        byte mins[4] = {20, 20, 60, 0};
        setProgSchedule(1, temps, mins);
        setProgSparge(1, 168);
        setProgHLT(1, 180);
        setProgRatio(1, 133);
        setProgPitch(1, 70);
        setProgGrainT(1, 60);
      } else {
        byte temps[4] = {40, 50, 67, 0};
        byte mins[4] = {20, 20, 60, 0};
        setProgSchedule(1, temps, mins);
        setProgSparge(1, 76);
        setProgHLT(1, 82);
        setProgRatio(1, 277);
        setProgPitch(1, 21);
        setProgGrainT(1, 16);
      }
      setProgBoil(1, 60);
      setProgGrain(1, 0);
      setProgDelay(1, 0);
      {
        unsigned long vols[3] = {0, 0, 0};
        setProgVols(1, vols);
      }
      setProgAdds(1, 0);
      
      EEPROM.write(2047, 3);
    default:
      //No EEPROM Upgrade Required
      return;
  }
}

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

byte getPwrRecovery() { return EEPROM.read(94); }
void setPwrRecovery(byte funcValue) {  EEPROM.write(94, funcValue); }

byte getABRecovery() { return EEPROM.read(95); }
void setABRecovery(byte recoveryStep) { EEPROM.write(95, recoveryStep); }
byte getABSparge() { return EEPROM.read(96); }
void setABSparge(byte spargeTemp) { EEPROM.write(96, spargeTemp); }
unsigned long getABGrain() { return PROMreadLong(97); }
void setABGrain(unsigned long grainWeight) { PROMwriteLong(97, grainWeight); }
unsigned int getABDelay() { return PROMreadInt(101); }
void setABDelay(unsigned int delayMins) { PROMwriteInt(101, delayMins); }
unsigned int getABBoil() { return PROMreadInt(103); }
void setABBoil(unsigned int boilMins) { PROMwriteInt(103, boilMins); }
unsigned int getABRatio() { return PROMreadInt(105); }
void setABRatio(unsigned int mashRatio) { PROMwriteInt(105, mashRatio); }
void loadABSteps(byte stepTemp[4], byte stepMins[4]) { 
  for (int i=0; i<4; i++) {
    stepTemp[i] = EEPROM.read(107 + i);
    stepMins[i] = EEPROM.read(111 + i);
  }
}
void saveABSteps(byte stepTemp[4], byte stepMins[4]) {
  for (int i=0; i<4; i++) {
    EEPROM.write(107 + i, stepTemp[i]);
    EEPROM.write(111 + i, stepMins[i]);
  }  
}
void loadABVols(unsigned long tgtVol[3]) { for (int i=0; i<3; i++) { tgtVol[i] = PROMreadLong(115 + i * 4); } }
void saveABVols(unsigned long tgtVol[3]) { for (int i=0; i<3; i++) { PROMwriteLong(115 + i * 4, tgtVol[i]); } }

void loadSetpoints() { for (int i=TS_HLT; i<=TS_KETTLE; i++) { setpoint[i] = EEPROM.read(131 + i); } }
void saveSetpoints() { for (int i=TS_HLT; i<=TS_KETTLE; i++) { EEPROM.write(131 + i, setpoint[i]); } }

unsigned int getTimerRecovery() { return PROMreadInt(134); }
void setTimerRecovery(unsigned int newMins) { PROMwriteInt(134, newMins); }

unsigned int getValveCfg(byte profile) { return PROMreadInt(136 + (profile - 1) * 2); }
void setValveCfg(byte profile, unsigned int value) { PROMwriteInt(136 + (profile - 1) * 2, value); }

byte getABPitch() { return EEPROM.read(152); }
void setABPitch(byte pitchTemp) { EEPROM.write(152, pitchTemp); }

unsigned int getABAdds() { return PROMreadInt(153); }
void setABAdds(unsigned int adds) { PROMwriteInt(153, adds); }

byte getABGrainTemp() { return EEPROM.read(127); }
void setABGrainTemp(byte grainTemp) { EEPROM.write(127, grainTemp); }

void setProgName(byte preset, char name[20]) {
  for (int i = 0; i < 19; i++) EEPROM.write(preset * 55 + 156 + i, name[i]);
}

void getProgName(byte preset, char name[20]) {
  for (int i = 0; i < 19; i++) name[i] = EEPROM.read(preset * 55 + 156 + i);
  name[19] = '\0';
}

void setProgSparge(byte preset, byte sparge) { EEPROM.write(preset * 55 + 175, sparge); }
byte getProgSparge(byte preset) { return EEPROM.read(preset * 55 + 175); }

void setProgGrain(byte preset, unsigned long grain) { PROMwriteLong(preset * 55 + 176, grain); }
unsigned long getProgGrain(byte preset) { return PROMreadLong(preset * 55 + 176); }

void setProgDelay(byte preset, unsigned int delayMins) { PROMwriteInt(preset * 55 + 180, delayMins); }
unsigned int getProgDelay(byte preset) { return PROMreadInt(preset * 55 + 180); }

void setProgBoil(byte preset, unsigned int boilMins) { PROMwriteInt(preset * 55 + 182, boilMins); }
unsigned int getProgBoil(byte preset) { return PROMreadInt(preset * 55 + 182); }

void setProgRatio(byte preset, unsigned int ratio) { PROMwriteInt(preset * 55 + 184, ratio); }
unsigned int getProgRatio(byte preset) { return PROMreadInt(preset * 55 + 184); }

void setProgSchedule(byte preset, byte stepTemp[4], byte stepMins[4]) {
  for (int i=0; i<4; i++) {
     EEPROM.write(preset * 55 + 186 + i, stepTemp[i]);
     EEPROM.write(preset * 55 + 190 + i, stepMins[i]);
  }
}

void getProgSchedule(byte preset, byte stepTemp[4], byte stepMins[4]) {
  for (int i=0; i<4; i++) {
    stepTemp[i] = EEPROM.read(preset * 55 + 186 + i);
    stepMins[i] = EEPROM.read(preset * 55 + 190 + i);
  }
}

void getProgVols(byte preset, unsigned long vols[3]) { for (int i=0; i<3; i++) vols[i] = PROMreadLong(preset * 55 + 194 + i * 4); }
void setProgVols(byte preset, unsigned long vols[3]) { for (int i=0; i<3; i++) PROMwriteLong(preset * 55 + 194 + i * 4, vols[i]); }

void setProgHLT(byte preset, byte HLT) { EEPROM.write(preset * 55 + 206, HLT); }
byte getProgHLT(byte preset) { return EEPROM.read(preset * 55 + 206); }

void setProgPitch(byte preset, byte pitch) { EEPROM.write(preset * 55 + 207, pitch); }
byte getProgPitch(byte preset) { return EEPROM.read(preset * 55 + 207); }

void setProgAdds(byte preset, unsigned int adds) { PROMwriteInt(preset * 55 + 208, adds); }
unsigned int getProgAdds(byte preset) { return PROMreadInt(preset * 55 + 208); }

void setProgGrainT(byte preset, byte grain) { EEPROM.write(preset * 55 + 210, grain); }
byte getProgGrainT(byte preset) { return EEPROM.read(preset * 55 + 210); }

//Set a single Volume Calibration (EEPROM Bytes 1861 - 2040)
// vessel: 0-2 Corresponding to TS_HLT, TS_MASH, TS_KETTLE
// slot: 0-9 Individual slots representing a single volume/value pairing
// vol: The volume for this calibration as a long in thousandths (1000 = 1)
// val: An int representing the analogReadValue() to pair to the given volume
void setVolCalib(byte vessel, byte slot, unsigned long vol, unsigned int val) {
  PROMwriteLong(1861 + slot * 4 + vessel * 60, vol);
  PROMwriteInt(1901 + slot * 2 + vessel * 60, val);
}

//Get all Volume Calibrations for a given vessel (EEPROM Bytes 1861 - 2040)
// vessel: 0-2 Corresponding to TS_HLT, TS_MASH, TS_KETTLE
// vol: The volume for this calibration as a long in thousandths (1000 = 1)
// val: An int representing the analogReadValue() to pair to the given volume
void getVolCalibs(byte vessel, unsigned long vols[10], unsigned int vals[10]) {
  for (int i = 0; i < 10; i++) {
    vols[i] = PROMreadLong(1861 + i * 4 + vessel * 60);
    vals[i] = PROMreadInt(1901 + i * 2 + vessel * 60);
    #ifdef DEBUG
      Serial.print("Vessel: ");
      Serial.print(vessel, DEC);
      Serial.print(" Slot: ");
      Serial.print(i, DEC);
      Serial.print(" Vol: ");
      Serial.print(vols[i], DEC);
      Serial.print(" Val: ");
      Serial.println(vals[i], DEC);
    #endif
  }
}

//Zero Volumes 2041-2046 (analogRead of Empty Vessels)
unsigned int getZeroVol(byte vessel) { return PROMreadInt(2041 + vessel * 2); }
void setZeroVol(byte vessel, unsigned int zeroVal) { PROMwriteInt(2041 + vessel * 2, zeroVal); }
