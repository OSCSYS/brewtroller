#ifdef BTPD_SUPPORT
#include <Wire.h>

unsigned long lastBTPD;

void btpdInit() {
  Wire.begin();
}

void updateBTPD() {
  if (millis() - lastBTPD > BTPD_INTERVAL) {
    #ifdef BTPD_HLT_TEMP
      sendVsTemp(BTPD_HLT_TEMP, VS_HLT);
    #endif
    #ifdef BTPD_MASH_TEMP
      sendVsTemp(BTPD_MASH_TEMP, VS_MASH);
    #endif
    #ifdef BTPD_KETTLE_TEMP
      sendVsTemp(BTPD_KETTLE_TEMP, VS_KETTLE);
    #endif
    #ifdef BTPD_H2O_TEMPS
      sendFloatsBTPD(BTPD_H2O_TEMPS, temp[TS_H2OIN], temp[TS_H2OOUT]);
    #endif
    #ifdef BTPD_FERM_TEMP
      sendFloatsBTPD(BTPD_FERM_TEMP, pitchTemp, temp[TS_BEEROUT]);
    #endif
    #ifdef BTPD_HLT_VOL
      sendVsVol(BTPD_HLT_VOL, VS_HLT);
    #endif
    #ifdef BTPD_MASH_VOL
      sendVsVol(BTPD_MASH_VOL, VS_MASH);
    #endif
    #ifdef BTPD_KETTLE_VOL
      sendVsVol(BTPD_KETTLE_VOL, VS_KETTLE);
    #endif
    #ifdef BTPD_STEAM_PRESS
      sendFloatsBTPD(BTPD_STEAM_PRESS, steamTgt, steamPressure);
    #endif
  }
}

void sendVsTemp(byte chan, byte vessel) {
  sendFloatsBTPD(chan, setpoint[vessel], temp[vessel]);  
}

void sendVsVol(byte chan, byte vessel) {
  sendFloatsBTPD(chan, tgtVol[vessel] / 1000.0, volAvg[vessel] / 1000.0);
}

void sendFloatsBTPD(byte chan, float line1, float line2) {
  char sData[9];
  ftoa(line1, sData, 1);
  ftoa(line2, buf, 1);
  strcat(sData, buf);
  Wire.beginTransmission(chan);
  Wire.send(sData);
  Wire.endTransmission();
}

#endif

