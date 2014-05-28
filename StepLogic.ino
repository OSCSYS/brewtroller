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
unsigned long lastHop, grainInStart;
unsigned int boilAdds, triggered;

/**
 * Used to determine if the given step is the active step in the program.
 */
boolean stepIsActive(byte brewStep) {
  if (stepProgram[brewStep] != PROGRAM_IDLE)
    return true; 
  return false;
}

/**
 * Usd to determine if the given ZONE is the active ZONE in the program.
 * Returns true is any step in the given ZONE is the active step, false otherwise.
 */
boolean zoneIsActive(byte brewZone) {
  switch (brewZone) {
    case ZONE_MASH:
      if (stepIsActive(BREWSTEP_FILL) 
        || stepIsActive(BREWSTEP_DELAY) 
        || stepIsActive(BREWSTEP_PREHEAT)
        || stepIsActive(BREWSTEP_GRAININ) 
        || stepIsActive(BREWSTEP_REFILL)
        || stepIsActive(BREWSTEP_DOUGHIN) 
        || stepIsActive(BREWSTEP_ACID)
        || stepIsActive(BREWSTEP_PROTEIN) 
        || stepIsActive(BREWSTEP_SACCH)
        || stepIsActive(BREWSTEP_SACCH2) 
        || stepIsActive(BREWSTEP_MASHOUT)
        || stepIsActive(BREWSTEP_MASHHOLD) 
        || stepIsActive(BREWSTEP_SPARGE)
      )
        return 1; 
      else
        return 0;
    case ZONE_BOIL:
      if (stepIsActive(BREWSTEP_BOIL) 
        || stepIsActive(BREWSTEP_CHILL) 
      )
        return 1;
      else return 0;
  }
}

//Returns 0 if start was successful or 1 if unable to start due to conflict with other step
//Performs any logic required at start of step
boolean brewStepInit(byte recipe, byte brewStep) {

  //Nothing more to do if starting 'Idle' program
  if(recipe == PROGRAM_IDLE) return 1;
  
  //Abort Fill/Mash step init if mash Zone is not free
  if (brewStep >= BREWSTEP_FILL && brewStep <= BREWSTEP_MASHHOLD && zoneIsActive(ZONE_MASH)) return 1;  
  //Abort sparge init if either zone is currently active
  else if (brewStep == BREWSTEP_SPARGE && (zoneIsActive(ZONE_MASH) || zoneIsActive(ZONE_BOIL))) return 1;  
  //Allow Boil step init while sparge is still going

  //If we made it without an abort, save the program number for stepCore
  setProgramStep(brewStep, recipe);
  brewStepSignal(brewStep, STEPSIGNAL_INIT);
  
  //Call event handler
  eventHandler(EVENT_STEPINIT, brewStep);  
  return 0;
}

void brewStepUpdate() {
  for (byte i = 0; i < BREWSTEP_COUNT; i++)
    if (stepProgram[i] != PROGRAM_IDLE)
      brewStepSignal(i, STEPSIGNAL_UPDATE);
}

boolean brewStepAdvance(byte brewStep) {
  //Save program for next step/rollback
  byte recipe = stepProgram[brewStep];
  brewStepExit(brewStep);
  //Advance step (if applicable)
  if (brewStep + 1 < BREWSTEP_COUNT) {
    if (brewStepInit(recipe, brewStep + 1)) {
      //Init Failed: Rollback
      brewStepExit(brewStep + 1);
      setProgramStep(recipe, brewStep); //Show the step we started with as active
      return 1;
    }
  }
  //Init Successful
  return 0;
}

void brewStepExit(byte brewStep) {
  //Mark step idle
  setProgramStep(brewStep, PROGRAM_IDLE);
  brewStepSignal(brewStep, STEPSIGNAL_EXIT);
  eventHandler(EVENT_STEPEXIT, brewStep);  
}

void (*brewStepFunc(byte brewStep))(enum StepSignal) {
  static void (*brewStepFunctionMap[BREWSTEP_COUNT])(enum StepSignal) = {
    &brewStepFill,
    &brewStepDelay,
    &brewStepPreheat,
    &brewStepGrainIn,
    &brewStepRefill,
    &brewStepDoughIn,
    &brewStepAcid,
    &brewStepProtein,
    &brewStepSacch,
    &brewStepSacch2,
    &brewStepMashOut,
    &brewStepMashHold,
    &brewStepSparge,
    &brewStepBoil,
    &brewStepChill
  };
  
  if (brewStep < BREWSTEP_COUNT)
    return brewStepFunctionMap[brewStep];
  return 0;
}

void brewStepSignal(byte brewStep, enum StepSignal signal) {
  void (*stepFunc)(enum StepSignal) = brewStepFunc(brewStep);
  if (stepFunc)
    (*stepFunc)(signal);
}

void brewStepFill(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      tgtVol[VS_HLT] = calcSpargeVol(stepProgram[BREWSTEP_FILL]);
      tgtVol[VS_MASH] = calcStrikeVol(stepProgram[BREWSTEP_FILL]);
      if (getProgMLHeatSrc(stepProgram[BREWSTEP_FILL]) == VS_HLT) {
        tgtVol[VS_HLT] = min(tgtVol[VS_HLT] + tgtVol[VS_MASH], getCapacity(VS_HLT));
        tgtVol[VS_MASH] = 0;
      }
      #ifdef AUTO_FILL_START
      autoValve[AV_FILL] = 1;
      #endif
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef AUTO_FILL_EXIT
        if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) brewStepAdvance(brewStep);
      #else
        #ifndef VOLUME_MANUAL
          if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) bitClear(actProfiles, VLV_FILLHLT);
        #endif
      #endif
      break;
    case STEPSIGNAL_EXIT: 
      tgtVol[VS_HLT] = 0;
      tgtVol[VS_MASH] = 0;
      autoValve[AV_FILL] = 0;
      bitClear(actProfiles, VLV_FILLHLT);
      bitClear(actProfiles, VLV_FILLMASH);
      break;
  }
}

void brewStepDelay(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      //Load delay minutes from EEPROM if timer is not already populated via Power Loss Recovery
      if (getDelayMins() && !timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getDelayMins());
      break;
    case STEPSIGNAL_UPDATE:
      if (timerValue[TIMER_MASH] == 0)
        brewStepAdvance(BREWSTEP_DELAY);
      break;
    case STEPSIGNAL_EXIT:
      clearTimer(TIMER_MASH);
      setAlarm(0);
      break;
  }
}

void brewStepPreheat(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      #ifdef MASH_PREHEAT_NOVALVES
        vlvConfig[VLV_MASHHEAT] = 0;
        vlvConfig[VLV_MASHIDLE] = 0;
      #endif
  
      if (getProgMLHeatSrc(stepProgram[BREWSTEP_PREHEAT]) == VS_HLT) {
        setSetpoint(TS_HLT, calcStrikeTemp(stepProgram[BREWSTEP_PREHEAT]));
        
        #ifdef MASH_PREHEAT_STRIKE
          setSetpoint(TS_MASH, calcStrikeTemp(stepProgram[BREWSTEP_PREHEAT]));
        #elif defined MASH_PREHEAT_STEP1
          setSetpoint(TS_MASH, getFirstStepTemp(stepProgram[BREWSTEP_PREHEAT]));
        #else
          setSetpoint(TS_MASH, 0);
        #endif        
      } else {
        setSetpoint(TS_HLT, getProgHLT(stepProgram[BREWSTEP_PREHEAT]));
        setSetpoint(TS_MASH, calcStrikeTemp(stepProgram[BREWSTEP_PREHEAT]));
      }
      
      #ifndef PID_FLOW_CONTROL
      setSetpoint(VS_STEAM, getSteamTgt());
      #endif
      preheated[VS_HLT] = 0;
      preheated[VS_MASH] = 0;
      //No timer used for preheat
      clearTimer(TIMER_MASH);
      #ifdef MASH_PREHEAT_SENSOR
        //Overwrite mash temp sensor address from EEPROM using the memory location of the specified sensor (sensor element number * 8 bytes)
        EEPROMreadBytes(MASH_PREHEAT_SENSOR * 8, tSensor[TS_MASH], 8);
      #endif
      break;
    case STEPSIGNAL_UPDATE:
      if ((setpoint[VS_MASH] && temp[VS_MASH] >= setpoint[VS_MASH])
        || (!setpoint[VS_MASH] && temp[VS_HLT] >= setpoint[VS_HLT])
      ) brewStepAdvance(BREWSTEP_PREHEAT);
      #if defined SMART_HERMS_HLT && defined SMART_HERMS_PREHEAT
        smartHERMSHLT();
      #endif
      break;
    case STEPSIGNAL_EXIT:
      clearTimer(TIMER_MASH);
      bitClear(actProfiles, VLV_MASHHEAT);    
      bitClear(actProfiles, VLV_MASHIDLE);
      resetHeatOutput(VS_HLT);
      resetHeatOutput(VS_MASH);
      #ifdef USESTEAM
        resetHeatOutput(VS_STEAM);
      #endif
      #ifdef MASH_PREHEAT_SENSOR
      //Restore mash temp sensor address from EEPROM (address 8)
        EEPROMreadBytes(8, tSensor[TS_MASH], 8);
      #endif
      #ifdef MASH_PREHEAT_NOVALVES
        loadVlvConfigs();
      #endif
      break;
  }
}

void brewStepGrainIn(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      //Disable HLT and Mash heat output during 'Add Grain' to avoid dry running heat elements and burns from HERMS recirc
      resetHeatOutput(VS_HLT);
      resetHeatOutput(VS_MASH);
      #ifndef PID_FLOW_CONTROL
      setSetpoint(VS_STEAM, getSteamTgt());
      #endif
      setAlarm(1);
      bitSet(actProfiles, VLV_ADDGRAIN);
      if(getProgMLHeatSrc(stepProgram[BREWSTEP_GRAININ]) == VS_HLT) {
        unsigned long spargeVol = calcSpargeVol(stepProgram[BREWSTEP_GRAININ]);
        unsigned long mashVol = calcStrikeVol(stepProgram[BREWSTEP_GRAININ]);
        tgtVol[VS_HLT] = (min((spargeVol + mashVol), getCapacity(VS_HLT)) - mashVol);
        #ifdef VOLUME_MANUAL
          // In manual volume mode show the target mash volume as a guide to the user
          tgtVol[VS_MASH] = mashVol;
        #endif
        #ifdef AUTO_ML_XFER
           autoValve[AV_SPARGEIN] = 1;
        #endif
      }
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef AUTO_GRAININ_EXIT
        if(!autoValve[AV_SPARGEIN]) {
          if (!grainInStart) grainInStart = millis();
          else if ((millis() - grainInStart) / 1000 > AUTO_GRAININ_EXIT) brewStepAdvance(BREWSTEP_ADDGRAIN);
        } 
      #endif
      //Turn off Sparge In AutoValve if tgtVol has been reached
      //Because this function is called before processautovalves() if we clear the auto valve here the bit in the active profile will still be set until the
      // user exits the grain in step, causing it to not shut off when target volume is reached. 
      if (autoValve[AV_SPARGEIN] && volAvg[VS_HLT] <= tgtVol[VS_HLT]) { autoValve[AV_SPARGEIN] = 0; bitClear(actProfiles, VLV_SPARGEIN);}
      else if (volAvg[VS_HLT] <= tgtVol[VS_HLT]) bitClear(actProfiles, VLV_SPARGEIN);
      break;
    case STEPSIGNAL_EXIT:
      tgtVol[VS_HLT] = 0;
      autoValve[AV_SPARGEIN] = 0;
      bitClear(actProfiles, VLV_ADDGRAIN);
      bitClear(actProfiles, VLV_SPARGEIN);
      bitClear(actProfiles, VLV_MASHHEAT);
      bitClear(actProfiles, VLV_MASHIDLE);
      resetHeatOutput(VS_HLT);
      #ifdef USESTEAM
        resetHeatOutput(VS_STEAM);
      #endif
      break;
  }
}

void brewStepRefill(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      if (getProgMLHeatSrc(stepProgram[BREWSTEP_REFILL]) == VS_HLT) {
      #ifdef HLT_MIN_REFILL
        SpargeVol = calcSpargeVol(stepProgram[BREWSTEP_REFILL]);
        tgtVol[VS_HLT] = max(SpargeVol, HLT_MIN_REFILL_VOL);
      #else
        tgtVol[VS_HLT] = calcSpargeVol(stepProgram[BREWSTEP_REFILL]);
      #endif
        tgtVol[VS_MASH] = 0;
      }
      #ifdef AUTO_REFILL_START
      autoValve[AV_FILL] = 1;
      #endif
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef AUTO_FILL_EXIT
        if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) brewStepAdvance(brewStep);
      #else
        #ifndef VOLUME_MANUAL
          if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) bitClear(actProfiles, VLV_FILLHLT);
        #endif
      #endif
      break;
    case STEPSIGNAL_EXIT:
      tgtVol[VS_HLT] = 0;
      tgtVol[VS_MASH] = 0;
      autoValve[AV_FILL] = 0;
      bitClear(actProfiles, VLV_FILLHLT);
      bitClear(actProfiles, VLV_FILLMASH);
      break;
  }
}

void brewStepMashHelper(byte mashStep, enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      setSetpoint(TS_HLT, getProgHLT(stepProgram[BREWSTEP_DOUGHIN + mashStep]));
      #ifdef RIMS_MLT_SETPOINT_DELAY
        starttime = millis(); // get current time
        timetoset = starttime + RIMS_DELAY; //note that overflow of the milisecond timer is not covered here 
        steptoset = BREWSTEP_DOUGHIN + mashStep; //step that we need to set the setpoint to after the timer is done. 
        RIMStimeExpired = 0; //reset the boolean so that we know if the timer has expired for this program or not
        autoValve[vesselAV(TS_MASH)] = 1; // turn on the mash recirc valve profile as if the setpoint had been set
      #else
        setSetpoint(TS_MASH, getProgMashTemp(stepProgram[BREWSTEP_DOUGHIN + mashStep], mashStep));
      #endif
      
      #ifndef PID_FLOW_CONTROL
      setSetpoint(VS_STEAM, getSteamTgt());
      #endif
      preheated[VS_MASH] = 0;
      //Set timer only if empty (for purposes of power loss recovery)
      if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(stepProgram[BREWSTEP_DOUGHIN + mashStep], mashStep)); 
      //Leave timer paused until preheated
      timerStatus[TIMER_MASH] = 0;
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef SMART_HERMS_HLT
        smartHERMSHLT();
      #endif
      if (!preheated[VS_MASH] && temp[TS_MASH] >= setpoint[VS_MASH]) {
        preheated[VS_MASH] = 1;
        //Unpause Timer
        if (!timerStatus[TIMER_MASH]) pauseTimer(TIMER_MASH);
      }
      //Exit Condition (and skip unused mash steps)
      #ifdef RIMS_MLT_SETPOINT_DELAY
        if (getProgMashTemp(stepProgram[BREWSTEP_DOUGHIN + mashStep], mashStep) == 0 || (preheated[VS_MASH] && timerValue[TIMER_MASH] == 0)) brewStepAdvance(BREWSTEP_DOUGHIN + mashStep);
      #else
        if (setpoint[VS_MASH] == 0 || (preheated[VS_MASH] && timerValue[TIMER_MASH] == 0)) brewStepAdvance(BREWSTEP_DOUGHIN + mashStep);
      #endif
      break;
    case STEPSIGNAL_EXIT:
      clearTimer(TIMER_MASH);
      bitClear(actProfiles, VLV_MASHHEAT);    
      bitClear(actProfiles, VLV_MASHIDLE);
      resetHeatOutput(VS_HLT);
      resetHeatOutput(VS_MASH);
      #ifdef USESTEAM
        resetHeatOutput(VS_STEAM);
      #endif
      #ifdef MASH_PREHEAT_SENSOR
      //Restore mash temp sensor address from EEPROM (address 8)
        EEPROMreadBytes(8, tSensor[TS_MASH], 8);
      #endif
      #ifdef MASH_PREHEAT_NOVALVES
        loadVlvConfigs();
      #endif
      break;
  }  
}

void brewStepDoughIn(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_DOUGHIN, signal);
}

void brewStepAcid(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_ACID, signal);
}

void brewStepProtein(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_PROTEIN, signal);
}

void brewStepSacch(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_SACCH, signal);
}

void brewStepSacch2(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_SACCH2, signal);
}

void brewStepMashOut(enum StepSignal signal) {
  brewStepMashHelper(MASHSTEP_MASHOUT, signal);
}

void brewStepMashHold(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      setAlarm(1);
      //Set HLT to Sparge Temp
      setSetpoint(TS_HLT, getProgSparge(stepProgram[BREWSTEP_MASHHOLD]));
      //Cycle through steps and use last non-zero step for mash setpoint
      if (!setpoint[TS_MASH]) {
        byte i = MASHSTEP_MASHOUT;
        while (setpoint[TS_MASH] == 0 && i >= MASHSTEP_DOUGHIN && i <= MASHSTEP_MASHOUT) setSetpoint(TS_MASH, getProgMashTemp(stepProgram[BREWSTEP_MASHHOLD], i--));
      }
      #ifndef PID_FLOW_CONTROL
        setSetpoint(VS_STEAM, getSteamTgt());
      #endif
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef AUTO_MASH_HOLD_EXIT 
        if (!zoneIsActive(ZONE_BOIL) && temp[VS_HLT] >= setpoint[VS_HLT]) brewStepAdvance(BREWSTEP_MASHHOLD);
      #endif
      break;
    case STEPSIGNAL_EXIT:
      break;
  }
}

void brewStepSparge(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      #ifdef HLT_HEAT_SPARGE
        #ifdef HLT_MIN_SPARGE
          if (volAvg[VS_HLT] >= HLT_MIN_SPARGE)
        #endif
            setSetpoint(TS_HLT, getProgSparge(stepProgram[BREWSTEP_SPARGE]));
      #endif
      
      #ifdef BATCH_SPARGE
        
      #else
          #ifdef SPARGE_IN_PUMP_CONTROL
          prevSpargeVol[1] = volAvg[VS_HLT]; // init the value at the start of sparge
          prevSpargeVol[0] = 0;
          #endif
        tgtVol[VS_KETTLE] = calcPreboilVol(stepProgram[BREWSTEP_SPARGE]);
        #ifdef AUTO_SPARGE_START
          autoValve[AV_FLYSPARGE] = 1;
        #endif
        #ifdef PID_FLOW_CONTROL
        #ifdef USEMETRIC
        // value is given in 10ths of a liter per min, so 1 liter/min would be 10, and 10 * 100 = 1000 which is 1 liter/min in flow rate calcs
        setSetpoint(VS_PUMP, (getSteamTgt() * 100));
        #else
        //value is given in 10ths of a quart per min, so 1 quart/min would be 10, and 10 *25 = 250 which is 1 quart/min in flow rate calcs (1000ths of a gallon/min)
        setSetpoint(VS_PUMP, getSteamTgt()* 25);
        #endif
        #endif
      #endif
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef HLT_HEAT_SPARGE
        #ifdef HLT_MIN_SPARGE
          if (volAvg[VS_HLT] < HLT_MIN_SPARGE) setSetpoint(TS_HLT, 0);
        #endif
      #endif
      
      #ifdef BATCH_SPARGE
      
      #else
        #ifdef AUTO_SPARGE_EXIT
           if (volAvg[VS_KETTLE] >= tgtVol[VS_KETTLE]) brewStepAdvance(BREWSTEP_SPARGE);
        #endif
      #endif
      break;
    case STEPSIGNAL_EXIT:
      #ifdef HLT_HEAT_SPARGE
        setSetpoint(TS_HLT, 0);
      #endif
      tgtVol[VS_HLT] = 0;
      tgtVol[VS_KETTLE] = 0;
      resetSpargeValves();
      break;
  }
}

void brewStepBoil(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      #ifdef PID_FLOW_CONTROL
      resetHeatOutput(VS_PUMP); // turn off the pump if we are moving to boil. 
      #endif
          setSetpoint(VS_KETTLE, getBoilTemp());
      preheated[VS_KETTLE] = 0;
      boilAdds = getProgAdds(stepProgram[BREWSTEP_BOIL]);
      
      //Set timer only if empty (for purposes of power loss recovery)
      if (!timerValue[TIMER_BOIL]) {
        //Clean start of Boil
        setTimer(TIMER_BOIL, getProgBoil(stepProgram[BREWSTEP_BOIL]));
        triggered = 0;
        setBoilAddsTrig(triggered);
      } else {
        //Assuming power loss recovery
        triggered = getBoilAddsTrig();
      }
      //Leave timer paused until preheated
      timerStatus[TIMER_BOIL] = 0;
      lastHop = 0;
      boilControlState = CONTROLSTATE_AUTO;
      break;
    case STEPSIGNAL_UPDATE:
      #ifdef PREBOIL_ALARM
        if (!(triggered & 32768) && temp[TS_KETTLE] != BAD_TEMP && temp[TS_KETTLE] >= PREBOIL_ALARM * 100) {
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
      if (lastHop > 0 && millis() - lastHop > HOPADD_DELAY) {
        bitClear(actProfiles, VLV_HOPADD);
        lastHop = 0;
      }
      if (preheated[VS_KETTLE]) {
        //Boil Addition
        if ((boilAdds ^ triggered) & 1) {
          bitSet(actProfiles, VLV_HOPADD);
          lastHop = millis();
          setAlarm(1); 
          triggered |= 1; 
          setBoilAddsTrig(triggered); 
        }
        //Timed additions (See hoptimes[] array in BrewTroller.pde)
        for (byte i = 0; i < 11; i++) {
          if (((boilAdds ^ triggered) & (1<<(i + 1))) && timerValue[TIMER_BOIL] <= hoptimes[i] * 60000) { 
            bitSet(actProfiles, VLV_HOPADD);
            lastHop = millis();
            setAlarm(1); 
            triggered |= (1<<(i + 1)); 
            setBoilAddsTrig(triggered);
          }
        }
        
        #ifdef AUTO_BOIL_RECIRC
        if (timerValue[TIMER_BOIL] <= AUTO_BOIL_RECIRC * 60000) bitSet(actProfiles, VLV_BOILRECIRC);
        #endif
      }
      //Exit Condition  
      if(preheated[VS_KETTLE] && timerValue[TIMER_BOIL] == 0) {
        //Kill Kettle power at end of timer...
        boilControlState = CONTROLSTATE_OFF;
        resetHeatOutput(VS_KETTLE);      
        //...but wait for last hop addition to complete before leaving step
        if(lastHop == 0) brewStepAdvance(BREWSTEP_BOIL);
      }
      break;
    case STEPSIGNAL_EXIT:
      bitClear(actProfiles, VLV_HOPADD);
      #ifdef AUTO_BOIL_RECIRC
        bitClear(actProfiles, VLV_BOILRECIRC);
      #endif
      boilControlState = CONTROLSTATE_OFF;
      resetHeatOutput(VS_KETTLE);
      clearTimer(TIMER_BOIL);
      break;
  }
}

void brewStepChill(enum StepSignal signal) {
  switch (signal) {
    case STEPSIGNAL_INIT:
      pitchTemp = getProgPitch(stepProgram[BREWSTEP_CHILL]);
      break;
    case STEPSIGNAL_UPDATE:
      if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
        if (!vlvConfigIsActive(VLV_KETTLELID)) bitSet(actProfiles, VLV_KETTLELID);
      } else {
        if (vlvConfigIsActive(VLV_KETTLELID)) bitClear(actProfiles, VLV_KETTLELID);
      }
      break;
    case STEPSIGNAL_EXIT:
      autoValve[AV_CHILL] = 0;
      bitClear(actProfiles, VLV_CHILLBEER);
      bitClear(actProfiles, VLV_CHILLH2O);
      break;
  }
}

void resetSpargeValves() {
  autoValve[AV_SPARGEIN] = 0;
  autoValve[AV_SPARGEOUT] = 0;
  autoValve[AV_FLYSPARGE] = 0;
  bitClear(actProfiles, VLV_SPARGEIN);
  bitClear(actProfiles, VLV_SPARGEOUT);
  bitClear(actProfiles, VLV_MASHHEAT);
  bitClear(actProfiles, VLV_MASHIDLE);
}

#ifdef SMART_HERMS_HLT
void smartHERMSHLT() {
  if (!setpoint[VS_MASH]) return;
  setpoint[VS_HLT] = setpoint[VS_MASH] * 2 - temp[TS_MASH];
  //Constrain HLT Setpoint to Mash Setpoint + MASH_HEAT_LOSS (minimum) and HLT_MAX_TEMP (Maximum)
  setpoint[VS_HLT] = constrain(setpoint[VS_HLT], setpoint[VS_MASH] + MASH_HEAT_LOSS * 100, HLT_MAX_TEMP * 100);
}
#endif
  
unsigned long calcStrikeVol(byte recipe) {
  unsigned int mashRatio = getProgRatio(recipe);
  unsigned long retValue;
  if (mashRatio) {
    retValue = round(getProgGrain(recipe) * mashRatio / 100.0);

    //Convert qts to gal for US
    #ifndef USEMETRIC
      retValue = round(retValue / 4.0);
    #endif
    retValue += getVolLoss(TS_MASH);
  }
  else {
    //No Sparge Logic (Matio Ratio = 0)
    retValue = calcPreboilVol(recipe);
  
    //Add Water Lost in Spent Grain
    retValue += calcGrainLoss(recipe);
    
    //Add Loss from other Vessels
    retValue += (getVolLoss(TS_HLT) + getVolLoss(TS_MASH));
  }
  
  #ifdef DEBUG_PROG_CALC_VOLS
    logStart_P(LOGDEBUG);
    logField_P(PSTR("StrikeVol:"));
    logFieldI( retValue);
    logEnd();
  #endif
  
  return retValue;
}

unsigned long calcSpargeVol(byte recipe) {
  //Determine Preboil Volume Needed (Batch + Evap + Deadspace + Thermo Shrinkage)
  unsigned long retValue = calcPreboilVol(recipe);

  //Add Water Lost in Spent Grain
  retValue += calcGrainLoss(recipe);
  
  //Add Loss from other Vessels
  retValue += (getVolLoss(TS_HLT) + getVolLoss(TS_MASH));

  //Subtract Strike Water Volume
  retValue -= calcStrikeVol(recipe);
  
  #ifdef DEBUG_PROG_CALC_VOLS
    logStart_P(LOGDEBUG);
    logField_P(PSTR("SpargeVol:"));
    logFieldI( retValue);
    logEnd();
  #endif
  
  return retValue;
}

unsigned long calcPreboilVol(byte recipe) {
  // Pre-Boil Volume is the total volume needed in the kettle to ensure you can collect your anticipated batch volume
  // It is (((batch volume + kettle loss) / thermo shrinkage factor ) / evap loss factor )
  //unsigned long retValue = (getProgBatchVol(recipe) / (1.0 - getEvapRate() / 100.0 * getProgBoil(recipe) / 60.0)) + getVolLoss(TS_KETTLE); // old logic 
  #ifdef BOIL_OFF_GALLONS
    unsigned long retValue = (((getProgBatchVol(recipe) + getVolLoss(TS_KETTLE)) / VOL_SHRINKAGE) + (((unsigned long)getEvapRate() * EvapRateConversion) * getProgBoil(recipe) / 60.0));
  #else
    unsigned long retValue = (((getProgBatchVol(recipe) + getVolLoss(TS_KETTLE)) / VOL_SHRINKAGE) / (1.0 - getEvapRate() / 100.0 * getProgBoil(recipe) / 60.0));
  #endif
  
  #ifdef DEBUG_PROG_CALC_VOLS
    logStart_P(LOGDEBUG);
    logField_P(PSTR("PreBoilVol:"));
    logFieldI( round(retValue));
    logEnd();
  #endif
  
  return round(retValue);
}

unsigned long calcGrainLoss(byte recipe) {
  unsigned long retValue;
  retValue = round(getProgGrain(recipe) * GRAIN_VOL_LOSS);
  
  #ifdef DEBUG_PROG_CALC_VOLS
    logStart_P(LOGDEBUG);
    logField_P(PSTR("GrainLoss"));
    logFieldI(retValue);
    logEnd();
  #endif
  
  return retValue;
}

unsigned long calcGrainVolume(byte recipe) {
  return round (getProgGrain(recipe) * GRAIN2VOL);
}

/**
 * Calculates the strike temperature for the mash.
 */
byte calcStrikeTemp(byte recipe) {
  //Metric temps are stored as quantity of 0.5C increments
  float strikeTemp = (float)getFirstStepTemp(recipe) / SETPOINT_DIV;
  float grainTemp = (float)getGrainTemp() / SETPOINT_DIV;
  
  //Imperial units must be converted from gallons to quarts
  #ifdef USEMETRIC
    const uint8_t kMashRatioVolumeFactor = 1;
  #else
    const uint8_t kMashRatioVolumeFactor = 4;
  #endif
  
  //Calculate mash ratio to include logic for no sparge recipes (Using mash ratio of 0 would not work in calcs)
  float mashRatio = (float)calcStrikeVol(recipe) *  kMashRatioVolumeFactor / getProgGrain(recipe);
  
  #ifdef USEMETRIC
    const float kGrainThermoDynamic = 0.41;
  #else
    const float kGrainThermoDynamic = 0.2;
  #endif
  
  //Calculate strike temp using the formula:
  //  Tw = (TDC/r)(T2 - T1) + T2
  //  where:
  //    TDC = Thermodynamic constant (0.2 for Imperial Units and 0.41 for Metric)
  //    r = The ratio of water to grain in quarts per pound or l per kg
  //    T1 = The initial temperature of the mash
  //    T2 = The target temperature of the mash
  //    Tw = The actual temperature of the infusion water
  strikeTemp = (kGrainThermoDynamic / mashRatio) * (strikeTemp - grainTemp) + strikeTemp;

  //Add Config.h value for adjustments if any
  strikeTemp += STRIKE_TEMP_OFFSET;
  
  //Return value in EEPROM format which is 0-255F or 0-255 x 0.5C
  return strikeTemp * SETPOINT_DIV;
}

byte getFirstStepTemp(byte recipe) {
  byte firstStep = 0;
  byte i = MASHSTEP_DOUGHIN;
  while (firstStep == 0 && i <= MASHSTEP_MASHOUT) firstStep = getProgMashTemp(recipe, i++);
  return firstStep;
}
