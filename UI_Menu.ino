#ifndef NOUI

void editProgramMenu() {
  char itemDesc[20];
  menu progMenu(3, 20);
  for (byte i = 0; i < 20; i++) {
    getProgName(i, itemDesc);
    progMenu.setItem(itemDesc, i);
  }
  byte profile = scrollMenu("Edit Program", &progMenu);
  if (profile < 20) {
    progMenu.getSelectedRow(itemDesc);
    getString(PSTR("Program Name:"), itemDesc, 19);
    setProgName(profile, itemDesc);
    editProgram(profile);
  }
}

void startProgramMenu() {
  char progName[20];
  menu progMenu(3, 20);
  for (byte i = 0; i < 20; i++) {
    getProgName(i, progName);
    progMenu.setItem(progName, i);
  }
  byte profile = scrollMenu("Start Program", &progMenu);
  progMenu.getSelectedRow(progName);
  if (profile < 20) {
    byte lastOption = 0; 
    menu startMenu(3, 5);
    while(1) {
      unsigned long spargeVol = calcSpargeVol(profile);
      unsigned long mashVol = calcStrikeVol(profile);
      unsigned long grainVol = calcGrainVolume(profile);
      unsigned long preboilVol = calcPreboilVol(profile);
      if (spargeVol > getCapacity(VS_HLT)) warnHLT(spargeVol);
      if (mashVol + grainVol > getCapacity(VS_MASH)) warnMash(mashVol, grainVol);
      if (preboilVol > getCapacity(VS_KETTLE)) warnBoil(preboilVol);
      startMenu.setItem_P(PSTR("Edit Program"), 0);
      
      startMenu.setItem_P(PSTR("Grain Temp:"), 1);
      startMenu.appendItem(itoa(getGrainTemp() / SETPOINT_DIV, buf, 10), 1);
      startMenu.appendItem_P(TUNIT, 1);
      
      startMenu.setItem_P(PSTR("Start"), 2);
      startMenu.setItem_P(PSTR("Delay Start"), 3);
      startMenu.setItem_P(EXIT, 255);

      lastOption = scrollMenu(progName, &startMenu);
      if (lastOption == 0) editProgram(profile);
      else if (lastOption == 1) setGrainTemp(getValue_P(PSTR("Grain Temp"), getGrainTemp(), SETPOINT_DIV, 255, TUNIT)); 
      else if (lastOption == 2 || lastOption == 3) {
        if (zoneIsActive(ZONE_MASH))
          infoBox("Cannot start program", "while mash zone is", "active.", CONTINUE);
        else {
          if (lastOption == 3) {
            //Delay Start
            setDelayMins(getTimerValue(PSTR("Delay Start"), getDelayMins(), 23));
          }
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

void editProgram(byte pgm) {
  menu progMenu(3, 12);

  while (1) {
    
    progMenu.setItem_P(PSTR("Batch Vol:"), 0);
    vftoa(getProgBatchVol(pgm), buf, 1000, 1);
    truncFloat(buf, 5);
    progMenu.appendItem(buf, 0);
    progMenu.appendItem_P(VOLUNIT, 0);

    progMenu.setItem_P(PSTR("Grain Wt:"), 1);
    vftoa(getProgGrain(pgm), buf, 1000, 1);
    truncFloat(buf, 7);
    progMenu.appendItem(buf, 1);
    progMenu.appendItem_P(WTUNIT, 1);

    
    progMenu.setItem_P(PSTR("Boil Length:"), 2);
    progMenu.appendItem(itoa(getProgBoil(pgm), buf, 10), 2);
    progMenu.appendItem_P(PSTR(" min"), 2);
    
    progMenu.setItem_P(PSTR("Mash Ratio:"), 3);
    unsigned int mashRatio = getProgRatio(pgm);
    if (mashRatio) {
      vftoa(mashRatio, buf, 100, 1);
      truncFloat(buf, 4);
      progMenu.appendItem(buf, 3);
      progMenu.appendItem_P(PSTR(":1"), 3);
    }
    else {
      progMenu.appendItem_P(PSTR("NoSparge"), 3);
    }
    
    progMenu.setItem_P( PSTR("HLT Temp:"), 4);
    vftoa(getProgHLT(pgm) * SETPOINT_MULT, buf, 100, 1);
    truncFloat(buf, 4);
    progMenu.appendItem(buf, 4);
    progMenu.appendItem_P(TUNIT, 4);
    
    progMenu.setItem_P(PSTR("Sparge Temp:"), 5);
    vftoa(getProgSparge(pgm) * SETPOINT_MULT, buf, 100, 1);
    truncFloat(buf, 4);
    progMenu.appendItem(buf, 5);
    progMenu.appendItem_P(TUNIT, 5);
    
    progMenu.setItem_P(PSTR("Pitch Temp:"), 6);
    vftoa(getProgPitch(pgm) * SETPOINT_MULT, buf, 100, 1);
    truncFloat(buf, 4);
    progMenu.appendItem(buf, 6);
    progMenu.appendItem_P(TUNIT, 6);

    progMenu.setItem_P(PSTR("Mash Schedule"), 7);

    progMenu.setItem_P(PSTR("Heat Strike In:"), 8);
    byte MLHeatSrc = getProgMLHeatSrc(pgm);
    if (MLHeatSrc == VS_HLT) progMenu.appendItem_P(PSTR("HLT"), 8);
    else if (MLHeatSrc == VS_MASH) progMenu.appendItem_P(PSTR("MASH"), 8);
    else progMenu.appendItem_P(PSTR("UNKWN"), 8);

    progMenu.setItem_P(BOILADDS, 9);
    progMenu.setItem_P(PSTR("Program Calcs"), 10);
    progMenu.setItem_P(EXIT, 255);

    byte lastOption = scrollMenu("Program Parameters", &progMenu);
    
    if (lastOption == 0) setProgBatchVol(pgm, getValue_P(PSTR("Batch Volume"), getProgBatchVol(pgm), 1000, 9999999, VOLUNIT));
    else if (lastOption == 1) setProgGrain(pgm, getValue_P(PSTR("Grain Weight"), getProgGrain(pgm), 1000, 9999999, WTUNIT));
    else if (lastOption == 2) setProgBoil(pgm, getTimerValue(PSTR("Boil Length"), getProgBoil(pgm), 2));
    else if (lastOption == 3) { 
      #ifdef USEMETRIC
        setProgRatio(pgm, getValue_P(PSTR("Mash Ratio"), getProgRatio(pgm), 100, 999, PSTR(" l/kg"))); 
      #else
        setProgRatio(pgm, getValue_P(PSTR("Mash Ratio"), getProgRatio(pgm), 100, 999, PSTR(" qts/lb")));
      #endif
    }
    else if (lastOption == 4) setProgHLT(pgm, getValue_P(PSTR("HLT Setpoint"), getProgHLT(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 5) setProgSparge(pgm, getValue_P(PSTR("Sparge Temp"), getProgSparge(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 6) setProgPitch(pgm, getValue_P(PSTR("Pitch Temp"), getProgPitch(pgm), SETPOINT_DIV, 255, TUNIT));
    else if (lastOption == 7) editMashSchedule(pgm);
    else if (lastOption == 8) setProgMLHeatSrc(pgm, MLHeatSrcMenu(getProgMLHeatSrc(pgm)));
    else if (lastOption == 9) setProgAdds(pgm, editHopSchedule(getProgAdds(pgm)));
    else if (lastOption == 10) showProgCalcs(pgm);
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

void showProgCalcs(byte pgm) {
  menu calcsMenu(3, 6);
  unsigned long value;
  char valtxt[8];

  calcsMenu.setItem_P(PSTR("Strike Temp:"), 0);
  value = calcStrikeTemp(pgm);
  vftoa(value * SETPOINT_MULT, buf, 100, 1);
  truncFloat(buf, 3);
  calcsMenu.appendItem(buf, 0);
  calcsMenu.appendItem_P(TUNIT, 0);
  
  calcsMenu.setItem_P(PSTR("Strike Vol:"), 1);
  value = calcStrikeVol(pgm);
  vftoa(value, buf, 1000, 1);
  truncFloat(buf, 4);
  calcsMenu.appendItem(buf, 1);
  calcsMenu.appendItem_P(VOLUNIT, 1);
  
  calcsMenu.setItem_P(PSTR("Sparge Vol:"), 2);
  value = calcSpargeVol(pgm);
  vftoa(value, buf, 1000, 1);
  truncFloat(buf, 4);
  calcsMenu.appendItem(buf, 2);
  calcsMenu.appendItem_P(VOLUNIT, 2);

  calcsMenu.setItem_P(PSTR("Preboil Vol:"), 3);
  value = calcPreboilVol(pgm);
  vftoa(value, buf, 1000, 1);
  truncFloat(buf, 4);
  calcsMenu.appendItem(buf, 3);
  calcsMenu.appendItem_P(VOLUNIT, 3);

  calcsMenu.setItem_P(PSTR("Grain Vol:"), 4);
  value = calcGrainVolume(pgm);
  vftoa(value, buf, 1000, 1);
  truncFloat(buf, 4);
  calcsMenu.appendItem(buf, 4);
  calcsMenu.appendItem_P(VOLUNIT, 4);

  calcsMenu.setItem_P(PSTR("Grain Loss:"), 5);
  value = calcGrainLoss(pgm);
  vftoa(value, buf, 1000, 1);
  truncFloat(buf, 4);
  calcsMenu.appendItem(buf, 5);
  calcsMenu.appendItem_P(VOLUNIT, 5);
  
  scrollMenu("Program Calcs", &calcsMenu);
}


#define OPT_SETMINS 0
#define OPT_SETTEMP 1

//Note: Menu values represent two 4-bit values
//High-nibble = mash step: MASH_DOUGHIN-MASH_MASHOUT
//Low-nibble = menu item: OPT_XXXXXXXX (see #defines above)
void editMashSchedule(byte pgm) {
  menu mashMenu(3, 13);
  while (1) {

    for (byte i = 0; i < MASHSTEP_COUNT; i++) {  
      mashMenu.setItem_P((char*)pgm_read_word(&(TITLE_MASHSTEP[i])), i << 4 | OPT_SETMINS);
      mashMenu.setItem_P((char*)pgm_read_word(&(TITLE_MASHSTEP[i])), i << 4 | OPT_SETTEMP);
      
      mashMenu.appendItem(itoa(getProgMashMins(pgm, i), buf, 10), i << 4 | OPT_SETMINS);
      mashMenu.appendItem(" min", i << 4 | OPT_SETMINS);

      vftoa(getProgMashTemp(pgm, i) * SETPOINT_MULT, buf, 100, 1);
      truncFloat(buf, 4);
      mashMenu.appendItem(buf, i << 4 | OPT_SETTEMP);
      mashMenu.appendItem_P(TUNIT, i << 4 | OPT_SETTEMP);
    }
    mashMenu.setItem_P(EXIT, 255);
    byte lastOption = scrollMenu("Mash Schedule", &mashMenu);
    byte mashstep = lastOption>>4;
    
    if ((lastOption & B00001111) == OPT_SETMINS)
      setProgMashMins(pgm, mashstep, getTimerValue((char*)pgm_read_word(&(TITLE_MASHSTEP[mashstep])), getProgMashMins(pgm, mashstep), 1));
    else if ((lastOption & B00001111) == OPT_SETTEMP)
      setProgMashTemp(pgm, mashstep, getValue_P((char*)pgm_read_word(&(TITLE_MASHSTEP[mashstep])), getProgMashTemp(pgm, mashstep), SETPOINT_DIV, 255, TUNIT));
    else return;
  }
}

unsigned int editHopSchedule (unsigned int sched) {
  unsigned int retVal = sched;
  menu hopMenu(3, 13);
  
  while (1) {
    if (retVal & 1) hopMenu.setItem_P(PSTR("At Boil: On"), 0); else hopMenu.setItem_P(PSTR("At Boil: Off"), 0);
    for (byte i = 0; i < 10; i++) {
      hopMenu.setItem(itoa(hoptimes[i], buf, 10), i + 1);
      if (i == 0) hopMenu.appendItem_P(PSTR(" Min: "), i + 1);
      else if (i < 9) hopMenu.appendItem_P(PSTR("  Min: "), i + 1);
      else hopMenu.appendItem_P(PSTR("   Min: "), i + 1);
      if (retVal & (1<<(i + 1))) hopMenu.appendItem_P(PSTR("On"), i + 1); else hopMenu.appendItem_P(PSTR("Off"), i + 1);
    }
    if (retVal & 2048) hopMenu.setItem_P(PSTR("0   Min: On"), 11); else hopMenu.setItem_P(PSTR("0   Min: Off"), 11);
    hopMenu.setItem_P(EXIT, 12);

    byte lastOption = scrollMenu("Boil Additions", &hopMenu);
    if (lastOption < 12) retVal = retVal ^ (1 << lastOption);
    else if (lastOption == 12) return retVal;
    else return sched;
  }
}

byte MLHeatSrcMenu(byte MLHeatSrc) {
  menu mlHeatMenu(3, 2);
  mlHeatMenu.setItem_P(HLTDESC, VS_HLT);
  mlHeatMenu.setItem_P(MASHDESC, VS_MASH);
  mlHeatMenu.setSelectedByValue(MLHeatSrc);
  byte lastOption = scrollMenu("Heat Strike In:", &mlHeatMenu);
  if (lastOption > 1) return MLHeatSrc;
  else return lastOption;
}

void warnHLT(unsigned long spargeVol) {
  char line2[21] = "Sparge Vol:";
  vftoa(spargeVol, buf, 1000, 1);
  truncFloat(buf, 5);
  strcat(line2, buf);
  strcat_P(line2, VOLUNIT);

  infoBox("HLT Capacity Issue", line2, "", CONTINUE);
}


void warnMash(unsigned long mashVol, unsigned long grainVol) {
  char line2[21] = "Strike Vol:";
  vftoa(mashVol, buf, 1000, 1);
  truncFloat(buf, 5);
  strcat(line2, buf);
  strcat_P(line2, VOLUNIT);

  char line3[21] = "Grain Vol:";
  vftoa(grainVol, buf, 1000, 1);
  truncFloat(buf, 5);
  strcat(line3, buf);
  strcat_P(line3, VOLUNIT);

  infoBox("Mash Capacity Issue", line2, line3, CONTINUE);
}

void warnBoil(unsigned long preboilVol) {
  char line2[21] = "Preboil Vol:";
  vftoa(preboilVol, buf, 1000, 1);
  truncFloat(buf, 5);
  strcat(line2, buf);
  strcat_P(line2, VOLUNIT);

  infoBox("Boil Capacity Issue", line2, "", CONTINUE);
}


//*****************************************************************************************************************************
// System Setup Menus
//*****************************************************************************************************************************
void menuSetup() {
  menu setupMenu(3, 9);
  setupMenu.setItem_P(PSTR("System Settings"), 0);
  setupMenu.setItem_P(PSTR("Temperature Sensors"), 1);
  setupMenu.setItem_P(PSTR("Outputs"), 2);
  setupMenu.setItem_P(PSTR("Volume/Capacity"), 3);
  setupMenu.setItem_P(INIT_EEPROM, 4);
  #ifdef UI_DISPLAY_SETUP
    setupMenu.setItem_P(PSTR("Display"), 5);
  #endif
  #ifdef RGBIO8_ENABLE
    setupMenu.setItem_P(PSTR("RGB Setup"), 6);
  #endif  
  #ifdef DIGITAL_INPUTS
    setupMenu.setItem_P(PSTR("Triggers"), 7);
  #endif
  setupMenu.setItem_P(EXIT, 255);
  
  while(1) {
    byte lastOption = scrollMenu("System Setup", &setupMenu);
    if (lastOption == 0)
      menuSystemSettings();
    else if (lastOption == 1)
      assignSensor();
    else if (lastOption == 2)
      menuOutputs();
    else if (lastOption == 3)
      menuVolume();
    else if (lastOption == 4) {
      if (confirmChoice("Reset Configuration?", "", "", INIT_EEPROM))
        UIinitEEPROM();
    }
    #ifdef UI_DISPLAY_SETUP
      else if (lastOption == 5)
        adjustLCD();
    #endif
    #ifdef RGBIO8_ENABLE
      else if (lastOption == 6) {
        menuRGBIO();
      }
    #endif  
    #ifdef DIGITAL_INPUTS
      else if (lastOption == 7)
        cfgTriggers();
    #endif
    else return;
  }
}

byte menuSelectTempSensor(char sTitle[]) {
  menu tsMenu(1, NUM_TS + 1);
  for (byte i = 0; i < NUM_TS; i++)
    tsMenu.setItem_P((char*)pgm_read_word(&(TITLE_TS[i])), i);
  tsMenu.setItem_P(EXIT, 255);
  return scrollMenu(sTitle, &tsMenu);
}

void assignSensor() {
  menu tsMenu(1, NUM_TS + 1);
  for (byte i = 0; i < NUM_TS; i++)
    tsMenu.setItem_P((char*)pgm_read_word(&(TITLE_TS[i])), i);
  tsMenu.setItem_P(EXIT, 255);
  
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
    } else encValue = Encoder.change();
    
    if (encValue >= 0) {
      tsMenu.setSelected(encValue);
      //The user has navigated toward a new temperature probe screen.
      LCD.clear();
      LCD.print_P(0, 0, PSTR("Assign Temp Sensor"));
      LCD.center(1, 0, tsMenu.getSelectedRow(buf), 20);
      for (byte i=0; i<8; i++) LCD.lPad(2,i*2+2,itoa(tSensor[tsMenu.getValue()][i], buf, 16), 2, '0');
    }
    displayAssignSensorTemp(tsMenu.getValue()); //Update each loop

    if (Encoder.cancel()) return;
    else if (Encoder.ok()) {
      encValue = Encoder.getCount();
      //Pop-Up Menu
      menu tsOpMenu(3, 5);
      tsOpMenu.setItem_P(PSTR("Scan Bus"), 0);
      tsOpMenu.setItem_P(PSTR("Delete Address"), 1);
      tsOpMenu.setItem_P(PSTR("Clone Address"), 3);
      tsOpMenu.setItem_P(CANCEL, 2);
      tsOpMenu.setItem_P(EXIT, 255);
      byte selected = scrollMenu(tsMenu.getSelectedRow(buf), &tsOpMenu);
      if (selected == 0) {
        if (confirmChoice(tsMenu.getSelectedRow(buf), "Disconnect all other", "temp sensors now", CONTINUE)) {
          byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
          getDSAddr(addr);
          setTSAddr(encValue, addr);
        }
      } else if (selected == 1) {
        byte addr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        setTSAddr(encValue, addr);
      } else if (selected == 3) {
        byte source = menuSelectTempSensor("Clone Sensor");
        if (source < NUM_TS) {
          byte addr[8];
          memcpy(addr, tSensor[source], 8);
          setTSAddr(encValue, addr);
        }
      } else if (selected == 255)
        return;

      Encoder.setMin(0);
      Encoder.setMax(tsMenu.getItemCount() - 1);
      Encoder.setCount(tsMenu.getSelected());
      redraw = 1;
    }
    brewCore();
  }
}

void displayAssignSensorTemp(int sensor) {
  LCD.print_P(3, 10, TUNIT); 
  if (temp[sensor] == BAD_TEMP) {
    LCD.print_P(3, 7, PSTR("---"));
  } else {
    LCD.lPad(3, 7, itoa(temp[sensor] / 100, buf, 10), 3, ' ');
  }
}


void menuSystemSettings() {
    menu settingsMenu(3, 4);
    settingsMenu.setItem_P(PSTR("Boil Temp"), 0);
    settingsMenu.setItem_P(PSTR("Boil Power"), 1);
    settingsMenu.setItem_P(PSTR("Evaporation Rate"), 2);
    settingsMenu.setItem_P(EXIT, 255);

    while (1) {
      byte lastOption = scrollMenu("System Settings", &settingsMenu);
      if (lastOption == 0)
        setBoilTemp(getValue_P(PSTR("Boil Temp"), getBoilTemp(), SETPOINT_DIV, 255, TUNIT));
      else if (lastOption == 1)
        setBoilPwr(getValue_P(PSTR("Boil Power"), boilPwr, 1, 100, PSTR("%")));
      else if (lastOption == 2)
        #ifdef BOIL_OFF_GALLONS
          #ifdef USEMETRIC
            setEvapRate(getValue_P(PSTR("Evaporation Rate"), getEvapRate(), 1, 255, PSTR("l/hr")));
          #else
            setEvapRate(getValue_P(PSTR("Evaporation Rate"), getEvapRate(), 1, 255, PSTR("0.1g/hr")));
          #endif
        #else
           setEvapRate(getValue_P(PSTR("Evaporation Rate"), getEvapRate(), 1, 100, PSTR("%/hr")));
        #endif
      else
        return;
    }
}

void menuOutputs() {
  menu outputMenu(3, 6);
  for (byte i = VS_HLT; i <= VS_KETTLE; i++)
    outputMenu.setItem_P((char*)pgm_read_word(&(TITLE_VS[i])), i);
  outputMenu.setItem_P(PSTR("Output Profiles"), 3);
  #ifdef OUTPUTBANK_MODBUS
    outputMenu.setItem_P(PSTR("RS485 Outputs"), 4);
  #endif
  outputMenu.setItem_P(EXIT, 255);
  
  while (1) {
    byte lastOption = scrollMenu("Output Settings", &outputMenu);
    if (lastOption <= VS_KETTLE)
      menuOutputSettings(lastOption);
    else if (lastOption == 3)
      menuOutputProfiles();
    #ifdef OUTPUTBANK_MODBUS
      else if (lastOption == 4)
        menuMODBUSOutputs();
    #endif
    else
      return;
  }

}

void menuOutputSettings(byte vessel) {
  while(1) {
    menu outputMenu(3, 9);
    outputMenu.setItem_P(PSTR("PWM: "), 0);
    byte pwmPin = getPWMPin(vessel);
    if (pwmPin == PWMPIN_NONE)
      outputMenu.appendItem_P(PSTR("NONE"), 0);
    else {
      outputMenu.appendItem(outputs->getOutputBankName(pwmPin, buf), 0);
      outputMenu.appendItem("-", 0);
      outputMenu.appendItem(outputs->getOutputName(pwmPin, buf), 0);

      outputMenu.setItem_P(PSTR("PWM Period: "), 1);
      vftoa(getPWMPeriod(vessel), buf, 10, 1);
      outputMenu.appendItem(buf, 1);

      outputMenu.setItem_P(PSTR("PWM Res: "), 2);
      outputMenu.appendItem(itoa(getPWMResolution(vessel), buf, 10), 2);

      outputMenu.setItem_P(PSTR("P Gain: "), 3);
      outputMenu.appendItem(itoa(getPIDp(vessel), buf, 10), 3);

      outputMenu.setItem_P(PSTR("I Gain: "), 4);
      outputMenu.appendItem(itoa(getPIDi(vessel), buf, 10), 4);

      outputMenu.setItem_P(PSTR("D Gain: "), 5);
      outputMenu.appendItem(itoa(getPIDd(vessel), buf, 10), 5);
      
      outputMenu.setItem_P(PSTR("PID Limit: "), 6);
      outputMenu.appendItem(itoa(getPIDLimit(vessel), buf, 10), 6);
    }
    outputMenu.setItem_P(HYSTERESIS, 7);
    outputMenu.setItem_P(EXIT, 255);
    
    
    byte lastOption = scrollMenu("Output Settings", &outputMenu);

    if (lastOption == 0)
      setPWMPin(vessel, menuSelectOutput("PWM Pin", getPWMPin(vessel)));
    else if (lastOption == 1)
      setPWMPeriod(vessel, getValue_P(PSTR("PWM Period"), getPWMPeriod(vessel), 10, 255, SEC));
    else if (lastOption == 2)
      setPWMResolution(vessel, getValue_P(PSTR("PWM Resolution"), getPWMResolution(vessel), 1, 255, PSTR("")));
    else if (lastOption == 3)
      setPIDp(vessel, getValue_P(PSTR("P Gain"), getPIDp(vessel), 0, 255, PSTR("")));
    else if (lastOption == 4)
      setPIDi(vessel, getValue_P(PSTR("I Gain"), getPIDi(vessel), 0, 255, PSTR("")));
    else if (lastOption == 5)
      setPIDd(vessel, getValue_P(PSTR("D Gain"), getPIDd(vessel), 0, 255, PSTR("")));
    else if (lastOption == 6)
      setPIDLimit(vessel, getValue_P(PSTR("PID Limit"), getPIDLimit(vessel), 0, 100, PSTR("")));
    else if (lastOption == 7)
      setHysteresis(vessel, getValue_P(HYSTERESIS, hysteresis[vessel], 10, 255, TUNIT));
    else {
      loadPWMOutputs();
      return;
    }
  } 
}

byte menuSelectOutput(char sTitle[], byte currentSelection) {
  menu outputMenu(3, outputs->getCount() + 2);
  for (byte i = 0; i < outputs->getCount(); i++) {
    outputMenu.setItem("", i);
    if (i == currentSelection)
      outputMenu.setItem("*", i);
    outputMenu.appendItem(outputs->getOutputBankName(i, buf), i);
    outputMenu.appendItem("-", i);
    outputMenu.appendItem(outputs->getOutputName(i, buf), i);
  }
  if (currentSelection == PWMPIN_NONE)
    outputMenu.setItem_P(PSTR("*None"), 254);
  else
    outputMenu.setItem_P(PSTR("None"), 254);
  outputMenu.setItem_P(EXIT, 255);

  byte lastOption = scrollMenu(sTitle, &outputMenu);
  if (lastOption == 255)
    return currentSelection;
  else if (lastOption == 254)
    return PWMPIN_NONE;
  return lastOption;
}

unsigned long menuSelectOutputs(char sTitle[], unsigned long currentSelection) {
  unsigned long newSelection = currentSelection;
  while (1) {
    menu outputMenu(3, outputs->getCount() + 2);
    for (byte i = 0; i < outputs->getCount(); i++) {
      if (newSelection & (1 << i)) {
        outputMenu.setItem(outputs->getOutputBankName(i, buf), i);
        outputMenu.appendItem("-", i);
        outputMenu.appendItem(outputs->getOutputName(i, buf), i);
      }
    }
    outputMenu.setItem_P(PSTR("[Add Output]"), 254);
    outputMenu.setItem_P(PSTR("[Test Profile]"), 253);
    outputMenu.setItem_P(EXIT, 255);
  
    byte lastOption = scrollMenu(sTitle, &outputMenu);
    if (lastOption == 254) {
      byte addOutput = menuSelectOutput("Add Output", PWMPIN_NONE);
      if (addOutput < outputs->getCount())
        newSelection |= (1 << addOutput);
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
      newSelection &= ~(1<<lastOption);
  }
}

void menuVolume(){
  menu volMenu(3, 4);
  for (byte i =0; i <= VS_KETTLE; i++)
    volMenu.setItem_P((char*)pgm_read_word(&(TITLE_VS[i])), i);
  volMenu.setItem_P(EXIT, 255);
  while (1) {
    byte lastOption = scrollMenu("Volume", &volMenu);
    if (lastOption == 255)
      return;
    menuVolumeVessel(lastOption);
  }
}

void menuVolumeVessel(byte vessel) {
  menu volMenu(3, 6);
  #ifdef ANALOGINPUTS_GPIO
    volMenu.setItem_P(PSTR("Analog Input"), 0);
  #endif
  volMenu.setItem_P(CAPACITY, 1);
  volMenu.setItem_P(DEADSPACE, 2);
  volMenu.setItem_P(CALIBRATION, 3);
  volMenu.setItem_P(PSTR("Clone Settings"), 4);
  volMenu.setItem_P(EXIT, 255);

  char title[20];
  strcpy_P(title, (char*)pgm_read_word(&(TITLE_VS[vessel])));
  strcat_P(title, PSTR(" Volume"));
  while(1) {
    byte lastOption = scrollMenu(title, &volMenu);
    strcpy_P(title, (char*)pgm_read_word(&(TITLE_VS[vessel])));
    strcat_P(title, PSTR(" "));
    if (lastOption  == 1) {
      strcat_P(title, CAPACITY);
      setCapacity(vessel, getValue(title, getCapacity(vessel), 1000, 9999999, VOLUNIT));
    }
    #ifdef ANALOGINPUTS_GPIO
      else if (lastOption  == 0) {
        strcat_P(title, PSTR("Sensor"));
        setVolumeSensor(vessel, menuSelectAnalogInput(title, vSensor[vessel]));
      } 
    #endif
    else if (lastOption == 2) {
      strcat_P(title, DEADSPACE);
      setVolLoss(vessel, getValue(title, getVolLoss(vessel), 1000, 65535, VOLUNIT));
    } else if (lastOption == 3) {
      strcat_P(title, CALIBRATION);
      volCalibMenu(title, vessel);
    } else if (lastOption == 4) {
      byte source = menuSelectVessel("Clone From:");
      if (source <= VS_KETTLE) {
         setVolumeSensor(vessel, getVolumeSensor(source));
         setCapacity(vessel, getCapacity(source));
         setVolLoss(vessel, getVolLoss(source));
         for (byte i = 0; i < 10; i++)
           setVolCalib(vessel, i, calibVals[source][i], calibVols[source][i]);
      }
    } else
      return;
  } 
}

#ifdef ANALOGINPUTS_GPIO
byte menuSelectAnalogInput(char sTitle[], byte currentValue) {
  menu volMenu(3, ANALOGINPUTS_GPIO_COUNT + 1);
  byte analogInputs[ANALOGINPUTS_GPIO_COUNT] = ANALOGINPUTS_GPIO_PINS;
  char analogTitles[] = ANALOGINPUTS_GPIO_NAMES;
  char* pos = analogTitles;
      
  for (byte i =0; i < ANALOGINPUTS_GPIO_COUNT; i++) {
    volMenu.setItem("", analogInputs[i]);
    if (currentValue == analogInputs[i])
      volMenu.appendItem("*", analogInputs[i]);
    volMenu.appendItem(pos, analogInputs[i]);
    pos += strlen(pos) + 1;
  }
  
  volMenu.setItem("", VOLUMESENSOR_NONE);
  if (currentValue == VOLUMESENSOR_NONE)
    volMenu.appendItem("*", VOLUMESENSOR_NONE);
  volMenu.appendItem_P(PSTR("None"), VOLUMESENSOR_NONE);
  
  return scrollMenu(sTitle, &volMenu);
}
#endif

byte menuSelectVessel(char sTitle[]) {
    menu volMenu(3, 4);
  for (byte i =0; i <= VS_KETTLE; i++)
    volMenu.setItem_P((char*)pgm_read_word(&(TITLE_VS[i])), i);
  volMenu.setItem_P(PSTR("None"), 255);
  return scrollMenu(sTitle, &volMenu);
}

void volCalibMenu(char sTitle[], byte vessel) {
  menu calibMenu(3, 11);    
  while(1) {
    for(byte i = 0; i < 10; i++) {
      if (calibVals[vessel][i] > 0) {
        vftoa(calibVols[vessel][i], buf, 1000, 1);
        truncFloat(buf, 6);
        calibMenu.setItem(buf, i);
        calibMenu.appendItem_P(SPACE, i);
        calibMenu.appendItem_P(VOLUNIT, i);
        calibMenu.appendItem_P(PSTR(" ("), i);
        calibMenu.appendItem(itoa(calibVals[vessel][i], buf, 10), i);
        calibMenu.appendItem_P(PSTR(")"), i);
      } else calibMenu.setItem_P(PSTR("OPEN"), i);
    }
    calibMenu.setItem_P(EXIT, 255);
    byte lastOption = scrollMenu(sTitle, &calibMenu);
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

        setVolCalib(vessel, lastOption, 0, getValue_P(PSTR("Current Volume:"), 0, 1000, 9999999, VOLUNIT)); //Set temporary the value to zero. It will be updated in the next step.
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
  char sTitle[21] ="";
  menu calibMenu(3, 4);
  
  while(1) {
    vftoa(calibVols[vessel][entry], buf, 1000, 1);
    truncFloat(buf, 6);
    strcpy_P(sTitle, PSTR("Calibrate"));
    strcat_P(sTitle, SPACE);
    strcat(sTitle, buf);
    strcat_P(sTitle, SPACE);
    strcat_P(sTitle, VOLUNIT);
      
    unsigned int newSensorValue = GetCalibrationValue(vessel);
    
    calibMenu.setItem_P(PSTR("Update "), 0);
    calibMenu.appendItem(itoa(calibVals[vessel][entry], buf, 10), 0); //Show the currently saved value which can be zero.
    calibMenu.appendItem_P(PSTR(" To "), 0);
    calibMenu.appendItem(itoa(newSensorValue, buf, 10), 0); //Show the value to be saved. So users know what to expect.
    calibMenu.setItem_P(PSTR("Manual Entry"), 1);
    calibMenu.setItem_P(DELETE, 2);
    calibMenu.setItem_P(EXIT, 255);
    
    byte lastOption = scrollMenu(sTitle, &calibMenu);

    if (lastOption == 0) {
      //Update the volume value.
      setVolCalib(vessel, entry, newSensorValue, calibVols[vessel][entry]); 
      return;
    } else if (lastOption == 1) {
      newSensorValue = (unsigned int) getValue_P(PSTR("Manual Volume Entry"), calibVals[vessel][entry], 1, 1023, PSTR(""));
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

void menuOutputProfiles() {
  byte dispOrder[] = {
    OUTPUTPROFILE_ALARM,
    OUTPUTPROFILE_FILLHLT,
    OUTPUTPROFILE_FILLMASH,
    OUTPUTPROFILE_HLTHEAT,
    OUTPUTPROFILE_HLTIDLE,
    OUTPUTPROFILE_HLTPWMACTIVE,
    OUTPUTPROFILE_MASHHEAT,
    OUTPUTPROFILE_MASHIDLE,
    OUTPUTPROFILE_MASHPWMACTIVE,
    OUTPUTPROFILE_ADDGRAIN,
    OUTPUTPROFILE_SPARGEIN,
    OUTPUTPROFILE_SPARGEOUT,
    OUTPUTPROFILE_KETTLEHEAT,
    OUTPUTPROFILE_KETTLEIDLE,
    OUTPUTPROFILE_KETTLEPWMACTIVE,
    OUTPUTPROFILE_HOPADD,
    OUTPUTPROFILE_KETTLELID,
    OUTPUTPROFILE_CHILLH2O,
    OUTPUTPROFILE_CHILLBEER,
    OUTPUTPROFILE_BOILRECIRC,
    OUTPUTPROFILE_DRAIN,
    OUTPUTPROFILE_USER1,
    OUTPUTPROFILE_USER2,
    OUTPUTPROFILE_USER3
  };
  menu outputProfileMenu(3, OUTPUTPROFILE_USERCOUNT + 1);
  for (byte profile = 0; profile < OUTPUTPROFILE_USERCOUNT; profile++)
    outputProfileMenu.setItem_P((char*)pgm_read_word(&(TITLE_VLV[dispOrder[profile]])), dispOrder[profile]);
  outputProfileMenu.setItem_P(EXIT, 255);
  while (1) {
    byte profile = scrollMenu("Output Profiles", &outputProfileMenu);
    if (profile >= OUTPUTPROFILE_USERCOUNT) return;
    else setOutputProfile(profile, menuSelectOutputs(outputProfileMenu.getSelectedRow(buf), outputs->getProfileMask(profile)));
  }
}

#ifdef OUTPUTBANK_MODBUS
const uint8_t ku8MBSuccess                    = 0x00;
const uint8_t ku8MBResponseTimedOut           = 0xE2;

  void menuMODBUSOutputs() {
    while(1) {
      menu boardMenu(3, OUTPUTBANK_MODBUS_MAXBOARDS + 1);
      for (byte i = 0; i < OUTPUTBANK_MODBUS_MAXBOARDS; i++) {
        byte addr = getOutModbusAddr(i);
        OutputBankMODBUS tempMB(addr, getOutModbusReg(i), getOutModbusCoilCount(i));
        
        boardMenu.setItem_P(PSTR("Board "), i);
        boardMenu.appendItem(itoa(i + 1, buf, 10), i);
        if (addr == OUTPUTBANK_MODBUS_ADDRNONE)
          boardMenu.appendItem_P(PSTR(": DISABLED"), i);
        else {
          byte result = tempMB.detect();
          if (result == ku8MBSuccess) 
            boardMenu.appendItem_P(PSTR(": CONNECTED"), i);
          else if (result == ku8MBResponseTimedOut)
            boardMenu.appendItem_P(PSTR(": TIMEOUT"), i);
          else {
            boardMenu.appendItem_P(PSTR(": ERROR "), i);
            boardMenu.appendItem(itoa(result, buf, 16), i);
          }
        }
      }
      boardMenu.setItem_P(PSTR("Exit"), 255);
      
      byte lastOption = scrollMenu("RS485 Outputs", &boardMenu);
      if (lastOption < OUTPUTBANK_MODBUS_MAXBOARDS) menuMODBUSOutputBoard(lastOption);
      else return;
    }
  }
  
  void menuMODBUSOutputBoard(byte board) {
    while(1) {
      OutputBankMODBUS tempMB(getOutModbusAddr(board), getOutModbusReg(board), getOutModbusCoilCount(board));
      menu boardMenu(3, 7);
      boardMenu.setItem_P(PSTR("Address: "), 0);
      byte addr = getOutModbusAddr(board);
      if (addr != OUTPUTBANK_MODBUS_ADDRNONE)
        boardMenu.appendItem(itoa(addr, buf, 10), 0);
      else
        boardMenu.appendItem_P(PSTR("N/A"), 0);
      
      boardMenu.setItem_P(PSTR("Register: "), 1);
      boardMenu.appendItem(itoa(getOutModbusReg(board), buf, 10), 1);
      boardMenu.setItem_P(PSTR("Count: "), 2);
      boardMenu.appendItem(itoa(getOutModbusCoilCount(board), buf, 10), 2);
      
      if (addr == OUTPUTBANK_MODBUS_ADDRNONE)
        boardMenu.setItem_P(PSTR("Auto Assign"), 3);
      else {
        boardMenu.setItem_P(PSTR("ID Mode: "), 4);
        boardMenu.appendItem_P((tempMB.getIDMode()) ? PSTR("On") : PSTR("Off"), 4);

        boardMenu.setItem_P(DELETE, 5);
      }
      boardMenu.setItem_P(PSTR("Exit"), 255);
      
      char title[] = "RS485 Output Board  ";
      title[19] = '0' + board;
      byte lastOption = scrollMenu(title, &boardMenu);
      if (lastOption == 0) {
        byte addr = getOutModbusAddr(board);
        setOutModbusAddr(board, getValue_P(PSTR("RS485 Relay Address"), addr == OUTPUTBANK_MODBUS_ADDRNONE ? OUTPUTBANK_MODBUS_BASEADDR + board : addr, 1, 255, PSTR("")));
      } else if (lastOption == 1)
        setOutModbusReg(board, getValue_P(PSTR("Coil Register"), getOutModbusReg(board), 1, 65536, PSTR("")));
      else if (lastOption == 2)
        setOutModbusCoilCount(board, getValue_P(PSTR("Coil Count"), getOutModbusCoilCount(board), 1, 32, PSTR("")));
      else if (lastOption == 3)
        cfgMODBUSOutputAssign(board);
      else if (lastOption == 4)
        tempMB.setIDMode((tempMB.getIDMode()) ^ 1);
      else {
        if (lastOption == 5)
          setOutModbusDefaults(board);
        loadOutputSystem();
        return;
      }
    }
  }
  
  void cfgMODBUSOutputAssign(byte board) {
    OutputBankMODBUS tempMB(OUTPUTBANK_MODBUS_ADDRINIT, getOutModbusReg(board), getOutModbusCoilCount(board));
    
    byte result = 1;
    while (result = tempMB.detect()) {
      LCD.clear();
      LCD.print_P(0, 0, PSTR("Click/hold to reset"));
      LCD.print_P(1, 0, PSTR("output board then"));
      LCD.print_P(2, 0, PSTR("click to activate."));
      menu choiceMenu(1, 2);
      if (result == ku8MBResponseTimedOut) {
        choiceMenu.setItem_P(PSTR("Timeout"), 0);
      } else {
        choiceMenu.setItem_P(PSTR("Error "), 0);
        choiceMenu.appendItem(itoa(result, buf, 16), 0);
      }
      choiceMenu.appendItem_P(PSTR(": Retry?"), 0);
      choiceMenu.setItem_P(PSTR("Abort"), 1);
      if(getChoice(&choiceMenu, 3))
        return;      
    }
    byte newAddr = getValue_P(PSTR("New Address"), OUTPUTBANK_MODBUS_BASEADDR + board, 1, 254, PSTR(""));
    if (tempMB.setAddr(newAddr)) {
      LCD.clear();
      LCD.print_P(1, 1, PSTR("Update Failed"));
      LCD.print_P(2, 4, PSTR("> Continue <"));
      while (!Encoder.ok()) brewCore();
    } else {
      setOutModbusAddr(board, newAddr);
    }
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
        LCD.lPad(1, 13, itoa(bright, buf, 10), 3, ' ');
        LCD.lPad(2, 13, itoa(contrast, buf, 10), 3, ' ');
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
      brewCore();
    }
  }
#endif //#ifdef UI_DISPLAY_SETUP

#ifdef DIGITAL_INPUTS
  void cfgTriggers() {
    menu triggerMenu(3, 6);
   
    while(1) {
      triggerMenu.setItem_P(PSTR("E-Stop: "), 0);
      triggerMenu.setItem_P(PSTR("Sparge Max: "), 1);
      triggerMenu.setItem_P(PSTR("HLT Min: "), 2);
      triggerMenu.setItem_P(PSTR("Mash Min: "), 3);
      triggerMenu.setItem_P(PSTR("Kettle Min: "), 4);
      triggerMenu.setItem_P(PSTR("Exit"), 255);
      for (byte i = 0; i < 5; i++) {
        if (getTriggerPin(i)) triggerMenu.appendItem(itoa(getTriggerPin(i), buf, 10), i);
        else triggerMenu.appendItem_P(PSTR("None"), i);
      }
      
      byte lastOption = scrollMenu("Trigger Assignment", &triggerMenu);
      if (lastOption < 5) setTriggerPin(lastOption, getValue_P(PSTR("Input Pin (0=None):"), getTriggerPin(lastOption), 1, DIGIN_COUNT, PSTR("")));
      else return;
    }
  }
#endif

#ifdef RGBIO8_ENABLE
  void menuRGBIO() {
    while(1) {
      menu rgbioMenu(3, RGBIO8_MAX_BOARDS + RGBIO8_MAX_OUTPUT_RECIPES + 1);
      for (byte i = 0; i < RGBIO8_MAX_BOARDS; i++) {
        byte addr = getRGBIOAddr(i);
        rgbioMenu.setItem_P(PSTR("Board "), i);
        rgbioMenu.appendItem(itoa(i + 1, buf, 10), i);
        if (addr == RGBIO8_UNASSIGNED)
          rgbioMenu.appendItem_P(PSTR(": DISABLED"), i);
        else {
          RGBIO8 tempRGBIO(addr);
          byte result = tempRGBIO.getInputs();
          if (result) 
            rgbioMenu.appendItem_P(PSTR(": CONNECTED"), i);
          else
            rgbioMenu.appendItem_P(PSTR(": ERROR"), i);
        }
      }
      for (byte i = 0; i < RGBIO8_MAX_OUTPUT_RECIPES; i++) {
        rgbioMenu.setItem_P(PSTR("Color Recipe "), RGBIO8_MAX_BOARDS + i);
        rgbioMenu.appendItem(itoa(i + 1, buf, 10), RGBIO8_MAX_BOARDS + i);
      }
      rgbioMenu.setItem_P(PSTR("Exit"), 255);
      
      byte lastOption = scrollMenu("RGBIO", &rgbioMenu);
      if (lastOption < RGBIO8_MAX_BOARDS)
        menuRGBIOBoard(lastOption);
      else if (lastOption - RGBIO8_MAX_BOARDS < RGBIO8_MAX_OUTPUT_RECIPES)
        menuRGBIORecipe(lastOption - RGBIO8_MAX_BOARDS);
      else
        return;
    }
  }
  
  void menuRGBIOBoard(byte board) {
    boolean idMode = 0;
    while(1) {
      byte addr = getRGBIOAddr(board);
      RGBIO8 tempRGBIO(addr);
      menu boardMenu(3, 6);
      boardMenu.setItem_P(PSTR("Address: "), 0);
      
      if (addr != RGBIO8_UNASSIGNED) {
        tempRGBIO.setIdMode(idMode);
        boardMenu.appendItem(itoa(addr, buf, 10), 0);
        
        boardMenu.setItem_P(PSTR("ID Mode: "), 2);
        boardMenu.appendItem_P(idMode ? PSTR("On") : PSTR("Off"), 2);
        
        boardMenu.setItem_P(PSTR("Assignments"), 3);
        boardMenu.setItem_P(DELETE, 4);
      } else {
        boardMenu.appendItem_P(PSTR("N/A"), 0);
        boardMenu.setItem_P(PSTR("Auto Address"), 1);
      }
      boardMenu.setItem_P(PSTR("Exit"), 255);
      
      char title[] = "RGBIO Board x";
      title[12] = '1' + board;
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
      brewCore();
    tempRGBIO.restart();
    setRGBIOAddr(board, newAddr);
    loadRGBIO8();
  }
  
  void menuRGBIOAssignments(byte board) {
    while(1) {
      menu assignMenu(3, 9);
      for (byte i = 0; i < 8; i++) {
        assignMenu.setItem(itoa(i + 1, buf, 10), i);
        assignMenu.appendItem(": ", i);
        byte assignment = getRGBIOAssignment(board, i);
        if (assignment == RGBIO8_UNASSIGNED)
          assignMenu.appendItem_P(PSTR("None"), i);
        else {
          assignMenu.appendItem(outputs->getOutputBankName(assignment, buf), i);
          assignMenu.appendItem("-", i);
          assignMenu.appendItem(outputs->getOutputName(assignment, buf), i);
        }
      }
      assignMenu.setItem_P(EXIT, 255);
      
      char title[20] = "RGBIO x Assignments";
      title[6] = '1' + board;
      byte lastOption = scrollMenu(title, &assignMenu);
      if (lastOption < 8)
        menuRGBIOAssignment(board, lastOption);
      else
        return;
    }
  }
  
  void menuRGBIOAssignment(byte board, byte channel) {
    byte assignment = getRGBIOAssignment(board, channel);
    byte recipe = getRGBIOAssignmentRecipe(board, channel);
    byte origAssignment = assignment;
    byte origRecipe = recipe;
    
    boolean changed = 0;
    while(1) {
      menu assignMenu(3, 4);
      
      if (assignment == RGBIO8_UNASSIGNED)
        assignMenu.setItem_P(PSTR("No Assignment"), 0);
      else {
        assignMenu.setItem(outputs->getOutputBankName(assignment, buf), 0);
        assignMenu.appendItem("-", 0);
        assignMenu.appendItem(outputs->getOutputName(assignment, buf), 0);
        
        assignMenu.setItem_P(PSTR("Recipe: "), 1);
        assignMenu.appendItem(itoa(recipe + 1, buf, 10), 1);
        
        assignMenu.setItem_P(DELETE, 2);
      }
      assignMenu.setItem_P(EXIT, 255);
      
      char title[] = "RGBIO x Channel y";
      title[6] = '1' + board;
      title[16] = '1' + channel;
      byte lastOption = scrollMenu(title, &assignMenu);
      if (lastOption == 0)
        assignment = menuSelectOutput(title, assignment == RGBIO8_UNASSIGNED ? PWMPIN_NONE : assignment);
      else if (lastOption == 1)
        recipe = menuRGBIOSelectRecipe(title, recipe);
      else if (lastOption == 2)
        assignment = RGBIO8_UNASSIGNED;
      else {
        if ((assignment != origAssignment || recipe != origRecipe) && confirmSave()) {
          setRGBIOAssignment(board, channel, assignment, recipe);
          loadRGBIO8();
        }
        return;
      }
        
    }
  }
  
  byte menuRGBIOSelectRecipe(char sTitle[], byte currentSelection) {
    menu recipeMenu(3, RGBIO8_MAX_OUTPUT_RECIPES);
    for (byte i = 0; i < RGBIO8_MAX_OUTPUT_RECIPES; i++) {
      recipeMenu.setItem("", i);
      if (i == currentSelection)
        recipeMenu.setItem("*", i);
      recipeMenu.appendItem("Color Recipe ", i);
      recipeMenu.appendItem(itoa(i + 1, buf, 10), i);
    }
  
    byte lastOption = scrollMenu(sTitle, &recipeMenu);
    if (lastOption == 255)
      return currentSelection;
    return lastOption;
  }


  prog_char RGBTITLE_OFF[] PROGMEM =     "Off:      0x";
  prog_char RGBTITLE_AUTOOFF[] PROGMEM = "Auto Off: 0x";
  prog_char RGBTITLE_AUTOON[] PROGMEM =  "Auto On:  0x";
  prog_char RGBTITLE_ON[] PROGMEM =      "On:       0x";
  
  PROGMEM const char *TITLE_RGBMODES[] = {
    RGBTITLE_OFF,
    RGBTITLE_AUTOOFF,
    RGBTITLE_AUTOON,
    RGBTITLE_ON
  };

  void menuRGBIORecipe(byte recipeIndex) {
    unsigned int recipe[4], origRecipe[4];
    getRGBIORecipe(recipeIndex, recipe);
    memcpy(&origRecipe, &recipe, 8);
    
    while (1) {
      menu recipeMenu(3, 5);
      for(byte i = 0; i < 4; i++) {
        recipeMenu.setItem_P((char*)pgm_read_word(&(TITLE_RGBMODES[i])), i);
        sprintf(buf, "%03X", recipe[i]);
        recipeMenu.appendItem(buf, i);
      }
      recipeMenu.setItem_P(EXIT, 255);
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
