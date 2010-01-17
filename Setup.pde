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


void menuSetup() {
  byte lastOption = 0;
  while(1) {
    strcpy_P(menuopts[0], PSTR("Assign Temp Sensor"));
    strcpy_P(menuopts[1], PSTR("Configure Outputs"));
    strcpy_P(menuopts[2], PSTR("Volume/Capacity"));
    strcpy_P(menuopts[3], PSTR("Configure Valves"));
    strcpy_P(menuopts[4], INIT_EEPROM);
    strcpy_P(menuopts[5], EXIT);
    
    lastOption = scrollMenu("System Setup", 6, lastOption);
    if (lastOption == 0) assignSensor();
    else if (lastOption == 1) cfgOutputs();
    else if (lastOption == 2) cfgVolumes();
    else if (lastOption == 3) cfgValves();
    else if (lastOption == 4) {
      clearLCD();
      printLCD_P(0, 0, PSTR("Reset Configuration?"));
      strcpy_P(menuopts[0], INIT_EEPROM);
        strcpy_P(menuopts[1], CANCEL);
        if (getChoice(2, 3) == 0) {
          EEPROM.write(2047, 0);
          checkConfig();
          loadSetup();
        }
    } else return;
    saveSetup();
  }
}

void assignSensor() {
  encMin = 0;
  encMax = 7;
  encCount = 0;
  byte lastCount = 1;
  
  char dispTitle[8][21];
  strcpy_P(dispTitle[0], HLTDESC);
  strcpy_P(dispTitle[1], MASHDESC);
  strcpy_P(dispTitle[2], PSTR("Brew Kettle"));
  strcpy_P(dispTitle[3], PSTR("H2O In"));
  strcpy_P(dispTitle[4], PSTR("H2O Out"));
  strcpy_P(dispTitle[5], PSTR("Beer Out"));
  strcpy_P(dispTitle[6], PSTR("AUX 1"));
  strcpy_P(dispTitle[7], PSTR("AUX 2"));
  
  while (1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      clearLCD();
      printLCD_P(0, 0, PSTR("Assign Temp Sensor"));
      printLCDCenter(1, 0, dispTitle[lastCount], 20);
      for (byte i=0; i<8; i++) printLCDLPad(2,i*2+2,itoa(tSensor[lastCount][i], buf, 16), 2, '0');  
    }
    if (enterStatus == 2) {
      enterStatus = 0;
      return;
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      //Pop-Up Menu
      strcpy_P(menuopts[0], PSTR("Scan Bus"));
      strcpy_P(menuopts[1], PSTR("Delete Address"));
      strcpy_P(menuopts[2], PSTR("Close Menu"));
      strcpy_P(menuopts[3], EXIT);
      byte selected = scrollMenu(dispTitle[lastCount], 4, 0);
      if (selected == 0) {
        clearLCD();
        printLCDCenter(0, 0, dispTitle[lastCount], 20);
        printLCD_P(1,0,PSTR("Disconnect all other"));
        printLCD_P(2,2,PSTR("temp sensors now"));
        {
          strcpy_P(menuopts[0], CONTINUE);
          strcpy_P(menuopts[1], CANCEL);
          if (getChoice(2, 3) == 0) getDSAddr(tSensor[lastCount]);
        }
      } else if (selected == 1) for (byte i = 0; i <8; i++) tSensor[lastCount][i] = 0;
      else if (selected > 2) return;

      encMin = 0;
      encMax = 7;
      encCount = lastCount;
      lastCount += 1;
    }
  }
}

void cfgOutputs() {
  byte lastOption = 0;
  while(1) {
    if (PIDEnabled[VS_HLT]) strcpy_P(menuopts[0], PSTR("HLT Mode: PID")); else strcpy_P(menuopts[0], PSTR("HLT Mode: On/Off"));
    strcpy_P(menuopts[1], HLTCYCLE);
    strcpy_P(menuopts[2], HLTGAIN);
    strcpy_P(menuopts[3], HLTHY);
    if (PIDEnabled[VS_MASH]) strcpy_P(menuopts[4], PSTR("Mash Mode: PID")); else strcpy_P(menuopts[4], PSTR("Mash Mode: On/Off"));
    strcpy_P(menuopts[5], MASHCYCLE);
    strcpy_P(menuopts[6], MASHGAIN);
    strcpy_P(menuopts[7], MASHHY);
    if (PIDEnabled[VS_KETTLE]) strcpy_P(menuopts[8], PSTR("Kettle Mode: PID")); else strcpy_P(menuopts[8], PSTR("Kettle Mode: On/Off"));
    strcpy_P(menuopts[9], KETTLECYCLE);
    strcpy_P(menuopts[10], KETTLEGAIN);
    strcpy_P(menuopts[11], KETTLEHY);
    strcpy_P(menuopts[12], PSTR("Boil Temp: "));
    strcat(menuopts[12], itoa(getBoilTemp(), buf, 10));
    strcat_P(menuopts[12], TUNIT);
    strcpy_P(menuopts[13], PSTR("Boil Power: "));
    strcat(menuopts[13], itoa(getBoilPwr(), buf, 10));
    strcat(menuopts[13], "%");
    if (PIDEnabled[VS_STEAM]) strcpy_P(menuopts[14], PSTR("Steam Mode: PID")); else strcpy_P(menuopts[14], PSTR("Steam Mode: On/Off"));
    strcpy_P(menuopts[15], STEAMCYCLE);
    strcpy_P(menuopts[16], STEAMGAIN);
    strcpy_P(menuopts[17], STEAMPRESS);
    strcpy_P(menuopts[18], STEAMSENSOR);
    strcpy_P(menuopts[19], STEAMZERO);
    strcpy_P(menuopts[20], EXIT);

    lastOption = scrollMenu("Configure Outputs", 21, lastOption);
    if (lastOption == 0) PIDEnabled[VS_HLT] = PIDEnabled[VS_HLT] ^ 1;
    else if (lastOption == 1) {
      PIDCycle[VS_HLT] = getValue(HLTCYCLE, PIDCycle[VS_HLT], 3, 0, 255, SEC);
      pid[VS_HLT].SetOutputLimits(0, PIDCycle[VS_HLT] * 10 * PIDLIMIT_HLT);
    } else if (lastOption == 2) {
      setPIDGain("HLT PID Gain", &PIDp[VS_HLT], &PIDi[VS_HLT], &PIDd[VS_HLT]);
      pid[VS_HLT].SetTunings(PIDp[VS_HLT], PIDi[VS_HLT], PIDd[VS_HLT]);
    } else if (lastOption == 3) hysteresis[VS_HLT] = getValue(HLTHY, hysteresis[VS_HLT], 3, 1, 255, TUNIT);
    else if (lastOption == 4) PIDEnabled[VS_MASH] = PIDEnabled[VS_MASH] ^ 1;
    else if (lastOption == 5) {
      PIDCycle[VS_MASH] = getValue(MASHCYCLE, PIDCycle[VS_MASH], 3, 0, 255, SEC);
      pid[VS_MASH].SetOutputLimits(0, PIDCycle[VS_MASH] * 10 * PIDLIMIT_MASH);
    } else if (lastOption == 6) {
      setPIDGain("Mash PID Gain", &PIDp[VS_MASH], &PIDi[VS_MASH], &PIDd[VS_MASH]);
      pid[VS_MASH].SetTunings(PIDp[VS_MASH], PIDi[VS_MASH], PIDd[VS_MASH]);
    } else if (lastOption == 7) hysteresis[VS_MASH] = getValue(MASHHY, hysteresis[VS_MASH], 3, 1, 255, TUNIT);
    else if (lastOption == 8) PIDEnabled[VS_KETTLE] = PIDEnabled[VS_KETTLE] ^ 1;
    else if (lastOption == 9) {
      PIDCycle[VS_KETTLE] = getValue(KETTLECYCLE, PIDCycle[VS_KETTLE], 3, 0, 255, SEC);
      pid[VS_KETTLE].SetOutputLimits(0, PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE);
    } else if (lastOption == 10) {
      setPIDGain("Kettle PID Gain", &PIDp[VS_KETTLE], &PIDi[VS_KETTLE], &PIDd[VS_KETTLE]);
      pid[VS_KETTLE].SetTunings(PIDp[VS_KETTLE], PIDi[VS_KETTLE], PIDd[VS_KETTLE]);
    } else if (lastOption == 11) hysteresis[VS_KETTLE] = getValue(KETTLEHY, hysteresis[VS_KETTLE], 3, 1, 255, TUNIT);
    else if (lastOption == 12) setBoilTemp(getValue(PSTR("Boil Temp"), getBoilTemp(), 3, 0, 255, TUNIT));
    else if (lastOption == 13) setBoilPwr(getValue(PSTR("Boil Power"), getBoilPwr(), 3, 0, min(PIDLIMIT_KETTLE, 100), PSTR("%")));
    else if (lastOption == 14) PIDEnabled[VS_STEAM] = PIDEnabled[VS_STEAM] ^ 1;
    else if (lastOption == 15) {
      PIDCycle[VS_STEAM] = getValue(STEAMCYCLE, PIDCycle[VS_STEAM], 3, 0, 255, SEC);
      pid[VS_STEAM].SetOutputLimits(0, PIDCycle[VS_STEAM] * 10 * PIDLIMIT_STEAM);
    } else if (lastOption == 16) {
      setPIDGain("Steam PID Gain", &PIDp[VS_STEAM], &PIDi[VS_STEAM], &PIDd[VS_STEAM]);
      pid[VS_STEAM].SetTunings(PIDp[VS_STEAM], PIDi[VS_STEAM], PIDd[VS_STEAM]);
    } else if (lastOption == 17) steamTgt = getValue(STEAMPRESS, steamTgt, 3, 0, 255, PUNIT);
    else if (lastOption == 18) {
      steamPSens = getValue(STEAMSENSOR, steamPSens, 4, 1, 9999, PSTR("mV/kPa"));
      #ifdef USEMETRIC
        pid[VS_STEAM].SetInputLimits(0, 50000 / steamPSens);
      #else
        pid[VS_STEAM].SetInputLimits(0, 7250 / steamPSens);
      #endif
    } else if (lastOption == 19) {
      clearLCD();
      printLCD_P(0, 0, STEAMZERO);
      printLCD_P(1,2,PSTR("Calibrate Zero?"));
      strcpy_P(menuopts[0], CONTINUE);
      strcpy_P(menuopts[1], CANCEL);
      if (getChoice(2, 3) == 0) steamZero = analogRead(STEAMPRESS_APIN);
    } else return;
  } 
}

void setPIDGain(char sTitle[], byte* p, byte* i, byte* d) {
  byte retP = *p;
  byte retI = *i;
  byte retD = *d;
  byte cursorPos = 0; //0 = p, 1 = i, 2 = d, 3 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  encMin = 0;
  encMax = 3;
  encCount = 0;
  byte lastCount = 1;
  
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD_P(1, 0, PSTR("P:     I:     D:    "));
  printLCD_P(3, 8, PSTR("OK"));
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        if (cursorPos == 0) retP = encCount;
        else if (cursorPos == 1) retI = encCount;
        else if (cursorPos == 2) retD = encCount;
      } else {
        cursorPos = encCount;
        if (cursorPos == 0) {
          printLCD_P(1, 2, PSTR(">"));
          printLCD_P(1, 9, PSTR(" "));
          printLCD_P(1, 16, PSTR(" "));
          printLCD_P(3, 7, PSTR(" "));
          printLCD_P(3, 10, PSTR(" "));
        } else if (cursorPos == 1) {
          printLCD_P(1, 2, PSTR(" "));
          printLCD_P(1, 9, PSTR(">"));
          printLCD_P(1, 16, PSTR(" "));
          printLCD_P(3, 7, PSTR(" "));
          printLCD_P(3, 10, PSTR(" "));
        } else if (cursorPos == 2) {
          printLCD_P(1, 2, PSTR(" "));
          printLCD_P(1, 9, PSTR(" "));
          printLCD_P(1, 16, PSTR(">"));
          printLCD_P(3, 7, PSTR(" "));
          printLCD_P(3, 10, PSTR(" "));
        } else if (cursorPos == 3) {
          printLCD_P(1, 2, PSTR(" "));
          printLCD_P(1, 9, PSTR(" "));
          printLCD_P(1, 16, PSTR(" "));
          printLCD_P(3, 7, PSTR(">"));
          printLCD_P(3, 10, PSTR("<"));
        }
      }
      printLCDLPad(1, 3, itoa(retP, buf, 10), 3, ' ');
      printLCDLPad(1, 10, itoa(retI, buf, 10), 3, ' ');
      printLCDLPad(1, 17, itoa(retD, buf, 10), 3, ' ');
      lastCount = encCount;
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == 3) {
        *p = retP;
        *i = retI;
        *d = retD;
        return;
      }
      cursorState = cursorState ^ 1;
      if (cursorState) {
        encMin = 0;
        encMax = 255;
        if (cursorPos == 0) encCount = retP;
        else if (cursorPos == 1) encCount = retI;
        else if (cursorPos == 2) encCount = retD;
      } else {
        encMin = 0;
        encMax = 3;
        encCount = cursorPos;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return;
    }
  }
}

void cfgVolumes() {
  byte lastOption = 0;
  while(1) {
    strcpy_P(menuopts[0], PSTR("HLT Capacity"));
    strcpy_P(menuopts[1], PSTR("HLT Dead Space"));
    strcpy_P(menuopts[2], PSTR("HLT Calibration"));
    strcpy_P(menuopts[3], PSTR("HLT Zero Volume"));
    strcpy_P(menuopts[4], PSTR("Mash Capacity"));
    strcpy_P(menuopts[5], PSTR("Mash Dead Space"));
    strcpy_P(menuopts[6], PSTR("Mash Calibration"));
    strcpy_P(menuopts[7], PSTR("Mash Zero Volume"));
    strcpy_P(menuopts[8], PSTR("Kettle Capacity"));
    strcpy_P(menuopts[9], PSTR("Kettle Dead Space"));
    strcpy_P(menuopts[10], PSTR("Kettle Calibration"));
    strcpy_P(menuopts[11], PSTR("Kettle Zero Volume"));
    strcpy_P(menuopts[12], PSTR("Evaporation Rate"));
    strcpy_P(menuopts[13], EXIT);

    lastOption = scrollMenu("Volume/Capacity", 14, lastOption);

    if (lastOption == 0) capacity[TS_HLT] = getValue(PSTR("HLT Capacity"), capacity[TS_HLT], 7, 3, 9999999, VOLUNIT);
    else if (lastOption == 1) volLoss[TS_HLT] = getValue(PSTR("HLT Dead Space"), volLoss[TS_HLT], 5, 3, 65535, VOLUNIT);
    else if (lastOption == 2) volCalibMenu(TS_HLT);
    else if (lastOption == 3) cfgZeroVol(menuopts[3], VS_HLT);
    else if (lastOption == 4) capacity[TS_MASH] = getValue(PSTR("Mash Capacity"), capacity[TS_MASH], 7, 3, 9999999, VOLUNIT);
    else if (lastOption == 5) volLoss[TS_MASH] = getValue(PSTR("Mash Dead Space"), volLoss[TS_MASH], 5, 3, 65535, VOLUNIT);
    else if (lastOption == 6) volCalibMenu(TS_MASH);
    else if (lastOption == 7) cfgZeroVol(menuopts[7], VS_MASH);
    else if (lastOption == 8) capacity[TS_KETTLE] = getValue(PSTR("Kettle Capacity"), capacity[TS_KETTLE], 7, 3, 9999999, VOLUNIT);
    else if (lastOption == 9) volLoss[TS_KETTLE] = getValue(PSTR("Kettle Dead Space"), volLoss[TS_KETTLE], 5, 3, 65535, VOLUNIT);
    else if (lastOption == 10) volCalibMenu(TS_KETTLE);
    else if (lastOption == 11) cfgZeroVol(menuopts[11], VS_KETTLE);
    else if (lastOption == 12) evapRate = getValue(PSTR("Evaporation Rate"), evapRate, 3, 0, 100, PSTR("%/hr"));
    else return;
  } 
}

void volCalibMenu(byte vessel) {
  byte lastOption = 0;
  char sVessel[7];
  char sTitle[20];
  if (vessel == TS_HLT) strcpy_P(sVessel, PSTR("HLT"));
  else if (vessel == TS_MASH) strcpy_P(sVessel, PSTR("Mash"));
  else if (vessel == TS_KETTLE) strcpy_P(sVessel, PSTR("Kettle"));

  while(1) {
    for(byte i = 0; i < 10; i++) {
      if (calibVals[vessel][i] > 0) {
        ftoa(calibVols[vessel][i] / 1000.0, buf, 3);
        truncFloat(buf, 6);
        strcpy(menuopts[i], buf);
        strcat_P(menuopts[i], SPACE);
        strcat_P(menuopts[i], VOLUNIT);
        strcat_P(menuopts[i], PSTR(" ("));
        strcat(menuopts[i], itoa(calibVals[vessel][i], buf, 10));
        strcat_P(menuopts[i], PSTR(")"));
      } else strcpy_P(menuopts[i], PSTR("OPEN"));
    }
    strcpy_P(menuopts[10], EXIT);
    strcpy(sTitle, sVessel);
    strcat_P(sTitle, PSTR(" Calibration"));
    lastOption = scrollMenu(sTitle, 11, lastOption);
    if (lastOption > 9) return; 
    else {
      if (calibVols[vessel][lastOption] > 0) {
        if(confirmDel()) {
          calibVals[vessel][lastOption] = 0;
          calibVols[vessel][lastOption] = 0;
        }
      } else {
        calibVols[vessel][lastOption] = getValue(PSTR("Current Volume:"), 0, 7, 3, 9999999, VOLUNIT);
        calibVals[vessel][lastOption] = analogRead(vSensor[vessel]) - zeroVol[vessel];
      }
    }
  }
}

void cfgZeroVol(char sTitle[], byte vessel) {
  clearLCD();
  printLCDCenter(0, 0, sTitle, 20);
  printLCD_P(1,2,PSTR("Calibrate Zero?"));
  {
    strcpy_P(menuopts[0], CONTINUE);
    strcpy_P(menuopts[1], CANCEL);
    if (getChoice(2, 3) == 0) zeroVol[vessel] = analogRead(vSensor[vessel]);
  }
}

void cfgValves() {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], FILLHLT);
    strcpy_P(menuopts[1], FILLMASH);
    strcpy_P(menuopts[2], ADDGRAIN);    
    strcpy_P(menuopts[3], MASHHEAT);
    strcpy_P(menuopts[4], MASHIDLE);
    strcpy_P(menuopts[5], SPARGEIN);
    strcpy_P(menuopts[6], SPARGEOUT);
    strcpy_P(menuopts[7], BOILADDS);
    strcpy_P(menuopts[8], PSTR("Kettle Lid"));
    strcpy_P(menuopts[9], CHILLH2O);
    strcpy_P(menuopts[10], CHILLBEER);
    strcpy_P(menuopts[11], BOILRECIRC);
    strcpy_P(menuopts[12], DRAIN);
    strcpy_P(menuopts[13], EXIT);
    
    lastOption = scrollMenu("Valve Configuration", 14, lastOption);
    if (lastOption > 12) return;
    else vlvConfig[lastOption] = cfgValveProfile(menuopts[lastOption], vlvConfig[lastOption]);
  }
}

unsigned long cfgValveProfile (char sTitle[], unsigned long defValue) {
  unsigned long retValue = defValue;
  encMin = 0;

#ifdef ONBOARDPV
  encMax = 12;
#else
  encMax = MUXBOARDS * 8 + 1;
#endif

  //The left most bit being displayed (Set to MAX + 1 to force redraw)
  byte firstBit = encMax + 1;
  encCount = 0;
  byte lastCount = 1;

  clearLCD();
  printLCD(0,0,sTitle);
  printLCD_P(3, 3, PSTR("Test"));
  printLCD_P(3, 13, PSTR("Save"));
  
  while(1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      
      if (lastCount < firstBit || lastCount > firstBit + 17) {
        if (lastCount < firstBit) firstBit = lastCount; else if (lastCount < encMax - 1) firstBit = lastCount - 17;
        for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) if (retValue & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
      }

      for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) {
        if (i < 9) itoa(i + 1, buf, 10); else buf[0] = i + 56;
        buf[1] = '\0';
        printLCD(2, i - firstBit + 1, buf);
      }

      if (firstBit > 0) printLCD_P(2, 0, PSTR("<")); else printLCD_P(2, 0, PSTR(" "));
      if (firstBit + 18 < encMax - 1) printLCD_P(2, 19, PSTR(">")); else printLCD_P(2, 19, PSTR(" "));
      if (lastCount == encMax - 1) {
        printLCD_P(3, 2, PSTR(">"));
        printLCD_P(3, 7, PSTR("<"));
        printLCD_P(3, 12, PSTR(" "));
        printLCD_P(3, 17, PSTR(" "));
      } else if (lastCount == encMax) {
        printLCD_P(3, 2, PSTR(" "));
        printLCD_P(3, 7, PSTR(" "));
        printLCD_P(3, 12, PSTR(">"));
        printLCD_P(3, 17, PSTR("<"));
      } else {
        printLCD_P(3, 2, PSTR(" "));
        printLCD_P(3, 7, PSTR(" "));
        printLCD_P(3, 12, PSTR(" "));
        printLCD_P(3, 17, PSTR(" "));
        printLCD_P(2, lastCount - firstBit + 1, PSTR("^"));
      }
    }
    
    if (enterStatus == 1) {
      enterStatus = 0;
      if (lastCount == encMax) return retValue;
      else if (lastCount == encMax - 1) {
        setValves(retValue);
        printLCD_P(3, 2, PSTR("["));
        printLCD_P(3, 7, PSTR("]"));
        while (!enterStatus) delay(100);
        enterStatus = 0;
        setValves(0);
        lastCount++;
      } else {
        retValue = retValue ^ ((unsigned long)1<<lastCount);
        for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) if (retValue & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return defValue;
    }
  }
}


