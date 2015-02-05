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

#ifndef NOUI
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
// UI Globals
//**********************************************************************************
byte activeScreen;
boolean screenLock;
unsigned long timerLastPrint;
boolean doInit = 1;

//**********************************************************************************
// uiInit:  One time intialization of all UI logic
//**********************************************************************************
void uiInit() {
  LCD.init();
   
  #ifndef ENCODER_I2C
    #ifndef ENCODER_OLD_CONSTRUCTOR
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN);
    #else
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN, ENTER_INT, ENCA_INT);
    #endif
    #ifdef ENCODER_ACTIVELOW
      Encoder.setActiveLow(1);
    #endif
  #else
     Encoder.begin(ENCODER_I2CADDR);
  #endif
  
  //Check to see if EEPROM Initialization is needed
  if (checkConfig()) {
    if (confirmChoice("Missing Config", "", "", INIT_EEPROM))
      UIinitEEPROM();
    LCD.clear();
  }

  setActive(SCREEN_HOME);
  unlockUI();
}

void UIinitEEPROM() {
  LCD.clear();
  LCD.print_P(1, 0, INIT_EEPROM);
  LCD.print_P(2, 3, PSTR("Please Wait..."));
  LCD.update();
  initEEPROM();
  //Apply any EEPROM updates
  checkConfig();
}

void uiEvent(byte eventID, byte eventParam) {
  if (eventID == EVENT_STEPINIT) {
    if (eventParam == BREWSTEP_FILL 
      || eventParam == BREWSTEP_REFILL
    ) setActive(SCREEN_FILL);
    else if (eventParam == BREWSTEP_DELAY
      || eventParam == BREWSTEP_PREHEAT
      || eventParam == BREWSTEP_DOUGHIN
      || eventParam == BREWSTEP_ACID
      || eventParam == BREWSTEP_PROTEIN
      || eventParam == BREWSTEP_SACCH
      || eventParam == BREWSTEP_SACCH2
      || eventParam == BREWSTEP_MASHOUT
      || eventParam == BREWSTEP_MASHHOLD
    ) setActive(SCREEN_MASH);
    else if (eventParam == BREWSTEP_GRAININ
      || eventParam == BREWSTEP_SPARGE
    ) setActive(SCREEN_SPARGE);
    else if (eventParam == BREWSTEP_BOIL) setActive(SCREEN_BOIL);
    else if (eventParam == BREWSTEP_CHILL) setActive(SCREEN_CHILL);
  }
  else if (eventID == EVENT_STEPEXIT) doInit = 1;
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
  doInit = 1;
}

void lockUI() {
  screenLock = 1;
  //Recall screenInit to setup encoder and other functions available only when locked
  doInit = 1;
}

//**********************************************************************************
// screenCore: Called in main loop to handle all UI functions
//**********************************************************************************
void uiCore() {
  if (isEStop())
    uiEstop();
  if (!screenLock) {
    int encValue = Encoder.change();
    if (encValue >= 0) {
      setActive(encValue);
    }
  }
  if (doInit) {
    screenInit();
    doInit = 0;
  }
  screenEnter();
  screenRefresh();
}

void setActive(byte screen) {
  activeScreen = screen;
  doInit = 1;
}

//**********************************************************************************
// screenInit: Initialize active screen
//**********************************************************************************
void screenInit() {
  LCD.clear();
  LCD.setCustChar_P(7, UNLOCK_ICON);
  
  //Print Program Active Char (Overwritten if no program active)
  if (activeScreen != SCREEN_HOME) {
    LCD.setCustChar_P(6, PROG_ICON);
    LCD.writeCustChar(0, 0, 6);
    LCD.setCustChar_P(5, BELL);
  }
  
  if (activeScreen == SCREEN_HOME) {
    //Screen Init: Home
      LCD.setCustChar_P(0, BMP0);
      LCD.setCustChar_P(1, BMP1);
      LCD.setCustChar_P(2, BMP2);
      LCD.setCustChar_P(3, BMP3);
      LCD.setCustChar_P(4, BMP4);
      LCD.writeCustChar(0, 0, 0);
      LCD.writeCustChar(0, 1, 1);
      LCD.writeCustChar(0, 2, 2);
      LCD.writeCustChar(1, 1, 3);
      LCD.writeCustChar(1, 2, 4);
      LCD.print_P(1, 4, BT);
      LCD.print_P(1, 16, BTVER);
      LCD.print_P(2, 4, PSTR("Build"));
      LCD.lPad(2, 10, itoa(BUILD, buf, 10), 4, '0');
      LCD.print_P(3, 0, PSTR("www.brewtroller.com"));
    
  } else if (activeScreen == SCREEN_FILL) {
    //Screen Init: Fill/Refill
    if (brewStepIsActive(BREWSTEP_FILL)) LCD.print_P(0, 1, PSTR("Fill"));
    else if (brewStepIsActive(BREWSTEP_REFILL)) LCD.print_P(0, 1, PSTR("Refill"));
    else LCD.print_P(0, 0, PSTR("Fill"));
    LCD.print_P(0, 11, PSTR("HLT"));
    LCD.print_P(0, 16, PSTR("Mash"));
    LCD.print_P(1, 1, PSTR("Target"));
    LCD.print_P(2, 1, PSTR("Actual"));
    vftoa(tgtVol[VS_HLT], buf, 1000, 1);
    truncFloat(buf, 5);
    LCD.lPad(1, 9, buf, 5, ' ');
    vftoa(tgtVol[VS_MASH], buf, 1000, 1);
    truncFloat(buf, 5);
    LCD.lPad(1, 15, buf, 5, ' ');

    if (screenLock) {
      LCD.print_P(3, 0, PSTR(">"));
      LCD.print_P(3, 10, PSTR("<"));
      LCD.print_P(3, 1, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(5);
      Encoder.setCount(0);
    }
    
  } else if (activeScreen == SCREEN_MASH) {
    //Screen Init: Preheat/Mash
    //Delay Start Indication
    timerLastPrint = 0;
    
    if (brewStepIsActive(BREWSTEP_DELAY)) LCD.print_P(0, 1, PSTR("Delay"));
    else if (brewStepIsActive(BREWSTEP_PREHEAT)) LCD.print_P(0, 1, PSTR("Preheat"));
    else if (brewStepIsActive(BREWSTEP_DOUGHIN)) LCD.print_P(0, 1, PSTR("Dough In"));
    else if (brewStepIsActive(BREWSTEP_ACID)) LCD.print_P(0, 1, PSTR("Acid"));
    else if (brewStepIsActive(BREWSTEP_PROTEIN)) LCD.print_P(0, 1, PSTR("Protein"));
    else if (brewStepIsActive(BREWSTEP_SACCH)) LCD.print_P(0, 1, PSTR("Sacch"));
    else if (brewStepIsActive(BREWSTEP_SACCH2)) LCD.print_P(0, 1, PSTR("Sacch2"));
    else if (brewStepIsActive(BREWSTEP_MASHOUT)) LCD.print_P(0, 1, PSTR("Mash Out"));
    else if (brewStepIsActive(BREWSTEP_MASHHOLD)) LCD.print_P(0, 1, PSTR("End Mash"));
    else LCD.print_P(0, 0, PSTR("Mash"));
    LCD.print_P(0, 11, PSTR("HLT"));
    LCD.print_P(0, 16, PSTR("Mash"));
    LCD.print_P(1, 1, PSTR("Target"));
    LCD.print_P(2, 1, PSTR("Actual"));
    
    LCD.print_P(1, 13, TUNIT);
    LCD.print_P(1, 19, TUNIT);
    LCD.print_P(2, 13, TUNIT);
    LCD.print_P(2, 19, TUNIT);
  } else if (activeScreen == SCREEN_SPARGE) {
    //Screen Init: Sparge
    if (brewStepIsActive(BREWSTEP_SPARGE)) LCD.print_P(0, 1, PSTR("Sparge"));
    else if (brewStepIsActive(BREWSTEP_GRAININ)) LCD.print_P(0, 1, PSTR("Grain In"));
    else LCD.print_P(0, 0, PSTR("Sparge"));
    LCD.print_P(1, 1, PSTR("HLT"));
    LCD.print_P(2, 1, PSTR("Mash"));
    LCD.print_P(3, 1, PSTR("Kettle"));
    LCD.print_P(1, 8, PSTR("---"));
    LCD.print_P(2, 8, PSTR("---"));
    LCD.print_P(3, 8, PSTR("---"));
    LCD.print_P(1, 14, PSTR("--.---"));
    LCD.print_P(2, 14, PSTR("--.---"));
    LCD.print_P(3, 14, PSTR("--.---"));
    LCD.print_P(1, 12, TUNIT);
    LCD.print_P(2, 12, TUNIT);
    LCD.print_P(3, 12, TUNIT);

    if (screenLock) {
      LCD.print_P(0, 8, PSTR(">"));
      LCD.print_P(0, 19, PSTR("<"));
      LCD.print_P(0, 10, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(7);
      Encoder.setCount(0);
    }
    
  } else if (activeScreen == SCREEN_BOIL) {
    //Screen Init: Boil
    timerLastPrint = 0;
    if (brewStepIsActive(BREWSTEP_BOIL)) LCD.print_P(0, 1, PSTR("Boil"));
    else LCD.print_P(0,0,PSTR("Boil"));
    LCD.print_P(1, 19, TUNIT);

    if (screenLock) {
        Encoder.setMin(0);
        Encoder.setMax(pwmOutput[VS_KETTLE] ? pwmOutput[VS_KETTLE]->getLimit() : 1);
        Encoder.setCount(pwmOutput[VS_KETTLE] ? PIDOutput[VS_KETTLE] : heatStatus[VS_KETTLE]);
        //If Kettle is off keep it off until unlocked
        if (!setpoint[VS_KETTLE]) boilControlState = CONTROLSTATE_OFF;
    }

  } else if (activeScreen == SCREEN_CHILL) {
    //Screen Init: Chill
    if (brewStepIsActive(BREWSTEP_CHILL)) LCD.print_P(0, 1, PSTR("Chill"));
    else LCD.print_P(0, 0, PSTR("Chill"));
    LCD.print_P(0, 11, PSTR("Beer"));
    LCD.print_P(0, 17, PSTR("H2O"));
    LCD.print_P(1, 8, PSTR("In"));
    LCD.print_P(2, 7, PSTR("Out"));

    LCD.print_P(1, 14, TUNIT);
    LCD.print_P(1, 19, TUNIT);
    LCD.print_P(2, 14, TUNIT);
    LCD.print_P(2, 19, TUNIT);
    
    if (screenLock) {
      LCD.print_P(3, 0, PSTR(">"));
      LCD.print_P(3, 11, PSTR("<"));
      LCD.print_P(3, 2, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(6);
      Encoder.setCount(0);
    }

  } else if (activeScreen == SCREEN_AUX) {
    //Screen Init: AUX
    LCD.print_P(0,0,PSTR("AUX Temps"));
    LCD.print_P(1,1,PSTR("AUX1"));
    LCD.print_P(2,1,PSTR("AUX2"));
    LCD.print_P(1, 11, TUNIT);
    LCD.print_P(2, 11, TUNIT);
    LCD.print_P(3, 1, PSTR("AUX3"));
    LCD.print_P(3, 11, TUNIT);
  }
  
  //Write Unlock symbol to upper right corner
  if (!screenLock) LCD.writeCustChar(0, 19, 7);
}

//**********************************************************************************
// screenRefresh:  Refresh active screen
//**********************************************************************************
void screenRefresh() {
  if (activeScreen == SCREEN_HOME) {
    //Refresh Screen: Home

  } else if (activeScreen == SCREEN_FILL) {
    vftoa(volAvg[VS_HLT], buf, 1000, 1);
    truncFloat(buf, 5);
    LCD.lPad(2, 9, buf, 5, ' ');

    vftoa(volAvg[VS_MASH], buf, 1000, 1);
    truncFloat(buf, 5);
    LCD.lPad(2, 15, buf, 5, ' ');

    LCD.print_P(3, 11, outputs->getProfileState(OUTPUTPROFILE_FILLHLT) ? PSTR("On ") : PSTR("Off"));
    LCD.print_P(3, 17, outputs->getProfileState(OUTPUTPROFILE_FILLMASH) ? PSTR("On ") : PSTR("Off"));
    
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        LCD.rPad(3, 1, "", 9, ' ');
        if (encValue == 0) LCD.print_P(3, 1, CONTINUE);
        else if (encValue == 1) LCD.print_P(3, 1, FILLHLT);
        else if (encValue == 2) LCD.print_P(3, 1, FILLMASH);
        else if (encValue == 3) LCD.print_P(3, 1, FILLBOTH);
        else if (encValue == 4) LCD.print_P(3, 2, ALLOFF);
        else if (encValue == 5) LCD.print_P(3, 3, MENU);
      }
    }
    
  } else if (activeScreen == SCREEN_MASH) {
    //Refresh Screen: Preheat/Mash
    
    for (byte i = VS_HLT; i <= VS_MASH; i++) {
      vftoa(setpoint[i], buf, 100, 1);
      truncFloat(buf, 4);
      LCD.lPad(1, i * 6 + 9, buf, 4, ' ');
      vftoa(temp[i], buf, 100, 1);
      truncFloat(buf, 4);
      if (temp[i] == BAD_TEMP) {
        LCD.print_P(2, i * 6 + 9, PSTR("----")); 
      } else {
        LCD.lPad(2, i * 6 + 9, buf, 4, ' ');
      }
      byte pct;
      if (pwmOutput[i]) {
        pct = getHeatPower(i);
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
      LCD.lPad(3, i * 6 + 11, buf, 3, ' ');
      printTimer(TIMER_MASH, 3, 0);
    }



  } else if (activeScreen == SCREEN_SPARGE) {
    //Refresh Screen: Sparge
    #ifdef VOLUME_MANUAL
      // In manual volume mode show the target volumes instead of the current volumes
      vftoa(tgtVol[VS_HLT], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(1, 14, buf, 6, ' ');
        
      vftoa(tgtVol[VS_MASH], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(2, 14, buf, 6, ' ');
        
      vftoa(tgtVol[VS_KETTLE], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(3, 14, buf, 6, ' ');
    #else
      vftoa(volAvg[VS_HLT], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(1, 14, buf, 6, ' ');
        
      vftoa(volAvg[VS_MASH], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(2, 14, buf, 6, ' ');
        
      vftoa(volAvg[VS_KETTLE], buf, 1000, 1);
      truncFloat(buf, 6);
      LCD.lPad(3, 14, buf, 6, ' ');
    #endif
    
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        LCD.rPad(0, 9, "", 10, ' ');

        if (encValue == 0) LCD.print_P(0, 10, CONTINUE);
        else if (encValue == 1) LCD.print_P(0, 9, SPARGEIN);
        else if (encValue == 2) LCD.print_P(0, 9, SPARGEOUT);
        else if (encValue == 3) LCD.print_P(0, 9, FLYSPARGE);
        else if (encValue == 4) LCD.print_P(0, 9, MASHHEAT);
        else if (encValue == 5) LCD.print_P(0, 9, MASHIDLE);
        else if (encValue == 6) LCD.print_P(0, 11, ALLOFF);
        else if (encValue == 7) LCD.print_P(0, 12, MENU);
      }
    }

    // Not sure what to do here, due to the very serious design
    // defect of using temperature sensors IDs as the index variable.
    for (byte i = TS_HLT; i <= TS_KETTLE; i++) {
      vftoa(temp[i], buf, 100, 1);
      truncFloat(buf, 4);
      if (temp[i] == BAD_TEMP) LCD.print_P(i + 1, 8, PSTR("----")); else LCD.lPad(i + 1, 8, buf, 4, ' ');
    }
  } else if (activeScreen == SCREEN_BOIL) {
    //Refresh Screen: Boil
    if (screenLock) {
      switch (boilControlState) {
        case CONTROLSTATE_OFF:
          LCD.print_P(0, 14, PSTR("   Off"));
          break;
        case CONTROLSTATE_AUTO:
          LCD.print_P(0, 14, PSTR("  Auto"));
          break;
        case CONTROLSTATE_MANUAL:
          LCD.print_P(0, 14, PSTR("Manual"));
          break;
      }
    }
    
    printTimer(TIMER_BOIL, 3, 0);

    vftoa(volAvg[VS_KETTLE], buf, 1000, 1);
    truncFloat(buf, 5);
    LCD.lPad(2, 15, buf, 5, ' ');

    if (pwmOutput[VS_KETTLE]) {
      byte pct = getHeatPower(VS_KETTLE);
      if (pct == 0) strcpy_P(buf, PSTR("Off"));
      else if (pct == 100) strcpy_P(buf, PSTR(" On"));
      else { itoa(pct, buf, 10); strcat(buf, "%"); }
    } else if (heatStatus[TS_KETTLE]) {
      strcpy_P(buf, PSTR(" On")); 
    } else {
      strcpy_P(buf, PSTR("Off"));
    }
    LCD.lPad(3, 17, buf, 3, ' ');
    vftoa(temp[TS_KETTLE], buf, 100, 1);
    truncFloat(buf, 5);
    if (temp[TS_KETTLE] == BAD_TEMP)
      LCD.print_P(1, 14, PSTR("-----"));
    else
      LCD.lPad(1, 14, buf, 5, ' ');
    if (screenLock) {
      if (boilControlState != CONTROLSTATE_OFF) {
        int encValue = Encoder.change();
        if (encValue >= 0) {
          if ( boilControlState == CONTROLSTATE_AUTO)
            boilControlState = CONTROLSTATE_MANUAL;
          PIDOutput[VS_KETTLE] = encValue;
        }
        
      }
      if (boilControlState == CONTROLSTATE_AUTO)
        Encoder.setCount(pwmOutput[VS_KETTLE] ? PIDOutput[VS_KETTLE] : heatStatus[VS_KETTLE]);
    }
    
  } else if (activeScreen == SCREEN_CHILL) {
    //Refresh Screen: Chill
    if (screenLock) {
      int encValue = Encoder.change();
      if (encValue >= 0) {
        LCD.rPad(3, 1, "", 10, ' ');
        if (encValue == 0) LCD.print_P(3, 2, CONTINUE);
        else if (encValue == 1) LCD.print_P(3, 1, CHILLNORM);
        else if (encValue == 2) LCD.print_P(3, 1, CHILLH2O);
        else if (encValue == 3) LCD.print_P(3, 1, CHILLBEER);
        else if (encValue == 4) LCD.print_P(3, 2, ALLOFF);
        else if (encValue == 5) LCD.print_P(3, 4, PSTR("Auto"));
        else if (encValue == 6) LCD.print_P(3, 3, ABORT);
      }
    }
    if (temp[TS_KETTLE] == BAD_TEMP) LCD.print_P(1, 11, PSTR("---")); else LCD.lPad(1, 11, itoa(temp[TS_KETTLE] / 100, buf, 10), 3, ' ');
    if (temp[TS_BEEROUT] == BAD_TEMP) LCD.print_P(2, 11, PSTR("---")); else LCD.lPad(2, 11, itoa(temp[TS_BEEROUT] / 100, buf, 10), 3, ' ');
    if (temp[TS_H2OIN] == BAD_TEMP) LCD.print_P(1, 16, PSTR("---")); else LCD.lPad(1, 16, itoa(temp[TS_H2OIN] / 100, buf, 10), 3, ' ');
    if (temp[TS_H2OOUT] == BAD_TEMP) LCD.print_P(2, 16, PSTR("---")); else LCD.lPad(2, 16, itoa(temp[TS_H2OOUT] / 100, buf, 10), 3, ' ');
    LCD.print_P(3, 12, outputs->getProfileState(OUTPUTPROFILE_CHILLBEER) ? PSTR("On ") : PSTR("Off"));
    LCD.print_P(3, 17, outputs->getProfileState(OUTPUTPROFILE_CHILLH2O) ? PSTR("On ") : PSTR("Off"));

  } else if (activeScreen == SCREEN_AUX) {
    //Screen Refresh: AUX
  for (byte i = TS_AUX1; i <= TS_AUX3; i++) {
      if (temp[i] == BAD_TEMP) {
        LCD.print_P(i - 5, 6, PSTR("-----")); 
      } else {
        vftoa(temp[i], buf, 100, 1);
        truncFloat(buf, 5);
        LCD.lPad(i - 5, 6, buf, 5, ' ');
      }
    }
  }
}


//**********************************************************************************
// screenEnter:  Check enterStatus and handle based on screenLock and activeScreen
//**********************************************************************************
void screenEnter() {
  if (Encoder.cancel()) {
    //Unlock screens
    unlockUI();
  } else if (Encoder.ok()) {
    if (alarmStatus) setAlarm(0);
    else if (!screenLock) lockUI();
    else {
      if (activeScreen == SCREEN_HOME) {
      //Screen Enter: Home
        menu homeMenu(3, 9);

        while(1) {
          //Item updated on each cycle
          homeMenu.setItem_P(PSTR("Edit Program"), 1);
          homeMenu.setItem_P(PSTR("Start Program"), 2);

          homeMenu.setItem_P(DRAIN, 3);
          homeMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_DRAIN) ? PSTR(": On") : PSTR(": Off"), 3);

          homeMenu.setItem_P(USER1, 4);
          homeMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_USER1) ? PSTR(": On") : PSTR(": Off"), 4);
          
          homeMenu.setItem_P(USER2, 5);
          homeMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_USER2) ? PSTR(": On") : PSTR(": Off"), 5);
          
          homeMenu.setItem_P(USER3, 6);
          homeMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_USER3) ? PSTR(": On") : PSTR(": Off"), 6);

          homeMenu.setItem_P(PSTR("Reset All"), 7);
          homeMenu.setItem_P(PSTR("System Setup"), 8);
          homeMenu.setItem_P(EXIT, 255);

          byte lastOption = scrollMenu("Main Menu", &homeMenu);
          
          if (lastOption == 1) editProgramMenu();
          else if (lastOption == 2) {
              startProgramMenu();
              if (activeScreen == SCREEN_FILL) {
                doInit = 1;
                break;
              }
          }
          else if (lastOption == 3) {
            //Drain
            if (outputs->getProfileState(OUTPUTPROFILE_DRAIN))
              outputs->setProfileState(OUTPUTPROFILE_DRAIN, 0);
            else {
              if (zoneIsActive(ZONE_MASH) || zoneIsActive(ZONE_BOIL)) {
                LCD.clear();
                LCD.print_P(0, 0, PSTR("Cannot drain while"));
                LCD.print_P(1, 0, PSTR("mash or boil zone"));
                LCD.print_P(2, 0, PSTR("is active"));
                LCD.print(3, 4, ">");
                LCD.print_P(3, 6, CONTINUE);
                LCD.print(3, 15, "<");
                while (!Encoder.ok()) brewCore();
              } else
                outputs->setProfileState(OUTPUTPROFILE_DRAIN, 1);
            }
          }
          else if (lastOption >= 4 && lastOption <= 6) {
            //User Profiles 1-3
            byte profileIndex = OUTPUTPROFILE_USER1 + (lastOption - 4);
            outputs->setProfileState(profileIndex, outputs->getProfileState(profileIndex) ? 0 : 1);
          }          
          else if (lastOption == 7) {
            //Reset All
            if (confirmAbort()) {
              programThreadResetAll();
              resetOutputs();
              clearTimer(TIMER_MASH);
              clearTimer(TIMER_BOIL);
            }
          }
          
          else if (lastOption == 8) menuSetup();
          else {
            //On exit of the Main menu go back to Splash/Home screen.
            setActive(SCREEN_HOME);
            unlockUI();
            break;
          }
        }
        doInit = 1;

      } else if (activeScreen == SCREEN_FILL) {
        //Sceeen Enter: Fill/Refill
        int encValue = Encoder.getCount();
        if (encValue == 0) continueClick();
        else if (encValue == 1) { 
          autoValve[AV_FILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_FILLMASH, 0); 
          outputs->setProfileState(OUTPUTPROFILE_FILLHLT, 1);
        } else if (encValue == 2) { 
          autoValve[AV_FILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_FILLHLT, 0); 
          outputs->setProfileState(OUTPUTPROFILE_FILLMASH, 1);
        } else if (encValue == 3) {
          autoValve[AV_FILL] = 0;
          outputs->setProfileState(OUTPUTPROFILE_FILLHLT, 1);
          outputs->setProfileState(OUTPUTPROFILE_FILLMASH, 1);
        } else if (encValue == 4) {
          autoValve[AV_FILL] = 0;
          outputs->setProfileState(OUTPUTPROFILE_FILLHLT, 0);
          outputs->setProfileState(OUTPUTPROFILE_FILLMASH, 0);
        } else if (encValue == 5) {
          menu fillMenu(3, 6);
          fillMenu.setItem_P(PSTR("Auto Fill"), 0);
          fillMenu.setItem_P(PSTR("HLT Target"), 1);
          fillMenu.setItem_P(PSTR("Mash Target"), 2);
          fillMenu.setItem_P(CONTINUE, 3);
          fillMenu.setItem_P(ABORT, 4);
          fillMenu.setItem_P(EXIT, 255);

          byte lastOption = scrollMenu("Fill Menu", &fillMenu);
          if (lastOption == 0) { if(tgtVol[VS_HLT] || tgtVol[VS_MASH]) autoValve[AV_FILL] = 1; }
          else if (lastOption == 1) tgtVol[VS_HLT] = getValue_P(PSTR("HLT Target Vol"), tgtVol[VS_HLT], 1000, 9999999, VOLUNIT);
          else if (lastOption == 2) tgtVol[VS_MASH] = getValue_P(PSTR("Mash Target Vol"), tgtVol[VS_MASH], 1000, 9999999, VOLUNIT);
          else if (lastOption == 3) continueClick();     
          else if (lastOption == 4) {
            if (confirmAbort()) {
              if (brewStepIsActive(BREWSTEP_FILL))
                brewStepSignal(BREWSTEP_FILL, STEPSIGNAL_ABORT);
              else
                brewStepSignal(BREWSTEP_REFILL, STEPSIGNAL_ABORT);
            }
          }
          doInit = 1;
        }

      } else if (activeScreen == SCREEN_MASH) {
        //Screen Enter: Preheat/Mash
        menu mashMenu(3, 7);

        mashMenu.setItem_P(PSTR("HLT Setpoint:"), 0);
        vftoa(setpoint[VS_HLT], buf, 100, 1);
        truncFloat(buf, 4);
        mashMenu.appendItem(buf, 0);
        mashMenu.appendItem_P(TUNIT, 0);
        
        mashMenu.setItem_P(PSTR("Mash Setpoint:"), 1);
        vftoa(setpoint[VS_MASH], buf, 100, 1);
        truncFloat(buf, 4);
        mashMenu.appendItem(buf, 1);
        mashMenu.appendItem_P(TUNIT, 1);
        
        mashMenu.setItem_P(PSTR("Set Timer"), 2);

        if (timerStatus[TIMER_MASH]) mashMenu.setItem_P(PSTR("Pause Timer"), 3);
        else mashMenu.setItem_P(PSTR("Start Timer"), 3);

        mashMenu.setItem_P(CONTINUE, 4);
        mashMenu.setItem_P(ABORT, 5);
        mashMenu.setItem_P(EXIT, 255);
        
        byte lastOption = scrollMenu("Mash Menu", &mashMenu);
        if (lastOption == 0) setSetpoint(VS_HLT, getValue_P(PSTR("HLT Setpoint"), setpoint[VS_HLT] / SETPOINT_MULT, SETPOINT_DIV, 255, TUNIT));
        else if (lastOption == 1) setSetpoint(VS_MASH, getValue_P(PSTR("Mash Setpoint"), setpoint[VS_MASH] / SETPOINT_MULT, SETPOINT_DIV, 255, TUNIT));
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
          byte brewstep = BREWSTEP_NONE;
          if (brewStepIsActive(BREWSTEP_DELAY)) brewstep = BREWSTEP_DELAY;
          else if (brewStepIsActive(BREWSTEP_DOUGHIN)) brewstep = BREWSTEP_DOUGHIN;
          else if (brewStepIsActive(BREWSTEP_PREHEAT)) brewstep = BREWSTEP_PREHEAT;
          else if (brewStepIsActive(BREWSTEP_ACID)) brewstep = BREWSTEP_ACID;
          else if (brewStepIsActive(BREWSTEP_PROTEIN)) brewstep = BREWSTEP_PROTEIN;
          else if (brewStepIsActive(BREWSTEP_SACCH)) brewstep = BREWSTEP_SACCH;
          else if (brewStepIsActive(BREWSTEP_SACCH2)) brewstep = BREWSTEP_SACCH2;
          else if (brewStepIsActive(BREWSTEP_MASHOUT)) brewstep = BREWSTEP_MASHOUT;
          else if (brewStepIsActive(BREWSTEP_MASHHOLD)) brewstep = BREWSTEP_MASHHOLD;
          if(brewstep != BREWSTEP_NONE) {
            brewStepSignal(brewstep, STEPSIGNAL_ADVANCE);
            if(brewStepIsActive(brewstep)) {
              //Failed to advance step
              stepAdvanceFailDialog();
            }
          } else activeScreen = SCREEN_SPARGE;
        } else if (lastOption == 5) {
          if (confirmAbort()) {
            if (brewStepIsActive(BREWSTEP_DELAY))
              brewStepSignal(BREWSTEP_DELAY, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_DOUGHIN))
              brewStepSignal(BREWSTEP_DOUGHIN, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_PREHEAT))
              brewStepSignal(BREWSTEP_PREHEAT, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_ACID))
              brewStepSignal(BREWSTEP_ACID, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_PROTEIN))
              brewStepSignal(BREWSTEP_PROTEIN, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_SACCH))
              brewStepSignal(BREWSTEP_SACCH, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_SACCH2))
              brewStepSignal(BREWSTEP_SACCH2, STEPSIGNAL_ABORT);
            else if (brewStepIsActive(BREWSTEP_MASHOUT))
              brewStepSignal(BREWSTEP_MASHOUT, STEPSIGNAL_ABORT);
            else
              brewStepSignal(BREWSTEP_MASHHOLD, STEPSIGNAL_ABORT); //Abort BREWSTEP_MASHOUT or manual operation
          }
        }
        doInit = 1;
        
      } else if (activeScreen == SCREEN_SPARGE) {
        //Screen Enter: Sparge
        int encValue = Encoder.getCount();
        if (encValue == 0) continueClick();
        else if (encValue == 1) { 
          resetSpargeOutputs(); 
          outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1); 
        } else if (encValue == 2) { 
          resetSpargeOutputs(); 
          outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 1); 
        } else if (encValue == 3) {
          resetSpargeOutputs(); 
          outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1); 
          outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 1); 
        } else if (encValue == 4) {
          resetSpargeOutputs(); 
          outputs->setProfileState(OUTPUTPROFILE_MASHHEAT, 1); 
        } else if (encValue == 5) {
          resetSpargeOutputs(); 
          outputs->setProfileState(OUTPUTPROFILE_MASHIDLE, 1); 
        } else if (encValue == 6)
          resetSpargeOutputs();
        else if (encValue == 7) {
          menu spargeMenu(3, 8);
          spargeMenu.setItem_P(PSTR("Auto In"), 0);
          spargeMenu.setItem_P(PSTR("Auto Out"), 1);
          spargeMenu.setItem_P(PSTR("Auto Fly"), 2);
          spargeMenu.setItem_P(PSTR("HLT Target"), 3);
          spargeMenu.setItem_P(PSTR("Kettle Target"), 4);
          spargeMenu.setItem_P(CONTINUE, 5);
          spargeMenu.setItem_P(ABORT, 6);
          spargeMenu.setItem_P(EXIT, 255);
          byte lastOption = scrollMenu("Sparge Menu", &spargeMenu);
          if (lastOption == 0) { resetSpargeOutputs(); if(tgtVol[VS_HLT]) autoValve[AV_SPARGEIN] = 1; }
          else if (lastOption == 1) { resetSpargeOutputs(); if(tgtVol[VS_KETTLE]) autoValve[AV_SPARGEOUT] = 1; }
          else if (lastOption == 2) { resetSpargeOutputs(); if(tgtVol[VS_KETTLE]) autoValve[AV_FLYSPARGE] = 1; }
          else if (lastOption == 3) tgtVol[VS_HLT] = getValue_P(PSTR("HLT Target Vol"), tgtVol[VS_HLT], 1000, 9999999, VOLUNIT);
          else if (lastOption == 4) tgtVol[VS_KETTLE] = getValue_P(PSTR("Kettle Target Vol"), tgtVol[VS_KETTLE], 1000, 9999999, VOLUNIT);
          else if (lastOption == 5) continueClick();
          else if (lastOption == 6) {
            if (confirmAbort()) {
              if (brewStepIsActive(BREWSTEP_GRAININ))
                brewStepSignal(BREWSTEP_GRAININ, STEPSIGNAL_ABORT);
              else
                brewStepSignal(BREWSTEP_SPARGE, STEPSIGNAL_ABORT); //Abort BREWSTEP_SPARGE or manual operation
            }
          }
          doInit = 1;
        }
       

      } else if (activeScreen == SCREEN_BOIL) {
        //Screen Enter: Boil
        menu boilMenu(3, 9);
        boilMenu.setItem_P(PSTR("Set Timer"), 0);
        
        if (timerStatus[TIMER_BOIL]) boilMenu.setItem_P(PSTR("Pause Timer"), 1);
        else boilMenu.setItem_P(PSTR("Start Timer"), 1);
        
        boilMenu.setItem_P(PSTR("Boil Ctrl: "), 2);
        switch (boilControlState) {
          case CONTROLSTATE_OFF:
            boilMenu.appendItem_P(PSTR("Off"), 2);
            break;
          case CONTROLSTATE_AUTO:
            boilMenu.appendItem_P(PSTR("Auto"), 2);
            break;
          case CONTROLSTATE_MANUAL:
            boilMenu.appendItem_P(PSTR("Manual"), 2);
            break;
        }

        
        boilMenu.setItem_P(PSTR("Boil Temp: "), 3);
        vftoa(getBoilTemp() * SETPOINT_MULT, buf, 100, 1);
        truncFloat(buf, 5);
        boilMenu.appendItem(buf, 3);
        boilMenu.appendItem_P(TUNIT, 3);
        
        boilMenu.setItem_P(PSTR("Boil Power: "), 4);
        boilMenu.appendItem(itoa(boilPwr, buf, 10), 4);
        boilMenu.appendItem("%", 4);
        
        boilMenu.setItem_P(BOILRECIRC, 5);
        boilMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_BOILRECIRC) ? PSTR(": On") : PSTR(": Off"), 5);
        
        boilMenu.setItem_P(CONTINUE, 6);
        boilMenu.setItem_P(ABORT, 7);
        boilMenu.setItem_P(EXIT, 255);        
        byte lastOption = scrollMenu("Boil Menu", &boilMenu);
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
        else if (lastOption == 2) boilControlMenu();
        else if (lastOption == 3) {
          setBoilTemp(getValue_P(PSTR("Boil Temp"), getBoilTemp(), SETPOINT_DIV, 255, TUNIT));
          setSetpoint(VS_KETTLE, getBoilTemp() * SETPOINT_MULT);
        }
        else if (lastOption == 4) setBoilPwr(getValue_P(PSTR("Boil Power"), boilPwr, 1, 100, PSTR("%")));
        else if (lastOption == 5)
          outputs->setProfileState(OUTPUTPROFILE_BOILRECIRC, outputs->getProfileState(OUTPUTPROFILE_BOILRECIRC) ? 0 : 1);
        else if (lastOption == 6) {
          if (brewStepIsActive(BREWSTEP_BOIL)) {
            brewStepSignal(BREWSTEP_BOIL, STEPSIGNAL_ADVANCE);
            if (brewStepIsActive(BREWSTEP_BOIL)) {
              //Failed to advance step
              stepAdvanceFailDialog();
            }
          } else {
            setActive(SCREEN_CHILL);
          }
        } else if (lastOption == 7) {
          if (confirmAbort())
            brewStepSignal(BREWSTEP_BOIL, STEPSIGNAL_ABORT);
        }
        doInit = 1;
        
      } else if (activeScreen == SCREEN_CHILL) {
        //Screen Enter: Chill

        int encValue = Encoder.getCount();
        if (encValue == 0) {
          brewStepSignal(BREWSTEP_CHILL, STEPSIGNAL_ADVANCE);
          setActive(SCREEN_HOME);
        }
        else if (encValue == 1) {
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILLH2O, 1);
          outputs->setProfileState(OUTPUTPROFILE_CHILLBEER, 1);
        } else if (encValue == 2) {
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILLBEER, 0);
          outputs->setProfileState(OUTPUTPROFILE_CHILLH2O, 1);
        } else if (encValue == 3) {
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILLH2O, 0);
          outputs->setProfileState(OUTPUTPROFILE_CHILLBEER, 1);
        } else if (encValue == 4) {
          autoValve[AV_CHILL] = 0;
          outputs->setProfileState(OUTPUTPROFILE_CHILLH2O, 0);
          outputs->setProfileState(OUTPUTPROFILE_CHILLBEER, 0); 
        } else if (encValue == 5)
          autoValve[AV_CHILL] = 1;        
      }
    }
  }
}

void uiEstop() {
  LCD.clear();
  LCD.print_P(0, 0, PSTR("E-Stop Triggered"));
  Encoder.setMin(0);
  Encoder.setMax(1);
  Encoder.setCount(0);
  LCD.print_P(1, 0, PSTR(">Clear Alarm"));
  LCD.print_P(2, 0, PSTR(" Clear E-Stop"));

  while (isEStop()) {
    if (Encoder.change() >= 0) {
      LCD.print(2 - Encoder.getCount(), 0, " ");
      LCD.print(Encoder.getCount() + 1, 0, ">");
      LCD.update();
    }
    if (Encoder.ok()) {
      if (Encoder.getCount() == 0)
        setAlarm(0);
      else if (Encoder.getCount() == 1)
        outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, 0xFFFFFFFFul);
    }
    brewCore();
  }
  doInit = 1; 
}

void boilControlMenu() {
  menu boilMenu(3, 3);
  boilMenu.setItem_P(PSTR("Off"), CONTROLSTATE_OFF);
  boilMenu.setItem_P(PSTR("Auto"), CONTROLSTATE_AUTO);
  boilMenu.setItem_P(PSTR("Manual"), CONTROLSTATE_MANUAL);
  byte lastOption = scrollMenu("Boil Control Menu", &boilMenu);
  if (lastOption < NUM_CONTROLSTATES) boilControlState = (ControlState) lastOption;
  switch (boilControlState) {
    case CONTROLSTATE_OFF:
      setSetpoint(VS_KETTLE, 0);
      break;
    case CONTROLSTATE_AUTO:
    case CONTROLSTATE_MANUAL:
      setSetpoint(VS_KETTLE, getBoilTemp() * SETPOINT_MULT);
      break;
  }
}

void continueClick() {
  byte brewstep = BREWSTEP_NONE;
  if (brewStepIsActive(BREWSTEP_FILL)) brewstep = BREWSTEP_FILL;
  else if (brewStepIsActive(BREWSTEP_REFILL)) brewstep = BREWSTEP_REFILL;
  else if (brewStepIsActive(BREWSTEP_SPARGE)) brewstep = BREWSTEP_SPARGE;
  else if (brewStepIsActive(BREWSTEP_GRAININ)) brewstep = BREWSTEP_GRAININ;
  if(brewstep != BREWSTEP_NONE) {
    brewStepSignal(brewstep, STEPSIGNAL_ADVANCE);
    if (brewStepIsActive(brewstep)) {
      //Failed to advance step
      stepAdvanceFailDialog();
    }
  } else setActive(activeScreen + 1);
  doInit = 1;
}

void stepAdvanceFailDialog() {
  LCD.clear();
  LCD.print_P(0, 0, PSTR("Failed to advance"));
  LCD.print_P(1, 0, PSTR("program."));
  LCD.print(3, 4, ">");
  LCD.print_P(3, 6, CONTINUE);
  LCD.print(3, 15, "<");
  while (!Encoder.ok()) brewCore();
}

#endif //#ifndef NOUI
