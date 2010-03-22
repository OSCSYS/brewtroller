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


#define MINS_PROMPT -1
#define STEP_DOUGHIN 0
#define STEP_PROTEIN 1
#define STEP_SACCH 2
#define STEP_MASHOUT 3

#define ADD_GRAIN 0
#define SPARGE 1

//Bit 1 = Boil; Bit 2-11 (See Below); Bit 12 = End of Boil; Bit 13-15 (Open); Bit 16 = Preboil (If Compile Option Enabled)
unsigned int hoptimes[10] = { 105, 90, 75, 60, 45, 30, 20, 15, 10, 5 };

void doAutoBrew() {
  unsigned int delayMins = 0;
  byte stepTemp[4], stepMins[4], spargeTemp;
  unsigned long grainWeight = 0;
  unsigned int boilMins;
  unsigned int mashRatio;
  unsigned int boilAdds = 0;
  unsigned long batchVol;
  byte grainTemp;
  byte HLTTemp;
  
  MLHeatSrc = getMLHeatSrc();
  HLTTemp = getABHLTTemp();
  loadABSteps(stepTemp, stepMins);
  spargeTemp = getABSparge();
  delayMins = getABDelay();
  batchVol = getABBatchVol();
  grainWeight = getABGrain();
  boilMins = getABBoil();
  mashRatio = getABRatio();
  pitchTemp = getABPitch();
  boilAdds = getABAdds();
  grainTemp = getABGrainTemp();
  
  if (pwrRecovery == 0) {
    recoveryStep = 0;
  }

  boolean inMenu = 1;
  if (recoveryStep) inMenu = 0;
  byte lastOption = 0;
  while (inMenu) {
    logStart_P(LOGAB);
    logField_P(PSTR("SETTINGS"));
  
    for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) {
      logFieldI(stepTemp[i]);
      logFieldI(stepMins[i]);
    }
    logFieldI(spargeTemp);
    logFieldI(delayMins);
    logFieldI(HLTTemp);
    logFieldI(batchVol);
    logFieldI(grainWeight);
    logFieldI(boilMins);
    logFieldI(mashRatio);
    logFieldI(pitchTemp);
    logFieldI(boilAdds);
    logFieldI(grainTemp);
    logEnd();
  
    strcpy_P(menuopts[0], PSTR("Batch Vol:"));
    strcpy_P(menuopts[1], PSTR("Grain Wt:"));
    strcpy_P(menuopts[2], PSTR("Grain Temp:"));
    strcpy_P(menuopts[3], PSTR("Boil Length:"));
    strcpy_P(menuopts[4], PSTR("Mash Ratio:"));
    strcpy_P(menuopts[5], PSTR("Delay Start:"));
    strcpy_P(menuopts[6], PSTR("HLT Temp:"));
    strcpy_P(menuopts[7], PSTR("Sparge Temp:"));
    strcpy_P(menuopts[8], PSTR("Pitch Temp:"));
    strcpy_P(menuopts[9], PSTR("Mash Schedule"));
    strcpy_P(menuopts[10], PSTR("Heat Mash Liq:"));    
    strcpy_P(menuopts[11], BOILADDS);    
    strcpy_P(menuopts[12], PSTR("Start Program"));
    strcpy_P(menuopts[13], PSTR("Load Program"));
    strcpy_P(menuopts[14], PSTR("Save Program"));
    strcpy_P(menuopts[15], EXIT);

    ftoa((float)batchVol/1000, buf, 2);
    truncFloat(buf, 5);
    strcat(menuopts[0], buf);
    strcat_P(menuopts[0], VOLUNIT);

    ftoa((float)grainWeight/1000, buf, 3);
    truncFloat(buf, 7);
    strcat(menuopts[1], buf);
    strcat_P(menuopts[1], WTUNIT);

    strncat(menuopts[2], itoa(grainTemp, buf, 10), 3);
    strcat_P(menuopts[2], TUNIT);

    strncat(menuopts[3], itoa(boilMins, buf, 10), 3);
    strcat_P(menuopts[3], PSTR(" min"));
    
    ftoa((float)mashRatio/100, buf, 2);
    truncFloat(buf, 4);
    strcat(menuopts[4], buf);
    strcat_P(menuopts[4], PSTR(":1"));

    strncat(menuopts[5], itoa(delayMins/60, buf, 10), 4);
    strcat_P(menuopts[5], PSTR(" hr"));
    
    strncat(menuopts[6], itoa(HLTTemp, buf, 10), 3);
    strcat_P(menuopts[6], TUNIT);
    
    strncat(menuopts[7], itoa(spargeTemp, buf, 10), 3);
    strcat_P(menuopts[7], TUNIT);
    
    strncat(menuopts[8], itoa(pitchTemp, buf, 10), 3);
    strcat_P(menuopts[8], TUNIT);
    
    if (MLHeatSrc == VS_HLT) strcat_P(menuopts[10], PSTR("HLT"));
    else if (MLHeatSrc == VS_MASH) strcat_P(menuopts[10], PSTR("MASH"));
    else strcat_P(menuopts[10], PSTR("UNKWN"));
    
    lastOption = scrollMenu("AutoBrew Parameters", 16, lastOption);
    if (lastOption == 0) batchVol = getValue(PSTR("Batch Volume"), batchVol, 7, 3, 9999999, VOLUNIT);
    else if (lastOption == 1) grainWeight = getValue(PSTR("Grain Weight"), grainWeight, 7, 3, 9999999, WTUNIT);
    else if (lastOption == 2) grainTemp = getValue(PSTR("Grain Temp"), grainTemp, 3, 0, 255, TUNIT);
    else if (lastOption == 3) boilMins = getTimerValue(PSTR("Boil Length"), boilMins);
    else if (lastOption == 4) { 
      #ifdef USEMETRIC
        mashRatio = getValue(PSTR("Mash Ratio"), mashRatio, 3, 2, 999, PSTR(" l/kg")); 
      #else
        mashRatio = getValue(PSTR("Mash Ratio"), mashRatio, 3, 2, 999, PSTR(" qts/lb"));
      #endif
    }
    else if (lastOption == 5) delayMins = getTimerValue(PSTR("Delay Start"), delayMins);
    else if (lastOption == 6) HLTTemp = getValue(PSTR("HLT Setpoint"), HLTTemp, 3, 0, 255, TUNIT);
    else if (lastOption == 7) spargeTemp = getValue(PSTR("Sparge Temp"), spargeTemp, 3, 0, 255, TUNIT);
    else if (lastOption == 8) pitchTemp = getValue(PSTR("Pitch Temp"), pitchTemp, 3, 0, 255, TUNIT);
    else if (lastOption == 9) editMashSchedule(stepTemp, stepMins);
    else if (lastOption == 10) MLHeatSrc = MLHeatSrcMenu(MLHeatSrc);
    else if (lastOption == 11) boilAdds = editHopSchedule(boilAdds);
    else if (lastOption == 12) inMenu = 0;
    else if (lastOption == 13) {
      byte profile = 0;
      //Display Stored Programs
      for (byte i = 0; i < 21; i++) getProgName(i, menuopts[i]);
      profile = scrollMenu("Load Program", 21, profile);
      if (profile < 21) {
        spargeTemp = getProgSparge(profile);
        grainWeight = getProgGrain(profile);
        delayMins = getProgDelay(profile);
        boilMins = getProgBoil(profile);
        mashRatio = getProgRatio(profile);
        getProgSchedule(profile, stepTemp, stepMins);
        batchVol = getProgBatchVol(profile);
        HLTTemp = getProgHLT(profile);
        pitchTemp = getProgPitch(profile);
        boilAdds = getProgAdds(profile);
        grainTemp = getProgGrainT(profile);
        MLHeatSrc = getProgMLHeatSrc(profile);
      }
    } 
    else if (lastOption == 14) {
      byte profile = 0;
      //Display Stored Schedules
      for (byte i = 0; i < 21; i++) getProgName(i, menuopts[i]);
      profile = scrollMenu("Save Program", 21, profile);
      if (profile < 21) {
        getString(PSTR("Save Program As:"), menuopts[profile], 19);
        setProgName(profile, menuopts[profile]);
        setProgSparge(profile, spargeTemp);
        setProgGrain(profile, grainWeight);
        setProgDelay(profile, delayMins);
        setProgBoil(profile, boilMins);
        setProgRatio(profile, mashRatio);
        setProgSchedule(profile, stepTemp, stepMins);
        setProgBatchVol(profile, batchVol);
        setProgHLT(profile, HLTTemp);
        setProgPitch(profile, pitchTemp);
        setProgAdds(profile, boilAdds);
        setProgGrainT(profile, grainTemp);
        setProgMLHeatSrc(profile, MLHeatSrc);
      }
    }
    else {
        if(confirmExit()) {
          setPwrRecovery(0);
          return;
        } else lastOption = 0;
    }
    
    tgtVol[TS_HLT] = calcSpargeVol(batchVol, boilMins, grainWeight, mashRatio);
    tgtVol[TS_MASH] = calcMashVol(grainWeight, mashRatio);

    //Grain-to-volume factor for mash tun capacity (1 lb = .15 gal)
    float grain2Vol;
    #ifdef USEMETRIC
      grain2Vol = 1.25;
    #else
      grain2Vol = .15;
    #endif

    //Check for capacity overages
    if (tgtVol[TS_HLT] > capacity[TS_HLT]) {
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
      while (!enterStatus) delay(500);
      enterStatus = 0;
    }
    if (tgtVol[TS_MASH] + round(grainWeight * grain2Vol) > capacity[TS_MASH]) {
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
      while (!enterStatus) delay(500);
      enterStatus = 0;
    }

    //Save Values to EEPROM for Recovery
    setMLHeatSrc(MLHeatSrc);
    setPwrRecovery(1);
    setABRecovery(0);
    setABHLTTemp(HLTTemp);
    saveABSteps(stepTemp, stepMins);
    setABSparge(spargeTemp);
    setABDelay(delayMins);
    setABBatchVol(batchVol);
    setABGrain(grainWeight);
    setABBoil(boilMins);
    setABRatio(mashRatio);
    setABPitch(pitchTemp);
    setABAdds(boilAdds);
    setABAddsTrig(0);
    setABGrainTemp(grainTemp);
  }

  switch (recoveryStep) {
    case 0:
    case 1:
      setABRecovery(1);
      //Set tgtVols
      if (MLHeatSrc == VS_HLT) {
        tgtVol[VS_HLT] = min(calcSpargeVol(batchVol, boilMins, grainWeight, mashRatio) + calcMashVol(grainWeight, mashRatio), capacity[VS_HLT]);
        tgtVol[VS_MASH] = 0;
      } else {
        tgtVol[VS_HLT] = calcSpargeVol(batchVol, boilMins, grainWeight, mashRatio);
        tgtVol[VS_MASH] = calcMashVol(grainWeight, mashRatio);
      }
      manFill();
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
    case 2:
      if(delayMins) {
        setABRecovery(2);
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 2 && recoverMins > 0)  delayStart(recoverMins); else delayStart(delayMins);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 3:
      //Find first temp and adjust for strike temp
      {
        byte strikeTemp = 0;
        byte i = 0;
        while (strikeTemp == 0 && i <= STEP_MASHOUT) strikeTemp = stepTemp[i++];
        #ifdef USEMETRIC
          //strikeTemp = round(.41 / (mashRatio / 100.0) * (strikeTemp - grainTemp)) + strikeTemp;
          strikeTemp = strikeTemp + round(.4 * (strikeTemp - grainTemp) / (mashRatio / 100.0)) + 1.7;
        #else
          //strikeTemp = round(.2 / (mashRatio / 100.0) * (strikeTemp - grainTemp)) + strikeTemp;
          strikeTemp = strikeTemp + round(.192 * (strikeTemp - grainTemp) / (mashRatio / 100.0)) + 3;
        #endif
        if (MLHeatSrc == VS_HLT) {
          #ifdef STRIKE_TEMP_OFFSET
            strikeTemp += STRIKE_TEMP_OFFSET;
          #endif
          setpoint[TS_HLT] = strikeTemp;
          setpoint[TS_MASH] = 0;
        } else {
          setpoint[TS_HLT] = HLTTemp;
          setpoint[TS_MASH] = strikeTemp;
        }
        setpoint[VS_STEAM] = steamTgt;
        pid[VS_HLT].SetMode(AUTO);
        pid[VS_MASH].SetMode(AUTO);
        pid[VS_STEAM].SetMode(AUTO);
      }
      setABRecovery(3);
      mashStep("Preheat", MINS_PROMPT);  
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
    case 4:
      //Add Grain
      setpoint[TS_HLT] = 0;
      setpoint[TS_MASH] = 0;
      setpoint[VS_STEAM] = steamTgt;
      setABRecovery(4);
      manSparge(ADD_GRAIN);
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
    case 5:
      //Refill HLT
      setABRecovery(5);
      if (MLHeatSrc == VS_HLT) {
        tgtVol[VS_HLT] = calcSpargeVol(batchVol, boilMins, grainWeight, mashRatio);
        tgtVol[VS_MASH] = 0;
        manFill();
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 6:
      if (stepTemp[STEP_DOUGHIN]) {
        setABRecovery(6);
        setpoint[TS_HLT] = HLTTemp;
        setpoint[TS_MASH] = stepTemp[STEP_DOUGHIN];
        setpoint[VS_STEAM] = steamTgt;
        pid[VS_HLT].SetMode(AUTO);
        pid[VS_MASH].SetMode(AUTO);
        pid[VS_STEAM].SetMode(AUTO);
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 6 && recoverMins > 0) mashStep("Dough In", recoverMins); else mashStep("Dough In", stepMins[STEP_DOUGHIN]);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 7:
      if (stepTemp[STEP_PROTEIN]) {
        setABRecovery(7);
        setpoint[TS_HLT] = HLTTemp;
        setpoint[TS_MASH] = stepTemp[STEP_PROTEIN];
        setpoint[VS_STEAM] = steamTgt;
        pid[VS_HLT].SetMode(AUTO);
        pid[VS_MASH].SetMode(AUTO);
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 7 && recoverMins > 0) mashStep("Protein", recoverMins); else mashStep("Protein", stepMins[STEP_PROTEIN]);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 8:
      if (stepTemp[STEP_SACCH]) {
        setABRecovery(8);
        setpoint[TS_HLT] = HLTTemp;
        setpoint[TS_MASH] = stepTemp[STEP_SACCH];
        setpoint[VS_STEAM] = steamTgt;
        pid[VS_HLT].SetMode(AUTO);
        pid[VS_MASH].SetMode(AUTO);
        pid[VS_STEAM].SetMode(AUTO);
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 8 && recoverMins > 0) mashStep("Sacch Rest", recoverMins); else mashStep("Sacch Rest", stepMins[STEP_SACCH]);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 9:
      if (stepTemp[STEP_MASHOUT]) {
        setABRecovery(9);
        setpoint[TS_HLT] = HLTTemp;
        setpoint[TS_MASH] = stepTemp[STEP_MASHOUT];
        setpoint[VS_STEAM] = steamTgt;
        pid[VS_HLT].SetMode(AUTO);
        pid[VS_MASH].SetMode(AUTO);
        pid[VS_STEAM].SetMode(AUTO);
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 9 && recoverMins > 0) mashStep("Mash Out", recoverMins); else mashStep("Mash Out", stepMins[STEP_MASHOUT]);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 10:
      //Hold last mash temp until user exits
      setABRecovery(10); 
      setpoint[TS_HLT] = spargeTemp;
      //Cycle through steps and use last non-zero step for mash
      for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) if (stepTemp[i]) setpoint[TS_MASH] = stepTemp[i];
      setpoint[VS_STEAM] = steamTgt;
      pid[VS_HLT].SetMode(AUTO);
      pid[VS_MASH].SetMode(AUTO);
      pid[VS_STEAM].SetMode(AUTO);
      mashStep("End Mash", MINS_PROMPT);
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      setpoint[TS_HLT] = 0;
      setpoint[TS_MASH] = 0;
      setpoint[VS_STEAM] = 0;
    case 11:  
      setABRecovery(11); 
      manSparge(SPARGE);
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
    case 12:
      {
        setpoint[TS_KETTLE] = getBoilTemp();
        setABRecovery(12); 
        unsigned int recoverMins = getTimerRecovery();
        if (recoveryStep == 12 && recoverMins > 0) boilStage(recoverMins, boilAdds); else boilStage(boilMins, boilAdds);
        setTimerRecovery(0);
        if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
      }
    case 13:
      setABRecovery(13); 
      manChill();
      if (enterStatus == 2) { enterStatus = 0; setPwrRecovery(0); return; }
    case 14:
      setABRecovery(14); 
      lastOption = 0;
      inMenu = 1;
      while (inMenu) {
        strcpy_P(menuopts[0], PSTR("Load Clean Program"));
        strcpy_P(menuopts[1], DRAIN);
        if (vlvConfig[VLV_DRAIN] != 0 && (vlvBits & vlvConfig[VLV_DRAIN]) == vlvConfig[VLV_DRAIN]) strcat_P(menuopts[1], PSTR(" (On)"));
        
        strcpy_P(menuopts[2], ALLOFF);
        strcpy_P(menuopts[3], EXIT);

        lastOption = scrollMenu("Clean/Drain", 4, lastOption);
        if (lastOption == 0) {
          byte profile = 20;
          setMLHeatSrc(getProgMLHeatSrc(profile));
          setPwrRecovery(1);
          setABRecovery(1);
          setABHLTTemp(getProgHLT(profile));
          getProgSchedule(profile, stepTemp, stepMins);
          saveABSteps(stepTemp, stepMins);
          setABSparge(getProgSparge(profile));
          setABDelay(getProgDelay(profile));
          setABBatchVol(getProgBatchVol(profile));
          setABGrain(getProgGrain(profile));
          setABBoil(getProgBoil(profile));
          setABRatio(getProgRatio(profile));
          setABPitch(getProgPitch(profile));
          setABAdds(getProgAdds(profile));
          setABAddsTrig(0);
          setABGrainTemp(getProgGrainT(profile));

          logStart_P(LOGSYS);
          logField_P(PSTR("SOFT_RESET"));
          logEnd();

          softReset();
        } else if (lastOption == 1) setValves(vlvConfig[VLV_DRAIN]);
        else if (lastOption == 2) setValves(0);
        else inMenu = 0;
      }
 
  }  
  enterStatus = 0;
  setABRecovery(0);
  setPwrRecovery(0);
}

void editMashSchedule(byte stepTemp[4], byte stepMins[4]) {
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
  
    strncat(menuopts[0], itoa(stepMins[STEP_DOUGHIN], buf, 10), 2);
    strcat(menuopts[0], " min");

    strncat(menuopts[1], itoa(stepTemp[STEP_DOUGHIN], buf, 10), 3);
    strcat_P(menuopts[1], TUNIT);
    
    strncat(menuopts[2], itoa(stepMins[STEP_PROTEIN], buf, 10), 2);
    strcat(menuopts[2], " min");

    strncat(menuopts[3], itoa(stepTemp[STEP_PROTEIN], buf, 10), 3);
    strcat_P(menuopts[3], TUNIT);
    
    strncat(menuopts[4], itoa(stepMins[STEP_SACCH], buf, 10), 2);
    strcat(menuopts[4], " min");

    strncat(menuopts[5], itoa(stepTemp[STEP_SACCH], buf, 10), 3);
    strcat_P(menuopts[5], TUNIT);
    
    strncat(menuopts[6], itoa(stepMins[STEP_MASHOUT], buf, 10), 2);
    strcat(menuopts[6], " min");

    strncat(menuopts[7], itoa(stepTemp[STEP_MASHOUT], buf, 10), 3);
    strcat_P(menuopts[7], TUNIT);

    lastOption = scrollMenu("Mash Schedule", 9, lastOption);
    if (lastOption == 0) stepMins[STEP_DOUGHIN] = getTimerValue(PSTR("Dough In"), stepMins[STEP_DOUGHIN]);
    else if (lastOption == 1) stepTemp[STEP_DOUGHIN] = getValue(PSTR("Dough In"), stepTemp[STEP_DOUGHIN], 3, 0, 255, TUNIT);
    else if (lastOption == 2) stepMins[STEP_PROTEIN] = getTimerValue(PSTR("Protein Rest"), stepMins[STEP_PROTEIN]);
    else if (lastOption == 3) stepTemp[STEP_PROTEIN] = getValue(PSTR("Protein Rest"), stepTemp[STEP_PROTEIN], 3, 0, 255, TUNIT);
    else if (lastOption == 4) stepMins[STEP_SACCH] = getTimerValue(PSTR("Sacch Rest"), stepMins[STEP_SACCH]);
    else if (lastOption == 5) stepTemp[STEP_SACCH] = getValue(PSTR("Sacch Rest"), stepTemp[STEP_SACCH], 3, 0, 255, TUNIT);
    else if (lastOption == 6) stepMins[STEP_MASHOUT] = getTimerValue(PSTR("Mash Out"), stepMins[STEP_MASHOUT]);
    else if (lastOption == 7) stepTemp[STEP_MASHOUT] = getValue(PSTR("Mash Out"), stepTemp[STEP_MASHOUT], 3, 0, 255, TUNIT);
    else return;
  }
}

void manFill() {
  autoValve = 0;
  
  while (1) {
    clearLCD();
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

    setValves(0);

    encMin = 0;
    encMax = 6;
    encCount = 0;
    byte lastCount = 1;
            
    boolean redraw = 0;
    while(!redraw) {
      brewCore();
      ftoa(volAvg[VS_HLT]/1000.0, buf, 2);
      truncFloat(buf, 6);
      printLCDRPad(2, 0, buf, 7, ' ');

      ftoa(volAvg[VS_MASH]/1000.0, buf, 2);
      truncFloat(buf, 6);
      printLCDLPad(2, 14, buf, 6, ' ');

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

      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (enterStatus == 1) {
        enterStatus = 0;
        autoValve = 0;
        if (encCount == 0) {
          resetOutputs();
          return;
        } else if (encCount == 1) autoValve = AV_FILL;
        else if (encCount == 2) setValves(vlvConfig[VLV_FILLHLT]);
        else if (encCount == 3) setValves(vlvConfig[VLV_FILLMASH]);
        else if (encCount == 4) setValves(vlvConfig[VLV_FILLHLT] | vlvConfig[VLV_FILLMASH]);
        else if (encCount == 5) setValves(0);
        else if (encCount == 6) {
          setValves(0);
          if (confirmExit()) {
            enterStatus = 2;
            resetOutputs();
            return;
          } else redraw = 1;
        }
      } else if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit()) { 
          resetOutputs();
          enterStatus = 2;
          return;
        } else redraw = 1;
      }
      
      if (vlvConfig[VLV_FILLMASH] != 0 && (vlvBits & vlvConfig[VLV_FILLMASH]) == vlvConfig[VLV_FILLMASH]) printLCD_P(3, 17, PSTR(" On"));
      else printLCD_P(3, 17, PSTR("Off"));

      if (vlvConfig[VLV_FILLHLT] != 0 && (vlvBits & vlvConfig[VLV_FILLHLT]) == vlvConfig[VLV_FILLHLT]) printLCD_P(3, 0, PSTR("On "));
      else printLCD_P(3, 0, PSTR("Off"));
    }
  }
}

void delayStart(int iMins) {
  setTimer(iMins);
  while(1) {
    boolean redraw = 0;
    clearLCD();
    printLCD_P(0,0,PSTR("Delay Start"));
    printLCD_P(0,14,PSTR("(WAIT)"));
    while(timerValue > 0) { 
      brewCore();
      printTimer(1,7);

      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (enterStatus == 1) {
        enterStatus = 0;
        redraw = 1;
        strcpy_P(menuopts[0], CANCEL);
        strcpy_P(menuopts[1], PSTR("Reset Timer"));
        strcpy_P(menuopts[2], PSTR("Pause Timer"));
        strcpy_P(menuopts[3], SKIPSTEP);
        strcpy_P(menuopts[4], ABORT);
        byte lastOption = scrollMenu("AutoBrew Delay Menu", 5, 0);
        if (lastOption == 1) {
          printLCDRPad(0, 14, "", 6, ' ');
          setTimer(iMins);
        } else if (lastOption == 2) pauseTimer();
        else if (lastOption == 3) return;
        else if (lastOption == 4) {
            if (confirmExit() == 1) {
              enterStatus = 2;
              return;
            }
        }
        if (redraw) break;
      }
      if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit() == 1) {
          enterStatus = 2;
          return;
        } else redraw = 1; break;
      }
    }
    if (!redraw) return;
  }
}

void mashStep(char sTitle[ ], int iMins) {
  boolean preheated = 0;
  setAlarm(0);
  boolean doPrompt = 0;
  if (iMins == MINS_PROMPT) doPrompt = 1;
  timerValue = 0;
  autoValve = AV_MASH;
  
  while(1) {
    boolean redraw = 0;
    timerLastWrite = 0;
    clearLCD();
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
    
    while(!preheated || timerValue > 0 || doPrompt) {
      #ifdef SMART_HERMS_HLT
        if (setpoint[VS_MASH] != 0) setpoint[VS_HLT] = constrain(setpoint[VS_MASH] * 2 - temp[TS_MASH], setpoint[VS_MASH] + MASH_HEAT_LOSS, HLT_MAX_TEMP);
      #endif
      brewCore();
      if (!preheated && ((setpoint[VS_MASH] != 0 && temp[TS_MASH] >= setpoint[TS_MASH]) || (setpoint[VS_MASH] == 0 && temp[TS_HLT] >= setpoint[TS_HLT]))) {
        preheated = 1;
        printLCDRPad(2, 7, "", 6, ' ');
        if(doPrompt) {
          printLCD(2, 5, ">");
          printLCD_P(2, 6, CONTINUE);
          printLCD(2, 14, "<");
        } else setTimer(iMins);
      }

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
      }

      if (preheated && !doPrompt) printTimer(2, 7);

      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (doPrompt && preheated && enterStatus == 1) { 
        enterStatus = 0;
        break; 
      }
      else if (enterStatus == 1) {
        enterStatus = 0;
        redraw = 1;
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
        if (redraw) break;
      }
      if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit() == 1) {
          resetOutputs();
          enterStatus = 2;
          return;
        }
        redraw = 1;
        break;
      }
    }
    if (!redraw) {
      resetOutputs();
      //Exit
      return;
    }
  }
}

//used for Sparge and Add Grain Steps
void manSparge(byte mode) {
  while (1) {
    clearLCD();
    if (mode == ADD_GRAIN) {
      printLCD_P(0, 0, PSTR("Grain In"));
      setValves(vlvConfig[VLV_ADDGRAIN]);
    } else printLCD_P(0, 0, PSTR("Sparge"));

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
    
    setValves(0);

    encMin = 0;
    encMax = 7;
    encCount = 0;
    byte lastCount = 1;
    
    boolean redraw = 0;
    while(!redraw) {
      brewCore();
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
        boolean moveUp = 1;
        if (encCount < lastCount) moveUp = 0;
        lastCount = encCount;
        //Skip unneeded menu options in Add Grain Step
        if (mode == ADD_GRAIN) {
          if (MLHeatSrc == VS_HLT) {
            if (lastCount >= 2 && lastCount <= 5) {
              if (moveUp) lastCount = 6; else lastCount = 1;
            }
          } else {
            if (lastCount >= 1 && lastCount <= 6) {
              if (moveUp) lastCount = 7; else lastCount = 0;
            }            
          }
          encCount = lastCount;
        }
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

      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (enterStatus == 1) {
        enterStatus = 0;
        if (encCount == 0) {
          resetOutputs();
          return;
        }
        else if (encCount == 1) setValves(vlvConfig[VLV_SPARGEIN]);
        else if (encCount == 2) setValves(vlvConfig[VLV_SPARGEOUT]);
        else if (encCount == 3) setValves(vlvConfig[VLV_SPARGEIN] | vlvConfig[VLV_SPARGEOUT]);
        else if (encCount == 4) setValves(vlvConfig[VLV_MASHHEAT]);
        else if (encCount == 5) setValves(vlvConfig[VLV_MASHIDLE]);
        else if (encCount == 6) setValves(0);
        else if (encCount == 7) {
            if (confirmExit()) {
              resetOutputs();
              enterStatus = 2;
              return;
            } else redraw = 1;
        }
        if (mode == ADD_GRAIN) setValves(vlvBits | vlvConfig[VLV_ADDGRAIN]);
      } else if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit()) {
          resetOutputs();
          enterStatus = 2;
          return;
        } else redraw = 1;
      }
    }
  }  
}

void boilStage(unsigned int iMins, unsigned int boilAdds) {
  boolean preheated = 0;
  unsigned int triggered = getABAddsTrig();
  setAlarm(0);
  timerValue = 0;
  unsigned long lastHop = 0;
  byte boilPwr = getBoilPwr();
  boolean doAutoBoil = 1;
  
  encMin = 0;
  encMax = PIDLIMIT_KETTLE;
  encCount = PIDLIMIT_KETTLE;
  byte lastCount = encCount;

  while(1) {
    boolean redraw = 0;
    timerLastWrite = 0;
    clearLCD();
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
    
    while(!preheated || timerValue > 0) {
      if (encCount != lastCount) {
        lastCount = encCount;
        doAutoBoil = 0;
        PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * lastCount;
      }
      
      if (doAutoBoil) {
        if(temp[TS_KETTLE] < setpoint[TS_KETTLE]) PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE;
        else PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * min(boilPwr, PIDLIMIT_KETTLE);
        printLCD_P(3, 14, PSTR("  Auto"));
        encCount = PIDOutput[VS_KETTLE] / PIDCycle[VS_KETTLE] / 10;
        lastCount = encCount;
      } else printLCD_P(3, 14, PSTR("Manual"));

      brewCore();
      #ifdef PREBOIL_ALARM
        if ((triggered ^ 32768) && temp[TS_KETTLE] >= PREBOIL_ALARM) {
          setAlarm(1);
          triggered |= 32768; 
          setABAddsTrig(triggered);
        }
      #endif
     if (alarmStatus) printLCD_P(0, 19, PSTR("!")); else printLCD_P(0, 19, SPACE);
      if (!preheated && temp[TS_KETTLE] >= setpoint[TS_KETTLE] && setpoint[TS_KETTLE] > 0) {
        preheated = 1;
        printLCDRPad(0, 14, "", 6, ' ');
        setTimer(iMins);
      }

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

      //Turn off hop valve profile after 5s
      if (lastHop > 0 && millis() - lastHop > HOPADD_DELAY) {
        if (vlvBits & vlvConfig[VLV_HOPADD]) setValves(vlvBits ^ vlvConfig[VLV_HOPADD]);
        lastHop = 0;
      }

      if (preheated) {
        printTimer(2, 7);
        //Boil Addition
        if ((boilAdds ^ triggered) & 1) {
          setValves(vlvConfig[VLV_HOPADD]);
          lastHop = millis();
          setAlarm(1); 
          triggered |= 1; 
          setABAddsTrig(triggered); 
        }
        //Timed additions (See hoptimes[] array at top of AutoBrew.pde)
        for (byte i = 0; i < 10; i++) {
          if (((boilAdds ^ triggered) & (1<<(i + 1))) && timerValue <= hoptimes[i] * 60000) { 
            setValves(vlvConfig[VLV_HOPADD]);
            lastHop = millis();
            setAlarm(1); 
            triggered |= (1<<(i + 1)); 
            setABAddsTrig(triggered);
          }
        }
        #ifdef AUTO_BOIL_RECIRC
        if (timerValue <= AUTO_BOIL_RECIRC * 60000) setValves(vlvConfig[VLV_BOILRECIRC]);
        #endif
      }

      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (enterStatus == 1 && alarmStatus) {
        enterStatus = 0;
        setAlarm(0);
      } else if (enterStatus == 1) {
        redraw = 1;
        enterStatus = 0;
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
        if (redraw) break;
      }
      if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit() == 1) {
          enterStatus = 2;
          resetOutputs();
          return;
        } 
        redraw = 1;
        break;
      }
    }
    if (!redraw) {
      //Turn off output
      resetOutputs();
      //0 Min Addition
      if ((boilAdds ^ triggered) & 2048) { 
        setValves(vlvConfig[VLV_HOPADD]);
        setAlarm(1);
        triggered |= 2048;
        setABAddsTrig(triggered);
        delay(HOPADD_DELAY);
        setValves(0);
      }
      //Exit
      return;
    }
    encMin = 0;
    encMax = PIDLIMIT_KETTLE;
    encCount = PIDOutput[VS_KETTLE] / PIDCycle[VS_KETTLE] / 10;
    lastCount = encCount;
  }
}

void manChill() {
  while (1) {
    clearLCD();
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
    
    setValves(0);

    encMin = 0;
    encMax = 6;
    encCount = 0;
    int lastCount = 1;
    
    boolean redraw = 0;
    while(!redraw) {
      brewCore();
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
      
      if (chkMsg()) rejectMsg(LOGGLB);
    
      if (enterStatus == 1 && alarmStatus) {
        enterStatus = 0;
        setAlarm(0);
      } else if (enterStatus == 1) {
        autoValve = 0;
        enterStatus = 0;
        if (encCount == 0) {
          resetOutputs();
          return;
        } else if (encCount == 1) setValves(vlvConfig[VLV_CHILLH2O] | vlvConfig[VLV_CHILLBEER]);
        else if (encCount == 2) setValves(vlvConfig[VLV_CHILLH2O]);
        else if (encCount == 3) setValves(vlvConfig[VLV_CHILLBEER]);
        else if (encCount == 4) setValves(0);
        else if (encCount == 5) autoValve = AV_CHILL;
        else if (encCount == 6) {
          if (confirmExit()) {
            resetOutputs();
            enterStatus = 2;
            return;
          } else redraw = 1;
        }
      } else if (enterStatus == 2) {
        enterStatus = 0;
        if (confirmExit()) { 
          resetOutputs();
          enterStatus = 2;
          return;
        } else redraw = 1;
      }
      if (temp[TS_KETTLE] == -1) printLCD_P(1, 0, PSTR("---")); else printLCDLPad(1, 0, itoa(temp[TS_KETTLE], buf, 10), 3, ' ');
      if (temp[TS_BEEROUT] == -1) printLCD_P(2, 0, PSTR("---")); else printLCDLPad(2, 0, itoa(temp[TS_BEEROUT], buf, 10), 3, ' ');
      if (temp[TS_H2OIN] == -1) printLCD_P(1, 16, PSTR("---")); else printLCDLPad(1, 16, itoa(temp[TS_H2OIN], buf, 10), 3, ' ');
      if (temp[TS_H2OOUT] == -1) printLCD_P(2, 16, PSTR("---")); else printLCDLPad(2, 16, itoa(temp[TS_H2OOUT], buf, 10), 3, ' ');

      if ((vlvBits & vlvConfig[VLV_CHILLBEER]) == vlvConfig[VLV_CHILLBEER]) printLCD_P(3, 0, PSTR("On ")); else printLCD_P(3, 0, PSTR("Off"));
      if ((vlvBits & vlvConfig[VLV_CHILLH2O]) == vlvConfig[VLV_CHILLH2O]) printLCD_P(3, 17, PSTR(" On")); else printLCD_P(3, 17, PSTR("Off"));
      
      if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
        if (vlvBits & vlvConfig[VLV_KETTLELID] == 0) setValves(vlvBits | vlvConfig[VLV_KETTLELID]);
      } else {
        if (vlvBits & vlvConfig[VLV_KETTLELID]) setValves(vlvBits ^ vlvConfig[VLV_KETTLELID]);
      }
    }
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

unsigned long calcMashVol(unsigned long grainWeight, unsigned int mashRatio) {
  unsigned long retValue = round(grainWeight * mashRatio / 100.0);
  //Convert qts to gal for US
  #ifndef USEMETRIC
    retValue = round(retValue / 4.0);
  #endif
  return retValue;
}

unsigned long calcSpargeVol(unsigned long batchVol, unsigned int boilMins, unsigned long grainWeight, unsigned int mashRatio) {
  //Detrmine Total Water Needed (Evap + Deadspaces)
  unsigned long retValue = round(batchVol / (1.0 - evapRate / 100.0 * boilMins / 60.0) + volLoss[TS_HLT] + volLoss[TS_MASH]);
  //Add Water Lost in Spent Grain
  #ifdef USEMETRIC
    retValue += round(grainWeight * 1.7884);
  #else
    retValue += round(grainWeight * .2143);
  #endif

  //Subtract mash volume
  retValue -= calcMashVol(grainWeight, mashRatio);
  return retValue;
}
