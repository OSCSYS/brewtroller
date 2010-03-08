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

unsigned long lastHop;
unsigned int boilAdds, triggered;
byte grainTemp;

void resetSteps() {
  for (byte i = 0; i < NUM_BREW_STEPS; i++) stepProgram[i] = PROGRAM_IDLE;
}

boolean stepIsActive(byte brewStep) {
  if (stepProgram[brewStep] != PROGRAM_IDLE) return true; else return false;
}

void stepCore() {
  if (stepIsActive(STEP_FILL)) stepFill(STEP_FILL);
  if (stepIsActive(STEP_PREHEAT)) stepMash(STEP_PREHEAT);
  if (stepIsActive(STEP_DELAY)) if (timerValue[TIMER_MASH] == 0) stepExit(STEP_DELAY);
  if (stepIsActive(STEP_ADDGRAIN)) { /*Nothing much happens*/ }
  if (stepIsActive(STEP_REFILL)) stepFill(STEP_REFILL);
  for (byte brewStep = STEP_DOUGHIN; brewStep <= STEP_MASHOUT; brewStep++) if (stepIsActive(brewStep)) stepMash(brewStep);
  
  if (stepIsActive(STEP_MASHHOLD)) {
    #ifdef SMART_HERMS_HLT
      smartHERMSHLT();
    #endif
  }
  
  if (stepIsActive(STEP_SPARGE)) { /*Nothing much happens*/ }
  if (stepIsActive(STEP_BOIL)) {
    if (doAutoBoil) {
      if(temp[TS_KETTLE] < setpoint[TS_KETTLE]) PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE;
      else PIDOutput[VS_KETTLE] = PIDCycle[VS_KETTLE] * 10 * min(boilPwr, PIDLIMIT_KETTLE);
    }

    #ifdef PREBOIL_ALARM
      if ((triggered ^ 32768) && temp[TS_KETTLE] >= PREBOIL_ALARM) {
        setAlarm(1);
        triggered |= 32768; 
        setABAddsTrig(triggered);
      }
    #endif

    if (!preheated[VS_KETTLE] && temp[TS_KETTLE] >= setpoint[TS_KETTLE] && setpoint[TS_KETTLE] > 0) {
      preheated[VS_KETTLE] = 1;
      setTimer(TIMER_BOIL, getProgBoil(stepProgram[STEP_BOIL]));
    }

    //Turn off hop valve profile after 5s
    if ((vlvBits & vlvConfig[VLV_HOPADD] == vlvConfig[VLV_HOPADD]) && lastHop > 0 && millis() - lastHop > HOPADD_DELAY) {
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
    if(preheated[VS_KETTLE] && timerValue == 0) stepExit(STEP_BOIL);
  }
  
  if (stepIsActive(STEP_CHILL)) {
    if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
      if (vlvBits & vlvConfig[VLV_KETTLELID] != vlvConfig[VLV_KETTLELID]) setValves(vlvConfig[VLV_KETTLELID], 1);
    } else {
      if (vlvBits & vlvConfig[VLV_KETTLELID] == vlvConfig[VLV_KETTLELID]) setValves(vlvConfig[VLV_KETTLELID], 0);
    }
  }
}


//Returns 0 if start was successful or 1 if unable to start due to conflict with other step
//Performs any logic required at start of step
boolean stepInit(byte pgm, byte brewStep) {
  if (brewStep = STEP_FILL) {
  //Step Init: Fill
  
    //Set tgtVols
    tgtVol[TS_HLT] = calcSpargeVol(pgm);
    tgtVol[TS_MASH] = calcMashVol(pgm);
    if (getProgMLHeatSrc(pgm) == VS_HLT) {
      tgtVol[VS_HLT] = min(tgtVol[VS_HLT] + tgtVol[VS_MASH], getCapacity(VS_HLT));
      tgtVol[VS_MASH] = 0;
    }

    //autoValve = 0;
    //setValves(0);

  } else if (brewStep = STEP_DELAY) {
  //Step Init: Delay
  if (progDelay) setTimer(TIMER_MASH, progDelay);   
    

  } else if (brewStep = STEP_PREHEAT) {
  //Step Init: Preheat
  
    //Find first temp and adjust for strike temp
    {
      if (getProgMLHeatSrc(pgm) == VS_HLT) {
        setpoint[TS_HLT] = calcStrikeTemp(pgm);
        setpoint[TS_MASH] = 0;
      } else {
        setpoint[TS_HLT] = getProgHLT(pgm);
        setpoint[TS_MASH] = calcStrikeTemp(pgm);
      }
      setpoint[VS_STEAM] = getSteamTgt();
      pid[VS_HLT].SetMode(AUTO);
      pid[VS_MASH].SetMode(AUTO);
      pid[VS_STEAM].SetMode(AUTO);
    }
    
    preheated[VS_MASH] = 0;
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
  } else if (brewStep = STEP_ADDGRAIN) {
  //Step Init: Add Grain
  
    setpoint[TS_HLT] = 0;
    setpoint[TS_MASH] = 0;
    setpoint[VS_STEAM] = getSteamTgt();
    setValves(vlvConfig[VLV_ADDGRAIN], 1);

  } else if (brewStep = STEP_REFILL) {
  //Step Init: Refill
  
    if (getProgMLHeatSrc(pgm) == VS_HLT) {
      tgtVol[VS_HLT] = calcSpargeVol(pgm);
      tgtVol[VS_MASH] = 0;
    }
  } else if (brewStep = STEP_DOUGHIN) {
  //Step Init: Dough In

    //If getTimerRecovery() blah blah blah
    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_DOUGHIN);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
 
  } else if (brewStep = STEP_ACID) {
  //Step Init: Acid Rest
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_ACID);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
  } else if (brewStep = STEP_PROTEIN) {
  //Step Init: Protein
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_PROTEIN);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
  } else if (brewStep = STEP_SACCH) {
  //Step Init: Sacch
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_SACCH);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
 
  } else if (brewStep = STEP_SACCH2) {
  //Step Init: Sacch2
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_SACCH2);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;
  } else if (brewStep = STEP_MASHOUT) {
  //Step Init: Mash Out
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = getProgHLT(pgm);
    setpoint[TS_MASH] = getProgMashTemp(pgm, MASH_MASHOUT);
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated[VS_MASH] = 0;
    setAlarm(0);
    timerValue[TIMER_MASH] = 0;
    autoValve[AV_MASH] = 1;

  } else if (brewStep = STEP_MASHHOLD) {
    //Cycle through steps and use last non-zero step for mash

    if (!setpoint[TS_MASH]) {
      byte i = MASH_MASHOUT;
      while (setpoint[TS_MASH] == 0 && i >= MASH_DOUGHIN && i <= MASH_MASHOUT) setpoint[TS_MASH] = getProgMashTemp(pgm, i--);
    }
    
    setpoint[VS_STEAM] = getSteamTgt();
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

  } else if (brewStep = STEP_SPARGE) {
  //Step Init: Sparge
    setpoint[TS_HLT] = getProgSparge(pgm);

  } else if (brewStep = STEP_BOIL) {
  //Step Init: Boil
    setpoint[TS_KETTLE] = getBoilTemp();
    preheated[VS_KETTLE] = 0;
    triggered = getBoilAddsTrig();
    setAlarm(0);
    timerValue[TIMER_BOIL] = 0;
    lastHop = 0;
    doAutoBoil = 1;
    
  } else if (brewStep = STEP_CHILL) {
  //Step Init: Chill
  }
}

//Returns 0 if exit was successful or 1 if unable to exit due to conflict with other step
//Performs any logic required at end of step
boolean stepExit(byte brewStep) {

  if (brewStep = STEP_FILL) {

  } else if (brewStep = STEP_DELAY) {

  } else if (brewStep = STEP_PREHEAT) {

  } else if (brewStep = STEP_ADDGRAIN) {
    
  } else if (brewStep = STEP_REFILL) {
    
  } else if (brewStep = STEP_DOUGHIN) {
    
  } else if (brewStep = STEP_ACID) {
    
  } else if (brewStep = STEP_PROTEIN) {
    
  } else if (brewStep = STEP_SACCH) {
    
  } else if (brewStep = STEP_SACCH2) {
    
  } else if (brewStep = STEP_MASHOUT) {
    
  } else if (brewStep = STEP_MASHHOLD) {

  } else if (brewStep = STEP_SPARGE) {
    
  } else if (brewStep = STEP_BOIL) {
    //0 Min Addition
    if ((boilAdds ^ triggered) & 2048) { 
      setValves(vlvConfig[VLV_HOPADD], 1);
      setAlarm(1);
      triggered |= 2048;
      setBoilAddsTrig(triggered);
      delay(HOPADD_DELAY);
      setValves(vlvConfig[VLV_HOPADD], 0);
#ifdef AUTO_BOIL_RECIRC
      setValves(vlvConfig[VLV_BOILRECIRC], 0);
#endif
    }
  } else if (brewStep = STEP_CHILL) {
    
  }
}


void stepFill(byte brewStep) {
  #ifdef AUTO_FILL
    if (volAvg[VS_HLT] >= tgtVol[VS_HLT] && volAvg[VS_MASH] >= tgtVol[VS_MASH]) stepExit(brewStep);
  #endif
}

void stepMash(byte brewStep) {
  #ifdef SMART_HERMS_HLT
    smartHERMSHLT();
  #endif
  if (preheated[VS_MASH] && timerValue == 0) stepExit(brewStep);
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
  //Detrmine Total Water Needed (Evap + Deadspaces)
  unsigned long retValue = round(getProgBatchVol(pgm) / (1.0 - getEvapRate() / 100.0 * getProgBoil(pgm) / 60.0) + getVolLoss(TS_HLT) + getVolLoss(TS_MASH));
  //Add Water Lost in Spent Grain
  #ifdef USEMETRIC
    retValue += round(getProgGrain(pgm) * 1.7884);
  #else
    retValue += round(getProgGrain(pgm) * .2143);
  #endif

  //Subtract mash volume
  retValue -= calcMashVol(pgm);
  return retValue;
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
    return strikeTemp + round(.4 * (strikeTemp - grainTemp) / (getProgRatio(pgm) / 100.0)) + 1.7;
  #else
    return strikeTemp + round(.192 * (strikeTemp - grainTemp) / (getProgRatio(pgm) / 100.0)) + 3;
  #endif
}
