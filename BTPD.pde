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
*/


//*****************************************************************************************************************************
// Special thanks to Jason von Nieda (vonnieda) for the design and code for this cool add-on to BrewTroller.
//*****************************************************************************************************************************


#ifdef BTPD_SUPPORT
#include "Config.h"
#include "Enum.h"

unsigned long lastBTPD;

void btpdInit() {
  //Wire.begin() moved to setup() to support multiple I2C plug-ins
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
