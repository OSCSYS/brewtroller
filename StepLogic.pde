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

unsigned long lastHop, grainInStart;
unsigned int boilAdds, triggered;

boolean stepIsActive(byte brewStep) {
  if (stepProgram[brewStep] != PROGRAM_IDLE) return true; else return false;
}

boolean zoneIsActive(byte brewZone) {
  if (brewZone == ZONE_MASH) {
    if (stepIsActive(STEP_FILL) 
      || stepIsActive(STEP_DELAY) 
      || stepIsActive(STEP_PREHEAT)
      || stepIsActive(STEP_ADDGRAIN) 
      || stepIsActive(STEP_REFILL)
      || stepIsActive(STEP_DOUGHIN) 
      || stepIsActive(STEP_ACID)
      || stepIsActive(STEP_PROTEIN) 
      || stepIsActive(STEP_SACCH)
      || stepIsActive(STEP_SACCH2) 
      || stepIsActive(STEP_MASHOUT)
      || stepIsActive(STEP_MASHHOLD) 
      || stepIsActive(STEP_SPARGE)
    ) return 1; else return 0;
  } else if (brewZone == ZONE_BOIL) {
    if (stepIsActive(STEP_BOIL) 
      || stepIsActive(STEP_CHILL) 
    ) return 1; else return 0;
  }
}

//Returns 0 if start was successful or 1 if unable to start due to conflict with other step
//Performs any logic required at start of step
//TO DO: Power Loss Recovery Handling
boolean stepInit(byte pgm, byte brewStep) {

  //Nothing more to do if starting 'Idle' program
  if(pgm == PROGRAM_IDLE) return 1;
  
  //Abort Fill/Mash step init if mash Zone is not free
  if (brewStep >= STEP_FILL && brewStep <= STEP_MASHHOLD && zoneIsActive(ZONE_MASH)) return 1;  
  //Abort sparge init if either zone is currently active
  else if (brewStep == STEP_SPARGE && (zoneIsActive(ZONE_MASH) || zoneIsActive(ZONE_BOIL))) return 1;  
  //Allow Boil step init while sparge is still going

  //If we made it without an abort, save the program number for stepCore
  setProgramStep(brewStep, pgm);

  if (brewStep == STEP_FILL) {
  //Step Init: Fill
    //Set Target Volumes
    tgtVol[VS_HLT] = calcSpargeVol(pgm);
    tgtVol[VS_MASH] = calcMashVol(pgm);
    if (getProgMLHeatSrc(pgm) == VS_HLT) {
      tgtVol[VS_HLT] = min(tgtVol[VS_HLT] + tgtVol[VS_MASH], getCapacity(VS_HLT));
      tgtVol[VS_MASH] = 0;
    }
    #ifdef AUTO_FILL_START
      autoValve[AV_FILL] = 1;
    #endif

  } else if (brewStep == STEP_DELAY) {
  //Step Init: Delay
    //Load delay minutes from EEPROM if timer is not already populated via Power Loss Recovery
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getDelayMins());

  } else if (brewStep == STEP_PREHEAT) {
  //Step Init: Preheat
    //Find first temp and adjust for strike temp
    {
      if (getProgMLHeatSrc(pgm) == VS_HLT) {
        setSetpoint(TS_HLT, calcStrikeTemp(pgm));
        #ifdef STRIKE_TEMP_OFFSET
          setSetpoint(TS_HLT, setpoint[TS_HLT] + STRIKE_TEMP_OFFSET;
        #endif
        setSetpoint(TS_MASH, 0);
      } else {
        setSetpoint(TS_HLT, getProgHLT(pgm));
        setSetpoint(TS_MASH, calcStrikeTemp(pgm));
      }
      setSetpoint(VS_STEAM, getSteamTgt());
    }
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //No timer used for preheat
    clearTimer(TIMER_MASH);
    
  } else if (brewStep == STEP_ADDGRAIN) {
  //Step Init: Add Grain
    //Disable HLT and Mash heat output during 'Add Grain' to avoid dry running heat elements and burns from HERMS recirc
    resetHeatOutput(VS_HLT);
    resetHeatOutput(VS_MASH);
    setSetpoint(VS_STEAM, getSteamTgt());
    setValves(vlvConfig[VLV_ADDGRAIN], 1);
    if(getProgMLHeatSrc(pgm) == VS_HLT) {
      unsigned long spargeVol = calcSpargeVol(pgm);
      unsigned long mashVol = calcMashVol(pgm);
      tgtVol[VS_HLT] = (min(spargeVol + mashVol, getCapacity(VS_HLT))) - spargeVol;
      #ifdef AUTO_ML_XFER
         autoValve[AV_SPARGEIN] = 1;
      #endif
    }
  } else if (brewStep == STEP_REFILL) {
  //Step Init: Refill
    if (getProgMLHeatSrc(pgm) == VS_HLT) {
      tgtVol[VS_HLT] = calcSpargeVol(pgm);
      tgtVol[VS_MASH] = 0;
    }

  } else if (brewStep == STEP_DOUGHIN) {
  //Step Init: Dough In
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_DOUGHIN));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_DOUGHIN)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_ACID) {
  //Step Init: Acid Rest
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_ACID));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_ACID)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_PROTEIN) {
  //Step Init: Protein
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_PROTEIN));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_PROTEIN)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_SACCH) {
  //Step Init: Sacch
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_SACCH));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_SACCH)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_SACCH2) {
  //Step Init: Sacch2
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_SACCH2));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_SACCH2)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_MASHOUT) {
  //Step Init: Mash Out
    setSetpoint(TS_HLT, getProgHLT(pgm));
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_MASHOUT));
    setSetpoint(VS_STEAM, getSteamTgt());
    preheated[VS_MASH] = 0;
    autoValve[AV_MASH] = 1;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_MASHOUT)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_MASHHOLD) {
    //Set HLT to Sparge Temp
    setSetpoint(TS_HLT, getProgSparge(pgm));
    //Cycle through steps and use last non-zero step for mash setpoint
    if (!setpoint[TS_MASH]) {
      byte i = MASH_MASHOUT;
      while (setpoint[TS_MASH] == 0 && i >= MASH_DOUGHIN && i <= MASH_MASHOUT) setSetpoint(TS_MASH, getProgMashTemp(pgm, i--));
    }
    setSetpoint(VS_STEAM, getSteamTgt());

  } else if (brewStep == STEP_SPARGE) {
  //Step Init: Sparge
    #ifdef BATCH_SPARGE
    
    #else
      tgtVol[VS_KETTLE] = calcPreboilVol(pgm);
      #ifdef AUTO_SPARGE_START
        autoValve[AV_FLYSPARGE] = 1;
      #endif
    #endif

  } else if (brewStep == STEP_BOIL) {
  //Step Init: Boil
    setSetpoint(VS_KETTLE, getBoilTemp());
    preheated[VS_KETTLE] = 0;
    boilAdds = getProgAdds(pgm);
    
    //Set timer only if empty (for purposes of power loss recovery)
    if (!timerValue[TIMER_BOIL]) {
      //Clean start of Boil
      setTimer(TIMER_BOIL, getProgBoil(pgm));
      triggered = 0;
      setBoilAddsTrig(triggered);
    } else {
      //Assuming power loss recovery
      triggered = getBoilAddsTrig();
    }
    //Leave timer paused until preheated
    timerStatus[TIMER_BOIL] = 0;
    lastHop = 0;
    doAutoBoil = 1;
    
  } else if (brewStep == STEP_CHILL) {
  //Step Init: Chill
  }

  //Call event handler
  eventHandler(EVENT_STEPINIT, brewStep);  
  return 0;
}

void stepCore() {
  if (stepIsActive(STEP_FILL)) stepFill(STEP_FILL);

  if (stepIsActive(STEP_PREHEAT)) {
    if ((setpoint[VS_MASH] && temp[VS_MASH] >= setpoint[VS_MASH])
      || (!setpoint[VS_MASH] && temp[VS_HLT] >= setpoint[VS_HLT])
    ) stepAdvance(STEP_PREHEAT);
  }

  if (stepIsActive(STEP_DELAY)) if (timerValue[TIMER_MASH] == 0) stepAdvance(STEP_DELAY);

  if (stepIsActive(STEP_ADDGRAIN)) {
    #ifdef AUTO_GRAININ_EXIT
      if(!autoValve[AV_SPARGEIN]) {
        if (!grainInStart) grainInStart = millis();
        else if ((millis() - grainInStart) / 1000 > AUTO_GRAININ_EXIT) stepAdvance(STEP_ADDGRAIN);
      } 
    #endif
    //Turn off Sparge In AutoValve if tgtVol has been reached
    if (autoValve[AV_SPARGEIN] && volAvg[VS_HLT] <= tgtVol[VS_HLT]) autoValve[AV_SPARGEIN] = 0;
  }

  if (stepIsActive(STEP_REFILL)) stepFill(STEP_REFILL);

  for (byte brewStep = STEP_DOUGHIN; brewStep <= STEP_MASHOUT; brewStep++) if (stepIsActive(brewStep)) stepMash(brewStep);
  
  if (stepIsActive(STEP_MASHHOLD)) {
    #ifdef SMART_HERMS_HLT
      smartHERMSHLT();
    #endif
    #ifdef AUTO_MASH_HOLD_EXIT
      if (!zoneIsActive(ZONE_BOIL)) stepAdvance(STEP_MASHHOLD);
    #endif
  }
  
  if (stepIsActive(STEP_SPARGE)) { 
    #ifdef BATCH_SPARGE
    
    #else
      #ifdef AUTO_SPARGE_EXIT
         if (volAvg[VS_KETTLE] >= tgtVol[VS_KETTLE]) stepAdvance(STEP_SPARGE);
      #endif
    #endif
  }
  
  if (stepIsActive(STEP_BOIL)) {
    if (doAutoBoil) {
      if(temp[TS_KETTLE] < setpoint[TS_KETTLE]) PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE;
      else PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * min(boilPwr, PIDLIMIT_KETTLE);
    }
    #ifdef PREBOIL_ALARM
      if (!(triggered & 32768) && temp[TS_KETTLE] >= PREBOIL_ALARM) {
        setAlarm(1);
        triggered |= 32768; 
        setBoilAddsTrig(triggered);
      }
    #endif
    if (!preheated[VS_KETTLE] && temp[TS_KETTLE] >= setpoint[VS_KETTLE] && setpoint[VS_KETTLE] > 0) {
      preheated[VS_KETTLE] = 1;
      //Unpause Timer
      if (!timerStatus[TIMER_BOIL]) pauseTimer(TIMER_BOIL);
    }
    //Turn off hop valve profile after 5s
    if ((vlvConfigIsActive(VLV_HOPADD)) && lastHop > 0 && millis() - lastHop > HOPADD_DELAY) {
      setValves(vlvConfig[VLV_HOPADD], 0);
      lastHop = 0;
    }
    if (preheated[VS_KETTLE]) {
      //Boil Addition
      if ((boilAdds ^ triggered) & 1) {
        setValves(vlvConfig[VLV_HOPADD], 1);
        lastHop = millis();
        setAlarm(1); 
        triggered |= 1; 
        setBoilAddsTrig(triggered); 
      }
      //Timed additions (See hoptimes[] array at top of AutoBrew.pde)
      for (byte i = 0; i < 10; i++) {
        if (((boilAdds ^ triggered) & (1<<(i + 1))) && timerValue[TIMER_BOIL] <= hoptimes[i] * 60000) { 
          setValves(vlvConfig[VLV_HOPADD], 1);
          lastHop = millis();
          setAlarm(1); 
          triggered |= (1<<(i + 1)); 
          setBoilAddsTrig(triggered);
        }
      }
      #ifdef AUTO_BOIL_RECIRC
      if (timerValue[TIMER_BOIL] <= AUTO_BOIL_RECIRC * 60000) setValves(vlvConfig[VLV_BOILRECIRC], 1);
      #endif
    }
    //Exit Condition  
    if(preheated[VS_KETTLE] && timerValue[TIMER_BOIL] == 0) stepAdvance(STEP_BOIL);
  }
  
  if (stepIsActive(STEP_CHILL)) {
    if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
      if (!vlvConfigIsActive(VLV_KETTLELID)) setValves(vlvConfig[VLV_KETTLELID], 1);
    } else {
      if (vlvConfigIsActive(VLV_KETTLELID)) setValves(vlvConfig[VLV_KETTLELID], 0);
    }
  }
}

//stepCore logic for Fill and Refill
void stepFill(byte brewStep) {
  #ifdef AUTO_FILL_EXIT
    if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) stepAdvance(brewStep);
  #endif
}

//stepCore Logic for all mash steps
void stepMash(byte brewStep) {
  #ifdef SMART_HERMS_HLT
    smartHERMSHLT();
  #endif
  if (!preheated[VS_MASH] && temp[TS_MASH] >= setpoint[VS_MASH]) {
    preheated[VS_MASH] = 1;
    //Unpause Timer
    if (!timerStatus[TIMER_MASH]) pauseTimer(TIMER_MASH);
  }
  //Exit Condition (and skip unused mash steps)
  if (setpoint[VS_MASH] == 0 || (preheated[VS_MASH] && timerValue[TIMER_MASH] == 0)) stepAdvance(brewStep);
}

//Advances program to next brew step
//Returns 0 if successful or 1 if unable to advance due to conflict with another step
boolean stepAdvance(byte brewStep) {
  //Save program for next step/rollback
  byte program = stepProgram[brewStep];
  stepExit(brewStep);
  //Advance step (if applicable)
  if (brewStep + 1 < NUM_BREW_STEPS) {
    if (stepInit(program, brewStep + 1)) {
      //Init Failed: Rollback
      stepExit(brewStep + 1); //Just to make sure we clean up a partial start
      setProgramStep(program, brewStep); //Show the step we started with as active
      return 1;
    }
    //Init Successful
    return 0;
  }
}

//Performs exit logic specific to each step
//Note: If called directly (as opposed through stepAdvance) acts as a program abort
void stepExit(byte brewStep) {
  //Mark step idle
  setProgramStep(brewStep, PROGRAM_IDLE);
  
  //Perform step closeout functions
  if (brewStep == STEP_FILL || brewStep == STEP_REFILL) {
  //Step Exit: Fill/Refill
    tgtVol[VS_HLT] = 0;
    tgtVol[VS_MASH] = 0;
    autoValve[AV_FILL] = 0;
    setValves(vlvConfig[VLV_FILLHLT], 0);
    setValves(vlvConfig[VLV_FILLMASH], 0);

  } else if (brewStep == STEP_DELAY) {
  //Step Exit: Delay
    clearTimer(TIMER_MASH);
  
  } else if (brewStep == STEP_ADDGRAIN) {
  //Step Exit: Add Grain
    tgtVol[VS_HLT] = 0;
    autoValve[AV_SPARGEIN] = 0;
    setValves(vlvConfig[VLV_ADDGRAIN], 0);
    setValves(vlvConfig[VLV_SPARGEIN], 0);
    setValves(vlvConfig[VLV_MASHHEAT], 0);
    setValves(vlvConfig[VLV_MASHIDLE], 0);
    resetHeatOutput(VS_HLT);
#ifdef USESTEAM
    resetHeatOutput(VS_STEAM);
#endif

  } else if (brewStep == STEP_PREHEAT || (brewStep >= STEP_DOUGHIN && brewStep <= STEP_MASHHOLD)) {
  //Step Exit: Preheat/Mash
    clearTimer(TIMER_MASH);
    autoValve[AV_MASH] = 0;
    setValves(vlvConfig[VLV_MASHHEAT], 0);    
    setValves(vlvConfig[VLV_MASHIDLE], 0);   
    resetHeatOutput(VS_HLT);
    resetHeatOutput(VS_MASH);
#ifdef USESTEAM
    resetHeatOutput(VS_STEAM);
#endif

  } else if (brewStep == STEP_SPARGE) {
  //Step Exit: Sparge
    tgtVol[VS_HLT] = 0;
    tgtVol[VS_KETTLE] = 0;
    autoValve[AV_SPARGEIN] = 0;
    autoValve[AV_SPARGEOUT] = 0;
    autoValve[AV_FLYSPARGE] = 0;
    setValves(vlvConfig[VLV_MASHHEAT], 0);
    setValves(vlvConfig[VLV_MASHIDLE], 0);
    setValves(vlvConfig[VLV_SPARGEIN], 0);
    setValves(vlvConfig[VLV_SPARGEOUT], 0);    

  } else if (brewStep == STEP_BOIL) {
  //Step Exit: Boil
    //0 Min Addition
    if ((boilAdds ^ triggered) & 2048) { 
      setValves(vlvConfig[VLV_HOPADD], 1);
      setAlarm(1);
      triggered |= 2048;
      setBoilAddsTrig(triggered);
      delay(HOPADD_DELAY);
    }
    setValves(vlvConfig[VLV_HOPADD], 0);
    #ifdef AUTO_BOIL_RECIRC
      setValves(vlvConfig[VLV_BOILRECIRC], 0);
    #endif
    resetHeatOutput(VS_KETTLE);
    clearTimer(TIMER_BOIL);
  } else if (brewStep == STEP_CHILL) {
  //Step Exit: Chill
    autoValve[AV_CHILL] = 0;
    setValves(vlvConfig[VLV_CHILLBEER], 0);    
    setValves(vlvConfig[VLV_CHILLH2O], 0);  
  }
}

#ifdef SMART_HERMS_HLT
void smartHERMSHLT() {
  if (setpoint[VS_MASH] != 0) setpoint[VS_HLT] = constrain(setpoint[VS_MASH] * 2 - temp[TS_MASH], setpoint[VS_MASH] + MASH_HEAT_LOSS, HLT_MAX_TEMP);
}
#endif
  
unsigned long calcMashVol(byte pgm) {
  unsigned long retValue = round(getProgGrain(pgm) * getProgRatio(pgm) / 100.0);
  //Convert qts to gal for US
  #ifndef USEMETRIC
    retValue = round(retValue / 4.0);
  #endif
  return retValue;
}

unsigned long calcSpargeVol(byte pgm) {
  //Determine Total Water Needed (Evap + Deadspaces)
  unsigned long retValue = calcPreboilVol(pgm);

  //Add Water Lost in Spent Grain
  retValue += calcGrainLoss(pgm);

  //Subtract mash volume
  retValue -= calcMashVol(pgm);
  return retValue;
}

unsigned long calcPreboilVol(byte pgm) {
  return round(getProgBatchVol(pgm) / (1.0 - getEvapRate() / 100.0 * getProgBoil(pgm) / 60.0) + getVolLoss(TS_HLT) + getVolLoss(TS_MASH));
}

unsigned long calcGrainLoss(byte pgm) {
  #ifdef USEMETRIC
    return round(getProgGrain(pgm) * 1.7884);
  #else
    return round(getProgGrain(pgm) * .2143);
  #endif
}

unsigned long calcGrainVolume(byte pgm) {
  //Grain-to-volume factor for mash tun capacity
  //Conservatively 1 lb = 0.15 gal 
  //Aggressively 1 lb = 0.093 gal
  #ifdef USEMETRIC
    #define GRAIN2VOL 1.25
  #else
    #define GRAIN2VOL 0.15
  #endif
  return round (getProgGrain(pgm) * GRAIN2VOL);
}

byte calcStrikeTemp(byte pgm) {
  byte strikeTemp = 0;
  byte i = MASH_DOUGHIN;
  while (strikeTemp == 0 && i <= MASH_MASHOUT) strikeTemp = getProgMashTemp(pgm, i++);
  #ifdef USEMETRIC
    return strikeTemp + round(.4 * (strikeTemp - getGrainTemp()) / (getProgRatio(pgm) / 100.0)) + 1.7;
  #else
    return strikeTemp + round(.192 * (strikeTemp - getGrainTemp()) / (getProgRatio(pgm) / 100.0)) + 3;
  #endif
}
