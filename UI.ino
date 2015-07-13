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

//UIScreenIndex controls screen order in screen navigation logic (screen unlocked)
enum UIScreenIndex {
  SCREEN_HOME,
  SCREEN_FILL,
  SCREEN_MASH,
  SCREEN_SPARGE,
  SCREEN_BOIL,
  SCREEN_CHILL,
  SCREEN_AUX,
  SCREEN_COUNT
};

//**********************************************************************************
// UI Globals
//**********************************************************************************
byte activeScreen;
void (*screenMap[SCREEN_COUNT])(enum ScreenSignal);
byte screenCount;

// screenLock: Indicates if encoder change is handled by screen navigation logic (unlocked)
// or by the active screen (locked)
boolean screenLock;

unsigned long timerLastPrint;

//**********************************************************************************
// uiInit:  One time initialization of all UI logic
//**********************************************************************************
void uiInit() {
  LCD.init();
  uiEncoderInit();
  
  //Check to see if EEPROM Initialization is needed
  uiCheckConfig();
  uiScreenInit();
}

//Screen map is dynamically built at init. This would allow for optional screens to
//be included if desired for certain setups. For example, additional screens could
//be added to map to brewsteps like Delay, Preheat, Add Grain, Strike Transfer, 
//Refill, etc. and not all may be used in all system builds.
void uiScreenInit() {
  screenCount = 0;
  screenMap[screenCount++] = &screenHome;
  screenMap[screenCount++] = &screenFill;
  screenMap[screenCount++] = &screenMash;
  screenMap[screenCount++] = &screenSparge;
  screenMap[screenCount++] = &screenBoil;
  screenMap[screenCount++] = &screenChill;
  screenMap[screenCount++] = &screenAUX;
  uiSetCustomCharactors();
  uiJumpScreen(0);
  uiUnlock();
}

void uiEncoderInit() {
  #ifdef ENCODER_I2C
     Encoder.begin(ENCODER_I2CADDR);
  #else
    #ifndef ENCODER_OLD_CONSTRUCTOR
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN);
    #else
      Encoder.begin(ENCODER_TYPE, ENTER_PIN, ENCA_PIN, ENCB_PIN, ENTER_INT, ENCA_INT);
    #endif
    #ifdef ENCODER_ACTIVELOW
      Encoder.setActiveLow(1);
    #endif
  #endif
}

void uiEvent(enum EventIndex eventID, byte eventParam) {
  switch (eventID) {
    case EVENT_STEPINIT:
    case EVENT_STEPEXIT:
      uiBrewStepDidChange(eventParam);
      break;
  }
}

void (*uiBrewStepToScreenFunction(byte brewStep))(enum ScreenSignal) {
  switch (brewStep) {
    case BREWSTEP_FILL:
      return &screenFill;
    case BREWSTEP_DELAY:
      return &screenMash;
    case BREWSTEP_PREHEAT:
      return &screenMash;
    case BREWSTEP_GRAININ:
      return &screenSparge;
    case BREWSTEP_REFILL:
      return &screenFill;
    case BREWSTEP_DOUGHIN:
    case BREWSTEP_ACID:
    case BREWSTEP_PROTEIN:
    case BREWSTEP_SACCH:
    case BREWSTEP_SACCH2:
    case BREWSTEP_MASHOUT:
    case BREWSTEP_MASHHOLD:
      return &screenMash;
    case BREWSTEP_SPARGE:
      return &screenSparge;
    case BREWSTEP_BOIL:
      return &screenBoil;
    case BREWSTEP_CHILL:
      return &screenChill;
  }
}

void uiJumpScreen(byte screenIndex) {
  activeScreen = screenIndex;
  (*screenMap[activeScreen])(SCREENSIGNAL_INIT);
  if (screenLock)
    (*screenMap[activeScreen])(SCREENSIGNAL_LOCK);
  else {
    LCD.writeCustChar(0, 19, 7);
    (*screenMap[activeScreen])(SCREENSIGNAL_UNLOCK);
  }
}

void uiRedrawActiveScreen() {
  uiJumpScreen(activeScreen);
}

void uiNextScreen() {
  if (activeScreen + 1 < screenCount)
    uiJumpScreen(++activeScreen);
}

void uiPrevScreen() {
  if (activeScreen)
    uiJumpScreen(--activeScreen);
}

byte uiFindScreenIndex(void (*targetScreen)(enum ScreenSignal)) {
  for (byte i = 0; i < screenCount; i++)
    if (screenMap[i] == targetScreen)
      return i;
  return 0;
}

void uiBrewStepDidChange(byte brewStep) {
  void (*targetScreen)(enum ScreenSignal) = uiBrewStepToScreenFunction(brewStep);
  byte screenIndex = uiFindScreenIndex(targetScreen);
  if (screenIndex)
    uiJumpScreen(screenIndex);
}

//**********************************************************************************
// uiUnlock:  Unlock active screen to select another
//**********************************************************************************
void uiUnlock() {
  Encoder.setMin(0);
  Encoder.setMax(screenCount - 1);
  Encoder.setCount(activeScreen);
  screenLock = 0;
  LCD.writeCustChar(0, 19, 7);
  (*screenMap[activeScreen])(SCREENSIGNAL_UNLOCK);
}

void uiLock() {
  screenLock = 1;
  LCD.writeCustChar(0, 19, ' ');
  (*screenMap[activeScreen])(SCREENSIGNAL_LOCK);
}

//Sets up custom charactors used by most screens
//This should be done at UI init and are not expected to be overwritten
void uiSetCustomCharactors() {
  LCD.setCustChar_P(7, UNLOCK_ICON);
  
  //Print Program Active Char (Overwritten if no program active)
  LCD.setCustChar_P(6, PROG_ICON);
  LCD.writeCustChar(0, 0, 6);
  LCD.setCustChar_P(5, BELL);
}

//**********************************************************************************
// uiUpdate(): Called in main loop to handle all UI functions
//**********************************************************************************
void uiUpdate() {
  #ifdef ESTOP_PIN
  if (isEStop()) {
    uiEStop(); //Note: Holds focus in event of eStop Trigger
    uiJumpScreen(activeScreen);
  }
  #endif
  
  if (Encoder.change() >= 0) {
    if (screenLock)
      (*screenMap[activeScreen])(SCREENSIGNAL_ENCODERCHANGE);
    else
      uiJumpScreen(Encoder.getCount());
  }
  
  if (Encoder.ok()) {
    if (alarmStatus)
      setAlarm(0);
    else if (!screenLock)
      uiLock();
    else
      (*screenMap[activeScreen])(SCREENSIGNAL_ENCODEROK);
  }

  if (Encoder.cancel())
    uiUnlock();
    
  (*screenMap[activeScreen])(SCREENSIGNAL_UPDATE);
  LCD.update();
}

void uiCheckConfig() {
  if (checkConfig()) {
    //Workaround: Initial encoder change results in a bogus cacncel press being detected.
    //Use infobox (which ignores cancel) before confirmChoice to prevent skipping of EEPROM init.
    infoBox("Configuration", "Not Found", "", CONTINUE);
    if (confirmChoice("Reset Configuration?", "", "", INIT_EEPROM))
      UIinitEEPROM();
    LCD.clear();
  }
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

void screenHome (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
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
      LCD.print_P(3, 2, PSTR("github.com/OSCSYS"));
      break;
      
    case SCREENSIGNAL_UPDATE:
      break;
    case SCREENSIGNAL_ENCODEROK:
      screenHomeMenu();
      uiRedrawActiveScreen();
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      break;
    case SCREENSIGNAL_LOCK:
      break;
    case SCREENSIGNAL_UNLOCK:
      break;
  }
}

void screenHomeMenu() {
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
        if (activeScreen == SCREEN_FILL)
          break;
    }
    else if (lastOption == 3) {
      //Drain
      if (outputs->getProfileState(OUTPUTPROFILE_DRAIN))
        outputs->setProfileState(OUTPUTPROFILE_DRAIN, 0);
      else {
        if (zoneIsActive(ZONE_MASH) || zoneIsActive(ZONE_BOIL))
          infoBox("Cannot drain while", "mash or boil zone", "is active", CONTINUE);
        else
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
      uiUnlock();
      break;
    }
  }
}

void screenFill (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      {
        boolean fillActive = brewStepIsActive(BREWSTEP_FILL);
        boolean refillActive = brewStepIsActive(BREWSTEP_REFILL);
        LCD.clear();
        if (fillActive)
          LCD.print_P(0, 1, PSTR("Fill"));
        else if (refillActive)
          LCD.print_P(0, 1, PSTR("Refill"));
        else
        LCD.print_P(0, 0, PSTR("Fill"));
        LCD.print_P(1, 1, PSTR("HLT"));
        LCD.print_P(2, 1, PSTR("Mash"));
        LCD.print_P(3, 1, PSTR("Auto"));
      }
      LCD.setCustChar_P(0, BUTTON_OFF);
      LCD.setCustChar_P(1, BUTTON_ON);
      LCD.setCustChar_P(2, BUTTON_OFF_SELECTED);
      LCD.setCustChar_P(3, BUTTON_ON_SELECTED);
      break;
    case SCREENSIGNAL_UPDATE:
      uiLabelFPoint(1, 9, 4, tgtVol[VS_HLT], 1000);
      uiLabelFPoint(2, 9, 4, tgtVol[VS_MASH], 1000);
      uiLabelFPoint(1, 15, 4, volAvg[VS_HLT], 1000);
      uiLabelFPoint(2, 15, 4, volAvg[VS_MASH], 1000);
      screenFillUpdateButtons(screenLock ? Encoder.getCount() : INDEX_NONE);
      break;
    case SCREENSIGNAL_ENCODEROK:
      {
        boolean fillActive = brewStepIsActive(BREWSTEP_FILL);
        boolean refillActive = brewStepIsActive(BREWSTEP_REFILL);
        switch (Encoder.getCount()) {
          case 0:
            if (confirmAdvance())
              continueClick();
            uiRedrawActiveScreen();
            break;
          case 1:
            outputs->toggleProfileState(OUTPUTPROFILE_FILLHLT);
            break;
          case 2:
            tgtVol[VS_HLT] = getValue_P(PSTR("HLT Target Vol"), tgtVol[VS_HLT], 1000, 9999999, VOLUNIT);
            uiRedrawActiveScreen();
            break;
          case 3:
            outputs->toggleProfileState(OUTPUTPROFILE_FILLMASH);
            break;
          case 4:
            tgtVol[VS_MASH] = getValue_P(PSTR("Mash Target Vol"), tgtVol[VS_MASH], 1000, 9999999, VOLUNIT);
            uiRedrawActiveScreen();
            break;
          case 5:
            autoValve[AV_FILL] ^= 1;
            break;
          case 6:
            outputs->setProfileState(OUTPUTPROFILE_FILLHLT, 0);
            outputs->setProfileState(OUTPUTPROFILE_FILLMASH, 0);
            autoValve[AV_FILL] = 0;
            break;
          case 7:
            if (confirmAbort()) {
              if (fillActive)
                brewStepSignal(BREWSTEP_FILL, STEPSIGNAL_ABORT);
              else
                brewStepSignal(BREWSTEP_REFILL, STEPSIGNAL_ABORT);
            }
            uiRedrawActiveScreen();
            break;
        }
      }
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      {
        byte cursorPosition = Encoder.getCount();        
        uiCursorHasFocus(1, 8, 6, cursorPosition == 2);
        uiCursorHasFocus(2, 8, 6, cursorPosition == 4);
        uiCursorHasFocus(3, 6, 6, cursorPosition == 6);

        if (brewStepIsActive(BREWSTEP_FILL) || brewStepIsActive(BREWSTEP_REFILL)) {
          uiCursorHasFocus(0, 10, 10, cursorPosition == 0);
          uiCursorHasFocus(3, 13, 7, cursorPosition == 7);
        }
      }
      break;
    case SCREENSIGNAL_LOCK:
      {
        boolean fillActive = brewStepIsActive(BREWSTEP_FILL);
        boolean refillActive = brewStepIsActive(BREWSTEP_REFILL);
        Encoder.setMin  (fillActive || refillActive ? 0 : 1);
        Encoder.setMax  (fillActive || refillActive ? 7 : 6);
        Encoder.setCount(fillActive || refillActive ? 0 : 1);
        LCD.print_P(3, 7, PSTR("Stop"));
        if (fillActive || refillActive) {
          LCD.print_P(0, 11, PSTR("Continue"));
          LCD.print_P(3, 14, PSTR("Abort"));
        }
        screenFill(SCREENSIGNAL_ENCODERCHANGE);
      }
      break;
    case SCREENSIGNAL_UNLOCK:
      screenFillUpdateButtons(INDEX_NONE);
      LCD.rPad(3, 6, "", 6, ' ');
      LCD.rPad(0, 10, "", 9, ' ');
      LCD.rPad(3, 13, "", 7, ' ');
      uiCursorNone(1, 8, 6);
      uiCursorNone(2, 8, 6);
      break;
  }
}

void screenFillUpdateButtons(byte cursorPosition) {
  LCD.writeCustChar(1, 0, (outputs->getProfileState(OUTPUTPROFILE_FILLHLT) ? 1 : 0) | ((cursorPosition == 1) ? 2 : 0));
  LCD.writeCustChar(2, 0, (outputs->getProfileState(OUTPUTPROFILE_FILLMASH) ? 1 : 0) | ((cursorPosition == 3) ? 2 : 0));
  LCD.writeCustChar(3, 0, (autoValve[AV_FILL] ? 1 : 0) | ((cursorPosition == 5) ? 2 : 0));
}

void screenMash (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
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
      break;
    case SCREENSIGNAL_UPDATE:
      for (byte i = VS_HLT; i <= VS_MASH; i++) {
        uiLabelTemperature (1, i * 6 + 9, 5, setpoint[i]);
        uiLabelTemperature (2, i * 6 + 9, 5, temp[i]);
        uiLabelPercentOnOff (3, i * 6 + 11, getHeatPower(i));        
        printTimer(TIMER_MASH, 3, 0);
      }
      break;
    case SCREENSIGNAL_ENCODEROK:
      screenMashMenu();
      uiRedrawActiveScreen();
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      break;
    case SCREENSIGNAL_LOCK:
      LCD.print_P(0, 16, PSTR("Mash"));
      break;
    case SCREENSIGNAL_UNLOCK:
      break;
  }
}

void screenMashMenu() {
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
  else if (lastOption == 4)
    continueClick();
  else if (lastOption == 5) {
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
}

void screenSparge (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
      if (brewStepIsActive(BREWSTEP_SPARGE)) LCD.print_P(0, 1, PSTR("Sparge"));
      else if (brewStepIsActive(BREWSTEP_GRAININ)) LCD.print_P(0, 1, PSTR("Grain In"));
      else LCD.print_P(0, 0, PSTR("Sparge"));
      LCD.print_P(1, 1, PSTR("HLT"));
      LCD.print_P(2, 1, PSTR("Mash"));
      LCD.print_P(3, 1, PSTR("Kettle"));
      break;
    case SCREENSIGNAL_UPDATE:
      for (byte i = VS_HLT; i <= VS_KETTLE; i++) {
        uiLabelFPoint(1 + i, 14, 6, vSensor[i] == INDEX_NONE ? tgtVol[i] : volAvg[i], 1000);
        uiLabelTemperature (i + 1, 8, 5, temp[i]);
      }
      break;
    case SCREENSIGNAL_ENCODEROK:
      {
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
        else if (encValue == 7)
          screenSpargeMenu();
      }
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      LCD.rPad(0, 9, "", 10, ' ');
      switch(Encoder.getCount()) {
        case 0:
          LCD.print_P(0, 10, CONTINUE);
          break;
        case 1:
          LCD.print_P(0, 9, SPARGEIN);
          break;
        case 2:
          LCD.print_P(0, 9, SPARGEOUT);
          break;
        case 3:
          LCD.print_P(0, 9, FLYSPARGE);
          break;
        case 4:
          LCD.print_P(0, 9, MASHHEAT);
          break;
        case 5:
          LCD.print_P(0, 9, MASHIDLE);
          break;
        case 6:
          LCD.print_P(0, 11, ALLOFF);
          break;
        case 7:
          LCD.print_P(0, 12, MENU);
          break;
      }
      break;
    case SCREENSIGNAL_LOCK:
      uiCursorFocus(0, 8, 12);
      LCD.print_P(0, 10, CONTINUE);
      Encoder.setMin(0);
      Encoder.setMax(7);
      Encoder.setCount(0);
      break;
    case SCREENSIGNAL_UNLOCK:
      LCD.rPad(0, 8, "", 11, ' ');
      break;
  }
}

void screenSpargeMenu() {
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
}

void screenBoil (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
      timerLastPrint = 0;
      if (brewStepIsActive(BREWSTEP_BOIL)) LCD.print_P(0, 1, PSTR("Boil"));
      else LCD.print_P(0,0,PSTR("Boil"));
      break;
    case SCREENSIGNAL_UPDATE:
		switch (boilControlState) {
			case CONTROLSTATE_OFF:
				LCD.print_P(0, 13, PSTR("   Off"));
				break;
			case CONTROLSTATE_AUTO:
				LCD.print_P(0, 13, PSTR("  Auto"));
				break;
			case CONTROLSTATE_MANUAL:
				LCD.print_P(0, 13, PSTR("Manual"));
				break;
			case CONTROLSTATE_SETPOINT:
				uiLabelTemperature(0, 14, 5, setpoint[VS_KETTLE]);
				break;
      }
      
      printTimer(TIMER_BOIL, 3, 0);
      uiLabelFPoint(2, 15, 5, volAvg[VS_KETTLE], 1000);
      uiLabelPercentOnOff (3, 17, getHeatPower(VS_KETTLE));
      uiLabelTemperature (1, 14, 6, temp[TS_KETTLE]);
      break;
    case SCREENSIGNAL_ENCODEROK:
      screenBoilMenu();
      uiRedrawActiveScreen();
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      switch (boilControlState) {
		case CONTROLSTATE_SETPOINT:
		case CONTROLSTATE_AUTO:
			setBoilControlState(CONTROLSTATE_MANUAL);
		case CONTROLSTATE_MANUAL:
			PIDOutput[VS_KETTLE] = Encoder.getCount();
      }
      break;
    case SCREENSIGNAL_LOCK:
      Encoder.setMin(0);
      Encoder.setMax(pwmOutput[VS_KETTLE] ? pwmOutput[VS_KETTLE]->getLimit() : 1);
      Encoder.setCount(pwmOutput[VS_KETTLE] ? PIDOutput[VS_KETTLE] : heatStatus[VS_KETTLE]);
      break;
    case SCREENSIGNAL_UNLOCK:
      //LCD.rPad(0, 14, "", 5, ' ');
      break;
  }
}

void screenBoilMenu() {
  menu boilMenu(3, 10);
  boilMenu.setItem_P(PSTR("Set Timer"), 0);
  
  if (timerStatus[TIMER_BOIL]) boilMenu.setItem_P(PSTR("Pause Timer"), 1);
  else boilMenu.setItem_P(PSTR("Start Timer"), 1);
  
  boilMenu.setItem_P(PSTR("Boil Ctrl: "), 2);
  switch (boilControlState) {
    case CONTROLSTATE_OFF:
      boilMenu.appendItem_P(LABEL_BUTTONOFF, 2);
      break;
    case CONTROLSTATE_AUTO:
      boilMenu.appendItem_P(PSTR("Auto"), 2);
      break;
    case CONTROLSTATE_MANUAL:
      boilMenu.appendItem_P(PSTR("Manual"), 2);
      break;
	case CONTROLSTATE_SETPOINT:
	  boilMenu.appendItem_P(PSTR("Setpoint"), 2);
	  break;
  }

  boilMenu.setItem_P(PSTR("Setpoint:"), 8);
  vftoa(setpoint[VS_KETTLE], buf, 100, 1);
  truncFloat(buf, 4);
  boilMenu.appendItem(buf, 8);
  boilMenu.appendItem_P(TUNIT, 8);
  
  boilMenu.setItem_P(PSTR("Boil Temp: "), 3);
  vftoa(getBoilTemp() * SETPOINT_MULT, buf, 100, 1);
  truncFloat(buf, 5);
  boilMenu.appendItem(buf, 3);
  boilMenu.appendItem_P(TUNIT, 3);
  
  boilMenu.setItem_P(PSTR("Boil Power: "), 4);
  boilMenu.appendItem(itoa(boilPwr, buf, 10), 4);
  boilMenu.appendItem("%", 4);
  
  boilMenu.setItem_P(WHIRLPOOL, 5);
  boilMenu.appendItem_P(outputs->getProfileState(OUTPUTPROFILE_WHIRLPOOL) ? PSTR(": On") : PSTR(": Off"), 5);
  
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
  }
  else if (lastOption == 4) setBoilPwr(getValue_P(PSTR("Boil Power"), boilPwr, 1, 100, PSTR("%")));
  else if (lastOption == 5)
    outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, outputs->getProfileState(OUTPUTPROFILE_WHIRLPOOL) ? 0 : 1);
  else if (lastOption == 6) 
    continueClick();
  else if (lastOption == 7) {
    if (confirmAbort())
      brewStepSignal(BREWSTEP_BOIL, STEPSIGNAL_ABORT);
  }
  else if (lastOption == 8) {
    setSetpoint(VS_KETTLE, getValue_P(PSTR("Kettle Setpoint"), setpoint[VS_KETTLE] / SETPOINT_MULT, SETPOINT_DIV, 255, TUNIT));
    setBoilControlState(CONTROLSTATE_SETPOINT);
  }
}

void screenChill (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
      if (brewStepIsActive(BREWSTEP_CHILL)) LCD.print_P(0, 1, PSTR("Chill"));
      else LCD.print_P(0, 0, PSTR("Chill"));
      LCD.print_P(0, 11, PSTR("Wort"));
      LCD.print_P(0, 17, PSTR("H2O"));
      LCD.print_P(1, 8, PSTR("In"));
      LCD.print_P(2, 7, PSTR("Out"));
      break;
    case SCREENSIGNAL_UPDATE:
      uiLabelTemperature (1, 11, 4, temp[TS_KETTLE]);
      uiLabelTemperature (2, 11, 4, temp[TS_BEEROUT]);
      uiLabelTemperature (1, 16, 4, temp[TS_H2OIN]);
      uiLabelTemperature (2, 16, 4, temp[TS_H2OOUT]);
      LCD.print_P(3, 12, outputs->getProfileState(OUTPUTPROFILE_WORTOUT) ? LABEL_BUTTONON : LABEL_BUTTONOFF);
      LCD.print_P(3, 17, outputs->getProfileState(OUTPUTPROFILE_CHILL) ? LABEL_BUTTONON : LABEL_BUTTONOFF);
      break;
    case SCREENSIGNAL_ENCODEROK:
      switch (Encoder.getCount()) {
        case 0:
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, 1);
          outputs->setProfileState(OUTPUTPROFILE_WORTOUT, 0);
          break;
        case 1:
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILL, 1);
          outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, 1);
          outputs->setProfileState(OUTPUTPROFILE_WORTOUT, 0);
          break;
        case 2:
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILL, 1);
          outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WORTOUT, 0);
          break;
        case 3:
          autoValve[AV_CHILL] = 0; 
          outputs->setProfileState(OUTPUTPROFILE_CHILL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WORTOUT, 1);
          break;
        case 4:
          autoValve[AV_CHILL] = 0;
          outputs->setProfileState(OUTPUTPROFILE_CHILL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WHIRLPOOL, 0);
          outputs->setProfileState(OUTPUTPROFILE_WORTOUT, 0);
          break;
        case 5:
          autoValve[AV_CHILL] = 1;
          break;
        case 6:
          brewStepSignal(BREWSTEP_CHILL, STEPSIGNAL_ADVANCE);
          uiJumpScreen(0);
          break;
      }
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      LCD.rPad(3, 1, "", 10, ' ');
      switch (Encoder.getCount()) {
        case 0:
          LCD.print_P(3, 1, WHIRLPOOL);
          break;        
        case 1:
          LCD.print_P(3, 1, WHIRLCHILL);
          break;
        case 2:
          LCD.print_P(3, 3, CHILL);
          break;
        case 3:
          LCD.print_P(3, 2, WORTOUT);
          break;
        case 4:
          LCD.print_P(3, 2, ALLOFF);
          break;
        case 5:
          LCD.print_P(3, 4, PSTR("Auto"));
          break;
        case 6:
          LCD.print_P(3, 2, CONTINUE);
          break;
        case 7:
          LCD.print_P(3, 3, ABORT);
          break;
      }
      break;
    case SCREENSIGNAL_LOCK:
      Encoder.setMin(0);
      Encoder.setMax(7);
      Encoder.setCount(0);
      LCD.print_P(0, 17, PSTR("H2O"));
      uiCursorFocus(3, 0, 12);
      screenChill(SCREENSIGNAL_ENCODERCHANGE);
      break;
    case SCREENSIGNAL_UNLOCK:
      LCD.rPad(3, 0, "", 12, ' ');
      break;
  }
}

void screenAUX (enum ScreenSignal signal) {
  switch (signal) {
    case SCREENSIGNAL_INIT:
      LCD.clear();
      LCD.print_P(0, 0, PSTR("AUX Temps"));
      LCD.print_P(1, 1, PSTR("AUX1"));
      LCD.print_P(2, 1, PSTR("AUX2"));
      LCD.print_P(3, 1, PSTR("AUX3"));
      break;
    case SCREENSIGNAL_UPDATE:
      for (byte i = TS_AUX1; i <= TS_AUX3; i++)
        uiLabelTemperature (i - TS_AUX1 + 1, 6, 6, temp[i]);
      break;
    case SCREENSIGNAL_ENCODEROK:
      break;
    case SCREENSIGNAL_ENCODERCHANGE:
      break;
    case SCREENSIGNAL_LOCK:
      break;
    case SCREENSIGNAL_UNLOCK:
      break;
  }
}

#ifdef ESTOP_PIN
// uiEStop() uses custom screen instead of menu object to auto-hide UI if E-Stop is cleaered.
void uiEStop() {
  LCD.clear();
  LCD.print_P(0, 0, PSTR("E-Stop Triggered"));
  Encoder.setMin(0);
  Encoder.setMax(1);
  Encoder.setCount(0);
  LCD.print_P(1, 0, PSTR(">Clear Alarm"));
  LCD.print_P(2, 0, PSTR(" Disable E-Stop"));

  while (isEStop()) {
    if (Encoder.change() >= 0) {
      for (byte i = 0; i < 3; i++)
        LCD.print(i + 1, 0, " ");
      LCD.print(Encoder.getCount() + 1, 0, ">");
      LCD.update();
    }
    if (Encoder.ok()) {
      if (Encoder.getCount() == 0)
        setAlarm(0);
      else if (Encoder.getCount() == 1) {
        setEStopEnabled(0);
        loadEStop();
      }
    }
    brewCore();
  }
}
#endif

void boilControlMenu() {
  menu boilMenu(3, 4);
  boilMenu.setItem_P(LABEL_BUTTONOFF, CONTROLSTATE_OFF);
  boilMenu.setItem_P(PSTR("Auto"), CONTROLSTATE_AUTO);
  boilMenu.setItem_P(PSTR("Manual"), CONTROLSTATE_MANUAL);
  boilMenu.setItem_P(PSTR("Setpoint"), CONTROLSTATE_SETPOINT);
  byte lastOption = scrollMenu("Boil Control Menu", &boilMenu);
  if (lastOption < NUM_CONTROLSTATES) setBoilControlState((ControlState) lastOption);
}

void continueClick() {
  byte brewstep = INDEX_NONE;
  if (brewStepIsActive(BREWSTEP_FILL)) brewstep = BREWSTEP_FILL;
  else if (brewStepIsActive(BREWSTEP_REFILL)) brewstep = BREWSTEP_REFILL;
  else if (brewStepIsActive(BREWSTEP_SPARGE)) brewstep = BREWSTEP_SPARGE;
  else if (brewStepIsActive(BREWSTEP_GRAININ)) brewstep = BREWSTEP_GRAININ;
  else if (brewStepIsActive(BREWSTEP_DELAY)) brewstep = BREWSTEP_DELAY;
  else if (brewStepIsActive(BREWSTEP_DOUGHIN)) brewstep = BREWSTEP_DOUGHIN;
  else if (brewStepIsActive(BREWSTEP_PREHEAT)) brewstep = BREWSTEP_PREHEAT;
  else if (brewStepIsActive(BREWSTEP_ACID)) brewstep = BREWSTEP_ACID;
  else if (brewStepIsActive(BREWSTEP_PROTEIN)) brewstep = BREWSTEP_PROTEIN;
  else if (brewStepIsActive(BREWSTEP_SACCH)) brewstep = BREWSTEP_SACCH;
  else if (brewStepIsActive(BREWSTEP_SACCH2)) brewstep = BREWSTEP_SACCH2;
  else if (brewStepIsActive(BREWSTEP_MASHOUT)) brewstep = BREWSTEP_MASHOUT;
  else if (brewStepIsActive(BREWSTEP_MASHHOLD)) brewstep = BREWSTEP_MASHHOLD;
  else if (brewStepIsActive(BREWSTEP_BOIL)) brewstep = BREWSTEP_BOIL;
  
  if(brewstep == INDEX_NONE)
    uiNextScreen();
  else {
    brewStepSignal(brewstep, STEPSIGNAL_ADVANCE);
    if (brewStepIsActive(brewstep)) {
      //Failed to advance step
      infoBox("Failed to advance", "program.", "", CONTINUE);
    }
  }
}

#endif //#ifndef NOUI
