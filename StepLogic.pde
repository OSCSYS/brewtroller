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

#include "Config.h"
#include "Enum.h"

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
    tgtVol[VS_MASH] = calcStrikeVol(pgm);
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
    #ifdef MASH_PREHEAT_NOVALVES
      vlvConfig[VLV_MASHHEAT] = 0;
      vlvConfig[VLV_MASHIDLE] = 0;
    #endif

    if (getProgMLHeatSrc(pgm) == VS_HLT) {
      setSetpoint(TS_HLT, calcStrikeTemp(pgm));
      
      #ifdef MASH_PREHEAT_STRIKE
        setSetpoint(TS_MASH, calcStrikeTemp(pgm));
      #elif defined MASH_PREHEAT_STEP1
        setSetpoint(TS_MASH, getFirstStepTemp(pgm));
      #else
        setSetpoint(TS_MASH, 0);
      #endif        
    } else {
      setSetpoint(TS_HLT, getProgHLT(pgm));
      setSetpoint(TS_MASH, calcStrikeTemp(pgm));
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
      PROMreadBytes(MASH_PREHEAT_SENSOR * 8, tSensor[TS_MASH], 8);
    #endif
  } else if (brewStep == STEP_ADDGRAIN) {
  //Step Init: Add Grain
    //Disable HLT and Mash heat output during 'Add Grain' to avoid dry running heat elements and burns from HERMS recirc
    resetHeatOutput(VS_HLT);
    resetHeatOutput(VS_MASH);
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    bitSet(actProfiles, VLV_ADDGRAIN);
    if(getProgMLHeatSrc(pgm) == VS_HLT) {
      unsigned long spargeVol = calcSpargeVol(pgm);
      unsigned long mashVol = calcStrikeVol(pgm);
      tgtVol[VS_HLT] = (min((spargeVol + mashVol), getCapacity(VS_HLT)) - mashVol);
      #ifdef VOLUME_MANUAL
        // In manual volume mode show the target mash volume as a guide to the user
        tgtVol[VS_MASH] = mashVol;
      #endif
      #ifdef AUTO_ML_XFER
         autoValve[AV_SPARGEIN] = 1;
      #endif
    }
  } else if (brewStep == STEP_REFILL) {
  //Step Init: Refill
    if (getProgMLHeatSrc(pgm) == VS_HLT) {
    #ifdef HLT_MIN_REFILL
      SpargeVol = calcSpargeVol(pgm);
      tgtVol[VS_HLT] = min(SpargeVol, HLT_MIN_REFILL_VOL);
    #else
      tgtVol[VS_HLT] = calcSpargeVol(pgm);
    #endif
      tgtVol[VS_MASH] = 0;
    }
    #ifdef AUTO_REFILL_START
    autoValve[AV_FILL] = 1;
    #endif

  } else if (brewStep == STEP_DOUGHIN) {
  //Step Init: Dough In
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    starttime = millis(); // get current time
    timetoset = starttime + RIMS_DELAY; //note that overflow of the milisecond timer is not covered here 
    steptoset = brewStep; //step that we need to set the setpoint to after the timer is done. 
    RIMStimeExpired = 0; //reset the boolean so that we know if the timer has expired for this program or not
    autoValve[vesselAV(TS_MASH)] = 1; // turn on the mash recirc valve profile as if the setpoint had been set
    #else
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_DOUGHIN));
    #endif
    
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_DOUGHIN)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_ACID) {
  //Step Init: Acid Rest
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    if(RIMStimeExpired == 0 && steptoset != 0) steptoset = brewStep;
    else
    #endif
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_ACID));
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_ACID)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_PROTEIN) {
  //Step Init: Protein
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    if(RIMStimeExpired == 0 && steptoset != 0) steptoset = brewStep;
    else
    #endif
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_PROTEIN));
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_PROTEIN)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_SACCH) {
  //Step Init: Sacch
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    if(RIMStimeExpired == 0 && steptoset != 0) steptoset = brewStep;
    else
    #endif
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_SACCH));
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_SACCH)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_SACCH2) {
  //Step Init: Sacch2
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    if(RIMStimeExpired == 0 && steptoset != 0) steptoset = brewStep;
    else
    #endif
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_SACCH2));
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
    //Set timer only if empty (for purposed of power loss recovery)
    if (!timerValue[TIMER_MASH]) setTimer(TIMER_MASH, getProgMashMins(pgm, MASH_SACCH2)); 
    //Leave timer paused until preheated
    timerStatus[TIMER_MASH] = 0;
    
  } else if (brewStep == STEP_MASHOUT) {
  //Step Init: Mash Out
    setSetpoint(TS_HLT, getProgHLT(pgm));
    #ifdef RIMS_MLT_SETPOINT_DELAY
    if(RIMStimeExpired == 0 && steptoset != 0) steptoset = brewStep;
    else
    #endif
    setSetpoint(TS_MASH, getProgMashTemp(pgm, MASH_MASHOUT));
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif
    preheated[VS_MASH] = 0;
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
    #ifndef PID_FLOW_CONTROL
    setSetpoint(VS_STEAM, getSteamTgt());
    #endif

  } else if (brewStep == STEP_SPARGE) {
  //Step Init: Sparge
    #ifdef HLT_HEAT_SPARGE
      #ifdef HLT_MIN_SPARGE
        if (volAvg[VS_HLT] >= HLT_MIN_SPARGE)
      #endif
          setSetpoint(TS_HLT, getProgSparge(pgm));
    #endif
    
    #ifdef BATCH_SPARGE
      
    #else
        #ifdef SPARGE_IN_PUMP_CONTROL
        prevSpargeVol[1] = volAvg[VS_HLT]; // init the value at the start of sparge
        prevSpargeVol[0] = 0;
        #endif
      tgtVol[VS_KETTLE] = calcPreboilVol(pgm);
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

  } else if (brewStep == STEP_BOIL) {
  //Step Init: Boil
    #ifdef PID_FLOW_CONTROL
    resetHeatOutput(VS_PUMP); // turn off the pump if we are moving to boil. 
    #endif
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
    pitchTemp = getProgPitch(pgm);
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
    #ifdef AUTO_MASH_HOLD_EXIT 
      #ifdef AUTO_MASH_HOLD_EXIT_AT_SPARGE_TEMP
      if (!zoneIsActive(ZONE_BOIL) && temp[VS_HLT] >= setpoint[VS_HLT]) stepAdvance(STEP_MASHHOLD);
      #else
      if (!zoneIsActive(ZONE_BOIL)) stepAdvance(STEP_MASHHOLD);
      #endif
    #endif
  }
  
  if (stepIsActive(STEP_SPARGE)) { 
    #ifdef HLT_HEAT_SPARGE
      #ifdef HLT_MIN_SPARGE
        if (volAvg[VS_HLT] < HLT_MIN_SPARGE) setSetpoint(TS_HLT, 0);
      #endif
    #endif
    
    #ifdef BATCH_SPARGE
    
    #else
      #ifdef AUTO_SPARGE_EXIT
         if (volAvg[VS_KETTLE] >= tgtVol[VS_KETTLE]) stepAdvance(STEP_SPARGE);
      #endif
    #endif
  }
  
  if (stepIsActive(STEP_BOIL)) {
    if (doAutoBoil) {
      if(temp[TS_KETTLE] < setpoint[TS_KETTLE]) PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * PIDLIMIT_KETTLE;
      else PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * min(boilPwr, PIDLIMIT_KETTLE);
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
      //Timed additions (See hoptimes[] array at top of AutoBrew.pde)
      for (byte i = 0; i < 10; i++) {
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
    if(preheated[VS_KETTLE] && timerValue[TIMER_BOIL] == 0) stepAdvance(STEP_BOIL);
  }
  
  if (stepIsActive(STEP_CHILL)) {
    if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
      if (!vlvConfigIsActive(VLV_KETTLELID)) bitSet(actProfiles, VLV_KETTLELID);
    } else {
      if (vlvConfigIsActive(VLV_KETTLELID)) bitClear(actProfiles, VLV_KETTLELID);
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
  #ifdef RIMS_MLT_SETPOINT_DELAY
  if (getProgMashTemp(stepProgram[brewStep], (brewStep - 5)) == 0 || (preheated[VS_MASH] && timerValue[TIMER_MASH] == 0)) stepAdvance(brewStep);
  #else
  if (setpoint[VS_MASH] == 0 || (preheated[VS_MASH] && timerValue[TIMER_MASH] == 0)) stepAdvance(brewStep);
  #endif
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
  }
  //Init Successful
  return 0;
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
    bitClear(actProfiles, VLV_FILLHLT);
    bitClear(actProfiles, VLV_FILLMASH);

  } else if (brewStep == STEP_DELAY) {
  //Step Exit: Delay
    clearTimer(TIMER_MASH);
  
  } else if (brewStep == STEP_ADDGRAIN) {
  //Step Exit: Add Grain
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

  } else if (brewStep == STEP_PREHEAT || (brewStep >= STEP_DOUGHIN && brewStep <= STEP_MASHHOLD)) {
  //Step Exit: Preheat/Mash
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
      PROMreadBytes(8, tSensor[TS_MASH], 8);
    #endif
    #ifdef MASH_PREHEAT_NOVALVES
      loadVlvConfigs();
    #endif
  } else if (brewStep == STEP_SPARGE) {
  //Step Exit: Sparge
    #ifdef HLT_HEAT_SPARGE
      setSetpoint(TS_HLT, 0);
    #endif
    tgtVol[VS_HLT] = 0;
    tgtVol[VS_KETTLE] = 0;
    resetSpargeValves();

  } else if (brewStep == STEP_BOIL) {
  //Step Exit: Boil
    //0 Min Addition
    if ((boilAdds ^ triggered) & 2048) { 
      bitSet(actProfiles, VLV_HOPADD);
      setAlarm(1);
      triggered |= 2048;
      setBoilAddsTrig(triggered);
      delay(HOPADD_DELAY);
    }
    bitClear(actProfiles, VLV_HOPADD);
    #ifdef AUTO_BOIL_RECIRC
      bitClear(actProfiles, VLV_BOILRECIRC);
    #endif
    resetHeatOutput(VS_KETTLE);
    clearTimer(TIMER_BOIL);
  } else if (brewStep == STEP_CHILL) {
  //Step Exit: Chill
    autoValve[AV_CHILL] = 0;
    bitClear(actProfiles, VLV_CHILLBEER);
    bitClear(actProfiles, VLV_CHILLH2O);
  }
  eventHandler(EVENT_STEPEXIT, brewStep);  
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
  if (setpoint[VS_MASH] != 0) setpoint[VS_HLT] = constrain(setpoint[VS_MASH] * 2 - temp[TS_MASH], setpoint[VS_MASH] + MASH_HEAT_LOSS * SETPOINT_DIV * 100, HLT_MAX_TEMP *  SETPOINT_DIV * 100);
}
#endif
  
unsigned long calcStrikeVol(byte pgm) {
  unsigned long retValue = round(getProgGrain(pgm) * getProgRatio(pgm) / 100.0);
  //Convert qts to gal for US
  #ifndef USEMETRIC
    retValue = round(retValue / 4.0);
  #endif
  retValue += getVolLoss(TS_MASH);
  
  #ifdef DEBUG_PROG_CALC_VOLS
  logStart_P(LOGDEBUG);
  logField_P(PSTR("StrikeVol:"));
  logFieldI( retValue);
  logEnd();
  #endif
  
  return retValue;
}

unsigned long calcSpargeVol(byte pgm) {
  //Determine Preboil Volume Needed (Batch + Evap + Deadspace + Thermo Shrinkage)
  unsigned long retValue = calcPreboilVol(pgm);

  //Add Water Lost in Spent Grain
  retValue += calcGrainLoss(pgm);
  
  //Add Loss from other Vessels
  retValue += (getVolLoss(TS_HLT) + getVolLoss(TS_MASH));

  //Subtract Strike Water Volume
  retValue -= calcStrikeVol(pgm);
  
  #ifdef DEBUG_PROG_CALC_VOLS
  logStart_P(LOGDEBUG);
  logField_P(PSTR("SpargeVol:"));
  logFieldI( retValue);
  logEnd();
  #endif
  
  return retValue;
}

unsigned long calcPreboilVol(byte pgm) {
  // Pre-Boil Volume is the total volume needed in the kettle to ensure you can collect your anticipated batch volume
  // It is (((batch volume + kettle loss) / thermo shrinkage factor ) / evap loss factor )
  //unsigned long retValue = (getProgBatchVol(pgm) / (1.0 - getEvapRate() / 100.0 * getProgBoil(pgm) / 60.0)) + getVolLoss(TS_KETTLE); // old logic 
  #ifdef BOIL_OFF_GALLONS
  unsigned long retValue = (((getProgBatchVol(pgm) + getVolLoss(TS_KETTLE)) / .96) + (((unsigned long)getEvapRate() * EvapRateConversion) * getProgBoil(pgm) / 60.0));
  #else
  unsigned long retValue = (((getProgBatchVol(pgm) + getVolLoss(TS_KETTLE)) / .96) / (1.0 - getEvapRate() / 100.0 * getProgBoil(pgm) / 60.0));
  #endif
  
  #ifdef DEBUG_PROG_CALC_VOLS
  logStart_P(LOGDEBUG);
  logField_P(PSTR("PreBoilVol:"));
  logFieldI( round(retValue));
  logEnd();
  #endif
  
  return round(retValue);
}

unsigned long calcGrainLoss(byte pgm) {
  unsigned long retValue;
  #ifdef USEMETRIC
    retValue = round(getProgGrain(pgm) * 1.7884);
  #else
    retValue = round(getProgGrain(pgm) * .2143); // This is pretty conservative (err on more absorbtion) - Ray Daniels suggests .20 - Denny Conn suggest .10
  #endif
  
  #ifdef DEBUG_PROG_CALC_VOLS
  logStart_P(LOGDEBUG);
  logField_P(PSTR("GrainLoss"));
  logFieldI(retValue);
  logEnd();
  #endif
  
  return retValue;
}

unsigned long calcGrainVolume(byte pgm) {
  //Grain-to-volume factor for mash tun capacity
  //Conservatively 1 lb = 0.15 gal 
  //Aggressively 1 lb = 0.093 gal
  #ifdef USEMETRIC
    #define GRAIN2VOL 1.25
  #else
    #define GRAIN2VOL .15
  #endif
  return round (getProgGrain(pgm) * GRAIN2VOL);
}

byte calcStrikeTemp(byte pgm) {
  float strikeTemp = (float)getFirstStepTemp(pgm) / SETPOINT_DIV;
  #ifdef USEMETRIC
    return (strikeTemp + round(.4 * (strikeTemp - (float) getGrainTemp() / SETPOINT_DIV) / (getProgRatio(pgm) / 100.0)) + 1.7 + STRIKE_TEMP_OFFSET) * SETPOINT_DIV;
  #else
    return (strikeTemp + round(.192 * (strikeTemp - getGrainTemp() / SETPOINT_DIV) / (getProgRatio(pgm) / 100.0)) + 3 + STRIKE_TEMP_OFFSET) * SETPOINT_DIV;
  #endif
}

byte getFirstStepTemp(byte pgm) {
  byte firstStep = 0;
  byte i = MASH_DOUGHIN;
  while (firstStep == 0 && i <= MASH_MASHOUT) firstStep = getProgMashTemp(pgm, i++);
  return firstStep;
}
