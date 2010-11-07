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

#ifndef NOUI
#include "Config.h"
#include "Enum.h"
#include <encoder.h>

//*****************************************************************************************************************************
// UI COMPILE OPTIONS
//*****************************************************************************************************************************

//**********************************************************************************
// ENCODER TYPE
//**********************************************************************************
// You must uncomment one and only one of the following ENCODER_ definitions
// Use ENCODER_ALPS for ALPS and Panasonic Encoders
// Use ENCODER_CUI for older CUI encoders
//
#define ENCODER_TYPE ALPS
//#define ENCODER_TYPE CUI
//**********************************************************************************

//*****************************************************************************************************************************
// Begin UI Code
//*****************************************************************************************************************************


//**********************************************************************************
// UI Definitions
//**********************************************************************************
#define SCREEN_HOME 0
#define SCREEN_FILL 1
#define SCREEN_MASH 2
#define SCREEN_SPARGE 3
#define SCREEN_BOIL 4
#define SCREEN_CHILL 5
#define SCREEN_AUX 6

//**********************************************************************************
// UI Strings
//**********************************************************************************
const char OK[] PROGMEM = "Ok";
const char CANCEL[] PROGMEM = "Cancel";
const char EXIT[] PROGMEM = "Exit";
const char MENU[] PROGMEM = "Menu";
const char SPACE[] PROGMEM = " ";
const char INIT_EEPROM[] PROGMEM = "Initialize EEPROM";
const char CONTINUE[] PROGMEM = "Continue";
const char FILLHLT[] PROGMEM = "Fill HLT";
const char FILLMASH[] PROGMEM = "Fill Mash";
const char FILLBOTH[] PROGMEM = "Fill Both";
const char ALLOFF[] PROGMEM = "All Off";
const char ABORT[] PROGMEM = "Abort";
const char ADDGRAIN[] PROGMEM = "Add Grain";
const char MASHHEAT[] PROGMEM = "Mash Heat";
const char MASHIDLE[] PROGMEM = "Mash Idle";
const char SPARGEIN[] PROGMEM = "Sparge In";
const char SPARGEOUT[] PROGMEM = "Sparge Out";
const char FLYSPARGE[] PROGMEM = "Fly Sparge";
const char BOILADDS[] PROGMEM = "Boil Additions";
const char CHILLNORM[] PROGMEM = "Chill Both";
const char CHILLH2O[] PROGMEM = "Chill H2O";
const char CHILLBEER[] PROGMEM = "Chill Beer";
const char BOILRECIRC[] PROGMEM = "Boil Recirc";
const char DRAIN[] PROGMEM = "Drain";
const char HLTHEAT[] PROGMEM = "HLT Heat";

#ifndef UI_NO_SETUP
const char HLTCYCLE[] PROGMEM = "HLT PID Cycle";
const char HLTGAIN[] PROGMEM = "HLT PID Gain";
const char HLTHY[] PROGMEM = "HLT Hysteresis";
const char MASHCYCLE[] PROGMEM = "Mash PID Cycle";
const char MASHGAIN[] PROGMEM = "Mash PID Gain";
const char MASHHY[] PROGMEM = "Mash Hysteresis";
const char KETTLECYCLE[] PROGMEM = "Kettle PID Cycle";
const char KETTLEGAIN[] PROGMEM = "Kettle PID Gain";
const char KETTLEHY[] PROGMEM = "Kettle Hysteresis";
#ifdef PID_FLOW_CONTROL
const char PUMPCYCLE[] PROGMEM = "Pump PID Cycle";
const char PUMPGAIN[] PROGMEM = "Pump PID Gain";
const char PUMPFLOW[] PROGMEM = "Pump Flow Rate";
const char NOUSE[] PROGMEM = " ";
#else
const char STEAMCYCLE[] PROGMEM = "Steam PID Cycle";
const char STEAMGAIN[] PROGMEM = "Steam PID Gain";
const char STEAMPRESS[] PROGMEM = "Steam Target";
const char STEAMSENSOR[] PROGMEM = "Steam Sensor Sens";
const char STEAMZERO[] PROGMEM = "Steam Zero Calib";
#endif
#endif

const char HLTDESC[] PROGMEM = "Hot Liquor Tank";
const char MASHDESC[] PROGMEM = "Mash Tun";
const char SEC[] PROGMEM = "s";
#ifdef USEMETRIC
const char VOLUNIT[] PROGMEM = "l";
const char WTUNIT[] PROGMEM = "kg";
const char TUNIT[] PROGMEM = "C";
const char PUNIT[] PROGMEM = "kPa";
#else
const char VOLUNIT[] PROGMEM = "gal";
const char WTUNIT[] PROGMEM = "lb";
const char TUNIT[] PROGMEM = "F";
const char PUNIT[] PROGMEM = "psi";
#endif

//**********************************************************************************
// UI Custom LCD Chars
//**********************************************************************************
const byte CHARFIELD[] PROGMEM = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARCURSOR[] PROGMEM = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARSEL[] PROGMEM = {B10001, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte BMP0[] PROGMEM = {B00000, B00000, B00000, B00000, B00011, B01111, B11111, B11111};
const byte BMP1[] PROGMEM = {B00000, B00000, B00000, B00000, B11100, B11110, B11111, B11111};
const byte BMP2[] PROGMEM = {B00001, B00011, B00111, B01111, B00001, B00011, B01111, B11111};
const byte BMP3[] PROGMEM = {B11111, B11111, B10001, B00011, B01111, B11111, B11111, B11111};
const byte BMP4[] PROGMEM = {B01111, B01110, B01100, B00001, B01111, B00111, B00011, B11101};
const byte BMP5[] PROGMEM = {B11111, B00111, B00111, B11111, B11111, B11111, B11110, B11001};
const byte BMP6[] PROGMEM = {B11111, B11111, B11110, B11101, B11011, B00111, B11111, B11111};
const byte UNLOCK_ICON[] PROGMEM = {B00110, B01001, B01001, B01000, B01111, B01111, B01111, B00000};
const byte PROG_ICON[] PROGMEM = {B00001, B11101, B10101, B11101, B10001, B10001, B00001, B11111};
const byte BELL[] PROGMEM = {B00100, B01110, B01110, B01110, B11111, B00000, B00100, B00000};
//**********************************************************************************
// UI Globals
//**********************************************************************************
byte activeScreen;
boolean screenLock;
unsigned long timerLastPrint;

//**********************************************************************************
// uiInit:  One time intialization of all UI logic
//**********************************************************************************
void uiInit() {
  initLCD();
  lcdSetCustChar_P(7, UNLOCK_ICON);
  Encoder.begin(ENCA_PIN, ENCB_PIN, ENTER_PIN, ENTER_INT, ENCODER_TYPE);

  //Check to see if EEPROM Initialization is needed
  if (checkConfig()) {
    clearLCD();
    printLCD_P(0, 0, PSTR("Missing Config"));
    strcpy_P(menuopts[0], INIT_EEPROM);
    strcpy_P(menuopts[1], EXIT);
    if (getChoice(2, 3) == 0) {
      clearLCD();
      printLCD_P(1, 0, INIT_EEPROM);
      printLCD_P(2, 3, PSTR("Please Wait..."));
      initEEPROM();
      //Apply any EEPROM updates
      checkConfig();
    }
    clearLCD();
  }

  activeScreen = SCREEN_HOME;
  screenInit(SCREEN_HOME);
  unlockUI();
}

void uiEvent(byte eventID, byte eventParam) {
  if (eventID == EVENT_STEPINIT) {
    if (eventParam == STEP_FILL 
      || eventParam == STEP_REFILL
    ) activeScreen = SCREEN_FILL;
    else if (eventParam == STEP_DELAY
      || eventParam == STEP_PREHEAT
      || eventParam == STEP_DOUGHIN
      || eventParam == STEP_ACID
      || eventParam == STEP_PROTEIN
      || eventParam == STEP_SACCH
      || eventParam == STEP_SACCH2
      || eventParam == STEP_MASHOUT
      || eventParam == STEP_MASHHOLD
    ) activeScreen = SCREEN_MASH;
    else if (eventParam == STEP_ADDGRAIN
      || eventParam == STEP_SPARGE
    ) activeScreen = SCREEN_SPARGE;
    else if (eventParam == STEP_BOIL) activeScreen = SCREEN_BOIL;
    else if (eventParam == STEP_CHILL) activeScreen = SCREEN_CHILL;
    screenInit(activeScreen);
  }
}

//**********************************************************************************
// unlockUI:  Unlock active screen to select another
//**********************************************************************************
void unlockUI() {
  Encoder.setMin(SCREEN_HOME);
  Encoder.setMax(SCREEN_AUX);
  Encoder.setCount(activeScreen);
  screenLock = 0;
  //Reinit screen to show unlock icon hide parts not visible while locked
  screenInit(activeScreen);
}

void lockUI() {
  screenLock = 1;
  //Recall screenInit to setup encoder and other functions available only when locked
  screenInit(activeScreen);
}

//**********************************************************************************
// screenCore: Called in main loop to handle all UI functions
//**********************************************************************************
void uiCore() {
  if (!screenLock) {
    int encValue = Encoder.change();
    if (encValue >= 0) {
      activeScreen = encValue;
      screenInit(activeScreen);
    }
  }
  screenEnter(activeScreen);
  screenRefresh(activeScreen);
}

//**********************************************************************************
// screenInit: Initialize active screen
//**********************************************************************************
void screenInit(byte screen) {
  clearLCD();
  
  //Print Program Active Char (Overwritten if no program active)
  if (screen != SCREEN_HOME) {
    lcdSetCustChar_P(6, PROG_ICON);
    lcdWriteCustChar(0, 0, 6);
    lcdSetCustChar_P(5, BELL);
  }
  
  if (screen == SCREEN_HOME) {
    //Screen Init: Home
    lcdSetCustChar_P(0, BMP0);
    lcdSetCustChar_P(1, BMP1);
    lcdSetCustChar_P(2, BMP2);
    lcdSetCustChar_P(3, BMP3);
    lcdSetCustChar_P(4, BMP4);
    lcdSetCustChar_P(5, BMP5);
    lcdSetCustChar_P(6, BMP6);
    lcdWriteCustChar(0, 1, 0);
    lcdWriteCustChar(0, 2, 1);
    lcdWriteCustChar(1, 0, 2); 
    lcdWriteCustChar(1, 1, 3); 
    lcdWriteCustChar(1, 2, 255); 
    lcdWriteCustChar(2, 0, 4); 
    lcdWriteCustChar(2, 1, 5); 
    lcdWriteCustChar(2, 2, 6); 
    printLCD_P(3, 0, BT);
    printLCD_P(3, 12, BTVER);
    printLCDLPad(3, 16, itoa(BUILD, buf, 10), 4, '0');
    
  } else if (screen == SCREEN_FILL) {
    //Screen Init: Fill/Refill
    if (stepIsActive(STEP_FILL)) printLCD_P(0, 1, PSTR("Fill"));
    else if (stepIsActive(STEP_REFILL)) printLCD_P(0, 1, PSTR("Refill"));
    else printLCD_P(0, 0, PSTR("Fill"));
    printLCD_P(0, 11, PSTR("HLT"));
    printLCD_P(0, 16, PSTR("Mash"));
    printLCD_P(1, 1, PSTR("Target"));
    printLCD_P(2, 1, PSTR("Actual"));
    vftoa(tgtVol[VS_HLT], buf, 3);
    truncFloat(buf, 5);
    printLCDLPad(1, 9, buf, 5, ' ');
    vftoa(tgtVol[VS_MASH], buf, 3);
    truncFloat(buf, 5);
    printLCDLPad(1, 15, buf, 5, ' ');

    if (screenLock) {
      printLCD_P(3, 0, PSTR(">"));
      printLCD_P(3, 10, PSTR("<"));
      printLCD_P(3, 1, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(5);
      Encoder.setCount(0);
    }
    
  } else if (screen == SCREEN_MASH) {
    //Screen Init: Preheat/Mash
    //Delay Start Indication
    timerLastPrint = 0;
    
    if (stepIsActive(STEP_DELAY)) printLCD_P(0, 1, PSTR("Delay"));
    else if (stepIsActive(STEP_PREHEAT)) printLCD_P(0, 1, PSTR("Preheat"));
    else if (stepIsActive(STEP_DOUGHIN)) printLCD_P(0, 1, PSTR("Dough In"));
    else if (stepIsActive(STEP_ACID)) printLCD_P(0, 1, PSTR("Acid"));
    else if (stepIsActive(STEP_PROTEIN)) printLCD_P(0, 1, PSTR("Protein"));
    else if (stepIsActive(STEP_SACCH)) printLCD_P(0, 1, PSTR("Sacch"));
    else if (stepIsActive(STEP_SACCH2)) printLCD_P(0, 1, PSTR("Sacch2"));
    else if (stepIsActive(STEP_MASHOUT)) printLCD_P(0, 1, PSTR("Mash Out"));
    else if (stepIsActive(STEP_MASHHOLD)) printLCD_P(0, 1, PSTR("End Mash"));
    else printLCD_P(0, 0, PSTR("Mash"));
    printLCD_P(0, 11, PSTR("HLT"));
    printLCD_P(0, 16, PSTR("Mash"));
    printLCD_P(1, 1, PSTR("Target"));
    printLCD_P(2, 1, PSTR("Actual"));
    
    printLCD_P(1, 13, TUNIT);
    printLCD_P(1, 19, TUNIT);
    printLCD_P(2, 13, TUNIT);
    printLCD_P(2, 19, TUNIT);

  } else if (screen == SCREEN_SPARGE) {
    //Screen Init: Sparge
    if (stepIsActive(STEP_SPARGE)) printLCD_P(0, 1, PSTR("Sparge"));
    else if (stepIsActive(STEP_ADDGRAIN)) printLCD_P(0, 1, PSTR("Grain In"));
    else printLCD_P(0, 0, PSTR("Sparge"));
    printLCD_P(1, 1, PSTR("HLT"));
    printLCD_P(2, 1, PSTR("Mash"));
    printLCD_P(3, 1, PSTR("Kettle"));
    printLCD_P(1, 8, PSTR("---"));
    printLCD_P(2, 8, PSTR("---"));
    printLCD_P(3, 8, PSTR("---"));
    printLCD_P(1, 13, PSTR("---.---"));
    printLCD_P(2, 13, PSTR("---.---"));
    printLCD_P(3, 13, PSTR("---.---"));
    printLCD_P(1, 11, TUNIT);
    printLCD_P(2, 11, TUNIT);
    printLCD_P(3, 11, TUNIT);

    if (screenLock) {
      printLCD_P(0, 8, PSTR(">"));
      printLCD_P(0, 19, PSTR("<"));
      printLCD_P(0, 10, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(7);
      Encoder.setCount(0);
    }
    
  } else if (screen == SCREEN_BOIL) {
    //Screen Init: Boil
    timerLastPrint = 0;
    if (stepIsActive(STEP_BOIL)) printLCD_P(0, 1, PSTR("Boil"));
    else printLCD_P(0,0,PSTR("Boil"));
    printLCD_P(1, 19, TUNIT);

  if (screenLock) {
      Encoder.setMin(0);
      Encoder.setMax(PIDLIMIT_KETTLE);
      Encoder.setCount(PIDLIMIT_KETTLE);
  }

  } else if (screen == SCREEN_CHILL) {
    //Screen Init: Chill
    if (stepIsActive(STEP_CHILL)) printLCD_P(0, 1, PSTR("Chill"));
    else printLCD_P(0, 0, PSTR("Chill"));
    printLCD_P(0, 11, PSTR("Beer"));
    printLCD_P(0, 17, PSTR("H2O"));
    printLCD_P(1, 8, PSTR("In"));
    printLCD_P(2, 7, PSTR("Out"));

    printLCD_P(1, 14, TUNIT);
    printLCD_P(1, 19, TUNIT);
    printLCD_P(2, 14, TUNIT);
    printLCD_P(2, 19, TUNIT);
    
    if (screenLock) {
      printLCD_P(3, 0, PSTR(">"));
      printLCD_P(3, 11, PSTR("<"));
      printLCD_P(3, 2, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(6);
      Encoder.setCount(0);
    }

  } else if (screen == SCREEN_AUX) {
    //Screen Init: AUX
    printLCD_P(0,0,PSTR("AUX Temps"));
    printLCD_P(1,1,PSTR("AUX1"));
    printLCD_P(2,1,PSTR("AUX2"));
    printLCD_P(3,1,PSTR("AUX3"));
    printLCD_P(1, 11, TUNIT);
    printLCD_P(2, 11, TUNIT);
    printLCD_P(3, 11, TUNIT);
  }
  
  //Write Unlock symbol to upper right corner
  if (!screenLock) lcdWriteCustChar(0, 19, 7);
}

//**********************************************************************************
// screenRefresh:  Refresh active screen
//**********************************************************************************
void screenRefresh(byte screen) {
  if (screen == SCREEN_HOME) {
    //Refresh Screen: Home

  } else if (screen == SCREEN_FILL) {
    vftoa(volAvg[VS_HLT], buf, 3);
    truncFloat(buf, 5);
    printLCDLPad(2, 9, buf, 5, ' ');

    vftoa(volAvg[VS_MASH], buf, 3);
    truncFloat(buf, 5);
    printLCDLPad(2, 15, buf, 5, ' ');

    if (vlvConfig[VLV_FILLHLT] != 0 && (vlvBits & vlvConfig[VLV_FILLHLT]) == vlvConfig[VLV_FILLHLT]) printLCD_P(3, 11, PSTR("On "));
    else printLCD_P(3, 11, PSTR("Off"));

    if (vlvConfig[VLV_FILLMASH] != 0 && (vlvBits & vlvConfig[VLV_FILLMASH]) == vlvConfig[VLV_FILLMASH]) printLCD_P(3, 17, PSTR(" On"));
    else printLCD_P(3, 17, PSTR("Off"));
    
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        printLCDRPad(3, 1, "", 9, ' ');
        if (encValue == 0) printLCD_P(3, 1, CONTINUE);
        else if (encValue == 1) printLCD_P(3, 1, FILLHLT);
        else if (encValue == 2) printLCD_P(3, 1, FILLMASH);
        else if (encValue == 3) printLCD_P(3, 1, FILLBOTH);
        else if (encValue == 4) printLCD_P(3, 2, ALLOFF);
        else if (encValue == 5) printLCD_P(3, 3, MENU);
      }
    }
    
  } else if (screen == SCREEN_MASH) {
    //Refresh Screen: Preheat/Mash
    for (byte i = VS_HLT; i <= VS_MASH; i++) {
      printLCDLPad(1, i * 6 + 10, itoa(setpoint[i] / 100, buf, 10), 3, ' ');
      if (temp[i] == -32768) printLCD_P(2, i * 6 + 10, PSTR("---")); else printLCDLPad(2, i * 6 + 10, itoa(temp[i] / 100, buf, 10), 3, ' ');
      byte pct;
      if (PIDEnabled[i]) {
        pct = PIDOutput[i] / PIDCycle[i];
        if (pct == 0) strcpy_P(buf, PSTR("Off"));
        else if (pct == 100) strcpy_P(buf, PSTR(" On"));
        else { itoa(pct, buf, 10); strcat(buf, "%"); }
      } else if (heatStatus[i]) {
        strcpy_P(buf, PSTR(" On")); 
        pct = 100;
      } else {
        strcpy_P(buf, PSTR("Off"));
        pct = 0;
      }
      printLCDLPad(3, i * 6 + 11, buf, 3, ' ');
    }

    printTimer(TIMER_MASH, 3, 0);

  } else if (screen == SCREEN_SPARGE) {
    //Refresh Screen: Sparge
    #ifdef VOLUME_MANUAL
      // In manual volume mode show the target volumes instead of the current volumes
      vftoa(tgtVol[VS_HLT], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(1, 13, buf, 7, ' ');
        
      vftoa(tgtVol[VS_MASH], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(2, 13, buf, 7, ' ');
        
      vftoa(tgtVol[VS_KETTLE], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(3, 13, buf, 7, ' ');
    #else
      vftoa(volAvg[VS_HLT], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(1, 13, buf, 7, ' ');
        
      vftoa(volAvg[VS_MASH], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(2, 13, buf, 7, ' ');
        
      vftoa(volAvg[VS_KETTLE], buf, 3);
      truncFloat(buf, 7);
      printLCDLPad(3, 13, buf, 7, ' ');
    #endif
    
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        printLCDRPad(0, 9, "", 10, ' ');

        if (encValue == 0) printLCD_P(0, 10, CONTINUE);
        else if (encValue == 1) printLCD_P(0, 9, SPARGEIN);
        else if (encValue == 2) printLCD_P(0, 9, SPARGEOUT);
        else if (encValue == 3) printLCD_P(0, 9, FLYSPARGE);
        else if (encValue == 4) printLCD_P(0, 9, MASHHEAT);
        else if (encValue == 5) printLCD_P(0, 9, MASHIDLE);
        else if (encValue == 6) printLCD_P(0, 11, ALLOFF);
        else if (encValue == 7) printLCD_P(0, 12, MENU);
      }
    }
    
    for (byte i = TS_HLT; i <= TS_KETTLE; i++) if (temp[i] == -32768) printLCD_P(i + 1, 8, PSTR("---")); else printLCDLPad(i + 1, 8, itoa(temp[i] / 100, buf, 10), 3, ' ');

  } else if (screen == SCREEN_BOIL) {
    //Refresh Screen: Boil
    if (screenLock) {
      if (doAutoBoil) printLCD_P(0, 14, PSTR("  Auto"));
      else printLCD_P(0, 14, PSTR("Manual"));
    }
    
    printTimer(TIMER_BOIL, 3, 0);

    vftoa(volAvg[VS_KETTLE], buf, 3);
    truncFloat(buf, 5);
    printLCDLPad(2, 15, buf, 5, ' ');

    if (PIDEnabled[TS_KETTLE]) {
      byte pct = PIDOutput[TS_KETTLE] / PIDCycle[TS_KETTLE];
      if (pct == 0) strcpy_P(buf, PSTR("Off"));
      else if (pct == 100) strcpy_P(buf, PSTR(" On"));
      else { itoa(pct, buf, 10); strcat(buf, "%"); }
    } else if (heatStatus[TS_KETTLE]) {
      strcpy_P(buf, PSTR(" On")); 
    } else {
      strcpy_P(buf, PSTR("Off"));
    }
    printLCDLPad(3, 17, buf, 3, ' ');
    
    if (temp[TS_KETTLE] == -32768) printLCD_P(1, 16, PSTR("---")); else printLCDLPad(1, 16, itoa(temp[TS_KETTLE] / 100, buf, 10), 3, ' ');
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        doAutoBoil = 0;
        PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * encValue;
      }
      if (doAutoBoil) Encoder.setCount(PIDOutput[VS_KETTLE] / PIDCycle[VS_KETTLE]);
    }
    
  } else if (screen == SCREEN_CHILL) {
    //Refresh Screen: Chill
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        printLCDRPad(3, 1, "", 10, ' ');
        if (encValue == 0) printLCD_P(3, 2, CONTINUE);
        else if (encValue == 1) printLCD_P(3, 1, CHILLNORM);
        else if (encValue == 2) printLCD_P(3, 1, CHILLH2O);
        else if (encValue == 3) printLCD_P(3, 1, CHILLBEER);
        else if (encValue == 4) printLCD_P(3, 2, ALLOFF);
        else if (encValue == 5) printLCD_P(3, 4, PSTR("Auto"));
        else if (encValue == 6) printLCD_P(3, 3, ABORT);
      }
    }
    if (temp[TS_KETTLE] == -32768) printLCD_P(1, 11, PSTR("---")); else printLCDLPad(1, 11, itoa(temp[TS_KETTLE] / 100, buf, 10), 3, ' ');
    if (temp[TS_BEEROUT] == -32768) printLCD_P(2, 11, PSTR("---")); else printLCDLPad(2, 11, itoa(temp[TS_BEEROUT] / 100, buf, 10), 3, ' ');
    if (temp[TS_H2OIN] == -32768) printLCD_P(1, 16, PSTR("---")); else printLCDLPad(1, 16, itoa(temp[TS_H2OIN] / 100, buf, 10), 3, ' ');
    if (temp[TS_H2OOUT] == -32768) printLCD_P(2, 16, PSTR("---")); else printLCDLPad(2, 16, itoa(temp[TS_H2OOUT] / 100, buf, 10), 3, ' ');
    if ((vlvBits & vlvConfig[VLV_CHILLBEER]) == vlvConfig[VLV_CHILLBEER]) printLCD_P(3, 12, PSTR(" On")); else printLCD_P(3, 12, PSTR("Off"));
    if ((vlvBits & vlvConfig[VLV_CHILLH2O]) == vlvConfig[VLV_CHILLH2O]) printLCD_P(3, 17, PSTR(" On")); else printLCD_P(3, 17, PSTR("Off"));

  } else if (screen == SCREEN_AUX) {
    //Screen Refresh: AUX
    for (byte i = TS_AUX1; i <= TS_AUX3; i++) {
      if (temp[i] == -32768) printLCD_P(i - 5, 6, PSTR("---.-")); else {
        vftoa(temp[i], buf, 2);
        truncFloat(buf, 5);
        printLCDLPad(i - 5, 6, buf, 5, ' ');
      }
    }
  }
}


//**********************************************************************************
// screenEnter:  Check enterStatus and handle based on screenLock and activeScreen
//**********************************************************************************
void screenEnter(byte screen) {
  if (Encoder.cancel()) {
    //Unlock screens
    unlockUI();
  } else if (Encoder.ok()) {
    if (alarmStatus) setAlarm(0);
    else if (!screenLock) lockUI();
    else {
      if (screen == SCREEN_HOME) {
        byte lastOption = 0;
        while(1) {
          //Screen Enter: Home
          strcpy_P(menuopts[0], EXIT);
          strcpy_P(menuopts[1], PSTR("Edit Program"));
          strcpy_P(menuopts[2], PSTR("Start Program"));
          strcpy_P(menuopts[3], DRAIN);
          if (vlvConfigIsActive(VLV_DRAIN)) strcat_P(menuopts[3], PSTR(": On"));
          else strcat_P(menuopts[3], PSTR(": Off"));
          strcpy_P(menuopts[4], PSTR("Reset All"));
          //strcpy_P(menuopts[5], PSTR("System Info"));
          strcpy_P(menuopts[5], PSTR("System Setup"));
          #ifdef UI_NO_SETUP
            lastOption = scrollMenu("Main Menu", 5, lastOption);
          #else
            lastOption = scrollMenu("Main Menu", 6, lastOption);
          #endif
          if (lastOption == 1) editProgramMenu();
          else if (lastOption == 2) {
              startProgramMenu();
              if (activeScreen == SCREEN_FILL) {
                screenInit(activeScreen);
                break;
              }
          }
          else if (lastOption == 3) {
            //Drain
            if (vlvConfigIsActive(VLV_DRAIN)) setValves(vlvConfig[VLV_DRAIN], 0);
            else {
              if (zoneIsActive(ZONE_MASH) || zoneIsActive(ZONE_BOIL)) {
                clearLCD();
                printLCD_P(0, 0, PSTR("Cannot drain while"));
                printLCD_P(1, 0, PSTR("mash or boil zone"));
                printLCD_P(2, 0, PSTR("is active"));
                printLCD(3, 4, ">");
                printLCD_P(3, 6, CONTINUE);
                printLCD(3, 15, "<");
                while (!Encoder.ok()) brewCore();
              } else setValves(vlvConfig[VLV_DRAIN], 1);
            }
          }
          else if (lastOption == 4) {
            //Reset All
            if (confirmAbort()) {
              resetOutputs();
              clearTimer(TIMER_MASH);
              clearTimer(TIMER_BOIL);
            }
          }
#ifndef UI_NO_SETUP        
          else if (lastOption == 5) menuSetup();
#endif
          else if (lastOption == 0){
            //On exit of the Main menu go back to Splash/Home screen.
            activeScreen = SCREEN_HOME;
            screenInit(activeScreen);
            unlockUI();
            break;
          }
        }
        screenInit(activeScreen);

      } else if (screen == SCREEN_FILL) {
        //Sceeen Enter: Fill/Refill
        int encValue = Encoder.getCount();
        if (encValue == 0) continueClick();
        else if (encValue == 1) { autoValve[AV_FILL] = 0; setValves(vlvConfig[VLV_FILLMASH], 0); setValves(vlvConfig[VLV_FILLHLT], 1);}
        else if (encValue == 2) { autoValve[AV_FILL] = 0; setValves(vlvConfig[VLV_FILLHLT], 0); setValves(vlvConfig[VLV_FILLMASH], 1);}
        else if (encValue == 3) { autoValve[AV_FILL] = 0; setValves(vlvConfig[VLV_FILLHLT], 1); setValves(vlvConfig[VLV_FILLMASH], 1);}
        else if (encValue == 4) { autoValve[AV_FILL] = 0; setValves(vlvConfig[VLV_FILLHLT], 0); setValves(vlvConfig[VLV_FILLMASH], 0);}
        else if (encValue == 5) {
          strcpy_P(menuopts[0], PSTR("Auto Fill"));
          strcpy_P(menuopts[1], PSTR("HLT Target"));
          strcpy_P(menuopts[2], PSTR("Mash Target"));
          strcpy_P(menuopts[3], CONTINUE);
          strcpy_P(menuopts[4], ABORT);
          strcpy_P(menuopts[5], EXIT);
          byte lastOption = scrollMenu("Fill Menu", 6, lastOption);
          if (lastOption == 0) { if(tgtVol[VS_HLT] || tgtVol[VS_MASH]) autoValve[AV_FILL] = 1; }
          else if (lastOption == 1) tgtVol[VS_HLT] = getValue(PSTR("HLT Target Vol"), tgtVol[VS_HLT], 7, 3, 9999999, VOLUNIT);
          else if (lastOption == 2) tgtVol[VS_MASH] = getValue(PSTR("Mash Target Vol"), tgtVol[VS_MASH], 7, 3, 9999999, VOLUNIT);
          else if (lastOption == 3) continueClick();     
          else if (lastOption == 4) {
            if (confirmAbort()) {
              if (stepIsActive(STEP_FILL)) stepExit(STEP_FILL);
              else stepExit(STEP_REFILL); //Abort STEP_REFILL or manual operation
            }
          }
          screenInit(activeScreen);
        }

      } else if (screen == SCREEN_MASH) {
        //Screen Enter: Preheat/Mash
        strcpy_P(menuopts[0], PSTR("HLT Setpoint: "));
        strcat(menuopts[0], itoa(setpoint[VS_HLT] / 100, buf, 10));
        strcat_P(menuopts[0], TUNIT);
        strcpy_P(menuopts[1], PSTR("Mash Setpoint: "));
        strcat(menuopts[1], itoa(setpoint[VS_MASH] / 100, buf, 10));
        strcat_P(menuopts[1], TUNIT);
        strcpy_P(menuopts[2], PSTR("Set Timer"));
        if (timerStatus[TIMER_MASH]) strcpy_P(menuopts[3], PSTR("Pause Timer"));
        else strcpy_P(menuopts[3], PSTR("Start Timer"));
        strcpy_P(menuopts[4], CONTINUE);
        strcpy_P(menuopts[5], ABORT);
        strcpy_P(menuopts[6], EXIT);
        byte lastOption = scrollMenu("Mash Menu", 7, lastOption);
        if (lastOption == 0) setSetpoint(VS_HLT, getValue(PSTR("HLT Setpoint"), setpoint[VS_HLT] / 100, 3, 0, 255, TUNIT));
        else if (lastOption == 1) setSetpoint(VS_MASH, getValue(PSTR("Mash Setpoint"), setpoint[VS_MASH] / 100, 3, 0, 255, TUNIT));
        else if (lastOption == 2) { 
          setTimer(TIMER_MASH, getTimerValue(PSTR("Mash Timer"), timerValue[TIMER_MASH] / 60000, 1));
          //Force Preheated
          preheated[VS_MASH] = 1;
        } 
        else if (lastOption == 3) {
          pauseTimer(TIMER_MASH);
          //Force Preheated
          preheated[VS_MASH] = 1;
        } 
        else if (lastOption == 4) {
          byte brewstep = PROGRAM_IDLE;
          if (stepIsActive(STEP_DELAY)) brewstep = STEP_DELAY;
          else if (stepIsActive(STEP_DOUGHIN)) brewstep = STEP_DOUGHIN;
          else if (stepIsActive(STEP_PREHEAT)) brewstep = STEP_PREHEAT;
          else if (stepIsActive(STEP_ACID)) brewstep = STEP_ACID;
          else if (stepIsActive(STEP_PROTEIN)) brewstep = STEP_PROTEIN;
          else if (stepIsActive(STEP_SACCH)) brewstep = STEP_SACCH;
          else if (stepIsActive(STEP_SACCH2)) brewstep = STEP_SACCH2;
          else if (stepIsActive(STEP_MASHOUT)) brewstep = STEP_MASHOUT;
          else if (stepIsActive(STEP_MASHHOLD)) brewstep = STEP_MASHHOLD;
          if(brewstep != PROGRAM_IDLE) {
            if (stepAdvance(brewstep)) {
              //Failed to advance step
              stepAdvanceFailDialog();
            }
          } else activeScreen = SCREEN_SPARGE;
        } else if (lastOption == 5) {
          if (confirmAbort()) {
            if (stepIsActive(STEP_DELAY)) stepExit(STEP_DELAY);
            else if (stepIsActive(STEP_DOUGHIN)) stepExit(STEP_DOUGHIN);
            else if (stepIsActive(STEP_PREHEAT)) stepExit(STEP_PREHEAT);
            else if (stepIsActive(STEP_ACID)) stepExit(STEP_ACID);
            else if (stepIsActive(STEP_PROTEIN)) stepExit(STEP_PROTEIN);
            else if (stepIsActive(STEP_SACCH)) stepExit(STEP_SACCH);
            else if (stepIsActive(STEP_SACCH2)) stepExit(STEP_SACCH2);
            else if (stepIsActive(STEP_MASHOUT)) stepExit(STEP_MASHOUT);
            else stepExit(STEP_MASHHOLD); //Abort STEP_MASHOUT or manual operation
          }
        }
        screenInit(activeScreen);
        
      } else if (screen == SCREEN_SPARGE) {
        //Screen Enter: Sparge
        int encValue = Encoder.getCount();
        if (encValue == 0) continueClick();
        else if (encValue == 1) { resetSpargeValves(); setValves(vlvConfig[VLV_SPARGEIN], 1); }
        else if (encValue == 2) { resetSpargeValves(); setValves(vlvConfig[VLV_SPARGEOUT], 1); }
        else if (encValue == 3) { resetSpargeValves(); setValves(vlvConfig[VLV_SPARGEIN], 1); setValves(vlvConfig[VLV_SPARGEOUT], 1); }
        else if (encValue == 4) { resetSpargeValves(); setValves(vlvConfig[VLV_MASHHEAT], 1); }
        else if (encValue == 5) { resetSpargeValves();  setValves(vlvConfig[VLV_MASHIDLE], 1); }
        else if (encValue == 6) { resetSpargeValves(); }
        else if (encValue == 7) {
          strcpy_P(menuopts[0], PSTR("Auto In"));
          strcpy_P(menuopts[1], PSTR("Auto Out"));
          strcpy_P(menuopts[2], PSTR("Auto Fly"));
          strcpy_P(menuopts[3], PSTR("HLT Target"));
          strcpy_P(menuopts[4], PSTR("Kettle Target"));
          strcpy_P(menuopts[5], PSTR("Continue"));
          strcpy_P(menuopts[6], PSTR("Abort"));
          strcpy_P(menuopts[7], EXIT);
          byte lastOption = scrollMenu("Sparge Menu", 8, lastOption);
          if (lastOption == 0) { resetSpargeValves(); if(tgtVol[VS_HLT]) autoValve[AV_SPARGEIN] = 1; }
          else if (lastOption == 1) { resetSpargeValves(); if(tgtVol[VS_KETTLE]) autoValve[AV_SPARGEOUT] = 1; }
          else if (lastOption == 2) { resetSpargeValves(); if(tgtVol[VS_KETTLE]) autoValve[AV_FLYSPARGE] = 1; }
          else if (lastOption == 3) tgtVol[VS_HLT] = getValue(PSTR("HLT Target Vol"), tgtVol[VS_HLT], 7, 3, 9999999, VOLUNIT);
          else if (lastOption == 4) tgtVol[VS_KETTLE] = getValue(PSTR("Kettle Target Vol"), tgtVol[VS_KETTLE], 7, 3, 9999999, VOLUNIT);
          else if (lastOption == 5) continueClick();
          else if (lastOption == 6) {
            if (confirmAbort()) {
              if (stepIsActive(STEP_ADDGRAIN)) stepExit(STEP_ADDGRAIN);
              else stepExit(STEP_SPARGE); //Abort STEP_SPARGE or manual operation
            }
          }
          screenInit(activeScreen);
        }
       

      } else if (screen == SCREEN_BOIL) {
        //Screen Enter: Boil
        strcpy_P(menuopts[0], PSTR("Set Timer"));
        if (timerStatus[TIMER_BOIL]) strcpy_P(menuopts[1], PSTR("Pause Timer"));
        else strcpy_P(menuopts[1], PSTR("Start Timer"));
        strcpy_P(menuopts[2], PSTR("Auto Boil"));
        strcpy_P(menuopts[3], PSTR("Boil Temp: "));
        strcat(menuopts[3], itoa(getBoilTemp(), buf, 10));
        strcat_P(menuopts[3], TUNIT);
        strcpy_P(menuopts[4], PSTR("Boil Power: "));
        strcat(menuopts[4], itoa(boilPwr, buf, 10));
        strcat(menuopts[4], "%");
        strcpy_P(menuopts[5], BOILRECIRC);
        if (vlvConfigIsActive(VLV_BOILRECIRC)) strcat_P(menuopts[5], PSTR(": On"));
        else strcat_P(menuopts[5], PSTR(": Off"));
        strcpy_P(menuopts[6], CONTINUE);
        strcpy_P(menuopts[7], ABORT);
        strcpy_P(menuopts[8], EXIT);        
        byte lastOption = scrollMenu("Boil Menu", 9, lastOption);
        if (lastOption == 0) {
          setTimer(TIMER_BOIL, getTimerValue(PSTR("Boil Timer"), timerValue[TIMER_BOIL] / 60000, 2));
          //Force Preheated
          preheated[VS_KETTLE] = 1;
        } 
        else if (lastOption == 1) {
          pauseTimer(TIMER_BOIL);
          //Force Preheated
          preheated[VS_KETTLE] = 1;
        } 
        else if (lastOption == 2) doAutoBoil = 1;
        else if (lastOption == 3) {
          setBoilTemp(getValue(PSTR("Boil Temp"), getBoilTemp(), 3, 0, 255, TUNIT));
          setSetpoint(VS_KETTLE, getBoilTemp());
        }
        else if (lastOption == 4) setBoilPwr(getValue(PSTR("Boil Power"), boilPwr, 3, 0, min(PIDLIMIT_KETTLE, 100), PSTR("%")));
        else if (lastOption == 5) {
          if (vlvConfigIsActive(VLV_BOILRECIRC)) setValves(vlvConfig[VLV_BOILRECIRC], 0);
          else setValves(vlvConfig[VLV_BOILRECIRC], 1);
        } else if (lastOption == 6) {
          byte brewstep = PROGRAM_IDLE;
          if (stepIsActive(STEP_BOIL)) brewstep = STEP_BOIL;
          if(brewstep != PROGRAM_IDLE) {
            if (stepAdvance(brewstep)) {
              //Failed to advance step
              stepAdvanceFailDialog();
            }
          } else {
            activeScreen = SCREEN_CHILL;
            screenInit(activeScreen);
          }
        } else if (lastOption == 7) { if (confirmAbort()) stepExit(STEP_BOIL); }
        screenInit(activeScreen);
        
      } else if (screen == SCREEN_CHILL) {
        //Screen Enter: Chill

        int encValue = Encoder.getCount();
        if (encValue == 0) {
          stepExit(STEP_CHILL);
          activeScreen = SCREEN_HOME;
          screenInit(activeScreen);
        }
        else if (encValue == 1) { autoValve[AV_CHILL] = 0; setValves(vlvConfig[VLV_CHILLH2O], 1); setValves(vlvConfig[VLV_CHILLBEER], 1); }
        else if (encValue == 2) { autoValve[AV_CHILL] = 0; setValves(vlvConfig[VLV_CHILLBEER], 0); setValves(vlvConfig[VLV_CHILLH2O], 1); }
        else if (encValue == 3) { autoValve[AV_CHILL] = 0; setValves(vlvConfig[VLV_CHILLH2O], 0); setValves(vlvConfig[VLV_CHILLBEER], 1); }
        else if (encValue == 4) { autoValve[AV_CHILL] = 0; setValves(vlvConfig[VLV_CHILLH2O], 0); setValves(vlvConfig[VLV_CHILLBEER], 0); }
        else if (encValue == 5) autoValve[AV_CHILL] = 1;        
      }
    }
  }
}

void continueClick() {
  byte brewstep = PROGRAM_IDLE;
  if (stepIsActive(STEP_FILL)) brewstep = STEP_FILL;
  else if (stepIsActive(STEP_REFILL)) brewstep = STEP_REFILL;
  else if (stepIsActive(STEP_SPARGE)) brewstep = STEP_SPARGE;
  else if (stepIsActive(STEP_ADDGRAIN)) brewstep = STEP_ADDGRAIN;
  if(brewstep != PROGRAM_IDLE) {
    if (stepAdvance(brewstep)) {
      //Failed to advance step
      stepAdvanceFailDialog();
    }
  } else activeScreen = activeScreen + 1; 
  screenInit(activeScreen); 
}

void resetSpargeValves() {
  autoValve[AV_SPARGEIN] = 0;
  autoValve[AV_SPARGEOUT] = 0;
  autoValve[AV_FLYSPARGE] = 0;
  setValves(vlvConfig[VLV_SPARGEIN], 0);
  setValves(vlvConfig[VLV_SPARGEOUT], 0);
  setValves(vlvConfig[VLV_MASHHEAT], 0);
  setValves(vlvConfig[VLV_MASHIDLE], 0);
}

void stepAdvanceFailDialog() {
  clearLCD();
  printLCD_P(0, 0, PSTR("Failed to advance"));
  printLCD_P(1, 0, PSTR("program."));
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!Encoder.ok()) brewCore();
}

void editProgramMenu() {
  for (byte i = 0; i < 20; i++) getProgName(i, menuopts[i]);
  byte profile = scrollMenu("Edit Program", 20, profile);
  if (profile < 20) {
    getString(PSTR("Program Name:"), menuopts[profile], 19);
    setProgName(profile, menuopts[profile]);
    editProgram(profile);
  }
}

void startProgramMenu() {
  for (byte i = 0; i < 20; i++) getProgName(i, menuopts[i]);
  byte profile = scrollMenu("Start Program", 20, 0);
  if (profile < 20) {
    byte lastOption = 0; 
    while(1) {
      unsigned long spargeVol = calcSpargeVol(profile);
      unsigned long mashVol = calcStrikeVol(profile);
      unsigned long grainVol = calcGrainVolume(profile);
      unsigned long preboilVol = calcPreboilVol(profile);
      if (spargeVol > getCapacity(TS_HLT)) warnHLT(spargeVol);
      if (mashVol + grainVol > getCapacity(TS_MASH)) warnMash(mashVol, grainVol);
      if (preboilVol > getCapacity(TS_KETTLE)) warnBoil(preboilVol);
      
      strcpy_P(menuopts[0], PSTR("Edit Program"));
      strcpy_P(menuopts[1], PSTR("Grain Temp:"));
        strncat(menuopts[1], itoa(getGrainTemp(), buf, 10), 3);
        strcat_P(menuopts[1], TUNIT);
      strcpy_P(menuopts[2], PSTR("Start"));
      strcpy_P(menuopts[3], PSTR("Delay Start"));
      strcpy_P(menuopts[4], EXIT);
      char progName[20];
      getProgName(profile, progName);
      lastOption = scrollMenu(progName, 5, lastOption);
      if (lastOption == 0) editProgram(profile);
      else if (lastOption == 1) setGrainTemp(getValue(PSTR("Grain Temp"), getGrainTemp(), 3, 0, 255, TUNIT)); 
      else if (lastOption == 2 || lastOption == 3) {
        if (zoneIsActive(ZONE_MASH)) {
          clearLCD();
          printLCD_P(0, 0, PSTR("Cannot start program"));
          printLCD_P(1, 0, PSTR("while mash zone is"));
          printLCD_P(2, 0, PSTR("active."));
          printLCD(3, 4, ">");
          printLCD_P(3, 6, CONTINUE);
          printLCD(3, 15, "<");
          while (!Encoder.ok()) brewCore();
        } else {
          if (lastOption == 3) {
            //Delay Start
            setDelayMins(getTimerValue(PSTR("Delay Start"), getDelayMins(), 23));
          }
          if (stepInit(profile, STEP_FILL)) {
            clearLCD();
            printLCD_P(1, 0, PSTR("Program start failed"));
            printLCD(3, 4, ">");
            printLCD_P(3, 6, CONTINUE);
            printLCD(3, 15, "<");
            while (!Encoder.ok()) brewCore();
          } else {
            activeScreen = SCREEN_FILL;
            //screenInit called by screenEnter upon return
            break;
          }
        }
      } else break;
    }
  }
}

void editProgram(byte pgm) {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], PSTR("Batch Vol:"));
    strcpy_P(menuopts[1], PSTR("Grain Wt:"));
    strcpy_P(menuopts[2], PSTR("Boil Length:"));
    strcpy_P(menuopts[3], PSTR("Mash Ratio:"));
    strcpy_P(menuopts[4], PSTR("HLT Temp:"));
    strcpy_P(menuopts[5], PSTR("Sparge Temp:"));
    strcpy_P(menuopts[6], PSTR("Pitch Temp:"));
    strcpy_P(menuopts[7], PSTR("Mash Schedule"));
    strcpy_P(menuopts[8], PSTR("Heat Strike In:"));    
    strcpy_P(menuopts[9], BOILADDS);    
    strcpy_P(menuopts[10], EXIT);

    vftoa(getProgBatchVol(pgm), buf, 3);
    truncFloat(buf, 5);
    strcat(menuopts[0], buf);
    strcat_P(menuopts[0], VOLUNIT);

    vftoa(getProgGrain(pgm), buf, 3);
    truncFloat(buf, 7);
    strcat(menuopts[1], buf);
    strcat_P(menuopts[1], WTUNIT);

    strncat(menuopts[2], itoa(getProgBoil(pgm), buf, 10), 3);
    strcat_P(menuopts[2], PSTR(" min"));
    
    vftoa(getProgRatio(pgm), buf, 2);
    truncFloat(buf, 4);
    strcat(menuopts[3], buf);
    strcat_P(menuopts[3], PSTR(":1"));

    strncat(menuopts[4], itoa(getProgHLT(pgm), buf, 10), 3);
    strcat_P(menuopts[4], TUNIT);
    
    strncat(menuopts[5], itoa(getProgSparge(pgm), buf, 10), 3);
    strcat_P(menuopts[5], TUNIT);
    
    strncat(menuopts[6], itoa(getProgPitch(pgm), buf, 10), 3);
    strcat_P(menuopts[6], TUNIT);
    {
      byte MLHeatSrc = getProgMLHeatSrc(pgm);
      if (MLHeatSrc == VS_HLT) strcat_P(menuopts[8], PSTR("HLT"));
      else if (MLHeatSrc == VS_MASH) strcat_P(menuopts[8], PSTR("MASH"));
      else strcat_P(menuopts[8], PSTR("UNKWN"));
    }
    lastOption = scrollMenu("Program Parameters", 11, lastOption);
    if (lastOption == 0) setProgBatchVol(pgm, getValue(PSTR("Batch Volume"), getProgBatchVol(pgm), 7, 3, 9999999, VOLUNIT));
    else if (lastOption == 1) setProgGrain(pgm, getValue(PSTR("Grain Weight"), getProgGrain(pgm), 7, 3, 9999999, WTUNIT));
    else if (lastOption == 2) setProgBoil(pgm, getTimerValue(PSTR("Boil Length"), getProgBoil(pgm), 2));
    else if (lastOption == 3) { 
      #ifdef USEMETRIC
        setProgRatio(pgm, getValue(PSTR("Mash Ratio"), getProgRatio(pgm), 3, 2, 999, PSTR(" l/kg"))); 
      #else
        setProgRatio(pgm, getValue(PSTR("Mash Ratio"), getProgRatio(pgm), 3, 2, 999, PSTR(" qts/lb")));
      #endif
    }
    else if (lastOption == 4) setProgHLT(pgm, getValue(PSTR("HLT Setpoint"), getProgHLT(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 5) setProgSparge(pgm, getValue(PSTR("Sparge Temp"), getProgSparge(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 6) setProgPitch(pgm, getValue(PSTR("Pitch Temp"), getProgPitch(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 7) editMashSchedule(pgm);
    else if (lastOption == 8) setProgMLHeatSrc(pgm, MLHeatSrcMenu(getProgMLHeatSrc(pgm)));
    else if (lastOption == 9) setProgAdds(pgm, editHopSchedule(getProgAdds(pgm)));
    else return;
    unsigned long spargeVol = calcSpargeVol(pgm);
    unsigned long mashVol = calcStrikeVol(pgm);
    unsigned long grainVol = calcGrainVolume(pgm);
    unsigned long preboilVol = calcPreboilVol(pgm);
    if (spargeVol > getCapacity(TS_HLT)) warnHLT(spargeVol);
    if (mashVol + grainVol > getCapacity(TS_MASH)) warnMash(mashVol, grainVol);
    if (preboilVol > getCapacity(TS_KETTLE)) warnBoil(preboilVol);
  }
}

void editMashSchedule(byte pgm) {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], PSTR("Dough In:"));
    strcpy_P(menuopts[1], PSTR("Dough In:"));
    strcpy_P(menuopts[2], PSTR("Acid Rest:"));
    strcpy_P(menuopts[3], PSTR("Acid Rest:"));
    strcpy_P(menuopts[4], PSTR("Protein Rest:"));
    strcpy_P(menuopts[5], PSTR("Protein Rest:"));
    strcpy_P(menuopts[6], PSTR("Sacch Rest:"));
    strcpy_P(menuopts[7], PSTR("Sacch Rest:"));
    strcpy_P(menuopts[8], PSTR("Sacch2 Rest:"));
    strcpy_P(menuopts[9], PSTR("Sacch2 Rest:"));
    strcpy_P(menuopts[10], PSTR("Mash Out:"));
    strcpy_P(menuopts[11], PSTR("Mash Out:"));
    strcpy_P(menuopts[12], EXIT);

    for (byte i = MASH_DOUGHIN; i <= MASH_MASHOUT; i++) {  
      strncat(menuopts[i * 2], itoa(getProgMashMins(pgm, i), buf, 10), 3);
      strcat(menuopts[i * 2], " min");

      strncat(menuopts[i * 2 + 1], itoa(getProgMashTemp(pgm, i), buf, 10), 3);
      strcat_P(menuopts[i * 2 + 1], TUNIT);
    }
    
    lastOption = scrollMenu("Mash Schedule", 13, lastOption);
    if (lastOption == 0) setProgMashMins(pgm, MASH_DOUGHIN, getTimerValue(PSTR("Dough In"), getProgMashMins(pgm, MASH_DOUGHIN), 1));
    else if (lastOption == 1) setProgMashTemp(pgm, MASH_DOUGHIN, getValue(PSTR("Dough In"), getProgMashTemp(pgm, MASH_DOUGHIN), 3, 0, 255, TUNIT));
    else if (lastOption == 2) setProgMashMins(pgm, MASH_ACID, getTimerValue(PSTR("Acid Rest"), getProgMashMins(pgm, MASH_ACID), 1));
    else if (lastOption == 3) setProgMashTemp(pgm, MASH_ACID, getValue(PSTR("Acid Rest"), getProgMashTemp(pgm, MASH_ACID), 3, 0, 255, TUNIT));
    else if (lastOption == 4) setProgMashMins(pgm, MASH_PROTEIN, getTimerValue(PSTR("Protein Rest"), getProgMashMins(pgm, MASH_PROTEIN), 1));
    else if (lastOption == 5) setProgMashTemp(pgm, MASH_PROTEIN, getValue(PSTR("Protein Rest"), getProgMashTemp(pgm, MASH_PROTEIN), 3, 0, 255, TUNIT));
    else if (lastOption == 6) setProgMashMins(pgm, MASH_SACCH, getTimerValue(PSTR("Sacch Rest"), getProgMashMins(pgm, MASH_SACCH), 1));
    else if (lastOption == 7) setProgMashTemp(pgm, MASH_SACCH, getValue(PSTR("Sacch Rest"), getProgMashTemp(pgm, MASH_SACCH), 3, 0, 255, TUNIT));
    else if (lastOption == 8) setProgMashMins(pgm, MASH_SACCH2, getTimerValue(PSTR("Sacch2 Rest"), getProgMashMins(pgm, MASH_SACCH2), 1));
    else if (lastOption == 9) setProgMashTemp(pgm, MASH_SACCH2, getValue(PSTR("Sacch2 Rest"), getProgMashTemp(pgm, MASH_SACCH2), 3, 0, 255, TUNIT));
    else if (lastOption == 10) setProgMashMins(pgm, MASH_MASHOUT, getTimerValue(PSTR("Mash Out"), getProgMashMins(pgm, MASH_MASHOUT), 1));
    else if (lastOption == 11) setProgMashTemp(pgm, MASH_MASHOUT, getValue(PSTR("Mash Out"), getProgMashTemp(pgm, MASH_MASHOUT), 3, 0, 255, TUNIT));
    else return;
  }
}

unsigned int editHopSchedule (unsigned int sched) {
  unsigned int retVal = sched;
  byte lastOption = 0;
  while (1) {
    if (retVal & 1) strcpy_P(menuopts[0], PSTR("At Boil: On")); else strcpy_P(menuopts[0], PSTR("At Boil: Off"));
    for (byte i = 0; i < 10; i++) {
      strcpy(menuopts[i + 1], itoa(hoptimes[i], buf, 10));
      if (i == 0) strcat_P(menuopts[i + 1], PSTR(" Min: "));
      else if (i < 9) strcat_P(menuopts[i + 1], PSTR("  Min: "));
      else strcat_P(menuopts[i + 1], PSTR("   Min: "));
      if (retVal & (1<<(i + 1))) strcat_P(menuopts[i + 1], PSTR("On")); else strcat_P(menuopts[i + 1], PSTR("Off"));
    }
    if (retVal & 2048) strcpy_P(menuopts[11], PSTR("0   Min: On")); else strcpy_P(menuopts[11], PSTR("0   Min: Off"));
    strcpy_P(menuopts[12], EXIT);

    lastOption = scrollMenu("Boil Additions", 13, lastOption);
    if (lastOption == 12) return retVal;
    else if (lastOption == 13) return sched;
    else retVal = retVal ^ (1 << lastOption);
  }
}

byte MLHeatSrcMenu(byte MLHeatSrc) {
  strcpy_P(menuopts[0], HLTDESC);
  strcpy_P(menuopts[1], MASHDESC);
  byte lastOption = scrollMenu("Heat Strike In:", 2, MLHeatSrc);
  if (lastOption > 1) return MLHeatSrc;
  else return lastOption;
}

void warnHLT(unsigned long spargeVol) {
  clearLCD();
  printLCD_P(0, 0, PSTR("HLT Capacity Issue"));
  printLCD_P(1, 0, PSTR("Sparge Vol:"));
  vftoa(spargeVol, buf, 3);
  truncFloat(buf, 5);
  printLCD(1, 11, buf);
  printLCD_P(1, 16, VOLUNIT);
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!Encoder.ok()) brewCore();
}


void warnMash(unsigned long mashVol, unsigned long grainVol) {
  clearLCD();
  printLCD_P(0, 0, PSTR("Mash Capacity Issue"));
  printLCD_P(1, 0, PSTR("Strike Vol:"));
  vftoa(mashVol, buf, 3);
  truncFloat(buf, 5);
  printLCD(1, 11, buf);
  printLCD_P(1, 16, VOLUNIT);
  printLCD_P(2, 0, PSTR("Grain Vol:"));
  vftoa(grainVol, buf, 3);
  truncFloat(buf, 5);
  printLCD(2, 11, buf);
  printLCD_P(2, 16, VOLUNIT);
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!Encoder.ok()) brewCore();
}

void warnBoil(unsigned long preboilVol) {
  clearLCD();
  printLCD_P(0, 0, PSTR("Boil Capacity Issue"));
  printLCD_P(1, 0, PSTR("Preboil Vol:"));
  vftoa(preboilVol, buf, 3);
  truncFloat(buf, 5);
  printLCD(1, 12, buf);
  printLCD_P(1, 17, VOLUNIT);
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!Encoder.ok()) brewCore();
}

//*****************************************************************************************************************************
//Generic Menu Functions
//*****************************************************************************************************************************
byte scrollMenu(char sTitle[], byte numOpts, byte defOption) {
  //Uses Global menuopts[][20]
  Encoder.setMin(0);
  Encoder.setMax(numOpts - 1);
  Encoder.setCount(defOption);
  byte topItem = numOpts;
  boolean redraw = 1;
  
  int encValue;
  while(1) {
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    } else encValue = Encoder.change();
    
    if (encValue >= 0) {
      //There is a new value for the encoder.
      if (encValue < topItem) {
        //Scrolling the menu up!
        topItem = encValue; //The first menu item to display.
      } else if (encValue > topItem + 2) {
        //Scrolling the menu down!
        topItem = encValue - 2; //Scroll the menu down by only one new menu item.
      }
      //Display a new menu or refresh the cursor location (encoder).
      drawMenu(sTitle, numOpts, topItem, encValue);
    }
    
    //If Enter
    if (Encoder.ok()) {
      return Encoder.getCount();
    } else if (Encoder.cancel()) {
      return numOpts;
    }
    brewCore();
  }
}

void drawMenu(char sTitle[], byte numOpts, byte topItem, int encValue) {
  clearLCD();
  if (sTitle != NULL) printLCD(0, 0, sTitle);
  drawItems(numOpts, topItem, encValue);
}

void drawItems(byte numOpts, byte topItem, int encValue) {
  //numOpts: Total of menu items for that menu.
  //topItem: The first menu item to display using the list numeric value (from 0 - X) (not the position in the menu from 1 to X).
  //Uses Global menuopts[][20]
  byte maxOpt;
  
  if (numOpts < 3) {
    //Only two of less menu item to display.
    topItem = 0;
    maxOpt = numOpts - 1; 
  } else if (topItem > numOpts - 3){
    //The first item to display is at the bottom of the list. Move the selection sightly up do display a full page of menu items, meaning the last three.
    topItem = numOpts - 3; //Select a new top item to display in order to display a full page of menu items.
    maxOpt = topItem + 2;
  } else {
    //Will only display the first 3 menu items that includes the "topItem".
    maxOpt = topItem + 2;
  }
  //Display menu items.
  for (byte i = topItem; i <= maxOpt; i++) printLCD(i-topItem+1, 1, menuopts[i]);

  //Display encoder position ">".
  for (byte i = 1; i <= 3; i++) if (i == encValue - topItem + 1) printLCD(i, 0, ">"); else printLCD(i, 0, " "); 
}

byte getChoice(byte numChoices, byte iRow) {
  //Uses Global menuopts[][20]
  //Force 18 Char Limit
  for (byte i = 0; i < numChoices; i++) menuopts[i][18] = '\0';
  printLCD_P(iRow, 0, PSTR(">"));
  printLCD_P(iRow, 19, PSTR("<"));
  Encoder.setMin(0);
  Encoder.setMax(numChoices - 1);
  Encoder.setCount(0);
  boolean redraw = 1;
  
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      printLCDCenter(iRow, 1, menuopts[encValue], 18);
    }
    
    //If Enter
    if (Encoder.ok()) {
      printLCD_P(iRow, 0, SPACE);
      printLCD_P(iRow, 19, SPACE);
      return Encoder.getCount();
    } else if (Encoder.cancel()) {
      return numChoices;
    }
    brewCore();
  }
}

boolean confirmAbort() {
  clearLCD();
  printLCD_P(0, 0, PSTR("Abort operation and"));
  printLCD_P(1, 0, PSTR("reset setpoints,"));
  printLCD_P(2, 0, PSTR("timers and outputs?"));
  strcpy_P(menuopts[0], CANCEL);
  strcpy_P(menuopts[1], PSTR("Reset"));
  if(getChoice(2, 3) == 1) return 1; else return 0;
}

boolean confirmDel() {
  clearLCD();
  printLCD_P(1, 0, PSTR("Delete Item?"));
  
  strcpy_P(menuopts[0], CANCEL);
  strcpy_P(menuopts[1], PSTR("Delete"));
  if(getChoice(2, 3) == 1) return 1; else return 0;
}


unsigned long getValue(const char *sTitle, unsigned long defValue, byte digits, byte precision, unsigned long maxValue, const char *dispUnit) {
  unsigned long retValue = defValue;
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected

  //Workaround for odd memory issue
  //availableMemory();

  Encoder.setMin(0);
  Encoder.setMax(digits);
  Encoder.setCount(0);

  lcdSetCustChar_P(0, CHARFIELD);
  lcdSetCustChar_P(1, CHARCURSOR);
  lcdSetCustChar_P(2, CHARSEL);
   
  clearLCD();
  printLCD_P(0, 0, sTitle);
  printLCD_P(1, (20 - digits + 1) / 2 + digits + 1, dispUnit);
  printLCD_P(3, 9, OK);
  unsigned long whole, frac;
  boolean redraw = 1;
  
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        unsigned long factor = 1;
        for (byte i = 0; i < digits - cursorPos - 1; i++) factor *= 10;
        //Subtract old digit value
        retValue -= (int (retValue / factor) - int (retValue / (factor * 10)) * 10) * factor;
        //Add new value
        retValue += encValue * factor;
        retValue = min(retValue, maxValue);
      } else {
        cursorPos = encValue;
        for (byte i = (20 - digits + 1) / 2 - 1; i < (20 - digits + 1) / 2 - 1 + digits - precision; i++) lcdWriteCustChar(2, i, 0);
        if (precision) for (byte i = (20 - digits + 1) / 2 + digits - precision; i < (20 - digits + 1) / 2 + digits; i++) lcdWriteCustChar(2, i, 0);
        printLCD(3, 8, " ");
        printLCD(3, 11, " ");
        if (cursorPos == digits) {
          printLCD(3, 8, ">");
          printLCD(3, 11, "<");
        } else {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos - 1, 1);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos, 1);
        }
      }
      whole = retValue / pow(10, precision);
      frac = retValue - (whole * pow(10, precision)) ;
      printLCDLPad(1, (20 - digits + 1) / 2 - 1, ltoa(whole, buf, 10), digits - precision, ' ');
      if (precision) {
        printLCD(1, (20 - digits + 1) / 2 + digits - precision - 1, ".");
        printLCDLPad(1, (20 - digits + 1) / 2 + digits - precision, ltoa(frac, buf, 10), precision, '0');
      }
    }
    
    if (Encoder.ok()) {
      if (cursorPos == digits) break;
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos - 1, 2);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos, 2);
          Encoder.setMin(0);
          Encoder.setMax(9);

          if (cursorPos < digits - precision) {
            ltoa(whole, buf, 10);
            if (cursorPos < digits - precision - strlen(buf)) Encoder.setCount(0); else  Encoder.setCount(buf[cursorPos - (digits - precision - strlen(buf))] - '0');
          } else {
            ltoa(frac, buf, 10);
            if (cursorPos < digits - strlen(buf)) Encoder.setCount(0); else  Encoder.setCount(buf[cursorPos - (digits - strlen(buf))] - '0');
          }
        } else {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos - 1, 1);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos, 1);
          Encoder.setMin(0);
          Encoder.setMax(digits);
          Encoder.setCount(cursorPos);
        }
      }
    } else if (Encoder.cancel()) {
      retValue = defValue;
      break;
    }
    brewCore();
  }
  return retValue;
}

void printTimer(byte timer, byte iRow, byte iCol) {
  if (timerValue[timer] > 0 && !timerStatus[timer]) printLCD(iRow, iCol, "PAUSED");
  else if (alarmStatus || timerStatus[timer]) {
    byte hours = timerValue[timer] / 3600000;
    byte mins = (timerValue[timer] - hours * 3600000) / 60000;
    byte secs = (timerValue[timer] - hours * 3600000 - mins * 60000) / 1000;

    //Update LCD once per second
    if (millis() - timerLastPrint >= 1000) {
      timerLastPrint = millis();
      printLCDRPad(iRow, iCol, "", 6, ' ');
      printLCD_P(iRow, iCol+2, PSTR(":  :"));
      printLCDLPad(iRow, iCol, itoa(hours, buf, 10), 2, '0');
      printLCDLPad(iRow, iCol + 3, itoa(mins, buf, 10), 2, '0');
      printLCDLPad(iRow, iCol + 6, itoa(secs, buf, 10), 2, '0');
      if (alarmStatus) lcdWriteCustChar(iRow, iCol + 8, 5);
    }
  } else printLCDRPad(iRow, iCol, "", 9, ' ');
}

int getTimerValue(const char *sTitle, int defMins, byte maxHours) {
  byte hours = defMins / 60;
  byte mins = defMins - hours * 60;
  byte cursorPos = 0; //0 = Hours, 1 = Mins, 2 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  Encoder.setMin(0);
  Encoder.setMax(2);
  Encoder.setCount(0);
  
  clearLCD();
  printLCD_P(0,0,sTitle);
  printLCD(1, 7, "(hh:mm)");
  printLCD(2, 10, ":");
  printLCD_P(3, 9, OK);
  boolean redraw = 1;
  int encValue;
 
  while(1) {
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    } else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        if (cursorPos) mins = encValue; else hours = encValue;
      } else {
        cursorPos = encValue;
        switch (cursorPos) {
          case 0: //hours
            printLCD(2, 7, ">");
            printLCD(2, 13, " ");
            printLCD(3, 8, " ");
            printLCD(3, 11, " ");
            break;
          case 1: //mins
            printLCD(2, 7, " ");
            printLCD(2, 13, "<");
            printLCD(3, 8, " ");
            printLCD(3, 11, " ");
            break;
          case 2: //OK
            printLCD(2, 7, " ");
            printLCD(2, 13, " ");
            printLCD(3, 8, ">");
            printLCD(3, 11, "<");
            break;
        }
      }
      printLCDLPad(2, 8, itoa(hours, buf, 10), 2, '0');
      printLCDLPad(2, 11, itoa(mins, buf, 10), 2, '0');
    }
    
    if (Encoder.ok()) {
      if (cursorPos == 2) return hours * 60 + mins;
      cursorState = cursorState ^ 1; //Toggles between value editing mode and cursor navigation.
      if (cursorState) {
        //Edition mode
        Encoder.setMin(0);
        if (cursorPos) {
          //Editing minutes
          Encoder.setMax(59);
          Encoder.setCount(mins); 
        } else {
          //Editing hours
          Encoder.setMax(maxHours);
          Encoder.setCount(hours);
        }
      } else {
        Encoder.setMin(0);
        Encoder.setMax(2);
        Encoder.setCount(cursorPos);
      }
    } else if (Encoder.cancel()) return -1; //This value will be validated in SetTimerValue. SetTimerValue will reject the storage of the timer value. 
    brewCore();
  }
}

void getString(const char *sTitle, char defValue[], byte chars) {
  char retValue[20];
  strcpy(retValue, defValue);
  
  //Right-Pad with spaces
  boolean doWipe = 0;
  for (byte i = 0; i < chars; i++) {
    if (retValue[i] < 32 || retValue[i] > 126) doWipe = 1;
    if (doWipe) retValue[i] = 32;
  }
  retValue[chars] = '\0';
  
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  Encoder.setMin(0);
  Encoder.setMax(chars);
  Encoder.setCount(0);


  lcdSetCustChar_P(0, CHARFIELD);
  lcdSetCustChar_P(1, CHARCURSOR);
  lcdSetCustChar_P(2, CHARSEL);
  
  clearLCD();
  printLCD_P(0,0,sTitle);
  printLCD_P(3, 9, OK);
  boolean redraw = 1;
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        retValue[cursorPos] = enc2ASCII(encValue);
      } else {
        cursorPos = encValue;
        for (byte i = (20 - chars + 1) / 2 - 1; i < (20 - chars + 1) / 2 - 1 + chars; i++) lcdWriteCustChar(2, i, 0);
        printLCD(3, 8, " ");
        printLCD(3, 11, " ");
        if (cursorPos == chars) {
          printLCD(3, 8, ">");
          printLCD(3, 11, "<");
        } else {
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 1);
        }
      }
      printLCD(1, (20 - chars + 1) / 2 - 1, retValue);
    }
    
    if (Encoder.ok()) {
      if (cursorPos == chars) {
        strcpy(defValue, retValue);
        return;
      }
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          Encoder.setMin(0);
          Encoder.setMax(94);
          Encoder.setCount(ASCII2enc(retValue[cursorPos]));
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 2);
        } else {
          Encoder.setMin(0);
          Encoder.setMax(chars);
          Encoder.setCount(cursorPos);
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 1);
        }
      }
    } else if (Encoder.cancel()) return;
    brewCore();
  }
}

//Next two functions used to change order of charactor scroll to (space), A-Z, a-z, 0-9, symbols
byte ASCII2enc(byte charin) {
  if (charin == 32) return 0;
  else if (charin >= 65 && charin <= 90) return charin - 64;
  else if (charin >= 97 && charin <= 122) return charin - 70;
  else if (charin >= 48 && charin <= 57) return charin + 5;
  else if (charin >= 33 && charin <= 47) return charin + 30;
  else if (charin >= 58 && charin <= 64) return charin + 20;
  else if (charin >= 91 && charin <= 96) return charin - 6;
  else if (charin >= 123 && charin <= 126) return charin - 32;
}

byte enc2ASCII(byte charin) {
  if (charin == 0) return 32;
  else if (charin >= 1 && charin <= 26) return charin + 64;  //Scan uper case alphabet
  else if (charin >= 27 && charin <= 52) return charin + 70; //Scan lower case alphabet
  else if (charin >= 53 && charin <= 62) return charin - 5;  //Scan number
  else if (charin >= 63 && charin <= 77) return charin - 30; //Scan special character from space
  else if (charin >= 78 && charin <= 84) return charin - 20; //Scan special character :
  else if (charin >= 85 && charin <= 90) return charin + 6;  //Scan special character from [
  else if (charin >= 91 && charin <= 94) return charin + 32; //Scan special character from {
}

//*****************************************************************************************************************************
// System Setup Menus
//*****************************************************************************************************************************
#ifndef UI_NO_SETUP
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
          initEEPROM();
          checkConfig();
        }
    } else return;
  }
}

void assignSensor() {
  Encoder.setMin(0);
  Encoder.setMax(8);
  Encoder.setCount(0);
  
  char dispTitle[9][21];
  strcpy_P(dispTitle[0], HLTDESC);
  strcpy_P(dispTitle[1], MASHDESC);
  strcpy_P(dispTitle[2], PSTR("Brew Kettle"));
  strcpy_P(dispTitle[3], PSTR("H2O In"));
  strcpy_P(dispTitle[4], PSTR("H2O Out"));
  strcpy_P(dispTitle[5], PSTR("Beer Out"));
  strcpy_P(dispTitle[6], PSTR("AUX 1"));
  strcpy_P(dispTitle[7], PSTR("AUX 2"));
  strcpy_P(dispTitle[8], PSTR("AUX 3"));
  boolean redraw = 1;
  int encValue, oldEncValue;
  
  while (1) {
    if (redraw) {
      //First time entry or back from the sub-menu.
      redraw = 0;
      encValue = Encoder.getCount();
    } else encValue = Encoder.change();
    
    if (encValue >= 0) {
      //The user has navigated toward a new temperature probe screen.
      oldEncValue = encValue;  //Will allow partial screen refresh when viewing the same screen.
      clearLCD();
      printLCD_P(0, 0, PSTR("Assign Temp Sensor"));
      printLCDCenter(1, 0, dispTitle[encValue], 20);
      for (byte i=0; i<8; i++) printLCDLPad(2,i*2+2,itoa(tSensor[encValue][i], buf, 16), 2, '0');  
      displayAssignSensorTemp(encValue);
    } else {
      //The user is still viewing the same screen (no change on the static data but refresh the temperature value).
        displayAssignSensorTemp(oldEncValue);  //Only refresh the current screen.
    }
    if (Encoder.cancel()) return;
    else if (Encoder.ok()) {
      encValue = Encoder.getCount();
      //Pop-Up Menu
      strcpy_P(menuopts[0], PSTR("Scan Bus"));
      strcpy_P(menuopts[1], PSTR("Delete Address"));
      strcpy_P(menuopts[2], CANCEL);
      strcpy_P(menuopts[3], EXIT);
      byte selected = scrollMenu(dispTitle[encValue], 4, 0);
      if (selected == 0) {
        clearLCD();
        printLCDCenter(0, 0, dispTitle[encValue], 20);
        printLCD_P(1,0,PSTR("Disconnect all other"));
        printLCD_P(2,2,PSTR("temp sensors now"));
        {
          strcpy_P(menuopts[0], CONTINUE);
          strcpy_P(menuopts[1], CANCEL);
          if (getChoice(2, 3) == 0) {
            byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
            getDSAddr(addr);
            setTSAddr(encValue, addr);
          }
        }
      } else if (selected == 1) {
        byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        setTSAddr(encValue, addr);
      }
      else if (selected > 2) return;

      Encoder.setMin(0);
      Encoder.setMax(8);
      Encoder.setCount(encValue);
      redraw = 1;
    }
    brewCore();
  }
}

void displayAssignSensorTemp(int encValue) {
  printLCD_P(3, 10, TUNIT); 
  if (temp[encValue] == -32768) {
    printLCD_P(3, 7, PSTR("---"));
  } else {
    printLCDLPad(3, 7, itoa(temp[encValue] / 100, buf, 10), 3, ' ');
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
    strcat(menuopts[13], itoa(boilPwr, buf, 10));
    strcat(menuopts[13], "%");
    #ifdef PID_FLOW_CONTROL
    if (PIDEnabled[VS_STEAM]) strcpy_P(menuopts[14], PSTR("Sparge Pump Mode: PID")); else strcpy_P(menuopts[14], PSTR("Sparge Pump Mode: On/Off"));
    strcpy_P(menuopts[15], PUMPCYCLE);
    strcpy_P(menuopts[16], PUMPGAIN);
    strcpy_P(menuopts[17], PUMPFLOW);
    strcpy_P(menuopts[20], EXIT);
    #else
    if (PIDEnabled[VS_STEAM]) strcpy_P(menuopts[14], PSTR("Steam Mode: PID")); else strcpy_P(menuopts[14], PSTR("Steam Mode: On/Off"));
    strcpy_P(menuopts[15], STEAMCYCLE);
    strcpy_P(menuopts[16], STEAMGAIN);
    strcpy_P(menuopts[17], STEAMPRESS);
    strcpy_P(menuopts[18], STEAMSENSOR);
    strcpy_P(menuopts[19], STEAMZERO);
    strcpy_P(menuopts[20], EXIT);
    #endif

    lastOption = scrollMenu("Configure Outputs", 21, lastOption);
    if (lastOption == 0) {
      if (PIDEnabled[VS_HLT]) setPIDEnabled(VS_HLT, 0);
      else setPIDEnabled(VS_HLT, 1);
    }
    else if (lastOption == 1) {
      if(1
          #ifdef PWM_8K_1
          && PWM_8K_1 != VS_HLT
          #endif
          #ifdef PWM_8K_2
          && PWM_8K_2 != VS_HLT
          #endif
        )
      {
        setPIDCycle(VS_HLT, getValue(HLTCYCLE, PIDCycle[VS_HLT], 3, 1, 255, SEC));
        pid[VS_HLT].SetOutputLimits(0, PIDCycle[VS_HLT] * PIDLIMIT_HLT);
      }
    } else if (lastOption == 2) {
      setPIDGain("HLT PID Gain", VS_HLT);
    } else if (lastOption == 3) setHysteresis(VS_HLT, getValue(HLTHY, hysteresis[VS_HLT], 3, 1, 255, TUNIT));
    else if (lastOption == 4) {
      if (PIDEnabled[VS_MASH]) setPIDEnabled(VS_MASH, 0);
      else setPIDEnabled(VS_MASH, 1);
    }
    else if (lastOption == 5) {
      if(1
          #ifdef PWM_8K_1
          && PWM_8K_1 != VS_MASH
          #endif
          #ifdef PWM_8K_2
          && PWM_8K_2 != VS_MASH
          #endif
        )
      {
        setPIDCycle(VS_MASH, getValue(MASHCYCLE, PIDCycle[VS_MASH], 3, 1, 255, SEC));
        pid[VS_MASH].SetOutputLimits(0, PIDCycle[VS_MASH] * PIDLIMIT_MASH);
      }
    } else if (lastOption == 6) {
      setPIDGain("Mash PID Gain", VS_MASH);
    } else if (lastOption == 7) setHysteresis(VS_MASH, getValue(MASHHY, hysteresis[VS_MASH], 3, 1, 255, TUNIT));
    else if (lastOption == 8) {
      if (PIDEnabled[VS_KETTLE]) setPIDEnabled(VS_KETTLE, 0);
      else setPIDEnabled(VS_KETTLE, 1);
    }
    else if (lastOption == 9) {
      if(1
          #ifdef PWM_8K_1
          && PWM_8K_1 != VS_KETTLE
          #endif
          #ifdef PWM_8K_2
          && PWM_8K_2 != VS_KETTLE
          #endif
        )
      {
        setPIDCycle(VS_KETTLE, getValue(KETTLECYCLE, PIDCycle[VS_KETTLE], 3, 1, 255, SEC));
        pid[VS_KETTLE].SetOutputLimits(0, PIDCycle[VS_KETTLE] * PIDLIMIT_KETTLE);
      }
    } else if (lastOption == 10) {
      setPIDGain("Kettle PID Gain", VS_KETTLE);
    } else if (lastOption == 11) setHysteresis(VS_KETTLE, getValue(KETTLEHY, hysteresis[VS_KETTLE], 3, 1, 255, TUNIT));
    else if (lastOption == 12) setBoilTemp(getValue(PSTR("Boil Temp"), getBoilTemp(), 3, 0, 255, TUNIT));
    else if (lastOption == 13) setBoilPwr(getValue(PSTR("Boil Power"), boilPwr, 3, 0, min(PIDLIMIT_KETTLE, 100), PSTR("%")));
    else if (lastOption == 14) {
      if (PIDEnabled[VS_STEAM]) setPIDEnabled(VS_STEAM, 0);
      else setPIDEnabled(VS_STEAM, 1);
    }
    else if (lastOption == 15) {
      if(1
          #ifdef PWM_8K_1
          && PWM_8K_1 != VS_STEAM // this also covers the VS_PUMP case
          #endif
          #ifdef PWM_8K_2
          && PWM_8K_2 != VS_STEAM
          #endif
        )
      {
        #ifndef PID_FLOW_CONTROL
        setPIDCycle(VS_STEAM, getValue(STEAMCYCLE, PIDCycle[VS_STEAM], 3, 1, 255, SEC));
        pid[VS_STEAM].SetOutputLimits(0, PIDCycle[VS_STEAM] * PIDLIMIT_STEAM);
        #endif
      }
    } else if (lastOption == 16) {
      #ifdef PID_FLOW_CONTROL
      setPIDGain("PUMP PID Gain", VS_PUMP);
      #else
      setPIDGain("Steam PID Gain", VS_STEAM);
      #endif
    #ifdef PID_FLOW_CONTROL
    } else if (lastOption == 17) setSteamTgt(getValue(PUMPFLOW, getSteamTgt(), 3, 0, 255, PUNIT));
    #else
    } else if (lastOption == 17) setSteamTgt(getValue(STEAMPRESS, getSteamTgt(), 3, 0, 255, PUNIT));
    #endif
    else if (lastOption == 18) {
      if(1
         #ifdef PWM_8K_1
         && PWM_8K_1 != VS_STEAM // this also covers the VS_PUMP case
         #endif
         #ifdef PWM_8K_2
         && PWM_8K_2 != VS_STEAM
         #endif
        )
      {
        #ifndef PID_FLOW_CONTROL
        setSteamPSens(getValue(STEAMSENSOR, steamPSens, 4, 1, 9999, PSTR("mV/kPa")));
        #endif
      }
    } else if (lastOption == 19) {
      #ifndef PID_FLOW_CONTROL
      clearLCD();
      printLCD_P(0, 0, STEAMZERO);
      printLCD_P(1,2,PSTR("Calibrate Zero?"));
      strcpy_P(menuopts[0], CONTINUE);
      strcpy_P(menuopts[1], CANCEL);
      if (getChoice(2, 3) == 0) setSteamZero(analogRead(STEAMPRESS_APIN));
      #endif
    } else return;
    brewCore();
  } 
}

void setPIDGain(char sTitle[], byte vessel) {
  byte retP = pid[vessel].GetP_Param();
  byte retI = pid[vessel].GetI_Param();
  byte retD = pid[vessel].GetD_Param();
  byte cursorPos = 0; //0 = p, 1 = i, 2 = d, 3 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  Encoder.setMin(0);
  Encoder.setMax(3);
  Encoder.setCount(0);
  
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD_P(1, 0, PSTR("P:     I:     D:    "));
  printLCD_P(3, 8, OK);
  boolean redraw = 1;
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        if (cursorPos == 0) retP = encValue;
        else if (cursorPos == 1) retI = encValue;
        else if (cursorPos == 2) retD = encValue;
      } else {
        cursorPos = encValue;
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
    }
    if (Encoder.ok()) {
      if (cursorPos == 3) {
        setPIDp(vessel, retP);
        setPIDi(vessel, retI);
        setPIDd(vessel, retD);
#ifdef DEBUG_PID_GAIN
        logDebugPIDGain(vessel);
#endif
        break;
      }
      cursorState = cursorState ^ 1;
      if (cursorState) {
        Encoder.setMin(0);
        Encoder.setMax(255);
        if (cursorPos == 0) Encoder.setCount(retP);
        else if (cursorPos == 1) Encoder.setCount(retI);
        else if (cursorPos == 2) Encoder.setCount(retD);
      } else {
        Encoder.setMin(0);
        Encoder.setMax(3);
        Encoder.setCount(cursorPos);
      }
    } else if (Encoder.cancel()) break;
    brewCore();
  }
  brewCore();
}

void cfgVolumes() {
  byte lastOption = 0;
  while(1) {
    strcpy_P(menuopts[0], PSTR("HLT Capacity"));
    strcpy_P(menuopts[1], PSTR("HLT Dead Space"));
    strcpy_P(menuopts[2], PSTR("HLT Calibration"));
    strcpy_P(menuopts[3], PSTR("Mash Capacity"));
    strcpy_P(menuopts[4], PSTR("Mash Dead Space"));
    strcpy_P(menuopts[5], PSTR("Mash Calibration"));
    strcpy_P(menuopts[6], PSTR("Kettle Capacity"));
    strcpy_P(menuopts[7], PSTR("Kettle Dead Space"));
    strcpy_P(menuopts[8], PSTR("Kettle Calibration"));
    strcpy_P(menuopts[9], PSTR("Evaporation Rate"));
    strcpy_P(menuopts[10], EXIT);

    lastOption = scrollMenu("Volume/Capacity", 11, lastOption);

    if (lastOption == 0) setCapacity(VS_HLT, getValue(PSTR("HLT Capacity"), getCapacity(VS_HLT), 7, 3, 9999999, VOLUNIT));
    else if (lastOption == 1) setVolLoss(VS_HLT, getValue(PSTR("HLT Dead Space"), getVolLoss(VS_HLT), 5, 3, 65535, VOLUNIT));
    else if (lastOption == 2) volCalibMenu(TS_HLT);
    else if (lastOption == 3) setCapacity(VS_MASH, getValue(PSTR("Mash Capacity"), getCapacity(VS_MASH), 7, 3, 9999999, VOLUNIT));
    else if (lastOption == 4) setVolLoss(VS_MASH, getValue(PSTR("Mash Dead Space"), getVolLoss(VS_MASH), 5, 3, 65535, VOLUNIT));
    else if (lastOption == 5) volCalibMenu(VS_MASH);
    else if (lastOption == 6) setCapacity(VS_KETTLE, getValue(PSTR("Kettle Capacity"), getCapacity(VS_KETTLE), 7, 3, 9999999, VOLUNIT));
    else if (lastOption == 7) setVolLoss(VS_KETTLE, getValue(PSTR("Kettle Dead Space"), getVolLoss(VS_KETTLE), 5, 3, 65535, VOLUNIT));
    else if (lastOption == 8) volCalibMenu(VS_KETTLE);
    else if (lastOption == 9) setEvapRate(getValue(PSTR("Evaporation Rate"), getEvapRate(), 3, 0, 100, PSTR("%/hr")));
    else return;
  } 
}

void volCalibMenu(byte vessel) {
  byte lastOption = 0;
  char sTitle[21];
  if (vessel == TS_HLT) strcpy_P(sTitle, PSTR("HLT"));
  else if (vessel == TS_MASH) strcpy_P(sTitle, PSTR("Mash"));
  else if (vessel == TS_KETTLE) strcpy_P(sTitle, PSTR("Kettle"));
  strcat_P(sTitle, PSTR(" Calibration"));
    
  while(1) {
    for(byte i = 0; i < 10; i++) {
      if (calibVals[vessel][i] > 0) {
        vftoa(calibVols[vessel][i], buf, 3);
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
    lastOption = scrollMenu(sTitle, 11, lastOption);
    if (lastOption > 9) return; 
    else {
      if (calibVals[vessel][lastOption] > 0) {
        //There is already a value saved for that volume. 
        //Review the saved value for the selected volume value.
        volCalibEntryMenu(vessel, lastOption);
      } else {
        #ifdef DEBUG_VOLCALIB
          logVolCalib("Value before dialog:", analogRead(vSensor[vessel]));
        #endif

        setVolCalib(vessel, lastOption, 0, getValue(PSTR("Current Volume:"), 0, 7, 3, 9999999, VOLUNIT)); //Set temporary the value to zero. It will be updated in the next step.
        volCalibEntryMenu(vessel, lastOption);

        #ifdef DEBUG_VOLCALIB
          logVolCalib("Value that was saved:", PROMreadInt(239 + vessel * 20 + lastOption * 2));
        #endif
      } 
    }
  }
}

//This function manages the volume value to calibrate. 
//The value can be updated or deleted. 
//Users can skip all actions by exiting. 
void volCalibEntryMenu(byte vessel, byte entry) {
  byte lastOption = 0;
  char sTitle[21] ="";
  
  while(1) {
    vftoa(calibVols[vessel][entry], buf, 3);
    truncFloat(buf, 6);
    strcpy_P(sTitle, PSTR("Calibrate"));
    strcat_P(sTitle, SPACE);
    strcat(sTitle, buf);
    strcat_P(sTitle, SPACE);
    strcat_P(sTitle, VOLUNIT);
      
    unsigned int newSensorValue = GetCalibrationValue(vessel);
    
    strcpy_P(menuopts[0], PSTR("Update "));
    strcat(menuopts[0], itoa(calibVals[vessel][entry], buf, 10)); //Show the currently saved value which can be zero.
    strcat_P(menuopts[0], PSTR(" To "));
    strcat(menuopts[0], itoa(newSensorValue, buf, 10)); //Show the value to be saved. So users know what to expect.
    strcpy_P(menuopts[1], PSTR("Manual Entry"));
    strcpy_P(menuopts[2], PSTR("Delete"));
    strcpy_P(menuopts[3], EXIT);
    
    lastOption = scrollMenu(sTitle, 4, lastOption);

    if (lastOption == 0) {
      //Update the volume value.
      setVolCalib(vessel, entry, newSensorValue, calibVols[vessel][entry]); 
      return;
    } else if (lastOption == 1) {
      newSensorValue = (unsigned int) getValue(PSTR("Manual Volume Entry"), calibVals[vessel][entry], 4, 0, 1000, PSTR(""));
      setVolCalib(vessel, entry, newSensorValue, calibVols[vessel][entry]); 
      return;    
    } else if (lastOption == 2) {
      //Delete the volume and value.
      if(confirmDel()) {
        setVolCalib(vessel, entry, 0, 0); 
        return;
      } 
    } else return;
  }
}

void cfgValves() {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], FILLHLT);
    strcpy_P(menuopts[1], FILLMASH);
    strcpy_P(menuopts[2], HLTHEAT);    
    strcpy_P(menuopts[3], ADDGRAIN);    
    strcpy_P(menuopts[4], MASHHEAT);
    strcpy_P(menuopts[5], MASHIDLE);
    strcpy_P(menuopts[6], SPARGEIN);
    strcpy_P(menuopts[7], SPARGEOUT);
    strcpy_P(menuopts[8], BOILADDS);
    strcpy_P(menuopts[9], PSTR("Kettle Lid"));
    strcpy_P(menuopts[10], CHILLH2O);
    strcpy_P(menuopts[11], CHILLBEER);
    strcpy_P(menuopts[12], BOILRECIRC);
    strcpy_P(menuopts[13], DRAIN);
    strcpy_P(menuopts[14], EXIT);
    
    lastOption = scrollMenu("Valve Configuration", 15, lastOption);
    if (lastOption > 13) return;
    else {
      byte vc = lastOption;
      if (vc == 2) vc = 13; /* Map HLTHEAT to vlvConfig[13] */
      else if (vc > 2) vc--; /* Subtract 1 for Add Grain - Drain to map to vlvConfig[2] - vlvConfig[12] */
      setValveCfg(vc, cfgValveProfile(menuopts[lastOption], vlvConfig[vc]));
    }
  }
}

unsigned long cfgValveProfile (char sTitle[], unsigned long defValue) {
  unsigned long retValue = defValue;
  //firstBit: The left most bit being displayed
  byte firstBit, encMax;
  
#ifdef ONBOARDPV
  encMax = 12;
#else
  encMax = MUXBOARDS * 8 + 1;
#endif
  Encoder.setMin(0);
  Encoder.setCount(0);
  Encoder.setMax(encMax);
  //(Set to MAX + 1 to force redraw)
  firstBit = encMax + 1;
  
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD_P(3, 3, PSTR("Test"));
  printLCD_P(3, 13, PSTR("Save"));
  
  boolean redraw = 1;
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (encValue < firstBit || encValue > firstBit + 17) {
        if (encValue < firstBit) firstBit = encValue; else if (encValue < encMax - 1) firstBit = encValue - 17;
        for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) if (retValue & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
      }

      for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) {
        if (i < 9) itoa(i + 1, buf, 10); else buf[0] = i + 56;
        buf[1] = '\0';
        printLCD(2, i - firstBit + 1, buf);
      }

      if (firstBit > 0) printLCD_P(2, 0, PSTR("<")); else printLCD_P(2, 0, PSTR(" "));
      if (firstBit + 18 < encMax - 1) printLCD_P(2, 19, PSTR(">")); else printLCD_P(2, 19, PSTR(" "));
      if (encValue == encMax - 1) {
        printLCD_P(3, 2, PSTR(">"));
        printLCD_P(3, 7, PSTR("<"));
        printLCD_P(3, 12, PSTR(" "));
        printLCD_P(3, 17, PSTR(" "));
      } else if (encValue == encMax) {
        printLCD_P(3, 2, PSTR(" "));
        printLCD_P(3, 7, PSTR(" "));
        printLCD_P(3, 12, PSTR(">"));
        printLCD_P(3, 17, PSTR("<"));
      } else {
        printLCD_P(3, 2, PSTR(" "));
        printLCD_P(3, 7, PSTR(" "));
        printLCD_P(3, 12, PSTR(" "));
        printLCD_P(3, 17, PSTR(" "));
        printLCD_P(2, encValue - firstBit + 1, PSTR("^"));
      }
    }
    
    if (Encoder.ok()) {
      encValue = Encoder.getCount();
      if (encValue == encMax) return retValue;
      else if (encValue == encMax - 1) {
        setValves(VLV_ALL, 0);
        setValves(retValue, 1);
        printLCD_P(3, 2, PSTR("["));
        printLCD_P(3, 7, PSTR("]"));
        while (!Encoder.ok()) delay(100);
        setValves(VLV_ALL, 0);
        redraw = 1;
      } else {
        retValue = retValue ^ ((unsigned long)1<<encValue);
        for (byte i = firstBit; i < min(encMax - 1, firstBit + 18); i++) if (retValue & ((unsigned long)1<<i)) printLCD_P(1, i - firstBit + 1, PSTR("1")); else printLCD_P(1, i - firstBit + 1, PSTR("0"));
      }
    } else if (Encoder.cancel()) return defValue;
    brewCore();
  }
}
#endif
#endif
