void doMon() {
  char buf[6];
  float temp[6] = { 0, 0, 0, 0, 0, 0 };
  char sTempUnit[2] = "C";
  unsigned long convStart = 0;
  unsigned long cycleStart[3];
  boolean heatStatus[3] = { 0, 0, 0 };

  clearTimer();
  
  for (int i = TS_HLT; i <= TS_KETTLE; i++) {
    if (PIDEnabled[i]) {
      pid[i].SetInputLimits(0, 255);
      pid[i].SetOutputLimits(0, PIDCycle[i] * 1000);
      PIDOutput[i] = 0;
      cycleStart[i] = millis();
    }
  }
  
  if (unit) strcpy(sTempUnit, "F");
  encMin = 0;
  encMax = 2;
  encCount = 0;
  int lastCount = 1;
  if (getPwrRecovery() == 2) {
    loadSetpoints();
    unsigned int newMins = getTimerRecovery();
    if (newMins > 0) setTimer(newMins);
  } else { 
    setTimerRecovery(0);
    saveSetpoints();
    setPwrRecovery(2);
  }
  
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
        strcpy(menuopts[0], "Set HLT Temp");
        strcpy(menuopts[1], "Clear HLT Temp");
        strcpy(menuopts[2], "Set Mash Temp");
        strcpy(menuopts[3], "Clear Mash Temp");
        strcpy(menuopts[4], "Set Kettle Temp");
        strcpy(menuopts[5], "Clear Kettle Temp");
        strcpy(menuopts[6], "Set Timer");
        strcpy(menuopts[7], "Pause Timer");
        strcpy(menuopts[8], "Clear Timer");
        strcpy(menuopts[9], "Close Menu");
        strcpy(menuopts[10], "Quit Brew Monitor");

        boolean inMenu = 1;
        byte lastOption = 0;
        while(inMenu) {
          char dispUnit[2] = "C"; if (unit) strcpy(dispUnit, "F");
          lastOption = scrollMenu("Brew Monitor Menu   ", menuopts, 11, lastOption);
          switch (lastOption) {
            case 0:
              {
                byte defHLTTemp = 180;
                if (!unit) defHLTTemp = round(defHLTTemp / 1.8) + 32;
                if (setpoint[TS_HLT] > 0) setpoint[TS_HLT] = getValue("Enter HLT Temp:", setpoint[TS_HLT], 3, 0, 255, dispUnit);
                else setpoint[TS_HLT] = getValue("Enter HLT Temp:", defHLTTemp, 3, 0, 255, dispUnit);
              }
              inMenu = 0;
              break;
            case 1: setpoint[TS_HLT] = 0; inMenu = 0; break; 
            case 2:
              {
                byte defMashTemp = 152;
                if (!unit) defMashTemp = round(defMashTemp / 1.8) + 32;
                if (setpoint[TS_MASH] > 0) setpoint[TS_MASH] = getValue("Enter Mash Temp:", setpoint[TS_MASH], 3, 0, 255, dispUnit);
                else setpoint[TS_MASH] = getValue("Enter Mash Temp:", defMashTemp, 3, 0, 255, dispUnit);
              }
              inMenu = 0;
              break;
            case 3: setpoint[TS_MASH] = 0; inMenu = 0; break; 
            case 4:
              {
                byte defKettleTemp = 212;
                if (!unit) defKettleTemp = round(defKettleTemp / 1.8) + 32;
                if (setpoint[TS_KETTLE] > 0) setpoint[TS_KETTLE] = getValue("Enter Kettle Temp:", setpoint[TS_KETTLE], 3, 0, 255, dispUnit);
                else setpoint[TS_KETTLE] = getValue("Enter Kettle Temp:", defKettleTemp, 3, 0, 255, dispUnit);
              }
              inMenu = 0;
              break;
            case 5: setpoint[TS_KETTLE] = 0; inMenu = 0; break; 
            case 6:
              unsigned int newMins;
              newMins = getTimerValue("Enter Timer Value:", timerValue/60000);
              if (newMins > 0) {
                setTimer(newMins);
                inMenu = 0;
              }
              break;
            case 7:
              pauseTimer();
              inMenu = 0;
              break;
            case 8:
              clearTimer();
              inMenu = 0;
              break;
            case 10:
              if (confirmExit()) {
                resetOutputs();
                setPwrRecovery(0);
                return;
              } else break;
            default:
              inMenu = 0;
              break;
          }
          saveSetpoints();
        }
        encMin = 0;
        encMax = 2;
        encCount = lastCount;
        lastCount += 1;
      }
    }
    char buf[6];
    switch (encCount) {
      case 0:
        if (encCount != lastCount) {
          clearLCD();
          printLCD(0,4,"Brew Monitor");
          printLCD(1,2,"HLT");
          printLCD(3,0,"[");
          printLCD(3,5,"]");
          printLCD(2, 4, sTempUnit);
          printLCD(3, 4, sTempUnit);
          printLCD(1,15,"Mash");
          printLCD(3,14,"[");
          printLCD(3,19,"]");
          printLCD(2, 18, sTempUnit);
          printLCD(3, 18, sTempUnit);
          lastCount = encCount;
          timerLastWrite = 0;
        }
        
        for (int i = TS_HLT; i <= TS_MASH; i++) {
          if (temp[i] == -1) printLCD(2, i * 14 + 1, "---"); else printLCDPad(2, i * 14 + 1, itoa(temp[i], buf, 10), 3, ' ');
          printLCDPad(3, i * 14 + 1, itoa(setpoint[i], buf, 10), 3, ' ');
          if (PIDEnabled[i]) {
            byte pct = PIDOutput[i] / PIDCycle[i] / 10;
            switch (pct) {
              case 0: strcpy(buf, "Off"); break;
              case 100: strcpy(buf, " On"); break;
              default: itoa(pct, buf, 10); strcat(buf, "%"); break;
            }
          } else if (heatStatus[i]) strcpy(buf, " On"); else strcpy(buf, "Off"); 
          printLCDPad(3, i * 5 + 6, buf, 3, ' ');
        }
        break;
      case 1:
        if (encCount != lastCount) {
          clearLCD();
          printLCD(0,4,"Brew Monitor");
          printLCD(1,0,"Kettle");
          printLCD(3,0,"[");
          printLCD(3,5,"]");
          printLCD(2, 4, sTempUnit);
          printLCD(3, 4, sTempUnit);
          lastCount = encCount;
          timerLastWrite = 0;
        }
        if (temp[TS_KETTLE] == -1) printLCD(2, 1, "---"); else printLCDPad(2, 1, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
        printLCDPad(3, 1, itoa(setpoint[TS_KETTLE], buf, 10), 3, ' ');
        if (PIDEnabled[TS_KETTLE]) {
          byte pct = PIDOutput[TS_KETTLE] / PIDCycle[TS_KETTLE] / 10;
          switch (pct) {
            case 0: strcpy(buf, "Off"); break;
            case 100: strcpy(buf, " On"); break;
            default: itoa(pct, buf, 10); strcat(buf, "%"); break;
          }
        } else if (heatStatus[TS_KETTLE]) strcpy(buf, " On"); else strcpy(buf, "Off");
        printLCDPad(3, 6, buf, 3, ' ');
        break;
      case 2:
        if (encCount != lastCount) {
          clearLCD();
          printLCD(0,4,"Brew Monitor");
          printLCD(1,1,"In");
          printLCD(1,16,"Out");
          printLCD(2,8,"Beer");
          printLCD(3,8,"H2O");
          printLCD(2, 3, sTempUnit);
          printLCD(2, 19, sTempUnit);
          printLCD(3, 3, sTempUnit);
          printLCD(3, 19, sTempUnit);
          lastCount = encCount;
          timerLastWrite = 0;
        }
        
        if (temp[TS_KETTLE] == -1) printLCD(2, 0, "---"); else printLCDPad(2, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
        if (temp[TS_BEEROUT] == -1) printLCD(2, 16, "---"); else printLCDPad(2, 16, itoa(temp[TS_BEEROUT], buf, 10), 3, ' ');
        if (temp[TS_H2OIN] == -1) printLCD(3, 0, "---"); else printLCDPad(3, 0, itoa(temp[TS_H2OIN], buf, 10), 3, ' ');
        if (temp[TS_H2OOUT] == -1) printLCD(3, 16, "---"); else printLCDPad(3, 16, itoa(temp[TS_H2OOUT], buf, 10), 3, ' ');
        break;
    }
    printTimer(1,7);

    if (convStart == 0) {
      convertAll();
      convStart = millis();
    } else if (millis() - convStart >= 750) {
      for (int i = TS_HLT; i <= TS_BEEROUT; i++) temp[i] = read_temp(unit, tSensor[i]);
      convStart = 0;
    }
    for (int i = TS_HLT; i <= TS_KETTLE; i++) {
      if (PIDEnabled[i]) {
        if (temp[i] == -1) {
          pid[i].SetMode(MANUAL);
          PIDOutput[i] = 0;
        } else {
          pid[i].SetMode(AUTO);
          PIDInput[i] = temp[i];
          pid[i].Compute();
        }
        if (millis() - cycleStart[i] > PIDCycle[i] * 1000) cycleStart[i] += PIDCycle[i] * 1000;
        if (PIDOutput[i] > millis() - cycleStart[i]) digitalWrite(heatPin[i], HIGH); else digitalWrite(heatPin[i], LOW);
      } else {
        if (heatStatus[i]) {
          if (temp[i] == -1 || temp[i] >= setpoint[i]) {
            digitalWrite(heatPin[i], LOW);
            heatStatus[i] = 0;
          } else digitalWrite(heatPin[i], HIGH);
        } else { 
          if (temp[i] != -1 && (float)(setpoint[i] - temp[i]) >= (float) hysteresis[i] / 10.0) {
            digitalWrite(heatPin[i], HIGH);
            heatStatus[i] = 1;
          } else digitalWrite(heatPin[i], LOW);
        }
      }
    }
  }
}
