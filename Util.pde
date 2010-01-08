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

Compiled on Arduino-0015 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

void ftoa(float val, char retStr[], int precision) {
  itoa(val, retStr, 10);  
  if(val < 0) val = -val;
  if( precision > 0) {
    strcat(retStr, ".");
    unsigned int mult = 1;
    for(int i = 0; i< precision; i++) mult *=10;
    unsigned int frac = (val - int(val)) * mult;
    char buf[6];
    itoa(frac, buf, 10);
    for(int i = 0; i < precision - (int)strlen(buf); i++) strcat(retStr, "0");
    strcat(retStr, buf);
  }
}

//Truncate a string representation of a float to (length) chars but do not end string with a decimal point
void truncFloat(char string[], byte length) {
  if (strlen(string) > length) {
    if (string[length - 1] == '.') string[length - 1] = '\0';
    else string[length] = '\0';
  }
}

int availableMemory() {
  int size = 4096;
  byte *buf;
  while ((buf = (byte *) malloc(--size)) == NULL);
  free(buf);
  return size;
}


void resetOutputs() {
  for (int i = TS_HLT; i <= TS_KETTLE; i++) {
    setpoint[i] = 0;
    if (PIDEnabled[i]) pid[i].SetMode(MANUAL);
  }
  digitalWrite(HLTHEAT_PIN, LOW);
  digitalWrite(MASHHEAT_PIN, LOW);
  digitalWrite(KETTLEHEAT_PIN, LOW);
  digitalWrite(ALARM_PIN, LOW);
  setValves(0);
}

void setTimer(unsigned int minutes) {
  timerValue = minutes * 60000;
  lastTime = millis();
  timerStatus = 1;
}

void pauseTimer() {
  if (timerStatus) {
    //Pause
    timerStatus = 0;
  } else {
    //Unpause
    timerStatus = 1;
    lastTime = millis();
    timerLastWrite = 0;
  }
}

void clearTimer() {
  timerValue = 0;
  timerStatus = 0;
}

void printTimer(int iRow, int iCol) {
  char buf[3];
  if (alarmStatus || timerValue > 0) {
    if (timerStatus) {
      unsigned long now = millis();
      if (timerValue > now - lastTime) {
        timerValue -= now - lastTime;
      } else {
        timerValue = 0;
        timerStatus = 0;
        setAlarm(1);
        printLCD(iRow, iCol + 5, "!");
      }
      lastTime = now;
    } else if (!alarmStatus) printLCD(iRow, iCol, "PAUSED");

    unsigned int timerHours = timerValue / 3600000;
    unsigned int timerMins = (timerValue - timerHours * 3600000) / 60000;
    unsigned int timerSecs = (timerValue - timerHours * 3600000 - timerMins * 60000) / 1000;

    //Update EEPROM once per minute
    if (timerLastWrite/60 != timerValue/60000) setTimerRecovery(timerValue/60000 + 1);
    //Update LCD once per second
    if (timerLastWrite != timerValue/1000) {
      printLCD(iRow, iCol, "  :   ");
      if (timerHours > 0) {
        printLCDPad(iRow, iCol, itoa(timerHours, buf, 10), 2, '0');
        printLCDPad(iRow, iCol + 3, itoa(timerMins, buf, 10), 2, '0');
      } else {
        printLCDPad(iRow, iCol, itoa(timerMins, buf, 10), 2, '0');
        printLCDPad(iRow, iCol+ 3, itoa(timerSecs, buf, 10), 2, '0');
      }
      timerLastWrite = timerValue/1000;
    }
  } else printLCD(iRow, iCol, "      ");
}

void setAlarm(boolean value) {
  alarmStatus = value;
  digitalWrite(ALARM_PIN, value);
}

void setValves (unsigned int valveBits) { 
  if (valveBits & 1) digitalWrite(VALVE1_PIN, HIGH); else digitalWrite(VALVE1_PIN, LOW);
  if (valveBits & 2) digitalWrite(VALVE2_PIN, HIGH); else digitalWrite(VALVE2_PIN, LOW);
  if (valveBits & 4) digitalWrite(VALVE3_PIN, HIGH); else digitalWrite(VALVE3_PIN, LOW);
  if (valveBits & 8) digitalWrite(VALVE4_PIN, HIGH); else digitalWrite(VALVE4_PIN, LOW);
  if (valveBits & 16) digitalWrite(VALVE5_PIN, HIGH); else digitalWrite(VALVE5_PIN, LOW);
  if (valveBits & 32) digitalWrite(VALVE6_PIN, HIGH); else digitalWrite(VALVE6_PIN, LOW);
  if (valveBits & 64) digitalWrite(VALVE7_PIN, HIGH); else digitalWrite(VALVE7_PIN, LOW);
  if (valveBits & 128) digitalWrite(VALVE8_PIN, HIGH); else digitalWrite(VALVE8_PIN, LOW);
  if (valveBits & 256) digitalWrite(VALVE9_PIN, HIGH); else digitalWrite(VALVE9_PIN, LOW);
  if (valveBits & 512) digitalWrite(VALVEA_PIN, HIGH); else digitalWrite(VALVEA_PIN, LOW);
  if (valveBits & 1024) digitalWrite(VALVEB_PIN, HIGH); else digitalWrite(VALVEB_PIN, LOW);
}
