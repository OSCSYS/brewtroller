void menuSetup() {
  byte lastOption = 0;
  
  while(1) {
    char tempUnit[2] = "C";
    if (unit) strcpy_P(tempUnit, PSTR("F"));

    if (unit) strcpy_P(menuopts[0], PSTR("Unit: US")); else strcpy_P(menuopts[0], PSTR("Unit: Metric"));
    if (sysType == SYS_HERMS) strcpy_P(menuopts[1], PSTR("System Type: HERMS")); else strcpy_P(menuopts[1], PSTR("System Type: Direct"));
      
    switch (encMode) {
      case ENC_CUI:
        strcpy_P(menuopts[2], PSTR("Encoder: CUI"));
        break;
      case ENC_ALPS:
        strcpy_P(menuopts[2], PSTR("Encoder: ALPS"));
        break;
    }
    
    strcpy_P(menuopts[3], PSTR("Assign Temp Sensor"));
    strcpy_P(menuopts[4], PSTR("Configure Outputs"));
    strcpy_P(menuopts[5], PSTR("Volume/Capacity"));
    strcpy_P(menuopts[6], PSTR("Default Grain Temp"));
    strcpy_P(menuopts[7], PSTR("Configure Valves"));
    strcpy_P(menuopts[8], PSTR("Save Settings"));
    strcpy_P(menuopts[9], PSTR("Load Settings"));
    strcpy_P(menuopts[10], PSTR("Exit Setup"));
    
    lastOption = scrollMenu("System Setup", menuopts, 11, lastOption);
    switch(lastOption) {
      case 0:
        unit = unit ^ 1;
        if (unit) {
          //Convert Setup params
          for (int i = TS_HLT; i <= TS_KETTLE; i++) {
            hysteresis[i] = round(hysteresis[i] * 1.8);
            capacity[i] = round(capacity[i] * 0.26417);
            volume[i] = round(volume[i] * 0.26417);
            volLoss[i] = round(volLoss[i] * 0.26417);
          }
          setDefGrainTemp(round(getDefGrainTemp() * 1.8) + 32);
          setDefBatch(round(getDefBatch() * 0.26417));
        } else {
          for (int i = TS_HLT; i <= TS_KETTLE; i++) {
            hysteresis[i] = round(hysteresis[i] / 1.8);
            capacity[i] = round(capacity[i] / 0.26417);
            volume[i] = round(volume[i] / 0.26417);
            volLoss[i] = round(volLoss[i] / 0.26417);
          }
          setDefGrainTemp(round((getDefGrainTemp() - 32)/ 1.8));
          setDefBatch(round(getDefBatch() / 0.26417));
        }
        break;
      case 1: cfgSysType(); break;
      case 2: cfgEncoder(); break;
      case 3: assignSensor(); break;
      case 4: cfgOutputs(); break;
      case 5: cfgVolumes(); break;
      case 6: setDefGrainTemp(getValue("Default Grain Temp", getDefGrainTemp(), 3, 0, 255, tempUnit)); break;
      case 7: cfgValves(); break;
      case 8: saveSetup(); break;
      case 9: loadSetup(); break;
      default: return;
    }
  }
}

void assignSensor() {
  encMin = 0;
  encMax = 5;
  encCount = 0;
  int lastCount = 1;
  char dispTitle[6][21] = {
    "   Hot Liquor Tank  ",
    "      Mash Tun      ",
    "     Brew Kettle    ",
    "       H2O In       ",
    "       H2O Out      ",
    "      Beer Out      "
  };
  char buf[3];
  
  while (1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      clearLCD();
      printLCD_P(0, 0, PSTR("Assign Temp Sensor"));
      printLCD(1, 0, dispTitle[lastCount]);
      for (int i=0; i<8; i++) printLCDPad(2,i*2+2,itoa(tSensor[lastCount][i], buf, 16), 2, '0');  
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
      strcpy_P(menuopts[3], PSTR("Exit"));
      switch (scrollMenu(dispTitle[lastCount], menuopts, 4, 0)) {
        case 0:
          clearLCD();
          printLCD(0,0, dispTitle[lastCount]);
          printLCD_P(1,0,PSTR("Disconnect all other"));
          printLCD_P(2,0,PSTR("  temp sensors now  "));
          {
            char conExit[2][19] = {
              "     Continue     ",
              "      Cancel      "};
            if (getChoice(conExit, 2, 3) == 0) getDSAddr(tSensor[lastCount]);
          }
          break;
        case 1:
          for (int i = 0; i <8; i++) tSensor[lastCount][i] = 0; break;
        case 2: break;
        default: return;
      }
      encMin = 0;
      encMax = 5;
      encCount = lastCount;
      lastCount += 1;
    }
  }
}

void cfgOutputs() {
  char dispUnit[2] = "C";
  if (unit) strcpy_P(dispUnit, PSTR("F"));

  byte lastOption = 0;
  while(1) {
    if (PIDEnabled[TS_HLT]) strcpy_P(menuopts[0], PSTR("HLT Mode: PID")); else strcpy_P(menuopts[0], PSTR("HLT Mode: On/Off"));
    strcpy_P(menuopts[1], PSTR("HLT PID Cycle"));
    strcpy_P(menuopts[2], PSTR("HLT PID Gain"));
    strcpy_P(menuopts[3], PSTR("HLT Hysteresis"));
    if (PIDEnabled[TS_MASH]) strcpy_P(menuopts[4], PSTR("Mash Mode: PID")); else strcpy_P(menuopts[4], PSTR("Mash Mode: On/Off"));
    strcpy_P(menuopts[5], PSTR("Mash PID Cycle"));
    strcpy_P(menuopts[6], PSTR("Mash PID Gain"));
    strcpy_P(menuopts[7], PSTR("Mash Hysteresis"));
    if (PIDEnabled[TS_KETTLE]) strcpy_P(menuopts[8], PSTR("Kettle Mode: PID")); else strcpy_P(menuopts[8], PSTR("Kettle Mode: On/Off"));
    strcpy_P(menuopts[9], PSTR("Kettle PID Cycle"));
    strcpy_P(menuopts[10], PSTR("Kettle PID Gain"));
    strcpy_P(menuopts[11], PSTR("Kettle Hysteresis"));
    strcpy_P(menuopts[12], PSTR("Exit"));

    lastOption = scrollMenu("Configure Outputs", menuopts, 13, lastOption);
    switch(lastOption) {
      case 0: PIDEnabled[TS_HLT] = PIDEnabled[TS_HLT] ^ 1; break;
      case 1: PIDCycle[TS_HLT] = getValue("HLT Cycle Time", PIDCycle[TS_HLT], 3, 0, 255, "s"); break;
      case 2: setPIDGain("HLT PID Gain", &PIDp[TS_HLT], &PIDi[TS_HLT], &PIDd[TS_HLT]); break;
      case 3: hysteresis[TS_HLT] = getValue("HLT Hysteresis", hysteresis[TS_HLT], 3, 1, 255, dispUnit); break;
      case 4: PIDEnabled[TS_MASH] = PIDEnabled[TS_MASH] ^ 1; break;
      case 5: PIDCycle[TS_MASH] = getValue("Mash Cycle Time", PIDCycle[TS_MASH], 3, 0, 255, "s"); break;
      case 6: setPIDGain("Mash PID Gain", &PIDp[TS_MASH], &PIDi[TS_MASH], &PIDd[TS_MASH]); break;
      case 7: hysteresis[TS_MASH] = getValue("Mash Hysteresis", hysteresis[TS_MASH], 3, 1, 255, dispUnit); break;
      case 8: PIDEnabled[TS_KETTLE] = PIDEnabled[TS_KETTLE] ^ 1; break;
      case 9: PIDCycle[TS_KETTLE] = getValue("Kettle Cycle Time", PIDCycle[TS_KETTLE], 3, 0, 255, "s"); break;
      case 10: setPIDGain("Kettle PID Gain", &PIDp[TS_KETTLE], &PIDi[TS_KETTLE], &PIDd[TS_KETTLE]); break;
      case 11: hysteresis[TS_KETTLE] = getValue("Kettle Hysteresis", hysteresis[TS_KETTLE], 3, 1, 255, dispUnit); break;
      default: return;
    }
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
  int lastCount = 1;
  char buf[3];
  
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD_P(1, 0, PSTR("P:     I:     D:    "));
  printLCD_P(3, 8, PSTR("OK"));
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        switch (cursorPos) {
          case 0: retP = encCount; break;
          case 1: retI = encCount; break;
          case 2: retD = encCount; break;
        }
      } else {
        cursorPos = encCount;
        switch (cursorPos) {
          case 0:
            printLCD_P(1, 2, PSTR(">"));
            printLCD_P(1, 9, PSTR(" "));
            printLCD_P(1, 16, PSTR(" "));
            printLCD_P(3, 7, PSTR(" "));
            printLCD_P(3, 10, PSTR(" "));
            break;
          case 1:
            printLCD_P(1, 2, PSTR(" "));
            printLCD_P(1, 9, PSTR(">"));
            printLCD_P(1, 16, PSTR(" "));
            printLCD_P(3, 7, PSTR(" "));
            printLCD_P(3, 10, PSTR(" "));
            break;
          case 2:
            printLCD_P(1, 2, PSTR(" "));
            printLCD_P(1, 9, PSTR(" "));
            printLCD_P(1, 16, PSTR(">"));
            printLCD_P(3, 7, PSTR(" "));
            printLCD_P(3, 10, PSTR(" "));
            break;
          case 3:
            printLCD_P(1, 2, PSTR(" "));
            printLCD_P(1, 9, PSTR(" "));
            printLCD_P(1, 16, PSTR(" "));
            printLCD_P(3, 7, PSTR(">"));
            printLCD_P(3, 10, PSTR("<"));
            break;
        }
      }
      printLCDPad(1, 3, itoa(retP, buf, 10), 3, ' ');
      printLCDPad(1, 10, itoa(retI, buf, 10), 3, ' ');
      printLCDPad(1, 17, itoa(retD, buf, 10), 3, ' ');
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
        switch (cursorPos) {
          case 0: encCount = retP; break;
          case 1: encCount = retI; break;
          case 2: encCount = retD; break;
        }
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
    strcpy_P(menuopts[0], PSTR("HLT Capacity       "));
    strcpy_P(menuopts[1], PSTR("HLT Dead Space     "));
    strcpy_P(menuopts[2], PSTR("Mash Capacity      "));
    strcpy_P(menuopts[3], PSTR("Mash Dead Space    "));
    strcpy_P(menuopts[4], PSTR("Kettle Capacity    "));
    strcpy_P(menuopts[5], PSTR("Kettle Dead Space  "));
    strcpy_P(menuopts[6], PSTR("Batch Size         "));
    strcpy_P(menuopts[7], PSTR("Evaporation Rate   "));
    strcpy_P(menuopts[8], PSTR("Exit               "));

    char volUnit[5] = "L";
    if (unit) strcpy_P(volUnit, PSTR("Gal"));
    lastOption = scrollMenu("Volume/Capacity", menuopts, 9, lastOption);
    switch(lastOption) {
      case 0: capacity[TS_HLT] = getValue("HLT Capacity", capacity[TS_HLT], 7, 3, 9999999, volUnit); break;
      case 1: volLoss[TS_HLT] = getValue("HLT Dead Space", volLoss[TS_HLT], 5, 3, 65535, volUnit); break;
      case 2: capacity[TS_MASH] = getValue("Mash Capacity", capacity[TS_MASH], 7, 3, 9999999, volUnit); break;
      case 3: volLoss[TS_MASH] = getValue("Mash Dead Spac", volLoss[TS_MASH], 5, 3, 65535, volUnit); break;
      case 4: capacity[TS_KETTLE] = getValue("Kettle Capacity", capacity[TS_KETTLE], 7, 3, 9999999, volUnit); break;
      case 5: volLoss[TS_KETTLE] = getValue("Kettle Dead Spac", volLoss[TS_KETTLE], 5, 3, 65535, volUnit); break;
      case 6: setDefBatch(getValue("Batch Size", getDefBatch(), 7, 3, 9999999, volUnit)); break;
      case 7: evapRate = getValue("Evaporation Rate", evapRate, 3, 0, 100, "%/hr");
      default: return;
    }
  } 
}

void cfgValves() {
  byte lastOption = 0;
  while (1) {
    strcpy_P(menuopts[0], PSTR("HLT Fill           "));
    strcpy_P(menuopts[1], PSTR("Mash Fill          "));
    strcpy_P(menuopts[2], PSTR("Mash Heat          "));
    strcpy_P(menuopts[3], PSTR("Mash Idle          "));
    strcpy_P(menuopts[4], PSTR("Sparge In          "));
    strcpy_P(menuopts[5], PSTR("Sparge Out         "));
    strcpy_P(menuopts[6], PSTR("Chiller H2O In     "));
    strcpy_P(menuopts[7], PSTR("Chiller Beer In    "));
    strcpy_P(menuopts[8], PSTR("Exit               "));
    
    lastOption = scrollMenu("Valve Configuration", menuopts, 9, lastOption);
    if (lastOption > 7) return; else setValveCfg(lastOption + 1, cfgValveProfile(menuopts[lastOption], getValveCfg(lastOption + 1)));
  }
}

unsigned int cfgValveProfile (char sTitle[], unsigned int defValue) {
  unsigned int retValue = defValue;
  encMin = 0;
  encMax = 11;
  encCount = 0;
  int lastCount = 1;
  char buf[6];

  clearLCD();
  printLCD(0,0,sTitle);
  {
    int bit = 1;
    for (int i = 0; i < 11; i++) { 
      if (retValue & bit) printLCD_P(1, i + 4, PSTR("1")); else printLCD_P(1, i + 4, PSTR("0"));
      bit *= 2;
    }
  }
  printLCD_P(3, 8, PSTR("OK"));
  
  while(1) {
    if (encCount != lastCount) {
      lastCount = encCount;
      printLCD_P(2, 0, PSTR("    123456789AB     "));
      if (lastCount == 11) {
        printLCD_P(3, 7, PSTR(">"));
        printLCD_P(3, 10, PSTR("<"));
      } else {
        printLCD_P(3, 7, PSTR(" "));
        printLCD_P(3, 10, PSTR(" "));
        printLCD_P(2, lastCount + 4, PSTR("^"));
      }
    }
    
    if (enterStatus == 1) {
      enterStatus = 0;
      if (lastCount == 11) {  return retValue; }
      {
        int bit;
        for (int i = 0; i <= lastCount; i++) if (!i) bit = 1; else bit *= 2;
        retValue = retValue ^ bit;
      }

      {
        int bit = 1;
        for (int i = 0; i < 11; i++) { 
          if (retValue & bit) printLCD_P(1, i + 4, PSTR("1")); else printLCD_P(1, i + 4, PSTR("0"));
          bit *= 2;
        }
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return defValue;
    }
  }
}

void cfgEncoder() {
  strcpy_P(menuopts[0], PSTR("CUI"));
  strcpy_P(menuopts[1], PSTR("ALPS"));
  switch( scrollMenu("Select Encoder Type:", menuopts, 2, encMode)) {
    case 0: encMode = ENC_CUI; break;
    case 1: encMode = ENC_ALPS; break;
  }
}

void cfgSysType() {
  strcpy_P(menuopts[0], PSTR("Direct Heat"));
  strcpy_P(menuopts[1], PSTR("HERMS"));
  strcpy_P(menuopts[2], PSTR("Steam"));
  //Steam is not enabled yet and hidden
  switch(scrollMenu("Select System Type:", menuopts, 2, sysType)) {
    case 0: sysType = SYS_DIRECT; break;
    case 1: sysType = SYS_HERMS; break;
    case 2: sysType = SYS_STEAM; break;
  }
}
