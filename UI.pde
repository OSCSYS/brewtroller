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
#define ENCODER_ALPS
//#define ENCODER_CUI
//**********************************************************************************

//**********************************************************************************
// LCD Timing Fix
//**********************************************************************************
// Some LCDs seem to have issues with displaying garbled characters but introducing
// a delay seems to help or resolve completely. You may comment out the following
// lines to remove this delay between a print of each character.
//
//#define LCD_DELAY_CURSOR 60
//#define LCD_DELAY_CHAR 60
//**********************************************************************************


//*****************************************************************************************************************************
// Begin UI Code
//*****************************************************************************************************************************

//**********************************************************************************
// UI Definitions
//**********************************************************************************
#define ENTER_CLEAR 0
#define ENTER_OK 1
#define ENTER_CANCEL 2

#define SCREEN_HOME 0
#define SCREEN_FILL 1
#define SCREEN_PREHEAT 2
#define SCREEN_ADDGRAIN 3
#define SCREEN_REFILL 4
#define SCREEN_MASH 5
#define SCREEN_SPARGE 6
#define SCREEN_BOIL 7
#define SCREEN_CHILL 8
#define SCREEN_DRAIN 9

#ifdef ENCODER_CUI
#define ENTER_BOUNCE_DELAY 50
#endif

#ifdef ENCODER_ALPS
#define ENTER_BOUNCE_DELAY 30
#endif

//**********************************************************************************
// UI Strings
//**********************************************************************************
const char CANCEL[] PROGMEM = "Cancel";
const char EXIT[] PROGMEM = "Exit";
const char SPACE[] PROGMEM = " ";
const char INIT_EEPROM[] PROGMEM = "Initialize EEPROM";
const char SKIPSTEP[] PROGMEM = "Skip Step";
const char CONTINUE[] PROGMEM = "Continue";
const char AUTOFILL[] PROGMEM = "Auto";
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
const char CHILLNORM[] PROGMEM = "Chiller Both";
const char CHILLH2O[] PROGMEM = "Chiller H2O";
const char CHILLBEER[] PROGMEM = "Chiller Beer";
const char BOILRECIRC[] PROGMEM = "Boil Recirc";
const char DRAIN[] PROGMEM = "Drain";
const char HLTCYCLE[] PROGMEM = "HLT PID Cycle";
const char HLTGAIN[] PROGMEM = "HLT PID Gain";
const char HLTHY[] PROGMEM = "HLT Hysteresis";
const char MASHCYCLE[] PROGMEM = "Mash PID Cycle";
const char MASHGAIN[] PROGMEM = "Mash PID Gain";
const char MASHHY[] PROGMEM = "Mash Hysteresis";
const char KETTLECYCLE[] PROGMEM = "Kettle PID Cycle";
const char KETTLEGAIN[] PROGMEM = "Kettle PID Gain";
const char KETTLEHY[] PROGMEM = "Kettle Hysteresis";
const char STEAMCYCLE[] PROGMEM = "Steam PID Cycle";
const char STEAMGAIN[] PROGMEM = "Steam PID Gain";
const char STEAMPRESS[] PROGMEM = "Steam Target";
const char STEAMSENSOR[] PROGMEM = "Steam Sensor Sens";
const char STEAMZERO[] PROGMEM = "Steam Zero Calib";
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
const byte BMP4[] PROGMEM = {B11111, B11111, B11111, B11111, B11111, B11111, B11111, B11111};
const byte BMP5[] PROGMEM = {B01111, B01110, B01100, B00001, B01111, B00111, B00011, B11101};
const byte BMP6[] PROGMEM = {B11111, B00111, B00111, B11111, B11111, B11111, B11110, B11001};
const byte BMP7[] PROGMEM = {B11111, B11111, B11110, B11101, B11011, B00111, B11111, B11111};

//**********************************************************************************
// UI Globals
//**********************************************************************************
volatile unsigned long lastEncUpd = millis();
unsigned long enterStart;
int encCount;
byte encMin, encMax, enterStatus, activeScreen, lastCount;
boolean screenLock = 1;
byte timerLastPrint;

//**********************************************************************************
// uiInit:  One time intialization of all UI logic
//**********************************************************************************
void uiInit() {
  initLCD();
  initEncoder();
  activeScreen = SCREEN_HOME;
  screenInit(SCREEN_HOME);
}

//**********************************************************************************
// unlockUI:  Unlock active screen to select another
//**********************************************************************************
void unlockUI() {
  encMin = SCREEN_HOME;
  encMax = SCREEN_DRAIN;
  encCount = activeScreen;
  screenLock = 0;
}

//**********************************************************************************
// screenCore: Called in main loop to handle all UI functions
//**********************************************************************************
void uiCore() {
  if (!screenLock && encCount != activeScreen) {
    activeScreen = encCount;
    screenInit(activeScreen);
  }
  screenEnter(activeScreen);
  screenRefresh(activeScreen);
}

//**********************************************************************************
// screenInit: Initialize active screen
//**********************************************************************************
void screenInit(byte screen) {
  clearLCD();
  if (screen == SCREEN_HOME) {
    //Screen Init: Home
    lcdSetCustChar_P(0, BMP0);
    lcdSetCustChar_P(1, BMP1);
    lcdSetCustChar_P(2, BMP2);
    lcdSetCustChar_P(3, BMP3);
    lcdSetCustChar_P(4, BMP4);
    lcdSetCustChar_P(5, BMP5);
    lcdSetCustChar_P(6, BMP6);
    lcdSetCustChar_P(7, BMP7);
    lcdWriteCustChar(0, 1, 0);
    lcdWriteCustChar(0, 2, 1);
    lcdWriteCustChar(1, 0, 2); 
    lcdWriteCustChar(1, 1, 3); 
    lcdWriteCustChar(1, 2, 4); 
    lcdWriteCustChar(2, 0, 5); 
    lcdWriteCustChar(2, 1, 6); 
    lcdWriteCustChar(2, 2, 7); 
    printLCD_P(0, 4, BT);
    printLCD_P(0, 16, BTVER);
    printLCD_P(1, 10, PSTR("Build "));
    printLCDLPad(1, 16, itoa(BUILD, buf, 10), 4, '0');
    printLCD_P(3, 1, PSTR("www.brewtroller.com"));    
  } else if (screen == SCREEN_FILL || screen == SCREEN_REFILL) {
    //Screen Init: Fill/Refill
    printLCD_P(0, 0, PSTR("HLT"));
    #ifdef USEMETRIC
      printLCD_P(0, 6, PSTR("Fill (l)"));
    #else
      printLCD_P(0, 5, PSTR("Fill (gal)"));
    #endif
    printLCD_P(0, 16, PSTR("Mash"));
    printLCD_P(1, 7, PSTR("Target"));
    printLCD_P(2, 7, PSTR("Actual"));
    printLCD_P(3, 4, PSTR(">"));
    printLCD_P(3, 15, PSTR("<"));
    ftoa(tgtVol[VS_HLT]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCD(1, 0, buf);
    ftoa(tgtVol[VS_MASH]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDLPad(1, 14, buf, 6, ' ');
    
    encMin = 0;
    encMax = 6;
    encCount = 0;
    lastCount = 1;
  } else if (screen == SCREEN_PREHEAT || screen == SCREEN_MASH) {
    //Screen Init: Preheat/Mash
    //Delay Start Indication
    timerLastWrite = 0;
    printLCDCenter(0, 5, sTitle, 10);
    printLCD_P(2, 7, PSTR("(WAIT)"));
    printLCD_P(0, 0, PSTR("HLT"));
    printLCD_P(3, 0, PSTR("[    ]"));
    printLCD_P(0, 16, PSTR("Mash"));
    printLCD_P(3, 14, PSTR("[    ]"));
    
    #ifdef USEMETRIC
      printLCD_P(1, 7, PSTR("Litres"));
    #else
      printLCD_P(1, 8, PSTR("Gals"));
    #endif

    printLCD_P(2, 3, TUNIT);
    printLCD_P(3, 4, TUNIT);
    printLCD_P(2, 19, TUNIT);
    printLCD_P(3, 18, TUNIT);

  } else if (screen == SCREEN_ADDGRAIN) {
    //Screen Init: Add Grain
    
  } else if (screen == SCREEN_SPARGE) {
    //Screen Init: Sparge
    printLCD_P(0, 8, PSTR(">"));
    printLCD_P(0, 19, PSTR("<"));
    
    printLCD_P(1, 0, PSTR("HLT"));
    printLCD_P(2, 0, PSTR("Mash"));
    printLCD_P(3, 0, PSTR("Kettle"));
    printLCD_P(1, 7, PSTR("---"));
    printLCD_P(2, 7, PSTR("---"));
    printLCD_P(3, 7, PSTR("---"));
    printLCD_P(1, 12, PSTR("----.---"));
    printLCD_P(2, 12, PSTR("----.---"));
    printLCD_P(3, 12, PSTR("----.---"));
    printLCD_P(1, 10, TUNIT);
    printLCD_P(2, 10, TUNIT);
    printLCD_P(3, 10, TUNIT);
    
    encMin = 0;
    encMax = 7;
    encCount = 0;
    lastCount = 1;
    
  } else if (screen == SCREEN_BOIL) {
    //Screen Init: Boil
    timerLastWrite = 0;
    printLCD_P(0,0,PSTR("Kettle"));
    printLCD_P(0,8,PSTR("Boil"));
    if (setpoint[TS_KETTLE] > 0) printLCD_P(2,7,PSTR("(WAIT)"));
    printLCD_P(3,0,PSTR("[    ]"));

    #ifdef USEMETRIC
      printLCD_P(1, 7, PSTR("Litres"));
    #else
      printLCD_P(1, 8, PSTR("Gals"));
    #endif
    printLCD_P(2, 3, TUNIT);
    printLCD_P(3, 4, TUNIT);


    encMin = 0;
    encMax = PIDLIMIT_KETTLE;
    encCount = PIDLIMIT_KETTLE;
    byte lastCount = encCount;

  } else if (screen == SCREEN_CHILL) {
    //Screen Init: Chill
    printLCD_P(0, 8, PSTR("Chill"));
    printLCD_P(0, 0, PSTR("Beer"));
    printLCD_P(0, 17, PSTR("H2O"));
    printLCD_P(1, 9, PSTR("IN"));
    printLCD_P(2, 9, PSTR("OUT"));

    printLCD_P(1, 3, TUNIT);
    printLCD_P(1, 19, TUNIT);
    printLCD_P(2, 3, TUNIT);
    printLCD_P(2, 19, TUNIT);
    printLCD_P(3, 3, PSTR(">"));
    printLCD_P(3, 16, PSTR("<"));    

    encMin = 0;
    encMax = 6;
    encCount = 0;
    lastCount = 1;
  } else if (screen == SCREEN_DRAIN) {
    //Screen Init: Drain
    
  }
}

//**********************************************************************************
// screenRefresh:  Refresh active screen
//**********************************************************************************
void screenRefresh(byte screen) {
  if (screen == SCREEN_HOME) {
    //Refresh Screen: Home

  } else if (screen == SCREEN_FILL || screen == SCREEN_REFILL) {
    ftoa(volAvg[VS_HLT]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDRPad(2, 0, buf, 7, ' ');

    ftoa(volAvg[VS_MASH]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDLPad(2, 14, buf, 6, ' ');

    if (vlvConfig[VLV_FILLMASH] != 0 && (vlvBits & vlvConfig[VLV_FILLMASH]) == vlvConfig[VLV_FILLMASH]) printLCD_P(3, 17, PSTR(" On"));
    else printLCD_P(3, 17, PSTR("Off"));

    if (vlvConfig[VLV_FILLHLT] != 0 && (vlvBits & vlvConfig[VLV_FILLHLT]) == vlvConfig[VLV_FILLHLT]) printLCD_P(3, 0, PSTR("On "));
    else printLCD_P(3, 0, PSTR("Off"));

    if (encCount != lastCount) {
      lastCount = encCount;
      printLCDRPad(3, 5, "", 10, ' ');
      if (lastCount == 0) printLCD_P(3, 6, CONTINUE);
      else if (lastCount == 1) printLCD_P(3, 8, AUTOFILL);
      else if (lastCount == 2) printLCD_P(3, 6, FILLHLT);
      else if (lastCount == 3) printLCD_P(3, 6, FILLMASH);
      else if (lastCount == 4) printLCD_P(3, 6, FILLBOTH);
      else if (lastCount == 5) printLCD_P(3, 7, ALLOFF);
      else if (lastCount == 6) printLCD_P(3, 8, ABORT);
    }
  } else if (screen == SCREEN_PREHEAT || screen == SCREEN_MASH) {
    //Refresh Screen: Preheat/Mash
    ftoa(volAvg[VS_HLT]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDRPad(1, 0, buf, 7, ' ');
      
    ftoa(volAvg[VS_MASH]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDLPad(1, 14, buf, 6, ' ');

    for (byte i = VS_HLT; i <= VS_MASH; i++) {
      if (temp[i] == -1) printLCD_P(2, i * 16, PSTR("---")); else printLCDLPad(2, i * 16, itoa(temp[i], buf, 10), 3, ' ');
      printLCDLPad(3, i * 14 + 1, itoa(setpoint[i], buf, 10), 3, ' ');
      byte pct;
      if (PIDEnabled[i]) {
        pct = PIDOutput[i] / PIDCycle[i] / 10;
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
      printLCDLPad(3, i * 5 + 6, buf, 3, ' ');
      
      if (!preheated && ((setpoint[VS_MASH] != 0 && temp[TS_MASH] >= setpoint[TS_MASH]) || (setpoint[VS_MASH] == 0 && temp[TS_HLT] >= setpoint[TS_HLT]))) {
        preheated = 1;
        printLCDRPad(2, 7, "", 6, ' ');
        if(doPrompt) {
          printLCD(2, 5, ">");
          printLCD_P(2, 6, CONTINUE);
          printLCD(2, 14, "<");
        } else setTimer(iMins);
      }
    }

    if (preheated && !doPrompt) printTimer(2, 7);

  } else if (screen == SCREEN_ADDGRAIN) {
    //Refresh Screen: Add Grain
    
  } else if (screen == SCREEN_SPARGE) {
    //Refresh Screen: Sparge
    ftoa(volAvg[VS_HLT]/1000.0, buf, 3);
    truncFloat(buf, 8);
    printLCDLPad(1, 12, buf, 8, ' ');
      
    ftoa(volAvg[VS_MASH]/1000.0, buf, 3);
    truncFloat(buf, 8);
    printLCDLPad(2, 12, buf, 8, ' ');
      
    ftoa(volAvg[VS_KETTLE]/1000.0, buf, 3);
    truncFloat(buf, 8);
    printLCDLPad(3, 12, buf, 8, ' ');

    if (encCount != lastCount) {
      printLCDRPad(0, 9, "", 10, ' ');
      lastCount = encCount;

      if (lastCount == 0) printLCD_P(0, 10, CONTINUE);
      else if (lastCount == 1) printLCD_P(0, 9, SPARGEIN);
      else if (lastCount == 2) printLCD_P(0, 9, SPARGEOUT);
      else if (lastCount == 3) printLCD_P(0, 9, FLYSPARGE);
      else if (lastCount == 4) printLCD_P(0, 9, MASHHEAT);
      else if (lastCount == 5) printLCD_P(0, 9, MASHIDLE);
      else if (lastCount == 6) printLCD_P(0, 11, ALLOFF);
      else if (lastCount == 7) printLCD_P(0, 12, ABORT);
    }

    for (byte i = TS_HLT; i <= TS_KETTLE; i++) if (temp[i] == -1) printLCD_P(i + 1, 7, PSTR("---")); else printLCDLPad(i + 1, 7, itoa(temp[i], buf, 10), 3, ' ');

  } else if (screen == SCREEN_BOIL) {
    //Refresh Screen: Boil
    if (doAutoBoil) printLCD_P(3, 14, PSTR("  Auto"));
    else printLCD_P(3, 14, PSTR("Manual"));

    if (preheated) printTimer(2, 7);
    if (alarmStatus) printLCD_P(0, 19, PSTR("!")); else printLCD_P(0, 19, SPACE);

    ftoa(volAvg[VS_KETTLE]/1000.0, buf, 2);
    truncFloat(buf, 6);
    printLCDRPad(1, 0, buf, 7, ' ');

    if (PIDEnabled[TS_KETTLE]) {
      byte pct = PIDOutput[TS_KETTLE] / PIDCycle[TS_KETTLE] / 10;
      if (pct == 0) strcpy_P(buf, PSTR("Off"));
      else if (pct == 100) strcpy_P(buf, PSTR(" On"));
      else { itoa(pct, buf, 10); strcat(buf, "%"); }
    } else if (heatStatus[TS_KETTLE]) {
      strcpy_P(buf, PSTR(" On")); 
    } else {
      strcpy_P(buf, PSTR("Off"));
    }
    printLCDLPad(3, 6, buf, 3, ' ');
    
    if (temp[TS_KETTLE] == -1) printLCD_P(2, 0, PSTR("---")); else printLCDLPad(2, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
    printLCDLPad(3, 1, itoa(setpoint[TS_KETTLE], buf, 10), 3, ' ');

    if (encCount != lastCount) {
      lastCount = encCount;
      doAutoBoil = 0;
      PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * lastCount;
    }

    if (doAutoBoil) {
      encCount = PIDOutput[VS_KETTLE] / PIDCycle[VS_KETTLE] / 10;
      lastCount = encCount;
    }

  } else if (screen == SCREEN_CHILL) {
    //Refresh Screen: Chill
    if (encCount != lastCount) {
      lastCount = encCount;
      printLCDRPad(3, 4, "", 12, ' ');
      if (lastCount == 0) printLCD_P(3, 6, CONTINUE);
      else if (lastCount == 1) printLCD_P(3, 4, CHILLNORM);
      else if (lastCount == 2) printLCD_P(3, 4, CHILLH2O);
      else if (lastCount == 3) printLCD_P(3, 4, CHILLBEER);
      else if (lastCount == 4) printLCD_P(3, 7, ALLOFF);
      else if (lastCount == 5) printLCD_P(3, 8, AUTOFILL);
      else if (lastCount == 6) printLCD_P(3, 8, ABORT);
    }
    if (temp[TS_KETTLE] == -1) printLCD_P(1, 0, PSTR("---")); else printLCDLPad(1, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
    if (temp[TS_BEEROUT] == -1) printLCD_P(2, 0, PSTR("---")); else printLCDLPad(2, 0, itoa(temp[TS_BEEROUT], buf, 10), 3, ' ');
    if (temp[TS_H2OIN] == -1) printLCD_P(1, 16, PSTR("---")); else printLCDLPad(1, 16, itoa(temp[TS_H2OIN], buf, 10), 3, ' ');
    if (temp[TS_H2OOUT] == -1) printLCD_P(2, 16, PSTR("---")); else printLCDLPad(2, 16, itoa(temp[TS_H2OOUT], buf, 10), 3, ' ');
    if ((vlvBits & vlvConfig[VLV_CHILLBEER]) == vlvConfig[VLV_CHILLBEER]) printLCD_P(3, 0, PSTR("On ")); else printLCD_P(3, 0, PSTR("Off"));
    if ((vlvBits & vlvConfig[VLV_CHILLH2O]) == vlvConfig[VLV_CHILLH2O]) printLCD_P(3, 17, PSTR(" On")); else printLCD_P(3, 17, PSTR("Off"));
  } else if (screen == SCREEN_DRAIN) {
    //Refresh Screen: Drain
  }
}


//**********************************************************************************
// screenEnter:  Check enterStatus and handle based on screenLock and activeScreen
//**********************************************************************************
void screenEnter(byte screen) {
  if (enterStatus == ENTER_CANCEL) {
    enterStatus = ENTER_CLEAR;    
    //Process Abort Logic
    if (confirmExit()) resetOutputs();
  } else if (enterStatus == ENTER_OK) {
    enterStatus = ENTER_CLEAR;
    if (!screenLock) screenLock = 1;
    else {
      if (screen == SCREEN_HOME) {
        //Screen Enter: Home
        
      } else if (screen == SCREEN_FILL || screen == SCREEN_REFILL) {
        //Sceeen Enter: Fill/Refill
        autoValve = 0;
        if (encCount == 0) {
          
          }
          activeScreen = SCREEN_PREHEAT;
          screenInit(activeScreen);
        } else if (encCount == 1) autoValve = AV_FILL;
        else if (encCount == 2) setValves(vlvConfig[VLV_FILLHLT]);
        else if (encCount == 3) setValves(vlvConfig[VLV_FILLMASH]);
        else if (encCount == 4) setValves(vlvConfig[VLV_FILLHLT] | vlvConfig[VLV_FILLMASH]);
        else if (encCount == 5) setValves(0);
        else if (encCount == 6) enterStatus = 2;
      } else if (screen == SCREEN_PREHEAT || screen == SCREEN_MASH) {
        //Screen Enter: Preheat/Mash
        strcpy_P(menuopts[0], CANCEL);
        if (timerValue > 0) strcpy_P(menuopts[1], PSTR("Reset Timer"));
        else strcpy_P(menuopts[1], PSTR("Start Timer"));
        strcpy_P(menuopts[2], PSTR("Pause Timer"));
        strcpy_P(menuopts[3], SKIPSTEP);
        strcpy_P(menuopts[4], ABORT);
        byte lastOption = scrollMenu("AutoBrew Mash Menu", 5, 0);
        if (lastOption == 1) {
          preheated = 1;
          printLCDRPad(0, 14, "", 6, ' ');
          setTimer(iMins);
        } else if (lastOption == 2) pauseTimer();
        else if (lastOption == 3) {
          resetOutputs();
          return;
        } else if (lastOption == 4) {
            if (confirmExit() == 1) {
              resetOutputs();
              enterStatus = 2;
              return;
            }
        }
      } else if (screen == SCREEN_ADDGRAIN) {
        //Screen Enter: Add Grain
        
      } else if (screen == SCREEN_SPARGE) {
        //Screen Enter: Sparge
        if (lastCount == 0) {
          resetOutputs();
          return;
        }
        else if (lastCount == 1) setValves(vlvConfig[VLV_SPARGEIN]);
        else if (lastCount == 2) setValves(vlvConfig[VLV_SPARGEOUT]);
        else if (lastCount == 3) setValves(vlvConfig[VLV_SPARGEIN] | vlvConfig[VLV_SPARGEOUT]);
        else if (lastCount == 4) setValves(vlvConfig[VLV_MASHHEAT]);
        else if (lastCount == 5) setValves(vlvConfig[VLV_MASHIDLE]);
        else if (lastCount == 6) setValves(0);
        else if (lastCount == 7) {
            if (confirmExit()) {
              resetOutputs();
              enterStatus = 2;
              return;
            } else redraw = 1;
        }
        if (mode == ADD_GRAIN) setValves(vlvBits | vlvConfig[VLV_ADDGRAIN]);
      } else if (screen == SCREEN_BOIL) {
        //Screen Enter: Boil
        while(1) {
          strcpy_P(menuopts[0], CANCEL);
          if (timerValue > 0) strcpy_P(menuopts[1], PSTR("Reset Timer"));
          else strcpy_P(menuopts[1], PSTR("Start Timer"));
          strcpy_P(menuopts[2], PSTR("Pause Timer"));
          strcpy_P(menuopts[3], PSTR("Auto Boil"));        
          strcpy_P(menuopts[4], BOILRECIRC);
          strcpy_P(menuopts[5], PSTR("Reset Valves"));
          strcpy_P(menuopts[6], SKIPSTEP);
          strcpy_P(menuopts[7], ABORT);
          byte lastOption = scrollMenu("AutoBrew Boil Menu", 8, 0);
          if (lastOption == 1) {
            preheated = 1;
            printLCDRPad(0, 14, "", 6, ' ');
            setTimer(iMins);
            break;
          } else if (lastOption == 2) pauseTimer();
          else if (lastOption == 3) doAutoBoil = 1;
          else if (lastOption == 4) setValves(vlvConfig[VLV_BOILRECIRC]);
          else if (lastOption == 5) setValves(0);
          else if (lastOption == 6) {
            resetOutputs();
            return;
          } else if (lastOption == 7) {
              if (confirmExit() == 1) {
                enterStatus = 2;
                resetOutputs();
                return;
              }
          }
        }
        encMin = 0;
        encMax = PIDLIMIT_KETTLE;
        encCount = PIDOutput[VS_KETTLE] / PIDCycle[VS_KETTLE] / 10;
        lastCount = encCount;
      } else if (screen == SCREEN_CHILL) {
        //Screen Enter: Chill
        autoValve = 0;
        if (encCount == 0) {

        } else if (encCount == 1) setValves(vlvConfig[VLV_CHILLH2O] | vlvConfig[VLV_CHILLBEER]);
        else if (encCount == 2) setValves(vlvConfig[VLV_CHILLH2O]);
        else if (encCount == 3) setValves(vlvConfig[VLV_CHILLBEER]);
        else if (encCount == 4) setValves(0);
        else if (encCount == 5) autoValve = AV_CHILL;
        else if (encCount == 6) {

        }
      } else if (screen == SCREEN_DRAIN) {
        //Screen Enter: Drain
        
      }
    }
  }
}

void printTimer(byte iRow, byte iCol) {
  if (timerValue > 0 && !timerStatus) printLCD(iRow, iCol, "PAUSED");
  else if (alarmStatus || timerStatus) {
    byte timerHours = timerValue / 3600000;
    byte timerMins = (timerValue - timerHours * 3600000) / 60000;
    byte timerSecs = (timerValue - timerHours * 3600000 - timerMins * 60000) / 1000;

    //Update LCD once per second
    if (timerLastPrint != timerSecs) {
      timerLastPrint = timerSecs;
      printLCDRPad(iRow, iCol, "", 6, ' ');
      printLCD_P(iRow, iCol+2, PSTR(":"));
      if (timerHours > 0) {
        printLCDLPad(iRow, iCol, itoa(timerHours, buf, 10), 2, '0');
        printLCDLPad(iRow, iCol + 3, itoa(timerMins, buf, 10), 2, '0');
      } else {
        printLCDLPad(iRow, iCol, itoa(timerMins, buf, 10), 2, '0');
        printLCDLPad(iRow, iCol+ 3, itoa(timerSecs, buf, 10), 2, '0');
      }
      if (alarmStatus) printLCD(iRow, iCol + 5, "!");
    }
  } else printLCDRPad(iRow, iCol, "", 6, ' ');
}

void editProgram(byte pgm) {
  byte lastOption;
  while (1) {
    strcpy_P(menuopts[0], PSTR("Batch Vol:"));
    strcpy_P(menuopts[1], PSTR("Grain Wt:"));
    strcpy_P(menuopts[2], PSTR("Grain Temp:"));
    strcpy_P(menuopts[3], PSTR("Boil Length:"));
    strcpy_P(menuopts[4], PSTR("Mash Ratio:"));
    strcpy_P(menuopts[5], PSTR("HLT Temp:"));
    strcpy_P(menuopts[6], PSTR("Sparge Temp:"));
    strcpy_P(menuopts[7], PSTR("Pitch Temp:"));
    strcpy_P(menuopts[8], PSTR("Mash Schedule"));
    strcpy_P(menuopts[9], PSTR("Heat Mash Liq:"));    
    strcpy_P(menuopts[10], BOILADDS);    
    strcpy_P(menuopts[11], EXIT);

    ftoa((float)getProgBatchVol(pgm)/1000, buf, 2);
    truncFloat(buf, 5);
    strcat(menuopts[0], buf);
    strcat_P(menuopts[0], VOLUNIT);

    ftoa((float)getProgGrain(pgm)/1000, buf, 3);
    truncFloat(buf, 7);
    strcat(menuopts[1], buf);
    strcat_P(menuopts[1], WTUNIT);

    strncat(menuopts[2], itoa(getProgGrainT(pgm), buf, 10), 3);
    strcat_P(menuopts[2], TUNIT);

    strncat(menuopts[3], itoa(getProgBoil(pgm), buf, 10), 3);
    strcat_P(menuopts[3], PSTR(" min"));
    
    ftoa((float)getProgRatio(pgm)/100, buf, 2);
    truncFloat(buf, 4);
    strcat(menuopts[4], buf);
    strcat_P(menuopts[4], PSTR(":1"));

    strncat(menuopts[6], itoa(getProgHLT(pgm), buf, 10), 3);
    strcat_P(menuopts[6], TUNIT);
    
    strncat(menuopts[7], itoa(getProgSparge(pgm), buf, 10), 3);
    strcat_P(menuopts[7], TUNIT);
    
    strncat(menuopts[8], itoa(getProgPitch(pgm), buf, 10), 3);
    strcat_P(menuopts[8], TUNIT);
    {
      byte MLHeatSrc = getProgMLHeatSrc(pgm);
      if (MLHeatSrc == VS_HLT) strcat_P(menuopts[10], PSTR("HLT"));
      else if (MLHeatSrc == VS_MASH) strcat_P(menuopts[10], PSTR("MASH"));
      else strcat_P(menuopts[10], PSTR("UNKWN"));
    }
    lastOption = scrollMenu("Program Parameters", 12, lastOption);
    if (lastOption == 0) setProgBatchVol(pgm, getValue(PSTR("Batch Volume"), getProgBatchVol(pgm), 7, 3, 9999999, VOLUNIT));
    else if (lastOption == 1) setProgGrain(pgm, getValue(PSTR("Grain Weight"), getProgGrain(pgm), 7, 3, 9999999, WTUNIT));
    else if (lastOption == 2) setProgGrainT(pgm, getValue(PSTR("Grain Temp"), getProgGrainT(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 3) setProgBoil(pgm, getTimerValue(PSTR("Boil Length"), getProgBoil(pgm)));
    else if (lastOption == 4) { 
      #ifdef USEMETRIC
        setProgRatio(pgm, getValue(PSTR("Mash Ratio"), getProgRatio(pgm), 3, 2, 999, PSTR(" l/kg"))); 
      #else
        setProgRatio(pgm, getValue(PSTR("Mash Ratio"), getProgRatio(pgm), 3, 2, 999, PSTR(" qts/lb")));
      #endif
    }
    else if (lastOption == 5) setProgHLT(pgm, getValue(PSTR("HLT Setpoint"), getProgHLT(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 6) setProgSparge(pgm, getValue(PSTR("Sparge Temp"), getProgSparge(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 7) setProgPitch(pgm, getValue(PSTR("Pitch Temp"), getProgPitch(pgm), 3, 0, 255, TUNIT));
    else if (lastOption == 8) editMashSchedule(pgm);
    else if (lastOption == 9) setMLHeatSrc(pgm, MLHeatSrcMenu(getProgMLHeatSrc(pgm)));
    else if (lastOption == 10) setProgAdds(pgm, editHopSchedule(getProgAdds(pgm)));
    else return;
  }
  if (calcSpargeVol(pgm) > capacity[TS_HLT]) warnHLT();
  if (calcMashVol(pgm) + calcGrainVolume(pgm) > capacity[TS_MASH]) warnMash();
}

void editMashSchedule(byte pgm) {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], PSTR("Dough In:"));
    strcpy_P(menuopts[1], PSTR("Dough In:"));
    strcpy_P(menuopts[2], PSTR("Protein Rest:"));
    strcpy_P(menuopts[3], PSTR("Protein Rest:"));
    strcpy_P(menuopts[4], PSTR("Sacch Rest:"));
    strcpy_P(menuopts[5], PSTR("Sacch Rest:"));
    strcpy_P(menuopts[6], PSTR("Mash Out:"));
    strcpy_P(menuopts[7], PSTR("Mash Out:"));
    strcpy_P(menuopts[8], EXIT);
  
    strncat(menuopts[0], itoa(getProgMashMins(pgm, MASH_DOUGHIN), buf, 10), 2);
    strcat(menuopts[0], " min");

    strncat(menuopts[1], itoa(getProgMashTemp(pgm, MASH_DOUGHIN), buf, 10), 3);
    strcat_P(menuopts[1], TUNIT);
    
    strncat(menuopts[2], itoa(getProgMashMins(pgm, MASH_PROTEIN), buf, 10), 2);
    strcat(menuopts[2], " min");

    strncat(menuopts[3], itoa(getProgMashTemp(pgm, MASH_PROTEIN), buf, 10), 3);
    strcat_P(menuopts[3], TUNIT);
    
    strncat(menuopts[4], itoa(getProgMashMins(pgm, MASH_SACCH), buf, 10), 2);
    strcat(menuopts[4], " min");

    strncat(menuopts[5], itoa(getProgMashTemp(pgm, MASH_SACCH), buf, 10), 3);
    strcat_P(menuopts[5], TUNIT);
    
    strncat(menuopts[6], itoa(getProgMashMins(pgm, MASH_MASHOUT), buf, 10), 2);
    strcat(menuopts[6], " min");

    strncat(menuopts[7], itoa(getProgMashTemp(pgm, MASH_MASHOUT), buf, 10), 3);
    strcat_P(menuopts[7], TUNIT);

    lastOption = scrollMenu("Mash Schedule", 9, lastOption);
    if (lastOption == 0) setProgMashMins(pgm, MASH_DOUGHIN, getTimerValue(PSTR("Dough In"), getProgMashMins(pgm, MASH_DOUGHIN)));
    else if (lastOption == 1) setProgMashTemp(pgm, MASH_DOUGHIN, getValue(PSTR("Dough In"), getProgMashTemp(pgm, MASH_DOUGHIN), 3, 0, 255, TUNIT));
    else if (lastOption == 2) setProgMashMins(pgm, MASH_PROTEIN, getTimerValue(PSTR("Protein Rest"), getProgMashMins(pgm, MASH_PROTEIN)));
    else if (lastOption == 3) setProgMashTemp(pgm, MASH_PROTEIN, getValue(PSTR("Protein Rest"), getProgMashTemp(pgm, MASH_PROTEIN), 3, 0, 255, TUNIT));
    else if (lastOption == 4) setProgMashMins(pgm, MASH_SACCH, getTimerValue(PSTR("Sacch Rest"), getProgMashMins(pgm, MASH_SACCH)));
    else if (lastOption == 5) setProgMashTemp(pgm, MASH_SACCH, getValue(PSTR("Sacch Rest"), getProgMashTemp(pgm, MASH_SACCH), 3, 0, 255, TUNIT));
    else if (lastOption == 6) setProgMashMins(pgm, MASH_MASHOUT, getTimerValue(PSTR("Mash Out"), getProgMashMins(pgm, MASH_MASHOUT)));
    else if (lastOption == 7) setProgMashTemp(pgm, MASH_MASHOUT, stepTemp[STEP_MASHOUT] = getValue(PSTR("Mash Out"), getProgMashTemp(pgm, MASH_MASHOUT), 3, 0, 255, TUNIT));
    else return;
  }
}

unsigned int editHopSchedule (unsigned int sched) {
  unsigned int retVal = sched;
  byte lastOption = 0;
  while (1) {
    if (retVal & 1) strcpy_P(menuopts[0], PSTR("Boil: On")); else strcpy_P(menuopts[0], PSTR("Boil: Off"));
    for (byte i = 0; i < 10; i++) {
      strcpy(menuopts[i + 1], itoa(hoptimes[i], buf, 10));
      strcat_P(menuopts[i + 1], PSTR(" Min: "));
      if (retVal & (1<<(i + 1))) strcat_P(menuopts[i + 1], PSTR("On")); else strcat_P(menuopts[i + 1], PSTR("Off"));
    }
    if (retVal & 2048) strcpy_P(menuopts[11], PSTR("0 Min: On")); else strcpy_P(menuopts[11], PSTR("0 Min: Off"));
    strcpy_P(menuopts[12], EXIT);

    lastOption = scrollMenu("Boil Additions", 13, lastOption);
    if (lastOption == 12) return retVal;
    else if (lastOption == 13) return sched;
    else retVal = retVal ^ (1 << lastOption);
  }
}

byte MLHeatSrcMenu (byte MLHeatSrc) {
  strcpy_P(menuopts[0], HLTDESC);
  strcpy_P(menuopts[1], MASHDESC);
  byte lastOption = scrollMenu("Heat Mash Liq In:", 2, MLHeatSrc);
  if (lastOption > 1) return MLHeatSrc;
  else return lastOption;
}

void warnHLT() {
  clearLCD();
  printLCD_P(0, 0, PSTR("HLT Capacity Issue"));
  printLCD_P(1, 0, PSTR("Sparge Vol:"));
  ftoa(tgtVol[TS_HLT]/1000.0, buf, 2);
  truncFloat(buf, 5);
  printLCD(1, 11, buf);
  printLCD_P(1, 16, VOLUNIT);
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!enterStatus) brewCore();
  enterStatus = 0;
}


void warnMash() {
  clearLCD();
  printLCD_P(0, 0, PSTR("Mash Capacity Issue"));
  printLCD_P(1, 0, PSTR("Strike Vol:"));
  ftoa(tgtVol[TS_MASH]/1000.0, buf, 2);
  truncFloat(buf, 5);
  printLCD(1, 11, buf);
  printLCD_P(1, 16, VOLUNIT);
  printLCD_P(2, 0, PSTR("Grain Vol:"));
  ftoa(round(grainWeight * grain2Vol) / 1000.0, buf, 2);
  truncFloat(buf, 5);
  printLCD(2, 11, buf);
  printLCD_P(2, 16, VOLUNIT);
  printLCD(3, 4, ">");
  printLCD_P(3, 6, CONTINUE);
  printLCD(3, 15, "<");
  while (!enterStatus) brewCore();
  enterStatus = 0;
}



//*****************************************************************************************************************************
//Generic Menu Functions
//*****************************************************************************************************************************
byte scrollMenu(char sTitle[], byte numOpts, byte defOption) {
  //Uses Global menuopts[][20]
  encMin = 0;
  encMax = numOpts-1;
  
  encCount = defOption;
  byte lastCount = encCount + 1;
  byte topItem = numOpts;
  
  while(1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      if (lastCount < topItem) {
        clearLCD();
        if (sTitle != NULL) printLCD(0, 0, sTitle);
        if (numOpts <= 3) topItem = 0;
        else topItem = lastCount;
        drawItems(numOpts, topItem);
      } else if (lastCount > topItem + 2) {
        clearLCD();
        if (sTitle != NULL) printLCD(0, 0, sTitle);
        topItem = lastCount - 2;
        drawItems(numOpts, topItem);
      }
      for (byte i = 1; i <= 3; i++) if (i == lastCount - topItem + 1) printLCD(i, 0, ">"); else printLCD(i, 0, " ");
    }
    
    if (chkMsg()) rejectMsg(LOGGLB);
    
    //If Enter
    if (enterStatus) {
      if (enterStatus == 1) {
        enterStatus = 0;
        return encCount;
      } else if (enterStatus == 2) {
        enterStatus = 0;
        return numOpts;
      }
    }
    brewCore();
  }
}

void drawItems(byte numOpts, byte topItem) {
  //Uses Global menuopts[][20]
  byte maxOpt = topItem + 2;
  if (maxOpt > numOpts - 1) maxOpt = numOpts - 1;
  for (byte i = topItem; i <= maxOpt; i++) printLCD(i-topItem+1, 1, menuopts[i]);
}

byte getChoice(byte numChoices, byte iRow) {
  //Uses Global menuopts[][20]
  //Force 18 Char Limit
  for (byte i = 0; i < numChoices; i++) menuopts[i][18] = '\0';
  printLCD_P(iRow, 0, PSTR(">"));
  printLCD_P(iRow, 19, PSTR("<"));
  encMin = 0;
  encMax = numChoices - 1;
 
  encCount = 0;
  byte lastCount = encCount + 1;

  while(1) {
    if (encCount != lastCount) {
      printLCDCenter(iRow, 1, menuopts[encCount], 18);
      lastCount = encCount;
    }
    
    if (chkMsg()) rejectMsg(LOGGLB);
    
    //If Enter
    if (enterStatus) {
      printLCD_P(iRow, 0, SPACE);
      printLCD_P(iRow, 19, SPACE);
      if (enterStatus == 1) {
        enterStatus = 0;
        return encCount;
      } else if (enterStatus == 2) {
        enterStatus = 0;
        return numChoices;
      }
    }
    brewCore();
  }
}

boolean confirmAbort() {
  clearLCD();
  printLCD_P(0, 0, PSTR("ABORT and reset all"));
  printLCD_P(1, 0, PSTR("outputs, setpoints"));
  printLCD_P(2, 0, PSTR("and timers?"));
  strcpy_P(menuopts[0], CANCEL);
  strcpy_P(menuopts[1], EXIT);
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
  availableMemory();

  encMin = 0;
  encMax = digits;
  encCount = 0;
  byte lastCount = 1;

  lcdSetCustChar_P(0, CHARFIELD);
  lcdSetCustChar_P(1, CHARCURSOR);
  lcdSetCustChar_P(2, CHARSEL);
   
  clearLCD();
  printLCD_P(0, 0, sTitle);
  printLCD_P(1, (20 - digits + 1) / 2 + digits + 1, dispUnit);
  printLCD(3, 9, "OK");
  unsigned long whole, frac;
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        unsigned long factor = 1;
        for (byte i = 0; i < digits - cursorPos - 1; i++) factor *= 10;
        if (encCount > lastCount) retValue += (encCount-lastCount) * factor; else retValue -= (lastCount-encCount) * factor;
        lastCount = encCount;
        if (retValue > maxValue) retValue = maxValue;
      } else {
        lastCount = encCount;
        cursorPos = lastCount;
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
      lastCount = encCount;
      whole = retValue / pow(10, precision);
      frac = retValue - (whole * pow(10, precision)) ;
      printLCDLPad(1, (20 - digits + 1) / 2 - 1, ltoa(whole, buf, 10), digits - precision, ' ');
      if (precision) {
        printLCD(1, (20 - digits + 1) / 2 + digits - precision - 1, ".");
        printLCDLPad(1, (20 - digits + 1) / 2 + digits - precision, ltoa(frac, buf, 10), precision, '0');
      }
    }
    
    if (chkMsg()) rejectMsg(LOGGLB);

    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == digits) break;
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos - 1, 2);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos, 2);
          encMin = 0;
          encMax = 9;
          if (cursorPos < digits - precision) {
            ltoa(whole, buf, 10);
            if (cursorPos < digits - precision - strlen(buf)) encCount = 0; else  encCount = buf[cursorPos - (digits - precision - strlen(buf))] - '0';
          } else {
            ltoa(frac, buf, 10);
            if (cursorPos < digits - strlen(buf)) encCount = 0; else  encCount = buf[cursorPos - (digits - strlen(buf))] - '0';
          }
        } else {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos - 1, 1);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + cursorPos, 1);
          encMin = 0;
          encMax = digits;
          encCount = cursorPos;
        }
        lastCount = encCount;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      retValue = defValue;
      break;
    }
    brewCore();
  }
  return retValue;
}

unsigned int getTimerValue(const char *sTitle, unsigned int defMins) {
  byte hours = defMins / 60;
  byte mins = defMins - hours * 60;
  byte cursorPos = 0; //0 = Hours, 1 = Mins, 2 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  encMin = 0;
  encMax = 2;
  encCount = 0;
  byte lastCount = 1;
  
  clearLCD();
  printLCD_P(0,0,sTitle);
  printLCD(1, 9, ":");
  printLCD(1, 13, "(hh:mm)");
  printLCD(3, 8, "OK");
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        if (cursorPos) mins = encCount; else hours = encCount;
      } else {
        cursorPos = encCount;
        if (cursorPos == 0) {
            printLCD(1, 6, ">");
            printLCD(1, 12, " ");
            printLCD(3, 7, " ");
            printLCD(3, 10, " ");
        } else if (cursorPos == 1) {
            printLCD(1, 6, " ");
            printLCD(1, 12, "<");
            printLCD(3, 7, " ");
            printLCD(3, 10, " ");
        } else if (cursorPos == 2) {
          printLCD(1, 6, " ");
            printLCD(1, 12, " ");
            printLCD(3, 7, ">");
            printLCD(3, 10, "<");
        }
      }
      printLCDLPad(1, 7, itoa(hours, buf, 10), 2, '0');
      printLCDLPad(1, 10, itoa(mins, buf, 10), 2, '0');
      lastCount = encCount;
    }
    
    if (chkMsg()) rejectMsg(LOGGLB);

    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == 2) return hours * 60 + mins;
      cursorState = cursorState ^ 1;
      if (cursorState) {
        encMin = 0;
        encMax = 99;
        if (cursorPos)encCount = mins; else encCount = hours;
      } else {
        encMin = 0;
        encMax = 2;
        encCount = cursorPos;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return NULL;
    }
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

  encMin = 0;
  encMax = chars;
  encCount = 0;
  byte lastCount = 1;

  lcdSetCustChar_P(0, CHARFIELD);
  lcdSetCustChar_P(1, CHARCURSOR);
  lcdSetCustChar_P(2, CHARSEL);
  
  clearLCD();
  printLCD_P(0,0,sTitle);
  printLCD(3, 9, "OK");
  
  while(1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      if (cursorState) {
        retValue[cursorPos] = enc2ASCII(lastCount);
      } else {
        cursorPos = lastCount;
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
    
    if (chkMsg()) rejectMsg(LOGGLB);

    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == chars) {
        strcpy(defValue, retValue);
        return;
      }
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          encMin = 0;
          encMax = 94;
          encCount = ASCII2enc(retValue[cursorPos]);
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 2);
        } else {
          encMin = 0;
          encMax = chars;
          encCount = cursorPos;
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 1);
        }
        lastCount = encCount;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return;
    }
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
  else if (charin >= 1 && charin <= 26) return charin + 64;
  else if (charin >= 27 && charin <= 52) return charin + 70;
  else if (charin >= 53 && charin <= 62) return charin - 5;
  else if (charin >= 63 && charin <= 77) return charin - 30;
  else if (charin >= 78 && charin <= 84) return charin - 20;
  else if (charin >= 85 && charin <= 90) return charin + 6;
  else if (charin >= 91 && charin <= 94) return charin + 32;
}
//*****************************************************************************************************************************
// System Setup Menus
//*****************************************************************************************************************************
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

//*****************************************************************************************************************************
//Encoder Functions
//*****************************************************************************************************************************
void initEncoder() {
  //Encoder Setup
  #ifdef ENCODER_ALPS
    attachInterrupt(2, doEncoderALPS, CHANGE);
  #endif
  #ifdef ENCODER_CUI
    attachInterrupt(2, doEncoderCUI, RISING);
  #endif
  attachInterrupt(1, doEnter, CHANGE);
}

void doEncoderALPS() {
  if (digitalRead(2) != digitalRead(4)) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 
void doEncoderCUI() {
  if (millis() - lastEncUpd < 50) return;
  //Read EncB
  if (digitalRead(4) == LOW) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEnter() {
  if (digitalRead(11) == HIGH) {
    enterStart = millis();
  } else {
    if (millis() - enterStart > 1000) {
      enterStatus = 2;
    } else if (millis() - enterStart > ENTER_BOUNCE_DELAY) {
      enterStatus = 1;
    }
  }
}
