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
      sendFloatsBTPD(BTPD_H2O_TEMPS, temp[TS_H2OIN] / 100.0, temp[TS_H2OOUT] / 100.0);
    #endif
    #ifdef BTPD_FERM_TEMP
      sendFloatsBTPD(BTPD_FERM_TEMP, pitchTemp, temp[TS_BEEROUT] / 100.0);
    #endif
    #ifdef BTPD_TIMERS
      sendFloatsBTPD(BTPD_TIMERS, timer2Float(timerValue[TIMER_MASH]), timer2Float(timerValue[TIMER_BOIL]));
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
      sendFloatsBTPD(BTPD_STEAM_PRESS, steamTgt, steamPressure / 1000.0 );
    #endif
    lastBTPD = millis();
  }
}

void sendVsTemp(byte chan, byte vessel) {
  sendFloatsBTPD(chan, setpoint[vessel] / 100.0, temp[vessel] / 100.0);  
}

void sendVsVol(byte chan, byte vessel) {
  sendFloatsBTPD(chan, tgtVol[vessel] / 1000.0, volAvg[vessel] / 1000.0);
}

void sendFloatsBTPD(byte chan, float line1, float line2) {
  Wire.beginTransmission(chan);
  Wire.send(0xff);
  Wire.send(0x00);
  Wire.send((uint8_t *) &line1, 4);
  Wire.send((uint8_t *) &line2, 4);
  Wire.endTransmission();
}

#ifdef BTPD_TIMERS
float timer2Float(unsigned long value) {
  value /= 1000;
  if (value > 3600) {
    byte hours = value / 3600;
    return hours + (value - hours * 3600) / 100;
  } else {
    byte mins = value / 60;
    return mins + (value - mins * 60) / 100;
  }
}
#endif
#endif
