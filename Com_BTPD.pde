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
//#define BTPD_KETTLE_TEMPTIME 0x23    // BTPD_KETTLE_TEMP: Displays Kettle temp and boil timer on specified channel
//#define BTPD_H2O_TEMPS 0x24 // BTPD_H2O_TEMPS: Displays H2O In and H2O Out temps on specified channels
#define BTPD_FERM_TEMP 0x24 // BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
#define BTPD_TIMERS 0x25 // BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
//#define BTPD_HLT_VOL 0x26 // BTPD_HLT_VOL: Displays current and target HLT volume
//#define BTPD_MASH_VOL 0x27 // BTPD_MASH_VOL: Displays current and target Mash volume
//#define BTPD_KETTLE_VOL 0x28 // BTPD_KETTLE_VOL: Displays current and target Kettle volume
//#define BTPD_STEAM_PRESS 0x29 // BTPD_STEAM_PRESS: Displays current and target Steam pressure
#define BTPD_AUX1_TEMP 0x2a

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
		#ifdef BTPD_KETTLE_TEMPTIME
			sendFloatsBTPD(BTPD_KETTLE_TEMPTIME, temp[TS_KETTLE] / 100.0, timer2Float(timerValue[TIMER_BOIL]));
		#endif
		#ifdef BTPD_H2O_TEMPS
			sendFloatsBTPD(BTPD_H2O_TEMPS, temp[TS_H2OIN] / 100.0, temp[TS_H2OOUT] / 100.0);
		#endif
		#ifdef BTPD_FERM_TEMP
			sendFloatsBTPD(BTPD_FERM_TEMP, pitchTemp, temp[TS_BEEROUT] / 100.0);
		#endif
		#ifdef BTPD_TIMERS
			sendVsTime(BTPD_TIMERS, TIMER_MASH, TIMER_BOIL);
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
                #ifdef BTPD_AUX1_TEMP
                	sendVsTemp(BTPD_AUX1_TEMP, TS_AUX1, VS_MASH);
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
			sendVsTime(BTPD_TIMERS, TIMER_MASH, TIMER_BOIL);
		#endif
		#ifdef BTPD_STEAM_PRESS
			sendFloatsBTPD(BTPD_STEAM_PRESS, steamTgt, steamPressure / 1000.0 );
		#endif
		lastBTPD = millis();
		odd = !odd;
	}
}

#endif //BTPD_ALTERNATE_TEMP_VOLUME


void sendVsTemp(byte chan, byte sensor, byte vessel) {
  if (temp[sensor] == BAD_TEMP )
    sendStringBTPD(chan, "    ----");
  else
    sendFloatsBTPD(chan, setpoint[vessel] / 100.0, temp[sensor] / 100.0);
}

void sendVsVol(byte chan, byte vessel) {
  sendFloatsBTPD(chan, tgtVol[vessel] / 1000.0, volAvg[vessel] / 1000.0);
}

void sendStringBTPD(byte chan, char *string) {
  Wire.beginTransmission(chan);
  Wire.send((uint8_t *)string, strlen(string));
  Wire.endTransmission();
} 

void sendFloat1BTPD(byte chan, float line) {
  Wire.beginTransmission(chan);
  Wire.send(0xfd);
  Wire.send(0x00);
  Wire.send((uint8_t *) &line, 4);
  Wire.endTransmission();
}

void sendFloat2BTPD(byte chan, float line) {
  Wire.beginTransmission(chan);
  Wire.send(0xfe);
  Wire.send(0x00);
  Wire.send((uint8_t *) &line, 4);
  Wire.endTransmission();
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
/*
  Converts brewtroller timers to byte values, and chooses appropriate set to send to BTPD
  sends HH:MM for times greater than 1 hour, and MM:SS for times under.
  If timeris paused, send high byte value to post "--:--"
  Timer1 fills the top row
  Timer2 fills the bottom row
*/
void sendVsTime(byte chan, byte timer1, byte timer2) {
  byte AA = 0;
  byte BB = 0;
  byte CC = 0;
  byte DD = 0;
  if (timerValue[timer1] > 0 && !timerStatus[timer1]) {
    AA = 100;
    BB = 100;
  } else if (alarmStatus || timerStatus[timer1]) {
    byte hours1 = timerValue[timer1] / 3600000;
    byte mins1 = (timerValue[timer1] - hours1 * 3600000) / 60000;
    byte secs1 = (timerValue[timer1] - hours1 * 3600000 - mins1 * 60000) / 1000;
    if(hours1 > 0) {
      AA = hours1;
      BB = mins1;
    } else {
      AA = mins1;
      BB = secs1;
    }
  }
  if (timerValue[timer2] > 0 && !timerStatus[timer2]) {
    CC = 100;
    DD = 100;
  } else if (alarmStatus || timerStatus[timer2]) {
    byte hours2 = timerValue[timer2] / 3600000;
    byte mins2 = (timerValue[timer2] - hours2 * 3600000) / 60000;
    byte secs2 = (timerValue[timer2] - hours2 * 3600000 - mins2 * 60000) / 1000;
    if(hours2 > 0) {
      CC = hours2;
      DD = mins2;
    } else {
      CC = mins2;
      DD = secs2;
    }
  }
  SendTimeBTPD(chan, AA, BB, CC, DD);
}

/*
  BTPD requires ASCII to enable colons;
  colon in first four characters enables top colon,
  colon after enables bottom colon. sent in middle for clarity.
  Format for BTPD is:
  AA:BB
  CC:DD
  values are checked for range, and if leading zero is required. (to maintian two digits)
  AA / CC value above 99 posts --:--
  BB / DD value above 59 posts --:--
*/
void SendTimeBTPD(byte chan, byte AA, byte BB, byte CC, byte DD) {
  Wire.beginTransmission(chan);
  if (AA > 99 || BB > 59) {
    Wire.send("--:--");
  } else {
    if (AA < 10)
      Wire.send("0");
    Wire.send(itoa(AA, buf, 10));
    Wire.send(":");
    if(BB < 10)
      Wire.send("0");
    Wire.send(itoa(BB, buf, 10));
  }
  if(CC > 99 || DD > 59) {
    Wire.send("--:--");
  } else {
    if(CC < 10)
      Wire.send("0");
    Wire.send(itoa(CC, buf, 10));
    Wire.send(":");
    if(DD < 10)
      Wire.send("0");
    Wire.send(itoa(DD, buf, 10));
  }
  Wire.endTransmission();
}

#endif //BTPD_TIMERS
#endif //BTPD_SUPPORT
