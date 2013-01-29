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


void doMon() {
//Program memory used: 4KB (as of Build 205)
#ifdef MODULE_BREWMONITOR
  clearTimer();
  
  encMin = 0;
  encMax = 2;
  encCount = 0;
  byte lastCount = 1;
  if (pwrRecovery == 2) {
    loadSetpoints();
    unsigned int newMins = getTimerRecovery();
    if (newMins > 0) setTimer(newMins);
  } else { 
    setTimerRecovery(0);
    saveSetpoints();
    setPwrRecovery(2);
  }
  
  for (byte i = VS_HLT; i <= VS_STEAM; i++) pid[i].SetMode(AUTO);
  
  while (1) {
    if (enterStatus == 2) {
      enterStatus = 0;
      if (confirmExit()) {
          resetOutputs();
          setPwrRecovery(0); 
          return;
      } else {
        encCount = lastCount;
        lastCount += 1;
      }
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      if (alarmStatus) {
        setAlarm(0);
      } else {
        //Pop-Up Menu
        strcpy_P(menuopts[0], PSTR("Set HLT Temp"));
        strcpy_P(menuopts[1], PSTR("Clear HLT Temp"));
        strcpy_P(menuopts[2], PSTR("Set Mash Temp"));
        strcpy_P(menuopts[3], PSTR("Clear Mash Temp"));
        strcpy_P(menuopts[4], PSTR("Set Kettle Temp"));
        strcpy_P(menuopts[5], PSTR("Clear Kettle Temp"));
        strcpy_P(menuopts[6], PSTR("Set Timer"));
        strcpy_P(menuopts[7], PSTR("Pause Timer"));
        strcpy_P(menuopts[8], PSTR("Clear Timer"));
        strcpy_P(menuopts[9], PSTR("Close Menu"));
        strcpy_P(menuopts[10], EXIT);

        boolean inMenu = 1;
        byte lastOption = 0;
        while(inMenu) {
          lastOption = scrollMenu("Brew Monitor Menu", 11, lastOption);
          if (lastOption == 0) {
            if (setpoint[TS_HLT] > 0) setpoint[TS_HLT] = getValue(PSTR("Enter HLT Temp:"), setpoint[TS_HLT], 3, 0, 255, TUNIT);
            else {
              #ifdef USEMETRIC
                setpoint[TS_HLT] = getValue(PSTR("Enter HLT Temp:"), 82, 3, 0, 255, TUNIT);
              #else
                setpoint[TS_HLT] = getValue(PSTR("Enter HLT Temp:"), 180, 3, 0, 255, TUNIT);
              #endif
            }
            inMenu = 0;
          } else if (lastOption == 1) {
            setpoint[TS_HLT] = 0;
            inMenu = 0;
          } else if (lastOption == 2) {
            if (setpoint[TS_MASH] > 0) setpoint[TS_MASH] = getValue(PSTR("Enter Mash Temp:"), setpoint[TS_MASH], 3, 0, 255, TUNIT);
            else {
              #ifdef USEMETRIC
                setpoint[TS_MASH] = getValue(PSTR("Enter Mash Temp:"), 67, 3, 0, 255, TUNIT);
              #else
                setpoint[TS_MASH] = getValue(PSTR("Enter Mash Temp:"), 152, 3, 0, 255, TUNIT);
              #endif
            }
            inMenu = 0;
          } else if (lastOption == 3) {
            setpoint[TS_MASH] = 0;
            inMenu = 0;
          } else if (lastOption == 4) {
            if (setpoint[TS_KETTLE] > 0) setpoint[TS_KETTLE] = getValue(PSTR("Enter Kettle Temp:"), setpoint[TS_KETTLE], 3, 0, 255, TUNIT);
            else {
              #ifdef USEMETRIC
                setpoint[TS_KETTLE] = getValue(PSTR("Enter Kettle Temp:"), 100, 3, 0, 255, TUNIT);
              #else
                setpoint[TS_KETTLE] = getValue(PSTR("Enter Kettle Temp:"), 212, 3, 0, 255, TUNIT);
              #endif
            }
            inMenu = 0;
          } else if (lastOption == 5) {
            setpoint[TS_KETTLE] = 0;
            inMenu = 0;
          } else if (lastOption == 6) {
            unsigned int newMins;
            newMins = getTimerValue(PSTR("Enter Timer Value:"), timerValue/60000);
            if (newMins > 0) {
              setTimer(newMins);
              inMenu = 0;
            }
          } else if (lastOption == 7) {
            pauseTimer();
            inMenu = 0;
          } else if (lastOption == 8) {
            clearTimer();
            inMenu = 0;
          } else if (lastOption == 10) {
            if (confirmExit()) {
              resetOutputs();
              setPwrRecovery(0);
              return;
            } else break;
          } else inMenu = 0;
          saveSetpoints();
        }
        encMin = 0;
        encMax = 2;
        encCount = lastCount;
        lastCount += 1;
      }
    }
    
    if (chkMsg()) rejectMsg(LOGGLB);
    brewCore();
    
    if (encCount == 0) {
      if (encCount != lastCount) {
        clearLCD();
        printLCD_P(0,4,PSTR("Brew Monitor"));
        printLCD_P(1,0,PSTR("HLT"));
        printLCD_P(3,0,PSTR("["));
        printLCD_P(3,5,PSTR("]"));
        printLCD_P(2, 3, TUNIT);
        printLCD_P(3, 4, TUNIT);
        printLCD_P(1,16,PSTR("Mash"));
        printLCD_P(3,14,PSTR("["));
        printLCD_P(3,19,PSTR("]"));
        printLCD_P(2, 19, TUNIT);
        printLCD_P(3, 18, TUNIT);
        lastCount = encCount;
        timerLastWrite = 0;
      }

      for (byte i = VS_HLT; i <= VS_MASH; i++) {
        if (temp[i] == -1) printLCD_P(2, i * 16, PSTR("---")); else printLCDLPad(2, i * 16, itoa(temp[i], buf, 10), 3, ' ');
        printLCDLPad(3, i * 14 + 1, itoa(setpoint[i], buf, 10), 3, ' ');
        if (PIDEnabled[i]) {
          byte pct = PIDOutput[i] / PIDCycle[i] / 10;
          if (pct == 0) strcpy_P(buf, PSTR("Off"));
          else if (pct == 100) strcpy_P(buf, PSTR(" On"));
          else { itoa(pct, buf, 10); strcat(buf, "%"); }
        } else if (heatStatus[i]) strcpy_P(buf, PSTR(" On")); else strcpy_P(buf, PSTR("Off")); 
        printLCDLPad(3, i * 5 + 6, buf, 3, ' ');
      }

    } else if (encCount == 1) {
      if (encCount != lastCount) {
        clearLCD();
        printLCD_P(0,4,PSTR("Brew Monitor"));
        printLCD_P(1,0,PSTR("Kettle"));
        printLCD_P(3,0,PSTR("["));
        printLCD_P(3,5,PSTR("]"));
        printLCD_P(2, 3, TUNIT);
        printLCD_P(3, 4, TUNIT);
        lastCount = encCount;
        timerLastWrite = 0;
      }

      if (temp[TS_KETTLE] == -1) printLCD_P(2, 0, PSTR("---")); else printLCDLPad(2, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
      printLCDLPad(3, 1, itoa(setpoint[TS_KETTLE], buf, 10), 3, ' ');
      if (PIDEnabled[TS_KETTLE]) {
        byte pct = PIDOutput[TS_KETTLE] / PIDCycle[TS_KETTLE] / 10;
        if (pct == 0) strcpy_P(buf, PSTR("Off"));
        else if (pct == 100) strcpy_P(buf, PSTR(" On"));
        else { itoa(pct, buf, 10); strcat_P(buf, PSTR("%")); }
      } else { if (heatStatus[TS_KETTLE]) strcpy_P(buf, PSTR(" On")); else strcpy_P(buf, PSTR("Off")); }
      printLCDLPad(3, 6, buf, 3, ' ');
    } else if (encCount == 2) {
      if (encCount != lastCount) {
        clearLCD();
        printLCD_P(0,4,PSTR("Brew Monitor"));
        printLCD_P(1,1,PSTR("In"));
        printLCD_P(1,16,PSTR("Out"));
        printLCD_P(2,8,PSTR("Beer"));
        printLCD_P(3,8,PSTR("H2O"));
        printLCD_P(2, 3, TUNIT);
        printLCD_P(2, 19, TUNIT);
        printLCD_P(3, 3, TUNIT);
        printLCD_P(3, 19, TUNIT);
        lastCount = encCount;
        timerLastWrite = 0;
      }
        
      if (temp[TS_KETTLE] == -1) printLCD_P(2, 0, PSTR("---")); else printLCDLPad(2, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
      if (temp[TS_BEEROUT] == -1) printLCD_P(2, 16, PSTR("---")); else printLCDLPad(2, 16, itoa(temp[TS_BEEROUT], buf, 10), 3, ' ');
      if (temp[TS_H2OIN] == -1) printLCD_P(3, 0, PSTR("---")); else printLCDLPad(3, 0, itoa(temp[TS_H2OIN], buf, 10), 3, ' ');
      if (temp[TS_H2OOUT] == -1) printLCD_P(3, 16, PSTR("---")); else printLCDLPad(3, 16, itoa(temp[TS_H2OOUT], buf, 10), 3, ' ');
    }
    printTimer(1,7);
  }
#endif
}
