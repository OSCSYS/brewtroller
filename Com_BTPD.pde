/*  
   Copyright (C) 2009, 2010 Matt Reba, Jeremiah Dillingham

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

#define BTPD_HLT_TEMP 0x20 // BTPD_HLT_TEMP: Displays HLT temp and setpoint on specified channel
#define BTPD_MASH_TEMP 0x22 // BTPD_MASH_TEMP: Displays Mash temp and setpoint on specified channel
#define BTPD_KETTLE_TEMP 0x23    // BTPD_KETTLE_TEMP: Displays Kettle temp and setpoint on specified channel
//#define BTPD_H2O_TEMPS 0x24 // BTPD_H2O_TEMPS: Displays H2O In and H2O Out temps on specified channels
#define BTPD_FERM_TEMP 0x24 // BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
#define BTPD_TIMERS 0x25 // BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
//#define BTPD_HLT_VOL 0x26 // BTPD_HLT_VOL: Displays current and target HLT volume
//#define BTPD_MASH_VOL 0x27 // BTPD_MASH_VOL: Displays current and target Mash volume
//#define BTPD_KETTLE_VOL 0x28 // BTPD_KETTLE_VOL: Displays current and target Kettle volume
//#define BTPD_STEAM_PRESS 0x29 // BTPD_STEAM_PRESS: Displays current and target Steam pressure
#ifdef RIMS_TEMP_SENSOR
  #define BTPD_RIMS_TEMP 0x21 // THe RIMS tube temp probe temperature
#endif
unsigned long lastBTPD;

#ifndef BTPD_ALTERNATE_TEMP_VOLUME

void updateBTPD() {
	if (millis() - lastBTPD > BTPD_INTERVAL) {
		#ifdef BTPD_HLT_TEMP
			sendVsTemp(BTPD_HLT_TEMP, TS_HLT, VS_HLT);
		#endif
		#ifdef BTPD_MASH_TEMP
			sendVsTemp(BTPD_MASH_TEMP, TS_MASH, VS_MASH);
		#endif
		#ifdef BTPD_KETTLE_TEMP
			sendVsTemp(BTPD_KETTLE_TEMP, TS_KETTLE, VS_KETTLE);
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
		#ifdef BTPD_RIMS_TEMP
			sendVsTemp(BTPD_RIMS_TEMP, RIMS_TEMP_SENSOR, VS_MASH);
		#endif
		lastBTPD = millis();
	}
}

#else
boolean odd = 1;
void updateBTPD() {
	if (millis() - lastBTPD > BTPD_INTERVAL) {
		if(odd) {
			#ifdef BTPD_HLT_TEMP
				sendVsTemp(BTPD_HLT_TEMP, TS_HLT, VS_HLT);
			#endif
			#ifdef BTPD_MASH_TEMP
				sendVsTemp(BTPD_MASH_TEMP, TS_MASH, VS_MASH);
			#endif
			#ifdef BTPD_KETTLE_TEMP
				sendVsTemp(BTPD_KETTLE_TEMP, TS_KETTLE, VS_KETTLE);
			#endif
		} else {
			#ifdef BTPD_HLT_VOL
				sendVsVol(BTPD_HLT_VOL, TS_HLT);
			#endif
			#ifdef BTPD_MASH_VOL
				sendVsVol(BTPD_MASH_VOL, TS_MASH);
			#endif
			#ifdef BTPD_KETTLE_VOL
				sendVsVol(BTPD_KETTLE_VOL, TS_KETTLE);
			#endif
		}
		// the temps with no volume always display
		#ifdef BTPD_RIMS_TEMP
			sendVsTemp(BTPD_RIMS_TEMP, TS_RIMS, VS_MASH);
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
		#ifdef BTPD_STEAM_PRESS
			sendFloatsBTPD(BTPD_STEAM_PRESS, steamTgt, steamPressure / 1000.0 );
		#endif
		lastBTPD = millis();
		odd = !odd;
	}
}

#endif BTPD_ALTERNATE_TEMP_VOLUME


void sendVsTemp(byte chan, byte sensor, byte vessel) {
  sendFloatsBTPD(chan, setpoint[vessel] / 100.0, temp[sensor] / 100.0);  
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
