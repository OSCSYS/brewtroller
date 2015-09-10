#ifndef NOUI

class menuProgramList : public menu {
  public:
    menuProgramList(byte pSize) : menu (pSize) {}
    byte getItemCount(void) { return 20; }
    
    char* getItem(byte index, char *retString) {
      getProgName(index, retString);
      return retString;
    }
};

void editProgramMenu() {
  menuProgramList progMenu(3);
  byte profile = scrollMenu("Edit Program", &progMenu);
  if (profile < 20)
    editProgram(profile);
}

class menuStartProgramOptions : public menuPROGMEM {
  public:
    menuStartProgramOptions(byte pSize) : menuPROGMEM (pSize, STARTPROGRAMOPTIONS, ARRAY_LENGTH(STARTPROGRAMOPTIONS)) {}
    
    char* getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      if (index == 1) {
        char numText[4];
        strcat(retString, itoa(getGrainTemp() / SETPOINT_DIV, numText, 10));
        strcat_P(retString, TUNIT);
      }
      return retString;
    }
};

void startProgramMenu() {
  menuProgramList progMenu(3);
  byte profile = scrollMenu("Start Program", &progMenu);
  if (profile < 20) {
    char progName[20];
    getProgName(profile, progName);
    menuStartProgramOptions startMenu(3);
    while(1) {
      unsigned long spargeVol = calcSpargeVol(profile);
      if (spargeVol > getCapacity(VS_HLT))
        warnHLT(spargeVol);

      unsigned long mashVol = calcStrikeVol(profile);
      unsigned long grainVol = calcGrainVolume(profile);
      if (mashVol + grainVol > getCapacity(VS_MASH))
        warnMash(mashVol, grainVol);

      unsigned long preboilVol = calcPreboilVol(profile);
      if (preboilVol > getCapacity(VS_KETTLE))
        warnBoil(preboilVol);
 
      byte lastOption = scrollMenu(progName, &startMenu);
      if (lastOption == 0)
        editProgram(profile);
      else if (lastOption == 1)
        setGrainTemp(getValue_P(PSTR("Grain Temp"), getGrainTemp(), SETPOINT_DIV, 255, TUNIT)); 
      else if (lastOption < 4) {
        if (zoneIsActive(ZONE_MASH))
          infoBox("Cannot start program", "while mash zone is", "active.", CONTINUE);
        else {
          if (lastOption == 3)
            setDelayMins(getTimerValue(PSTR("Delay Start"), getDelayMins(), 23));
          if (!programThreadInit(profile))
            infoBox("", "Program start failed", "", CONTINUE);
          else
            break;
        }
      } else
        break;
    }
  }
}

class menuEditProgramOptions : public menuPROGMEM {
  private:
    byte recipe;
    
  public:
    menuEditProgramOptions(byte pSize, byte r) : menuPROGMEM(pSize, EDITPROGRAMOPTIONS, ARRAY_LENGTH(EDITPROGRAMOPTIONS)) {
      recipe = r;
    }
    char *getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      char numText[12];
      if (index == 0)
        getProgName(recipe, retString);
      else if (index == 1) {
        vftoa(getProgBatchVol(recipe), numText, 1000, 1);
        truncFloat(numText, 5);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      } else if (index == 2) {
        vftoa(getProgGrain(recipe), numText, 1000, 1);
        truncFloat(numText, 7);
        strcat(retString, numText);
        strcat_P(retString, WTUNIT);
      } else if (index == 3) {
        strcat(retString, itoa(getProgBoil(recipe), numText, 10));
        strcat_P(retString, MIN);
      } else if (index == 4) {
        unsigned int mashRatio = getProgRatio(recipe);
        if (mashRatio) {
          vftoa(mashRatio, numText, 100, 1);
          truncFloat(numText, 4);
          strcat(retString, numText);
          strcat_P(retString, PSTR(":1"));
        } else {
          strcat_P(retString, PSTR("NoSparge"));
        }
      } else if (index == 5) {
        vftoa(getProgHLT(recipe) * SETPOINT_MULT, numText, 100, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, TUNIT);
      } else if (index == 6) {
        vftoa(getProgSparge(recipe) * SETPOINT_MULT, numText, 100, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, TUNIT);
      } else if (index == 7) {
        vftoa(getProgPitch(recipe) * SETPOINT_MULT, numText, 100, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, TUNIT);
      } else if (index == 9)
        strcat_P(retString, (char*)pgm_read_word(&(TITLE_VS[getProgMLHeatSrc(recipe)])));
      return retString;
    }
};

void editProgram(byte pgm) {
  menuEditProgramOptions progMenu(3, pgm);
  while (1) {
    byte lastOption = scrollMenu("Program Parameters", &progMenu);
    
    if (lastOption == 0) {
        char itemDesc[20];
        getProgName(pgm, itemDesc);
        getString(PSTR("Program Name:"), itemDesc, 19);
        setProgName(pgm, itemDesc);
    } else if (lastOption == 1)
      setProgBatchVol(pgm, getValue_P(PSTR("Batch Volume"), getProgBatchVol(pgm), 1000, 9999999, VOLUNIT));
    else if (lastOption == 2)
      setProgGrain(pgm, getValue_P(PSTR("Grain Weight"), getProgGrain(pgm), 1000, 9999999, WTUNIT));
    else if (lastOption == 3)
      setProgBoil(pgm, getTimerValue(PSTR("Boil Length"), getProgBoil(pgm), 2));
    else if (lastOption == 4) { 
      #ifdef USEMETRIC
        setProgRatio(pgm, getValue_P(PSTR("Mash Ratio"), getProgRatio(pgm), 100, 999, PSTR(" l/kg"))); 
      #else
        setProgRatio(pgm, getValue_P(PSTR("Mash Ratio"), getProgRatio(pgm), 100, 999, PSTR(" qts/lb")));
      #endif
    }
    else if (lastOption == 5)
      setProgHLT(pgm, getValue_P(PSTR("HLT Setpoint"), getProgHLT(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 6)
      setProgSparge(pgm, getValue_P(PSTR("Sparge Temp"), getProgSparge(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 7)
      setProgPitch(pgm, getValue_P(PSTR("Pitch Temp"), getProgPitch(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 8)
      editMashSchedule(pgm);
    else if (lastOption == 9)
      setProgMLHeatSrc(pgm, MLHeatSrcMenu(getProgMLHeatSrc(pgm)));
    else if (lastOption == 10)
      setProgAdds(pgm, editHopSchedule(getProgAdds(pgm)));
    else if (lastOption == 11)
      showProgCalcs(pgm);
    else return;
    unsigned long spargeVol = calcSpargeVol(pgm);
    unsigned long mashVol = calcStrikeVol(pgm);
    unsigned long grainVol = calcGrainVolume(pgm);
    unsigned long preboilVol = calcPreboilVol(pgm);
    if (spargeVol > getCapacity(VS_HLT)) warnHLT(spargeVol);
    if (mashVol + grainVol > getCapacity(VS_MASH)) warnMash(mashVol, grainVol);
    if (preboilVol > getCapacity(VS_KETTLE)) warnBoil(preboilVol);
  }
}

class menuRecipeCalculations : public menuPROGMEM {
  private:
    byte recipe;
    
  public:
    menuRecipeCalculations(byte pSize, byte r) : menuPROGMEM(pSize, RECIPECALCS, ARRAY_LENGTH(RECIPECALCS)) {
      recipe = r;
    }
    char *getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      char numText[12];
      if (index == 0) {
        vftoa(calcStrikeTemp(recipe) * SETPOINT_MULT, numText, 100, 1);
        truncFloat(numText, 3);
        strcat(retString, numText);
        strcat_P(retString, TUNIT);
      } else if (index == 1) {
        vftoa(calcStrikeVol(recipe), numText, 1000, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      } else if (index == 2) {
        vftoa(calcSpargeVol(recipe), numText, 1000, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      } else if (index == 3) {
        vftoa(calcPreboilVol(recipe), numText, 1000, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      } else if (index == 4) {
        vftoa(calcGrainVolume(recipe), numText, 1000, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      } else if (index == 5) {
        vftoa(calcGrainLoss(recipe), numText, 1000, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        strcat_P(retString, VOLUNIT);
      }
      return retString;
    }
};

void showProgCalcs(byte pgm) {
  menuRecipeCalculations calcsMenu(3, pgm);
  scrollMenu("Program Calcs", &calcsMenu);
}


class menuMashSchedule : public menu {
  private:
    byte recipe;
    
  public:
    menuMashSchedule(byte pSize, byte r) : menu (pSize) {
      recipe = r;
    }
   
    byte getItemCount(void) {
      return MASHSTEP_COUNT * 2 + 1;
    }

    char *getItem(byte index, char *retString) {
      if (index < MASHSTEP_COUNT * 2)
        return getItemMash(index, retString);
      return strcpy_P(retString, EXIT);
    }
    char *getItemMash(byte index, char *retString) {
      byte mashStep = index >> 1;
      strcpy_P(retString, (char*)pgm_read_word(&(TITLE_MASHSTEP[mashStep])));
      char numText[7];
      
      if (index & 1) {
        vftoa(getProgMashTemp(recipe, mashStep) * SETPOINT_MULT, numText, 100, 1);
        truncFloat(numText, 4);
        strcat(retString, numText);
        return strcat_P(retString, TUNIT);
      }
      strcat(retString, itoa(getProgMashMins(recipe, mashStep), numText, 10));
      return strcat_P(retString, MIN);
    }
};

//Note: Menu values represent two 4-bit values
//High-nibble = mash step: MASH_DOUGHIN-MASH_MASHOUT
//Low-nibble = menu item: OPT_XXXXXXXX (see #defines above)
void editMashSchedule(byte pgm) {
  menuMashSchedule mashMenu(3, pgm);
  while (1) {
    byte lastOption = scrollMenu("Mash Schedule", &mashMenu);
    if (lastOption > 11)
      return;
    byte mashstep = lastOption >> 1;
    if (lastOption & 1)
      setProgMashTemp(pgm, mashstep, getValue_P((char*)pgm_read_word(&(TITLE_MASHSTEP[mashstep])), getProgMashTemp(pgm, mashstep), SETPOINT_DIV, 255, TUNIT));
    else
      setProgMashMins(pgm, mashstep, getTimerValue((char*)pgm_read_word(&(TITLE_MASHSTEP[mashstep])), getProgMashMins(pgm, mashstep), 1));
  }
}


class menuBoilAddsList : public menu {
  private:
    unsigned int *bitmask;
    
  public:
    menuBoilAddsList(byte pSize, unsigned int *m) : menu(pSize) {
      bitmask = m;
    }
    byte getItemCount(void) {
      return 13;
    }
    char *getItem(byte index, char *retString) {
      byte value = hoptimes[index];
      if (value == 255)
        return strcpy_P(retString, EXIT);
      retString[0] = '\0';
      if (value == 254)
        strcpy(retString, "At Boil: ");
      if (value < 100)
        strcat(retString, " ");
      if (value < 10)
        strcat(retString, " ");
      if (value < 254) {
        char numText[4];
        strcat(retString, itoa(value, numText, 10));
        strcat(retString, " Min: ");
      }
      return strcat_P(retString, (*bitmask & (1 << index))? ON : OFF);
    }
};

unsigned int editHopSchedule (unsigned int sched) {
  unsigned int retVal = sched;
  menuBoilAddsList hopMenu(3, &retVal);
  
  while (1) {
    byte lastOption = scrollMenu("Boil Additions", &hopMenu);
    if (lastOption < 12)
      retVal = retVal ^ (1 << lastOption);
    else
      return retVal;
  }
}

byte MLHeatSrcMenu(byte MLHeatSrc) {
  menuPROGMEM mlHeatMenu(3, TITLE_VS, 2);
  mlHeatMenu.setSelected(MLHeatSrc);
  byte lastOption = scrollMenu("Heat Strike In:", &mlHeatMenu);
  if (lastOption > 1)
    return MLHeatSrc;
  return lastOption;
}

void warnHLT(unsigned long spargeVol) {
  char line2[21] = "Sparge Vol:";
  char numText[12];
  vftoa(spargeVol, numText, 1000, 1);
  truncFloat(numText, 5);
  strcat(line2, numText);
  strcat_P(line2, VOLUNIT);

  infoBox("HLT Capacity Issue", line2, "", CONTINUE);
}


void warnMash(unsigned long mashVol, unsigned long grainVol) {
  char line2[21] = "Strike Vol:";
  char numText[12];
  vftoa(mashVol, numText, 1000, 1);
  truncFloat(numText, 5);
  strcat(line2, numText);
  strcat_P(line2, VOLUNIT);

  char line3[21] = "Grain Vol:";
  vftoa(grainVol, numText, 1000, 1);
  truncFloat(numText, 5);
  strcat(line3, numText);
  strcat_P(line3, VOLUNIT);

  infoBox("Mash Capacity Issue", line2, line3, CONTINUE);
}

void warnBoil(unsigned long preboilVol) {
  char line2[21] = "Preboil Vol:";
  char numText[12];
  vftoa(preboilVol, numText, 1000, 1);
  truncFloat(numText, 5);
  strcat(line2, numText);
  strcat_P(line2, VOLUNIT);

  infoBox("Boil Capacity Issue", line2, "", CONTINUE);
}


//*****************************************************************************************************************************
// Generic selection dialogs
//*****************************************************************************************************************************

class menuOutputList : public menu {
  private:
    byte currentSelection;
    
  public:
    menuOutputList(byte pSize, byte s) : menu (pSize) {
      currentSelection = min(s, outputs->getCount());
    }
    byte getItemCount(void) {
      return outputs->getCount() + 1;
    }
    char *getItem(byte index, char *retString) {
      strcpy(retString, index == currentSelection ? "*" : " ");

      char outputName[OUTPUT_FULLNAME_MAXLEN] = "None";        
      if (index < outputs->getCount())
        outputs->getOutputFullName(index, outputName);
      return strcat(retString, outputName);
    }
};

byte menuSelectOutput(char sTitle[], byte currentSelection) {
  menuOutputList outputMenu(3, currentSelection);
  byte lastOption = scrollMenu(sTitle, &outputMenu);
  if (lastOption == 255)
    return currentSelection;
  else if (lastOption == outputs->getCount())
    return INDEX_NONE;
  return lastOption;
}

class menuOutputsBitmask : public menu {
  private:
    unsigned long *bitmask;
    boolean showTest;
    
  public:
    menuOutputsBitmask(byte pSize, unsigned long *m, boolean t) : menu(pSize) {
      bitmask = m;
      showTest = t;
    }
    byte getItemCount(void) {
      byte count = showTest ? 3 : 2;
      for (byte i = 0; i < outputs->getCount(); i++)
        if ((*bitmask >> i) & 1)
          count++;
      return count;
    }
    byte getItemValue(byte index) {
      byte count = 0;
      byte bitPos = 0;
      for (bitPos = 0; bitPos < outputs->getCount() && count < index + 1; bitPos++)
        if ((*bitmask >> bitPos) & 1)
          count++;
      bitPos--;

      if (index == count - 1)
        return bitPos;
      if (index == count)
        return 254;
      if (showTest && index == count + 1)
        return 253;
      return 255;  
    }
    char *getItem(byte index, char *retString) {
      byte option = getItemValue(index);
      if (option < outputs->getCount())
        return outputs->getOutputFullName(option, retString);
      if (option == 254)
        return strcpy(retString, "[Add Output]");
      if (option == 253)
        return strcpy(retString, "[Test Profile]");
      return strcpy_P(retString, EXIT);
    }
};

unsigned long menuSelectOutputs(char sTitle[], unsigned long currentSelection, boolean doTest) {
  unsigned long newSelection = currentSelection;
  menuOutputsBitmask outputMenu(3, &newSelection, doTest);
  while (1) {
    byte lastOption = scrollMenu(sTitle, &outputMenu);
    if (lastOption == 254) {
      byte addOutput = menuSelectOutput("Add Output", INDEX_NONE);
      if (addOutput < outputs->getCount())
        newSelection |= (1uL << addOutput);
    } else if (lastOption == 253) {
      //Test Profile: Use OUTPUTENABLE_SYSTEMTEST to disable unused outputs
      outputs->setOutputEnableMask(OUTPUTENABLE_SYSTEMTEST, newSelection);
      outputs->setProfileMask(OUTPUTPROFILE_SYSTEMTEST, newSelection);
      outputs->setProfileState(OUTPUTPROFILE_SYSTEMTEST, 1);
      outputs->update();

      infoBox("Testing Profile", sTitle, "", CONTINUE);

      // Update outputs to clear overrides (overrides are not persistent across updates)
      outputs->setOutputEnableMask(OUTPUTENABLE_SYSTEMTEST, 0xFFFFFFFFul);
      outputs->setProfileMask(OUTPUTPROFILE_SYSTEMTEST, 0);
      outputs->setProfileState(OUTPUTPROFILE_SYSTEMTEST, 0);
      outputs->update();
    }  else if (lastOption == 255) {
      if (newSelection != currentSelection && confirmSave())
        return newSelection;
      return currentSelection;
    } else
      newSelection &= ~(1uL << lastOption);
  }
}

class menuOutputProfileBitmask : public menuPROGMEM {
  private:
    unsigned long *bitmask;
    
  public:
    menuOutputProfileBitmask(byte pSize, unsigned long *m) : menuPROGMEM(pSize, TITLE_VLV, ARRAY_LENGTH(TITLE_VLV) - 1) {
      bitmask = m;
    }
    byte getItemCount(void) {
      byte count = 2;
      for (byte i = 0; i < menuPROGMEM::getItemCount(); i++)
        if ((*bitmask >> i) & 1)
          count++;
      return count;
    }
    byte getItemValue(byte index) {
      byte count = 0;
      byte bitPos = 0;
      for (bitPos = 0; bitPos < menuPROGMEM::getItemCount() && count < index + 1; bitPos++)
        if ((*bitmask >> bitPos) & 1)
          count++;
      bitPos--;
      if (index < count)
        return bitPos;
      if (index == count)
        return 254;
      return 255;  
    }
    char *getItem(byte index, char *retString) {
      byte option = getItemValue(index);
      if (option < menuPROGMEM::getItemCount())
        return menuPROGMEM::getItem(index, retString);
      else if (option == 254)
        return strcpy(retString, "[Add Profile]");
      else
        return strcpy_P(retString, EXIT);
    }
};

unsigned long menuSelectOutputProfiles(char sTitle[], unsigned long currentSelection) {
  unsigned long newSelection = currentSelection;
  menuOutputProfileBitmask outputMenu(3, &newSelection);
  while (1) {
    byte lastOption = scrollMenu(sTitle, &outputMenu);
    if (lastOption == 254) {
      byte addOutput = menuSelectOutputProfile("Add Profile");
      if (addOutput < OUTPUTPROFILE_USERCOUNT)
        newSelection |= (1ul << addOutput);
    }  else if (lastOption == 255) {
      if (newSelection != currentSelection && confirmSave())
        return newSelection;
      return currentSelection;
    } else
      newSelection &= ~(1ul << lastOption);
  }
}

class menuOutputProfileList : public menuPROGMEM {
  public:
    menuOutputProfileList(byte pSize) : menuPROGMEM(pSize, TITLE_VLV, ARRAY_LENGTH(TITLE_VLV)) {}
    menuOutputProfileList(byte pSize, byte altSize) : menuPROGMEM(pSize, TITLE_VLV, altSize) {}
    byte getItemValue(byte index) {
      if (index < OUTPUTPROFILE_USERCOUNT)
        return outputProfileDisplayOrder[index];
      return index;
    }
};

byte menuSelectOutputProfile(char sTitle[]) {
  menuOutputProfileList outputMenu(3, ARRAY_LENGTH(TITLE_VLV) - 1);
  return scrollMenu(sTitle, &outputMenu);
}

#ifdef ANALOGINPUTS_GPIO
class menuAnalogInputSelection : public menu {
  private:
    byte currentSelection;
    
  public:
    menuAnalogInputSelection(byte pSize, byte sel) : menu(pSize) {
      currentSelection = ANALOGINPUTS_GPIO_COUNT;
      byte analogInputs[] = ANALOGINPUTS_GPIO_PINS;
      for (byte i = 0; i < ANALOGINPUTS_GPIO_COUNT; i++)
        if (analogInputs[i] == sel)
          currentSelection = i;
        setSelected(currentSelection);
    }
    byte getItemCount(void) {
      return ANALOGINPUTS_GPIO_COUNT + 1;
    }
    byte getItemValue(byte index) {
      if (index < ANALOGINPUTS_GPIO_COUNT) {
        byte analogInputs[] = ANALOGINPUTS_GPIO_PINS;
        return analogInputs[index];
      }
      return INDEX_NONE;
    }
    char *getItem(byte index, char *retString) {
      strcpy(retString, index == currentSelection ? "*" : " ");
      if (index < ANALOGINPUTS_GPIO_COUNT)
        return getItemAnalogItem(index, retString);
      return strcat_P(retString, NONE);
    }
    char *getItemAnalogItem(byte index, char *retString) {
      char analogTitles[] = ANALOGINPUTS_GPIO_NAMES;
      char* titleItem = analogTitles;
          
      for (byte i = 0; i < index; i++)
        titleItem += strlen(titleItem) + 1;
      strcat(retString, titleItem);
    }
};

byte menuSelectAnalogInput(char sTitle[], byte currentValue) {
  menuAnalogInputSelection volMenu(3, currentValue);
  return scrollMenu(sTitle, &volMenu);
}
#endif

byte menuSelectVessel(char sTitle[], byte cSelection, boolean showNone) {
  menuPROGMEMSelection volMenu(3, VESSELSELECTION, ARRAY_LENGTH(VESSELSELECTION), cSelection);
  byte lastOption = scrollMenu(sTitle, &volMenu);
  //Check Cancel click
  if (lastOption == 255)
    return cSelection;
  //Remap None (3) to INDEX_NONE
  return lastOption == 3 ? INDEX_NONE : lastOption;
}

#ifdef DIGITAL_INPUTS
  byte menuSelectDigitalInput(byte index) {
    menuNumberedItemList inputMenu(3, index, DIGITAL_INPUTS_COUNT, PSTR("Digital Input "));
    inputMenu.setSelected(index);
    byte lastOption = scrollMenu("Select Input", &inputMenu);
    if (lastOption == 255)
      return index;
    return lastOption;
  }
#endif

byte menuSelectTempSensor(char sTitle[]) {
  menuPROGMEM tsMenu(3, TITLE_TS, ARRAY_LENGTH(TITLE_TS));
  return scrollMenu(sTitle, &tsMenu);
}

//*****************************************************************************************************************************
// System Setup Menus
//*****************************************************************************************************************************
class menuSystemSetup : public menuPROGMEM {
  public:
    menuSystemSetup(byte pSize) : menuPROGMEM(pSize, SYSTEMSETUPOPTIONS, ARRAY_LENGTH(SYSTEMSETUPOPTIONS)) {}
    byte getItemCount(void) {
      byte count = 8;
      #ifdef  OUTPUTBANK_MODBUS
        count++;
      #endif
      #ifdef  RGBIO8_ENABLE
        count++;
      #endif
      #ifdef  UI_DISPLAY_SETUP
        count++;
      #endif
      return count;
    }
    byte getItemValue(byte index) {
      byte values[] = { 
        0, 1, 2, 3,
        #ifdef OUTPUTBANK_MODBUS
          4,
        #endif
        5, 6,
        #ifdef RGBIO8_ENABLE
          7,
        #endif
        #ifdef UI_DISPLAY_SETUP
          8,
        #endif
        9, 10
      };
      return values[index];
    }
};

void menuSetup() {
  menuSystemSetup setupMenu(3);
  
  while(1) {
    byte lastOption = scrollMenu("System Setup", &setupMenu);
    if (lastOption == 0)
      menuSystemSettings();
    else if (lastOption == 1)
      assignSensor();
    else if (lastOption == 2)
      menuVessels();
    else if (lastOption == 3)
      menuOutputProfiles();
    #ifdef OUTPUTBANK_MODBUS
      else if (lastOption == 4)
        menuMODBUSOutputs();
    #endif
    else if (lastOption == 5)
        menuBrewStepAutomation();
    else if (lastOption == 6)
      menuTriggers();
    #ifdef RGBIO8_ENABLE
      else if (lastOption == 7) {
        menuRGBIO();
      }
    #endif  
    #ifdef UI_DISPLAY_SETUP
      else if (lastOption == 8)
        adjustLCD();
    #endif
    else if (lastOption == 9) {
      if (confirmChoice("Reset Configuration?", "", "", INIT_EEPROM))
        UIinitEEPROM();
    }
    else return;
  }
}

void assignSensor() {
  menuPROGMEM tsMenu(1, TITLE_TS, ARRAY_LENGTH(TITLE_TS));
  
  Encoder.setMin(0);
  Encoder.setMax(tsMenu.getItemCount() - 1);
  Encoder.setCount(tsMenu.getSelected());
  
  boolean redraw = 1;
  int encValue;
  
  while (1) {
    if (redraw) {
      //First time entry or back from the sub-menu.
      redraw = 0;
      encValue = Encoder.getCount();
    } else
      encValue = Encoder.change();
    
    if (encValue >= 0) {
      tsMenu.setSelected(encValue);
      //The user has navigated toward a new temperature probe screen.
      LCD.clear();
      LCD.print_P(0, 0, PSTR("Assign Temp Sensor"));
      char optionText[20];
      LCD.center(1, 0, tsMenu.getSelectedRow(optionText), 20);
      for (byte i=0; i<8; i++)
        LCD.lPad(2,i*2+2,itoa(tSensor[tsMenu.getValue()][i], optionText, 16), 2, '0');
    }
    displayAssignSensorTemp(tsMenu.getValue()); //Update each loop

    if (Encoder.cancel()) return;
    else if (Encoder.ok()) {
      encValue = Encoder.getCount();
      //Pop-Up Menu
      menuPROGMEM tsOpMenu(3, TSASSIGNOPTIONS, ARRAY_LENGTH(TSASSIGNOPTIONS));
      char title[21];
      byte selected = scrollMenu(tsMenu.getSelectedRow(title), &tsOpMenu);
      if (selected == 0) {
        char optionText[20];
        if (confirmChoice(tsMenu.getSelectedRow(optionText), "Disconnect all other", "temp sensors now", CONTINUE)) {
          byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
          getDSAddr(addr);
          setTSAddr(encValue, addr);
        }
      } else if (selected == 1) {
        byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        setTSAddr(encValue, addr);
      } else if (selected == 2) {
        byte source = menuSelectTempSensor("Clone Sensor");
        if (source < NUM_TS) {
          byte addr[8];
          memcpy(addr, tSensor[source], 8);
          setTSAddr(encValue, addr);
        }
      } else if (selected == 4)
        return;

      Encoder.setMin(0);
      Encoder.setMax(tsMenu.getItemCount() - 1);
      Encoder.setCount(tsMenu.getSelected());
      redraw = 1;
    }
    BrewTrollerApplication::getInstance()->update(PRIORITYLEVEL_NORMAL);
  }
}

void displayAssignSensorTemp(int sensor) {
  LCD.print_P(3, 10, TUNIT); 
  if (temp[sensor] == BAD_TEMP) {
    LCD.print_P(3, 7, PSTR("---"));
  } else {
    char numText[7];
    LCD.lPad(3, 7, itoa(temp[sensor] / 100, numText, 10), 3, ' ');
  }
}

void menuSystemSettings() {
    menuPROGMEM settingsMenu(3, SYSTEMOPTIONS, ARRAY_LENGTH(SYSTEMOPTIONS));

    while (1) {
      byte lastOption = scrollMenu("System Settings", &settingsMenu);
      if (lastOption == 0)
        setBoilTemp(getValue_P(BOIL_TEMP, getBoilTemp(), SETPOINT_DIV, 255, TUNIT));
      else if (lastOption == 1)
        setBoilPwr(getValue_P(BOIL_POWER, boilPwr, 1, 100, PSTR("%")));
      else if (lastOption == 2)
        setEvapRate(getValue_P(EVAPORATION_RATE, getEvapRate(), 1000 / EvapRateConversion, 255, EVAPUNIT));
      else if (lastOption == 3)
        setGrainDisplacement(getValue_P(GRAIN_DISPLACEMENT, getGrainDisplacement(), 1000, 65535, GRAINRATIOUNIT));
      else if (lastOption == 4)
        setGrainLiquorLoss(getValue_P(GRAIN_LIQUOR_LOSS, getGrainLiquorLoss(), 10000, 65535, GRAINRATIOUNIT));
      else if (lastOption == 5)
        setStrikeLoss(getValue_P(STRIKE_LOSS, getStrikeLoss(), 1000, 65535, VOLUNIT));
      else if (lastOption == 6)
        setSpargeLoss(getValue_P(SPARGE_LOSS, getSpargeLoss(), 1000, 65535, VOLUNIT));
      else if (lastOption == 7)
        setMashLoss(getValue_P(MASH_LOSS, getMashLoss(), 1000, 65535, VOLUNIT));
      else if (lastOption == 8)
        setBoilLoss(getValue_P(BOIL_LOSS, getBoilLoss(), 1000, 65535, VOLUNIT));
      else if (lastOption == 9)
        setMashTunHeatCapacity(getValue("Mash Specific Heat", getMashTunHeatCapacity(), 1000, 65536, PSTR("")));
      else if (lastOption == 10)
        setMinimumSpargeVolume(getValue("Min Sparge Volume", getMinimumSpargeVolume(), 10, 65536, VOLUNIT));
      else
        return;
    }
}

class menuAutomationOptions : public menuPROGMEM {
  public:
    menuAutomationOptions(byte pSize): menuPROGMEM(pSize, AUTOMATIONOPTIONS, ARRAY_LENGTH(AUTOMATIONOPTIONS)) {}
    
    char *getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      char numText[4];
      if (index == 0)
        strcat_P(retString, brewStepConfiguration.fillSpargeBeforePreheat ? PSTR("Start") : PSTR("Refill"));
      else if (index == 1)
        strcat_P(retString, brewStepConfiguration.autoStartFill ? ON : OFF);
      else if (index == 2)
        strcat_P(retString, brewStepConfiguration.autoExitFill ? ON : OFF);
      else if (index == 3)
        strcat_P(retString, brewStepConfiguration.autoExitPreheat ? ON : OFF);
      else if (index == 4)
        strcat_P(retString, brewStepConfiguration.autoStrikeTransfer ? ON : OFF);
      else if (index == 5)
      {  
        if (brewStepConfiguration.autoExitGrainInMinutes) {
          strcat(retString, itoa(brewStepConfiguration.autoExitGrainInMinutes, numText, 10));
          strcat_P(retString, MIN);
        } else {
          strcat_P(retString, OFF);
        }
      }
      else if (index == 6)
        strcat_P(retString, brewStepConfiguration.autoExitMash ? ON : OFF);
      else if (index == 7)
        strcat_P(retString, brewStepConfiguration.autoStartFlySparge ? ON : OFF);
      else if (index == 9)
        strcat_P(retString, brewStepConfiguration.autoExitSparge ? ON : OFF);
      else if (index == 10) {
        if(brewStepConfiguration.autoBoilWhirlpoolMinutes) {
          strcat(retString, itoa(brewStepConfiguration.autoBoilWhirlpoolMinutes, numText, 10));
          strcat_P(retString, MIN);
        } else {
          strcat_P(retString, OFF);
        }
      } else if (index == 11) {
        if(brewStepConfiguration.boilAdditionSeconds) {
          strcat(retString, itoa(brewStepConfiguration.boilAdditionSeconds, numText, 10));
          strcat(retString, "s");
        } else {
          strcat_P(retString, OFF);
        }
      } else if (index == 12) {
        strcat(retString, itoa(brewStepConfiguration.preBoilAlarm, numText, 10));
        strcat_P(retString, TUNIT);
      }
    }
};

void menuBrewStepAutomation() {
  menuAutomationOptions settingsMenu(3);
  while(1) {
    byte lastOption = scrollMenu("Step Automation", &settingsMenu);
    if (lastOption == 0)
      brewStepConfiguration.fillSpargeBeforePreheat ^= 1;
    else if (lastOption == 1)
      brewStepConfiguration.autoStartFill ^= 1;
    else if (lastOption == 2)
      brewStepConfiguration.autoExitFill ^= 1;
    else if (lastOption == 3)
      brewStepConfiguration.autoExitPreheat ^= 1;
    else if (lastOption == 4)
      brewStepConfiguration.autoStrikeTransfer ^= 1;
    else if (lastOption == 5)
      brewStepConfiguration.autoExitGrainInMinutes = getValue("Auto Exit Grain In", brewStepConfiguration.autoExitGrainInMinutes, 1, 255, MIN);
    else if (lastOption == 6)
      brewStepConfiguration.autoExitMash ^= 1;
    else if (lastOption == 7)
      brewStepConfiguration.autoStartFlySparge ^= 1;
    else if (lastOption == 8)
      brewStepConfiguration.flySpargeHysteresis = getValue("Sparge Hysteresis", brewStepConfiguration.flySpargeHysteresis, 10, 255, VOLUNIT);
    else if (lastOption == 9)
      brewStepConfiguration.autoExitSparge ^= 1;
    else if (lastOption == 10)
      brewStepConfiguration.autoBoilWhirlpoolMinutes = getValue("Auto Boil Whirlpool", brewStepConfiguration.autoBoilWhirlpoolMinutes, 1, 255, MIN);
    else if (lastOption == 11)
      brewStepConfiguration.boilAdditionSeconds = getValue("Boil Additions", brewStepConfiguration.boilAdditionSeconds, 1, 255, PSTR("s"));
    else if (lastOption == 12)
      brewStepConfiguration.preBoilAlarm = getValue("Preboil Alarm", brewStepConfiguration.preBoilAlarm, 1, 255, TUNIT);
    else {
      eepromSaveBrewStepConfiguration();
      return;
    }
  }
}

void menuVessels() {
  menuPROGMEM vesselMenu(3, TITLE_VS, ARRAY_LENGTH(TITLE_VS));
  while (1) {
    byte lastOption = scrollMenu("Vessel Settings", &vesselMenu);
    if (lastOption < VESSEL_COUNT)
      menuVesselSettings(lastOption);
    else if(lastOption == VESSEL_COUNT)
      menuBubbler();
    else
      return;
  }
}

class menuVesselOptions : public menuPROGMEM {
  private:
    byte vessel;
  public:
    menuVesselOptions(byte pSize, byte v) : menuPROGMEM(pSize, MENUVESSELOPTIONS, ARRAY_LENGTH(MENUVESSELOPTIONS) ) {
      vessel = v;  
    }
    byte getItemCount(void) {
      #ifdef ANALOGINPUTS_GPIO
        return (getPWMPin(vessel) == INDEX_NONE) ? 7 : 14;
      #else
        return (getPWMPin(vessel) == INDEX_NONE) ? 5 : 12;
      #endif
    }

    byte getItemValue(byte index) {
      #ifdef ANALOGINPUTS_GPIO
        byte values[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
      #else
        byte values[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13};
      #endif
      
      if (getPWMPin(vessel) == INDEX_NONE) {
        #ifdef ANALOGINPUTS_GPIO
          byte extraOptions[] = {8, 9, 10, 11, 12, 13, 13, 13, 13, 13, 13, 13, 13};
        #else
          byte extraOptions[] = {8, 10, 12, 13, 13, 13, 13, 13, 13, 13, 13};
        #endif
        memcpy(values + 1, extraOptions, sizeof(extraOptions));
      }
      return values[index];
    }
};

void menuVesselSettings(byte vessel) {
  byte lastOption = 0;
  while(1) {
    menuVesselOptions vesselMenu(3, vessel);

    char title[20];
    strcpy_P(title, (char*)pgm_read_word(&(TITLE_VS[vessel])));
    strcat_P(title, PSTR(" Settings"));
    vesselMenu.setSelected(lastOption);
    lastOption = scrollMenu(title, &vesselMenu);

    strcpy_P(title, (char*)pgm_read_word(&(TITLE_VS[vessel])));
    strcat_P(title, PSTR(" "));

    if (lastOption == 0)
      setPWMPin(vessel, menuSelectOutput("PWM Pin", getPWMPin(vessel)));
    else if (lastOption == 1)
      setPWMPeriod(vessel, getValue_P(PSTR("PWM Period"), getPWMPeriod(vessel), 10, 255, SEC));
    else if (lastOption == 2)
      setPWMResolution(vessel, getValue_P(PSTR("PWM Resolution"), getPWMResolution(vessel), 1, 255, PSTR("")));
    else if (lastOption == 3)
      setPIDp(vessel, getValue_P(PSTR("P Gain"), getPIDp(vessel), PIDGAIN_DIV, PIDGAIN_LIM, PSTR("")));
    else if (lastOption == 4)
      setPIDi(vessel, getValue_P(PSTR("I Gain"), getPIDi(vessel), PIDGAIN_DIV, PIDGAIN_LIM, PSTR("")));
    else if (lastOption == 5)
      setPIDd(vessel, getValue_P(PSTR("D Gain"), getPIDd(vessel), PIDGAIN_DIV, PIDGAIN_LIM, PSTR("")));
    else if (lastOption == 6)
      uiAutoTuneMenu(vessel);
    else if (lastOption == 7)
      setPIDLimit(vessel, getValue_P(PSTR("PID Limit"), getPIDLimit(vessel), 1, 100, PSTR("")));
    else if (lastOption == 8)
      setHysteresis(vessel, getValue_P(HYSTERESIS, BrewTrollerApplication::getInstance()->getVessel(vessel)->getHysteresis(), 10, 255, TUNIT));

    else if (lastOption  == 10) {
      strcat_P(title, CAPACITY);
      setCapacity(vessel, getValue(title, getCapacity(vessel), 1000, 9999999, VOLUNIT));
    }
    #ifdef ANALOGINPUTS_GPIO
      else if (lastOption  == 9) {
        strcat_P(title, PSTR("Sensor"));
        setVolumeSensor(vessel, menuSelectAnalogInput(title, BrewTrollerApplication::getInstance()->getVessel(vessel)->getVolumeInput()));
      } 
    #endif
    else if (lastOption == 11) {
      strcat_P(title, CALIBRATION);
      volCalibMenu(title, vessel);
    } else if (lastOption == 12) {
      byte sourceIndex = menuSelectVessel("Clone From:", INDEX_NONE, 1);
      if (sourceIndex <= VS_KETTLE) {
        Vessel *source = BrewTrollerApplication::getInstance()->getVessel(sourceIndex);
        setPWMPin(vessel, getPWMPin(sourceIndex));
        setPWMPeriod(vessel, getPWMPeriod(sourceIndex));
        setPWMResolution(vessel, getPWMResolution(sourceIndex));
        setPIDp(vessel, getPIDp(sourceIndex));
        setPIDi(vessel, getPIDi(sourceIndex));
        setPIDd(vessel, getPIDd(sourceIndex));
        setPIDLimit(vessel, getPIDLimit(sourceIndex));
        setHysteresis(vessel, source->getHysteresis());
        setVolumeSensor(vessel, getVolumeSensor(sourceIndex));
        setCapacity(vessel, getCapacity(sourceIndex));
        for (byte i = 0; i < 10; i++) {
          struct Calibration calibration = source->getVolumeCalibration(i);
          setVolCalib(vessel, i, calibration);
        }
      }
    }
    else {
      loadPWMOutput(vessel);
      return;
    }
  } 
}

class menuAutoTuneOptions : public menuPROGMEM {
  private:
    byte *startPercent;
    byte *stepPercent;
    unsigned int *lookbackSecs;
    byte *inputNoise;
    int *controlMode;
    
  public:
    menuAutoTuneOptions(byte pSize, byte *startP, byte *stepP, unsigned int *lookback, byte *noise, int *mode) : menuPROGMEM(pSize, MENUAUTOTUNEOPTIONS, ARRAY_LENGTH(MENUAUTOTUNEOPTIONS) ) { 
      startPercent = startP;
      stepPercent = stepP;
      lookbackSecs = lookback;
      inputNoise = noise;
      controlMode = mode;
    }
    
    char* getItem(byte index, char *retString) {
        menuPROGMEM::getItem(index, retString);
        byte option = getItemValue(index);
        char numText[6];
        if (option == 0) {
          strcat(retString, itoa(*startPercent, numText, 10));
          strcat(retString, "%");
        } else if (option == 1) {
          strcat(retString, itoa(*stepPercent, numText, 10));
          strcat(retString, "%");
        } else if (option == 2) {
          strcat(retString, itoa(*lookbackSecs, numText, 10));
          strcat(retString, "s");
        } else if (option == 3) {
          vftoa(*inputNoise, numText, 100, 1);
          truncFloat(numText, 4);
          strcat(retString, numText);
          strcat_P(retString, TUNIT);
        } else if (option == 4 && *controlMode)
          strcat(retString, "D");
        return retString;
      }
};

void uiAutoTuneMenu(byte vIndex) {
  byte aTuneStartPercent = 40;
  byte aTuneStepPercent = 20;
  unsigned int aTuneLookBack = 20;

  #ifdef USEMETRIC
    byte aTuneNoise = 56;
  #else
    byte aTuneNoise = 100;
  #endif

  // Default to PI control
  int useDerivative = 0;

  menuAutoTuneOptions autoTuneMenu(3, &aTuneStartPercent, &aTuneStepPercent, &aTuneLookBack, &aTuneNoise, &useDerivative);
  while(1) {
    byte lastOption = scrollMenu("PID Auto Tune", &autoTuneMenu);
    if (lastOption == 0)
      aTuneStartPercent = getValue_P(PSTR("Start Power:"), aTuneStartPercent, 1, 100, PSTR("%"));
    else if (lastOption == 1)
      aTuneStepPercent = getValue_P(PSTR("Step Power:"), aTuneStepPercent, 1, 100, PSTR("%"));
    else if (lastOption == 2)
      aTuneLookBack = getValue_P(PSTR("Lookback:"), aTuneLookBack, 1, 999, SEC);
    else if (lastOption == 3)
      aTuneNoise = getValue_P(PSTR("Input Noise:"), aTuneNoise, 100, 255, TUNIT);
    else if (lastOption == 4)
      useDerivative = useDerivative ? 0 : 1;
    else {
      if (lastOption == 5 && (confirmChoice(" Vessel filled and", " ready to heat for", "  PID Auto Tuning?", CONTINUE)))
        uiAutoTune(vIndex, useDerivative, aTuneStartPercent, aTuneStepPercent, aTuneNoise, aTuneLookBack);
      break;
    }
  }
}

void uiAutoTune(byte vIndex, int useDerivative, byte aTuneStartPercent, byte aTuneStepPercent, byte aTuneNoise, unsigned int aTuneLookBack) {
  BrewTrollerApplication *btApp = BrewTrollerApplication::getInstance();
  Vessel *vessel = btApp->getVessel(vIndex);
  if (!vessel->getPWMOutput())
    return;
  unsigned long maxOutput = vessel->getPWMOutput()->getLimit();
  
  unsigned long aTuneStartValue =  maxOutput * aTuneStartPercent / 100;
  unsigned long aTuneStep =  maxOutput * aTuneStepPercent / 100;
  
  if (vIndex == VS_KETTLE)
    setBoilControlState(CONTROLSTATE_MANUAL);
  
  vessel->startAutoTune(useDerivative, aTuneStartValue, aTuneStep, aTuneNoise, aTuneLookBack);
  boolean didInit = 0;
  while (vessel->isTuning()) {
    if (!didInit) {
      LCD.clear();
      LCD.print_P(0, 3, PSTR("PID Auto Tune"));
      LCD.print_P(1, 2, PSTR("Peak Count:   /10"));
      LCD.print_P(2, 10, PSTR("-"));
      LCD.print_P(3, 0, PSTR("Current:"));
      didInit = 1;
    }
    if (Encoder.ok()) {
      if (confirmChoice("", "Abort PID Auto Tune?", "", ABORT)) {
        vessel->stopAutoTune();
        return;
      }
      didInit = 0;
    }
    char numText[7];
    LCD.lPad(1, 14, itoa(vessel->getPIDAutoTune()->GetPeakCount(), numText, 10), 2, ' ');
    uiLabelTemperature(2, 3, 6, vessel->getPIDAutoTune()->GetAbsMin());
    uiLabelTemperature(2, 12, 6, vessel->getPIDAutoTune()->GetAbsMax());
    uiLabelTemperature(3, 9, 6, vessel->getTemperature());
    uiLabelPercentOnOff(3, 17, vessel->getHeatPower());
    btApp->update(PRIORITYLEVEL_NORMAL);
  }

  if (vIndex == VS_KETTLE)
    setBoilControlState(CONTROLSTATE_OFF);
    
  LCD.clear();
  LCD.print(0, 1,  "Auto Tune Complete");
  LCD.print(1, 2,  "Peak Count:");
  LCD.print(2, 10, "-");
  LCD.print(3, 0,  "P");
  LCD.print(3, 7,  "I");
  LCD.print(3, 14, "D");

  char numText[7];
  LCD.print(1, 14, itoa(vessel->getPIDAutoTune()->GetPeakCount(), numText, 10));
  uiLabelFPoint(3, 1, 5,  vessel->getPIDAutoTune()->GetKp() * PIDGAIN_DIV, 1);

  uiLabelTemperature(2, 3, 6, vessel->getPIDAutoTune()->GetAbsMin());
  uiLabelTemperature(2, 12, 6, vessel->getPIDAutoTune()->GetAbsMax());
  
  uiLabelFPoint(3, 1, 5,  vessel->getPIDAutoTune()->GetKp() * PIDGAIN_DIV, PIDGAIN_DIV);
  uiLabelFPoint(3, 8, 5,  vessel->getPIDAutoTune()->GetKi() * PIDGAIN_DIV, PIDGAIN_DIV);
  uiLabelFPoint(3, 15, 5, vessel->getPIDAutoTune()->GetKd() * PIDGAIN_DIV, PIDGAIN_DIV);

  while(!Encoder.ok())
    btApp->update(PRIORITYLEVEL_NORMAL);
    
  setPIDp(vIndex, vessel->getPIDAutoTune()->GetKp() * PIDGAIN_DIV);
  setPIDi(vIndex, vessel->getPIDAutoTune()->GetKi() * PIDGAIN_DIV);
  setPIDd(vIndex, vessel->getPIDAutoTune()->GetKd() * PIDGAIN_DIV);
}

class menuVolumeCalibrationList : public menu {
  private:
    Vessel *vessel;
    
    char* getItemCalibration(byte index, char *retString) {
      struct Calibration calibration = vessel->getVolumeCalibration(index);
      
      if (calibration.inputValue == 0)
        return strcpy(retString, "OPEN");
        
      char numText[12];
      vftoa(calibration.outputValue, retString, 1000, 1);
      truncFloat(retString, 6);
      strcat(retString, " ");
      strcat_P(retString, VOLUNIT);
      strcat(retString, " (");
      strcat(retString, itoa(calibration.inputValue, numText, 10));
      strcat(retString, ")");
      return retString;
    }
        
  public:
    menuVolumeCalibrationList(byte pSize, Vessel *v) : menu(pSize) {
     vessel = v;
    }
    byte getItemCount(void) {
      return 11;
    }
    char* getItem(byte index, char *retString) {
      if (index < 10)
        getItemCalibration(index, retString);
      else
        strcpy_P(retString, EXIT);
      return retString;
    }
};

void volCalibMenu(char sTitle[], byte vesselIndex) {
  Vessel *vessel = BrewTrollerApplication::getInstance()->getVessel(vesselIndex);
  
  menuVolumeCalibrationList calibMenu(3, vessel);    
  while(1) {
    byte lastOption = scrollMenu(sTitle, &calibMenu);
    if (lastOption > 9)
      return; 
    struct Calibration calibration = vessel->getVolumeCalibration(lastOption);
    if (calibration.inputValue == 0) {
      calibration.outputValue = getValue_P(PSTR("Current Volume:"), 0, 1000, 9999999, VOLUNIT);
      setVolCalib(vesselIndex, lastOption, calibration);
    }
    volCalibEntryMenu(vesselIndex, lastOption);
  }
}

class menuVolumeCalibrationOptions : public menuPROGMEM {
  private:
    unsigned int oldValue, newValue;
    
  public:
   menuVolumeCalibrationOptions(byte pSize, unsigned int oValue, unsigned int nValue) : menuPROGMEM(pSize, VOLUMECALIBRATIONOPTIONS, ARRAY_LENGTH(VOLUMECALIBRATIONOPTIONS)) {
     oldValue = oValue;
     newValue = nValue;
   }
   char* getItem(byte index, char *retString) {
     menuPROGMEM::getItem(index, retString);
     if (index == 0) {
       char numText[7];
       strcat(retString, itoa(oldValue, numText, 10));
       strcat(retString, " to ");
       strcat(retString, itoa(newValue, numText, 10));
     }
     return retString;
   }
};

//This function manages the volume value to calibrate. 
//The value can be updated or deleted. 
//Users can skip all actions by exiting. 
void volCalibEntryMenu(byte vesselIndex, byte entry) {
  Vessel *vessel = BrewTrollerApplication::getInstance()->getVessel(vesselIndex);

  struct Calibration calibration = vessel->getVolumeCalibration(entry);
  char sTitle[21] = "Calibrate ";
  char numText[12];
      
  vftoa(calibration.outputValue, numText, 1000, 1);
  truncFloat(numText, 6);
  strcat(sTitle, numText);
  strcat(sTitle, " ");
  strcat_P(sTitle, VOLUNIT);

  unsigned int origValue = calibration.inputValue;
  calibration.inputValue = vessel->getRawVolumeValue();
  
  menuVolumeCalibrationOptions calibMenu(3, origValue, calibration.inputValue);
  byte lastOption = scrollMenu(sTitle, &calibMenu);

  if (lastOption < 2) {
    if (lastOption == 1)
      calibration.inputValue = (unsigned int) getValue_P(PSTR("Manual Volume Entry"), calibration.inputValue, 1, 1023, PSTR(""));
    setVolCalib(vesselIndex, entry, calibration); 
  } else if (lastOption == 2) {
    //Delete the volume and value.
    if(confirmDel()) {
      calibration.inputValue = 0;
      calibration.outputValue = 0;
      setVolCalib(vesselIndex, entry, calibration); 
    } 
  }
}

class menuBubblerConfig : public menuPROGMEM {
  public:
    menuBubblerConfig(byte pSize) : menuPROGMEM(pSize, BUBBLEROPTIONS, ARRAY_LENGTH(BUBBLEROPTIONS)) {}
    byte getItemCount(void) {
      return getBubblerOutput() == INDEX_NONE ? 2 : 5;
    }
    byte getItemValue(byte index) {
      if (getBubblerOutput() == INDEX_NONE && index > 0)
        return 4;
      return index;
    }
    char* getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      byte option = getItemValue(index);
      char numText[5];
      if (option == 0) {
        byte bubbleOutput = getBubblerOutput();
        char outputFullName[OUTPUT_FULLNAME_MAXLEN] = "DISABLED";
        if (bubbleOutput != INDEX_NONE)
          outputs->getOutputFullName(bubbleOutput, outputFullName);
        strcat(retString, outputFullName);
      } else if (option == 1) {
        strcat(retString, itoa(getBubblerInterval(), numText, 10));
        strcat(retString, "s");
      } else if (option == 2) {
        strcat(retString, vftoa(getBubblerDuration(), numText, 10, 1));
        strcat(retString, "s");
      } else if (option == 3) {
        strcat(retString, vftoa(getBubblerDelay(), numText, 10, 1));
        strcat(retString, "s");        
      }
      return retString;
    }
};

void menuBubbler() {
  while (1) {
    menuBubblerConfig volMenu(3);

    byte lastOption = scrollMenu("Bubbler Setup", &volMenu);
    if (lastOption == 0)
      setBubblerOutput(menuSelectOutput("Bubbler Output", getBubblerOutput()));
    else if (lastOption == 1)
      setBubblerInterval(getValue("Bubbler Interval", getBubblerInterval(), 1, 255, PSTR("s")));
    else if (lastOption == 2)
      setBubblerDuration(getValue("Bubbler Duration", getBubblerDuration(), 10, 255, PSTR("s")));
    else if (lastOption == 3)
      setBubblerDelay(getValue("Bubbler Read Delay", getBubblerDelay(), 10, 255, PSTR("s")));
    else {
      loadBubbler();
      return;
    }
  }
}

void menuOutputProfiles() {
  menuOutputProfileList outputProfileMenu(3);
  while (1) {
    byte profile = scrollMenu("Output Profiles", &outputProfileMenu);
    if (profile < OUTPUTPROFILE_USERCOUNT) {
      char profileName[20];
      strcpy_P(profileName, (char*)pgm_read_word(&(TITLE_VLV[profile])));
      setOutputProfile(profile, menuSelectOutputs(profileName, outputs->getProfileMask(profile), 1));
    } else
      return;
  }
}

#ifdef OUTPUTBANK_MODBUS
  class menuMODBUSOutputBoardList : public menu {
    private:

    public:
      menuMODBUSOutputBoardList(byte pSize) : menu(pSize) {}
      byte getItemCount(void) {
        return OUTPUTBANK_MODBUS_MAXBOARDS + 1;
      }
      char* getItem(byte index, char *retString) {
        if (index < OUTPUTBANK_MODBUS_MAXBOARDS)
          getItemBoard(index, retString);
        else
          strcpy_P(retString, EXIT);
        return retString;
      }
      
      char* getItemBoard(byte index, char *retString) {
        strcpy(retString, "Board 1: ");
        retString[6] += index;
        byte addr = getOutModbusAddr(index);
        OutputBankMODBUS tempMB(addr, getOutModbusReg(index), getOutModbusCoilCount(index));
        
        if (addr == OUTPUTBANK_MODBUS_ADDRNONE)
          strcat(retString, "DISABLED");
        else {
          byte result = tempMB.detect();
          if (result == ModbusMaster::ku8MBSuccess) 
            strcat(retString, "CONNECTED");
          else if (result == ModbusMaster::ku8MBResponseTimedOut)
            strcat(retString, "TIMEOUT");
          else {
            strcat(retString, "ERROR ");
            char numText[3];
            strcat(retString, itoa(result, numText, 16));
          }
        }
        return retString;
      }
  };

  void menuMODBUSOutputs() {
    menuMODBUSOutputBoardList boardMenu(3);
    while(1) {
      byte lastOption = scrollMenu("RS485 Outputs", &boardMenu);
      if (lastOption < OUTPUTBANK_MODBUS_MAXBOARDS)
        menuMODBUSOutputBoard(lastOption);
      else
        return;
    }
  }

  class menuMODBUSConfig : public menuPROGMEM {
    private:
      byte address;
      unsigned int coilReg;
      byte coilCount;
      byte idMode;
      
    public:
      menuMODBUSConfig(byte pSize, byte a, unsigned int r, byte c, byte m) : menuPROGMEM(pSize, MODBUSBOARDOPTIONS, ARRAY_LENGTH(MODBUSBOARDOPTIONS)) {
        address = a;
        coilReg = r;
        coilCount = c;
        idMode = m;
      }
      byte getItemCount(void) {
        return (address == OUTPUTBANK_MODBUS_ADDRNONE) ? 3 : 6;
      }
      byte getItemValue(byte index) {
        byte values[6] = {0, 3, 6, 6, 6, 6};
        if (address != OUTPUTBANK_MODBUS_ADDRNONE) {
          byte optValues[] = {0, 1, 2, 4, 5};
          memcpy(values, optValues, sizeof(optValues));
        }
        return values[index];
      }
      char* getItem(byte index, char *retString) {
        menuPROGMEM::getItem(index, retString);
        byte option = getItemValue(index);
        char numText[6] = "N/A";
        if (option == 0) {
          if (address != OUTPUTBANK_MODBUS_ADDRNONE)
            itoa(address, numText, 10);
          strcat(retString, numText);
        } else if (option == 1)
          strcat(retString, itoa(coilReg, numText, 10));
        else if (option == 2)
          strcat(retString, itoa(coilCount, numText, 10));
        else if (option == 4)
          strcat_P(retString, idMode ? ON : OFF);
        return retString;
      }
  };
  
  void menuMODBUSOutputBoard(byte board) {
    
    while(1) {
      byte address = getOutModbusAddr(board);
      unsigned int coilReg = getOutModbusReg(board);
      byte coilCount = getOutModbusCoilCount(board);
      OutputBankMODBUS tempMB(address, coilReg, coilCount);
      byte idMode = tempMB.getIDMode();
      menuMODBUSConfig boardMenu(3, address, coilReg, coilCount, idMode);
      
      char title[] = "RS485 Output Board 1";
      title[19] += board;
      byte lastOption = scrollMenu(title, &boardMenu);
      if (lastOption == 0)
        setOutModbusAddr(board, getValue_P(PSTR("Address"), address == OUTPUTBANK_MODBUS_ADDRNONE ? OUTPUTBANK_MODBUS_BASEADDR + board : address, 1, 255, PSTR("")));
      else if (lastOption == 1)
        setOutModbusReg(board, getValue_P(PSTR("Coil Register"), coilReg, 1, 65536, PSTR("")));
      else if (lastOption == 2)
        setOutModbusCoilCount(board, getValue_P(PSTR("Coil Count"), coilCount, 1, 32, PSTR("")));
      else if (lastOption == 3)
        cfgMODBUSOutputAssign(board);
      else if (lastOption == 4)
        tempMB.setIDMode(idMode ^ 1);
      else {
        if (lastOption == 5)
          setOutModbusDefaults(board);
        loadOutputSystem();
        return;
      }
    }
  }

  class menuMODBUSDetectError : public menu {
    private:
      byte *result;
    public:
      menuMODBUSDetectError(byte pSize, byte *r) : menu(pSize) {
        result = r;
      }
      byte getItemCount(void) {
        return 2;
      }
      char* getItem(byte index, char *retString) {
        if (index)
          return strcpy_P(retString, ABORT);

        if (*result == ModbusMaster::ku8MBResponseTimedOut)
          strcpy_P(retString, PSTR("Timeout"));
        else {
          strcpy_P(retString, PSTR("Error "));
          char numText[3];
          strcat(retString, itoa(*result, numText, 16));
        }
        strcat_P(retString, PSTR(": Retry?"));
        return retString;
      }
  };
  
  void cfgMODBUSOutputAssign(byte board) {
    OutputBankMODBUS tempMB(OUTPUTBANK_MODBUS_ADDRINIT, getOutModbusReg(board), getOutModbusCoilCount(board));
    
    byte result = 1;
    menuMODBUSDetectError choiceMenu(1, &result);
    while (result = tempMB.detect()) {
      LCD.clear();
      LCD.print_P(0, 0, PSTR("Click/hold to reset"));
      LCD.print_P(1, 0, PSTR("output board then"));
      LCD.print_P(2, 0, PSTR("click to activate."));
      if(getChoice(&choiceMenu, 3))
        return;      
    }
    byte newAddr = getValue_P(PSTR("New Address"), OUTPUTBANK_MODBUS_BASEADDR + board, 1, 254, PSTR(""));
    if (tempMB.setAddr(newAddr))
      infoBox("","Update Failed", "", CONTINUE);
    else
      setOutModbusAddr(board, newAddr);
  }
#endif

#ifdef UI_DISPLAY_SETUP
  void adjustLCD() {
    byte cursorPos = 0; //0 = brightness, 1 = contrast, 2 = cancel, 3 = save
    boolean cursorState = 0; //0 = Unselected, 1 = Selected

    Encoder.setMin(0);
    Encoder.setCount(0);
    Encoder.setMax(3);
    
    LCD.clear();
    LCD.print_P(0,0,PSTR("Adjust LCD"));
    LCD.print_P(1, 1, PSTR("Brightness:"));
    LCD.print_P(2, 3, PSTR("Contrast:"));
    LCD.print_P(3, 1, PSTR("Cancel"));
    LCD.print_P(3, 15, PSTR("Save"));
    byte bright = LCD.getBright();
    byte contrast = LCD.getContrast();
    byte origBright = bright;
    byte origContrast = contrast;
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
          if (cursorPos == 0) { 
            bright = encValue;
            LCD.setBright(bright);
          } else if (cursorPos == 1) {
            contrast = encValue;
            LCD.setContrast(contrast);
          }
        } else {
          cursorPos = encValue;
          if (cursorPos == 0) {
            uiCursorFocus(1, 12, 5);
            uiCursorNone(2, 12, 5);
            uiCursorNone(3, 0, 8);
            uiCursorNone(3, 14, 6);
          } else if (cursorPos == 1) {
            uiCursorNone(1, 12, 5);
            uiCursorFocus(2, 12, 5);
            uiCursorNone(3, 0, 8);
            uiCursorNone(3, 14, 6);
          } else if (cursorPos == 2) {
            uiCursorNone(1, 12, 5);
            uiCursorNone(2, 12, 5);
            uiCursorFocus(3, 0, 8);
            uiCursorNone(3, 14, 6);
          } else if (cursorPos == 3) {
            uiCursorNone(1, 12, 5);
            uiCursorNone(2, 12, 5);
            uiCursorNone(3, 0, 8);
            uiCursorFocus(3, 14, 6);
          }
        }
        char numText[4];
        LCD.lPad(1, 13, itoa(bright, numText, 10), 3, ' ');
        LCD.lPad(2, 13, itoa(contrast, numText, 10), 3, ' ');
      }
      if (Encoder.ok()) {
        if (cursorPos == 2) {
          LCD.setBright(origBright);
          LCD.setContrast(origContrast);
          return;
        }
        else if (cursorPos == 3) {
          LCD.saveConfig();
          return;
        }
        cursorState = cursorState ^ 1;
        if (cursorState) {
          Encoder.setMin(0);
          Encoder.setMax(255);
          if (cursorPos == 0) Encoder.setCount(bright);
          else if (cursorPos == 1) Encoder.setCount(contrast);
        } else {
          Encoder.setMin(0);
          Encoder.setMax(3);
          Encoder.setCount(cursorPos);
        }
      } else if (Encoder.cancel()) return;
      BrewTrollerApplication::getInstance()->update(PRIORITYLEVEL_NORMAL);
    }
  }
#endif //#ifdef UI_DISPLAY_SETUP

class menuTriggerList : public menu {
  private:
    
  public:
    menuTriggerList(byte pSize) : menu(pSize) {
    }
    
    byte getItemCount(void) {
      #ifdef ESTOP_PIN
        return USERTRIGGER_COUNT + 2;
      #else
        return USERTRIGGER_COUNT + 1;
      #endif
    }
      
    char* getItem(byte index, char *retString) {
      if (index < USERTRIGGER_COUNT) {
        struct TriggerConfiguration trigConfig;
        loadTriggerConfiguration(index, &trigConfig);
        switch (trigConfig.type) {
          case TRIGGERTYPE_NONE:
            strcpy_P(retString, PSTR("NOT CONFIGURED"));
            break;
        #ifdef DIGITAL_INPUTS
          case TRIGGERTYPE_GPIO:
            strcpy_P(retString, PSTR("INPUT 1"));
            retString[6] += trigConfig.index;
            break;
        #endif
          case TRIGGERTYPE_VOLUME:
            strcpy_P(retString, (char*)pgm_read_word(&(TITLE_VS[trigConfig.index])));
            strcat_P(retString, PSTR(" Volume"));
            break;
          case TRIGGERTYPE_SETPOINTDELAY:
            strcpy_P(retString, (char*)pgm_read_word(&(TITLE_VS[trigConfig.index])));
            strcat_P(retString, PSTR(" Delay"));
            break;
        }
      }
      #ifdef ESTOP_PIN
        else if (index == USERTRIGGER_COUNT) {
          strcpy_P(retString, PSTR("E-Stop: "));
          strcat_P(retString, getEStopEnabled() ? PSTR("Enabled") : PSTR("Disabled"));
          return retString;
        }
      #endif
      else
        strcpy_P(retString, EXIT);
      return retString;
    }
};

void menuTriggers() {
  menuTriggerList triggerMenu(3);
  while(1) {
    byte lastOption = scrollMenu("Triggers", &triggerMenu);
    if (lastOption < USERTRIGGER_COUNT)
      cfgTrigger(lastOption);
    else if (lastOption == USERTRIGGER_COUNT) {
      #ifdef ESTOP_PIN
        setEStopEnabled(getEStopEnabled() ? 0 : 1);
        loadEStop();
      #endif
    } else 
      return;
  }
}

class menuTriggerConfig : public menuPROGMEM {
  private:
    struct TriggerConfiguration *trigConfig;
  public:
    menuTriggerConfig(byte pSize, struct TriggerConfiguration *c) : menuPROGMEM(pSize, TRIGGEROPTIONS, ARRAY_LENGTH(TRIGGEROPTIONS)) {
      trigConfig = c;
    }
    byte getItemCount(void) {
      switch (trigConfig->type) {
        case TRIGGERTYPE_NONE:
          return 2;
      #ifdef DIGITAL_INPUTS
        case TRIGGERTYPE_GPIO:
      #endif
        case TRIGGERTYPE_SETPOINTDELAY:
          return 7;
        case TRIGGERTYPE_VOLUME:
          return 8;
      }
    }
    byte getItemValue(byte index) {
      byte values[8] = {0, 8, 8, 8, 8, 8, 8, 8};
      if (trigConfig->type == TRIGGERTYPE_VOLUME) {
        byte optValues[] = {0, 2, 3, 4, 5, 6, 7};
        memcpy(values, optValues, sizeof(optValues));
    #ifdef DIGITAL_INPUTS
      } else if (trigConfig->type == TRIGGERTYPE_GPIO) {
        byte optValues[] = {0, 1, 4, 5, 6, 7};
        memcpy(values, optValues, sizeof(optValues));
    #endif
      } else if (trigConfig->type == TRIGGERTYPE_SETPOINTDELAY) {
        byte optValues[] = {0, 2, 4, 5, 6, 7};
        memcpy(values, optValues, sizeof(optValues));
      }
      return values[index];
    }
    char* getItem(byte index, char *retString) {
      menuPROGMEM::getItem(index, retString);
      byte option = getItemValue(index);
      if (option == 0) {
        strcat_P(retString, (char*)pgm_read_word(&(TITLE_TRIGGERTYPE[trigConfig->type])));
      } else if (option == 1) {
        retString[7] += trigConfig->index;        
      } else if (option == 2) {
        strcat_P(retString, (char*)pgm_read_word(&(TITLE_VS[trigConfig->index])));
      } else if (option == 4) {
        strcat_P(retString, trigConfig->activeLow ? PSTR("Low") : PSTR("High"));
      } else if (option == 7) {
        char numText[4];
        strcat(retString, itoa(trigConfig->releaseHysteresis, numText, 10));
        strcat(retString, "s");
      }
      return retString;
    }
};

void cfgTrigger(byte triggerIndex) {
  struct TriggerConfiguration trigConfig;
  loadTriggerConfiguration(triggerIndex, &trigConfig);
  
  struct TriggerConfiguration origConfig = trigConfig;
  menuTriggerConfig triggerMenu(3, &trigConfig);
  
  while(1) {
    byte lastOption = scrollMenu("Triggers", &triggerMenu);
    if (lastOption == 0) {
      byte origType = trigConfig.type;
      trigConfig.type = menuTriggerType(trigConfig.type);
      if (trigConfig.type != origType)
        trigConfig.index = 0;
    }
    #ifdef DIGITAL_INPUTS
      else if (lastOption == 1)
        trigConfig.index = menuSelectDigitalInput(trigConfig.index);
    #endif
    else if (lastOption == 2)
      trigConfig.index = menuSelectVessel("Select Vessel", trigConfig.index, 0);
    else if (lastOption == 3)
      trigConfig.threshold = getValue_P(PSTR("Trigger Threshold"), trigConfig.threshold, 1000, 9999999, VOLUNIT);
    else if (lastOption == 4) 
      trigConfig.activeLow = ~trigConfig.activeLow;
    else if (lastOption == 5)
      trigConfig.profileFilter = menuSelectOutputProfiles("Profile Filter", trigConfig.profileFilter);
    else if (lastOption == 6)
      trigConfig.disableMask = menuSelectOutputs("Disabled Output", trigConfig.disableMask, 0);
    else if (lastOption == 7)
      trigConfig.releaseHysteresis = getValue_P(PSTR("Release Delay"), trigConfig.releaseHysteresis, 1, 255, PSTR("s"));
    else {
      if (triggerConfigurationDidChange(&trigConfig, &origConfig) && confirmSave()) {
        saveTriggerConfiguration(triggerIndex, &trigConfig);
        loadTriggerInstance(triggerIndex);
      }
      return;
    }
  }
}

boolean triggerConfigurationDidChange(struct TriggerConfiguration *a, struct TriggerConfiguration *b) {
  if (a->type == b->type 
      && a->index == b->index 
      && a->activeLow == b->activeLow 
      && a->threshold == b->threshold
      && a->profileFilter == b->profileFilter
      && a->disableMask == b->disableMask
      && a->releaseHysteresis == b->releaseHysteresis
    )
    return 0;
  return 1;
}

class menuTriggerTypes : public menu {
  private:
    byte currentSelection;
    
  public:
    menuTriggerTypes(byte pSize, byte cSelect) : menu (pSize) {
      currentSelection = cSelect;
    }
    byte getItemCount(void) { return TRIGGERTYPE_COUNT; }
    char* getItem(byte index, char *retString) {
      retString[0] = '\0';
      if (currentSelection == index)
        strcat(retString, "*");
      strcat_P(retString, (char*)pgm_read_word(&(TITLE_TRIGGERTYPE[index])));
      return retString;
    }
};

byte menuTriggerType (byte type) {
  menuTriggerTypes triggerMenu(3, type);
  byte newType = scrollMenu("Trigger Type", &triggerMenu);
  if (newType == 255)
    return type;
  return newType;
}

#ifdef RGBIO8_ENABLE
  class menuRGBIOConfig : public menu {
    private:
      enum connectionStatusIndex *connectStatus;
      
    public:
      menuRGBIOConfig(byte pSize, enum connectionStatusIndex *c) : menu(pSize) {
        connectStatus = c;
      }
      byte getItemCount(void) { return RGBIO8_MAX_BOARDS + RGBIO8_MAX_OUTPUT_RECIPES + 1; }
      char* getItem(byte index, char *retString) {
        if (index < RGBIO8_MAX_BOARDS)
          return getItemBoard(index, retString);
        if (index < RGBIO8_MAX_BOARDS + RGBIO8_MAX_OUTPUT_RECIPES)
          return getItemRecipe(index - RGBIO8_MAX_BOARDS, retString);
        return strcpy_P(retString, EXIT);
      }
      char* getItemBoard(byte index, char *retString) {
        strcpy_P(retString, PSTR("Board 1: "));
        retString[6] += index;
        strcat_P(retString, (char*)pgm_read_word(&(CONNECTIONSTATETITLES[connectStatus[index]])));
        return retString;
      }
      char* getItemRecipe(byte index, char *retString) {
        strcpy_P(retString, PSTR("Color Recipe 1"));
        retString[13] += index;
        return retString;
      }
  };

  void menuRGBIO() {
    while(1) {
      enum connectionStatusIndex connectStatus[RGBIO8_MAX_BOARDS];
      for (byte i = 0; i < RGBIO8_MAX_BOARDS; i++) {
        byte addr = getRGBIOAddr(i);
        if (addr == RGBIO8_UNASSIGNED)
          connectStatus[i] = CONNECTIONSTATUS_DISABLED;
        else {
          RGBIO8 tempRGBIO(addr);
          byte result = tempRGBIO.getInputs();
          if (result) 
            connectStatus[i] = CONNECTIONSTATUS_CONNECTED;
          else
            connectStatus[i] = CONNECTIONSTATUS_ERROR;
        }
      }              
      menuRGBIOConfig rgbioMenu(3, connectStatus);
      
      byte lastOption = scrollMenu("RGBIO", &rgbioMenu);
      if (lastOption < RGBIO8_MAX_BOARDS)
        menuRGBIOBoard(lastOption);
      else if (lastOption - RGBIO8_MAX_BOARDS < RGBIO8_MAX_OUTPUT_RECIPES)
        menuRGBIORecipe(lastOption - RGBIO8_MAX_BOARDS);
      else
        return;
    }
  }

  class menuRGBIOBoardConfig : public menuPROGMEM {
    private:
      byte *address;
      boolean *idMode;
    public:
      menuRGBIOBoardConfig(byte pSize, byte *a, boolean *id) : menuPROGMEM(pSize, RGBIOBOARDOPTIONS, ARRAY_LENGTH(RGBIOBOARDOPTIONS)) {
        address = a;
        idMode = id;
      }
      byte getItemCount(void) { return (*address == RGBIO8_UNASSIGNED ? 3 : 5); }
      byte getItemValue(byte index) {
        byte values[5] = {0, 2, 3, 4, 5};
        if (*address == RGBIO8_UNASSIGNED) {
          values[1] = 1;
          values[2] = 5;
        }
        return values[index];
      }
      char* getItem(byte index, char *retString) {
        menuPROGMEM::getItem(index, retString);
        byte option = getItemValue(index);
        if (option == 0) {
            if (*address == RGBIO8_UNASSIGNED)
              strcat_P(retString, PSTR("None"));
            else {
              char numText[4];
              strcat(retString, itoa(*address, numText, 10));
            }
        } else if (option == 2)
          strcat_P(retString, (*idMode ? ON : OFF));
        return retString;
      }
  };
  
  void menuRGBIOBoard(byte board) {
    boolean idMode = 0;
    byte addr;
    
    menuRGBIOBoardConfig boardMenu(3, &addr, &idMode);
    char title[] = "RGBIO Board 1";
    title[12] += board;
    while(1) {
      addr = getRGBIOAddr(board);      
      RGBIO8 tempRGBIO(addr);
      if (addr != RGBIO8_UNASSIGNED)
        tempRGBIO.setIdMode(idMode);
      
      byte lastOption = scrollMenu(title, &boardMenu);
      if (lastOption == 0)
        setRGBIOAddr(board, getValue_P(PSTR("RGBIO Address"), addr == RGBIO8_UNASSIGNED ? RGBIO8_START_ADDR + board : addr, 1, 127, PSTR("")));
      else if (lastOption == 1)
        cfgRGBIOAutoAddress(board);
      else if (lastOption == 2)
        idMode = !idMode;
      else if (lastOption == 3)
        menuRGBIOAssignments(board);
      else {
        if (lastOption == 4)
          setRGBIOAddr(board, RGBIO8_UNASSIGNED);
        loadRGBIO8();
        return;
      }
    }
  }
  
  void cfgRGBIOAutoAddress(byte board) {
    RGBIO8 tempRGBIO(RGBIO8_INIT_ADDR);
    
    byte result = 0;
    while (!(result = tempRGBIO.getInputs())) {
      if(!confirmChoice("Click/hold to reset", "RGBIO board then ", "click to activate.", PSTR("Error: Retry?")))
        return;      
    }
    byte newAddr = getValue_P(PSTR("New Address"), RGBIO8_START_ADDR + board, 1, 127, PSTR(""));
    tempRGBIO.setAddress(newAddr);
    unsigned long waitUntil = millis() + 250;
    while (millis() < waitUntil)
      BrewTrollerApplication::getInstance()->update(PRIORITYLEVEL_NORMAL);
    tempRGBIO.restart();
    setRGBIOAddr(board, newAddr);
    loadRGBIO8();
  }

  class menuRGBIOChannels : public menu {
    private:
      byte *assignment;
      
    public:
      menuRGBIOChannels(byte pSize, byte *a) : menu(pSize) {
        assignment = a;
      }
      byte getItemCount(void) { return 9; }
      char* getItem(byte index, char *retString) {
        if (index < 8) {
          strcpy_P(retString, PSTR("1: "));
          retString[0] += index;
          char outName[OUTPUT_FULLNAME_MAXLEN] = "None";
          if (assignment[index] != RGBIO8_UNASSIGNED)
            outputs->getOutputFullName(assignment[index], outName);
          strcat(retString, outName);
        } else
          strcpy_P(retString, EXIT);
        return retString;
      }
  };
  
  void menuRGBIOAssignments(byte board) {
    while(1) {
      byte assignment[8];
      for (byte i = 0; i < 8; i++)
        assignment[i] = getRGBIOAssignment(board, i);

      menuRGBIOChannels assignMenu(3, assignment);
      
      char title[20] = "RGBIO 1 Assignments";
      title[6] += board;
      byte lastOption = scrollMenu(title, &assignMenu);
      if (lastOption < 8)
        menuRGBIOAssignment(board, lastOption);
      else
        return;
    }
  }

  class menuRGBIOChannelConfig : public menuPROGMEM {
    private:
      byte *assignment;
      byte *recipe;
    
    public:
      menuRGBIOChannelConfig(byte pSize, byte *a, byte *r) : menuPROGMEM(pSize, RGBIOCHANNELCONFIGTITLES, ARRAY_LENGTH(RGBIOCHANNELCONFIGTITLES)) {
        assignment = a;
        recipe = r;
      }

      char* getItem(byte index, char *retString) {
        menuPROGMEM::getItem(index, retString);
        if (index == 0 && *assignment != RGBIO8_UNASSIGNED)
          outputs->getOutputFullName(*assignment, retString);
        else if (index == 1)
          retString[8] += *recipe;
        return retString;
      }
  };
  
  void menuRGBIOAssignment(byte board, byte channel) {
    char title[] = "RGBIO 1 Channel 1";
    title[6] += board;
    title[16] += channel;
    byte assignment = getRGBIOAssignment(board, channel);
    byte recipe = getRGBIOAssignmentRecipe(board, channel);
    byte origAssignment = assignment;
    byte origRecipe = recipe;
    
    if (assignment == RGBIO8_UNASSIGNED)
      assignment = menuSelectOutput(title, INDEX_NONE);

    menuRGBIOChannelConfig assignMenu(3, &assignment, &recipe);
    while(1) {
      byte lastOption = (assignment == RGBIO8_UNASSIGNED) ? 2 : scrollMenu(title, &assignMenu);
      if (lastOption == 0)
        assignment = menuSelectOutput(title, assignment);
      else if (lastOption == 1)
        recipe = menuRGBIOSelectRecipe(title, recipe);
      else {
        if (lastOption == 2)
          assignment = RGBIO8_UNASSIGNED;
        if ((assignment != origAssignment || recipe != origRecipe) && confirmSave()) {
          setRGBIOAssignment(board, channel, assignment, recipe);
          loadRGBIO8();
        }
        return;
      }
        
    }
  }
  
  byte menuRGBIOSelectRecipe(char sTitle[], byte currentSelection) {
    menuNumberedItemList recipeMenu(3, currentSelection, RGBIO8_MAX_OUTPUT_RECIPES, PSTR("Color Recipe  "));

    byte lastOption = scrollMenu(sTitle, &recipeMenu);
    if (lastOption == 255)
      return currentSelection;
    return lastOption;
  }

  class menuRGBIORecipeItems : public menuPROGMEM {
    private:
      unsigned int *recipe;
      
    public:
      menuRGBIORecipeItems(byte pSize, unsigned int *r) : menuPROGMEM(pSize, TITLE_RGBMODES, ARRAY_LENGTH(TITLE_RGBMODES)) {
        recipe = r;
      }
      char* getItem(byte index, char *retString) {
        menuPROGMEM::getItem(index, retString);
        if (index < 4) {
            char hexValue[4];
            sprintf(hexValue, "%03X", recipe[index]);
            strcat(retString, hexValue);
        }
        return retString;
      }
  };

  void menuRGBIORecipe(byte recipeIndex) {
    unsigned int recipe[4], origRecipe[4];
    getRGBIORecipe(recipeIndex, recipe);
    memcpy(&origRecipe, &recipe, sizeof(recipe));
    
    menuRGBIORecipeItems recipeMenu(3, recipe);
    while (1) {
      char title[] = "Color Recipe x";
      title[13] = '1' + recipeIndex;
      byte recipeMode = scrollMenu(title, &recipeMenu);
      if (recipeMode < 4)
        recipe[recipeMode] = getHexValue("RGB Value", recipe[recipeMode], 3);
      else {
        if (memcmp(recipe, origRecipe, 8) != 0) {
          if(confirmSave()) {
            setRGBIORecipe(recipeIndex, recipe);
            loadRGBIO8();
          }
        }
        return; 
      }
    }
  }
#endif

#endif
