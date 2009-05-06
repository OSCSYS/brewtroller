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
  //Default Batch size (88-91)
  EEPROM.write(92, evapRate);
  EEPROM.write(93, encMode);

  //94 - 135 Reserved for Power Loss Recovery
  //136-151 Reserved for Valve Profiles 
  //152-154 Power Recovery
  //155 System Type (Direct, HERMS, Steam)
  EEPROM.write(155, sysType);
  //156 DefGrainTemp
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
  //Default Batch size (88-91)
  evapRate = EEPROM.read(92);
  encMode = EEPROM.read(93);

  //94 - 135 Reserved for Power Recovery
  //136-151 Reserved for Valve Profiles 
  //152-154 Power Recovery
  //155 System Type (Direct, HERMS, Steam)
  sysType = EEPROM.read(155);
  //156 DefGrainTemp
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

unsigned long getDefBatch() { return PROMreadLong(88); }
void setDefBatch(unsigned long batchSize) { PROMwriteLong(88, batchSize); }

byte getDefGrainTemp() { return EEPROM.read(156); }
void setDefGrainTemp(byte grainTemp) { EEPROM.write(156, grainTemp); }
