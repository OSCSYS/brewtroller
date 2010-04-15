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

byte lastEEPROMWrite[2];

void setTimer(byte timer, unsigned int minutes) {
  timerValue[timer] = minutes * 60000;
  lastTime[timer] = millis();
  timerStatus[timer] = 1;
  setTimerRecovery(timer, minutes);
}

void pauseTimer(byte timer) {
  if (timerStatus[timer]) {
    //Pause
    timerStatus[timer] = 0;
  } else {
    //Unpause
    timerStatus[timer] = 1;
    lastTime[timer] = millis();
  }
}

void clearTimer(byte timer) {
  timerValue[timer] = 0;
  timerStatus[timer] = 0;
  setTimerRecovery(timer, 0);
}

void updateTimers() {
  for (byte timer = TIMER_MASH; timer <= TIMER_BOIL; timer++) {
    if (timerStatus[timer]) {
      unsigned long now = millis();
      if (timerValue[timer] > now - lastTime[timer]) {
        timerValue[timer] -= now - lastTime[timer];
      } else {
        timerValue[timer] = 0;
        timerStatus[timer] = 0;
        setAlarm(1);
      }
      lastTime[timer] = now;
    }

    byte timerHours = timerValue[timer] / 3600000;
    byte timerMins = (timerValue[timer] - timerHours * 3600000) / 60000;

    //Update EEPROM once per minute
    if (timerMins != lastEEPROMWrite[timer]) {
      lastEEPROMWrite[timer] = timerMins;
      setTimerRecovery(timer, timerValue[timer]/60000 + 1);
    }
  }
}

void setAlarm(boolean value) {
  setAlarmStatus(value);
  alarmPin.set(value);
}
