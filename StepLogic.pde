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

//Returns 0 if start was successful or 1 if unable to start due to conflict with other step
//Performs any logic required at start of step
boolean stepInit(byte pgm, byte brewStep) {
  if (brewStep = STEP_FILL) {
  //Step Init: Fill
  
    //Set tgtVols
    tgtVol[TS_HLT] = calcSpargeVol(pgm);
    tgtVol[TS_MASH] = calcMashVol(pgm);
    if (MLHeatSrc == VS_HLT) {
      tgtVol[VS_HLT] = min(tgtVol[VS_HLT] + tgtVol[VS_MASH], capacity[VS_HLT]);
      tgtVol[VS_MASH] = 0;
    }

    //autoValve = 0;
    //setValves(0);

  } else if (brewStep = STEP_DELAY) {
  //Step Init: Delay
    if (delayMins) setTimer(delayMins);   
    

  } else if (brewStep = STEP_PREHEAT) {
  //Step Init: Preheat
  
    //Find first temp and adjust for strike temp
    {
      byte strikeTemp = 0;
      byte i = 0;
      while (strikeTemp == 0 && i <= STEP_MASHOUT) strikeTemp = stepTemp[i++];
      #ifdef USEMETRIC
        strikeTemp = strikeTemp + round(.4 * (strikeTemp - grainTemp) / (mashRatio / 100.0)) + 1.7;
      #else
        strikeTemp = strikeTemp + round(.192 * (strikeTemp - grainTemp) / (mashRatio / 100.0)) + 3;
      #endif
      if (MLHeatSrc == VS_HLT) {
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
    
    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
  } else if (brewStep = STEP_ADDGRAIN) {
  //Step Init: Add Grain
  
    setpoint[TS_HLT] = 0;
    setpoint[TS_MASH] = 0;
    setpoint[VS_STEAM] = steamTgt;
    setValves(vlvConfig[VLV_ADDGRAIN]);

  } else if (brewStep = STEP_REFILL) {
  //Step Init: Refill
  
    if (MLHeatSrc == VS_HLT) {
      tgtVol[VS_HLT] = calcSpargeVol(pgm);
      tgtVol[VS_MASH] = 0;
    }
  } else if (brewStep = STEP_DOUGHIN) {
  //Step Init: Dough In

    //If getTimerRecovery() blah blah blah
    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_DOUGHIN];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
 
  } else if (brewStep = STEP_ACID) {
  //Step Init: Acid Rest
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_PROTEIN];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH; 
  } else if (brewStep = STEP_PROTEIN) {
  //Step Init: Protein
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_PROTEIN];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
  } else if (brewStep = STEP_SACCH) {
  //Step Init: Sacch
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_SACCH];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
 
  } else if (brewStep = STEP_SACCH2) {
  //Step Init: Sacch2
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_PROTEIN];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
  } else if (brewStep = STEP_MASHOUT) {
  //Step Init: Mash Out
  
    //If getTimerRecovery() blah blah blah

    setpoint[TS_HLT] = HLTTemp;
    setpoint[TS_MASH] = stepTemp[STEP_MASHOUT];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

    preheated = 0;
    setAlarm(0);
    doPrompt = 0;
    if (iMins == MINS_PROMPT) doPrompt = 1;
    timerValue = 0;
    autoValve = AV_MASH;
  } else if (brewStep = STEP_SPARGE) {
  //Step Init: Sparge
    //Hold last mash temp until starts sparge
    setpoint[TS_HLT] = spargeTemp;
    //Cycle through steps and use last non-zero step for mash
    for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) if (stepTemp[i]) setpoint[TS_MASH] = stepTemp[i];
    setpoint[VS_STEAM] = steamTgt;
    pid[VS_HLT].SetMode(AUTO);
    pid[VS_MASH].SetMode(AUTO);
    pid[VS_STEAM].SetMode(AUTO);

  } else if (brewStep = STEP_BOIL) {
  //Step Init: Boil
    setpoint[TS_KETTLE] = getBoilTemp();
    boolean preheated = 0;
    unsigned int triggered = getABAddsTrig();
    setAlarm(0);
    timerValue = 0;
    unsigned long lastHop = 0;
    byte boilPwr = getBoilPwr();
    boolean doAutoBoil = 1;
    
  } else if (brewStep = STEP_CHILL) {
  //Step Init: Chill
  } else if (brewStep = STEP_DRAIN) {
  //Step Init: Drain
  
  }
}

void stepCore() {
  for (byte pgm = 0; pgm <= NUM_PROGRAMS; pgm++) {
    if (programStep[pgm] == STEP_FILL || programStep[pgm] == STEP_REFILL) {
  
    }
  
    if (programStep[pgm] == STEP_PREHEAT || programStep[pgm] == STEP_DOUGHIN || programStep[pgm] == STEP_PROTEIN || programStep[pgm] == STEP_SACCH || programStep[pgm] == STEP_MASHOUT) {
      #ifdef SMART_HERMS_HLT
        if (setpoint[VS_MASH] != 0) setpoint[VS_HLT] = constrain(setpoint[VS_MASH] * 2 - temp[TS_MASH], setpoint[VS_MASH] + MASH_HEAT_LOSS, HLT_MAX_TEMP);
      #endif
      if (preheated && timerValue == 0 && !doPrompt) stepExit(pgm, programStep[pgm]);
    }
    
    if (programStep[pgm] == STEP_ADDGRAIN) {
      
    }
    
    if (programStep[pgm] == STEP_SPARGE) {
      //Once sparging starts
      setpoint[TS_HLT] = 0;
      setpoint[TS_MASH] = 0;
      setpoint[VS_STEAM] = 0;
    }
    
    if (programStep[pgm] == STEP_BOIL) {
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

      if (!preheated && temp[TS_KETTLE] >= setpoint[TS_KETTLE] && setpoint[TS_KETTLE] > 0) {
        preheated = 1;
        setTimer(iMins);
      }

      //Turn off hop valve profile after 5s
      if (lastHop > 0 && millis() - lastHop > HOPADD_DELAY) {
        if (vlvBits & vlvConfig[VLV_HOPADD]) setValves(vlvBits ^ vlvConfig[VLV_HOPADD]);
        lastHop = 0;
      }

      if (preheated) {
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

      //Exit Condition  
      if(preheated && timerValue == 0) stepExit(pgm, STEP_BOIL);
    }
    
    if (programStep[pgm] == STEPM_CHILL) {
      if (temp[TS_KETTLE] != -1 && temp[TS_KETTLE] <= KETTLELID_THRESH) {
        if (vlvBits & vlvConfig[VLV_KETTLELID] == 0) setValves(vlvBits | vlvConfig[VLV_KETTLELID]);
      } else {
        if (vlvBits & vlvConfig[VLV_KETTLELID]) setValves(vlvBits ^ vlvConfig[VLV_KETTLELID]);
      }
    }
    
    if (programStep[pgm] == STEP_DRAIN) {
      
    }
  }
}


//Returns 0 if exit was successful or 1 if unable to exit due to conflict with other step
//Performs any logic required at end of step
boolean stepExit(byte pgm, byte brewStep) {

  if (brewStep = STEP_FILL) {

  } else if (brewStep = STEP_PREHEAT) {

  } else if (brewStep = STEP_ADDGRAIN) {
    
  } else if (brewStep = STEP_REFILL) {
    
  } else if (brewStep = STEP_DOUGHIN) {
    
  } else if (brewStep = STEP_PROTEIN) {
    
  } else if (brewStep = STEP_SACCH) {
    
  } else if (brewStep = STEP_MASHOUT) {
    
  } else if (brewStep = STEP_SPARGE) {
    
  } else if (brewStep = STEP_BOIL) {
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
  } else if (brewStep = STEP_CHILL) {
    
  } else if (brewStep = STEP_DRAIN) {
    
  }
}

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
  unsigned long retValue = round(getProgBatchVol(pgm) / (1.0 - evapRate / 100.0 * getProgBoil(pgm) / 60.0) + volLoss[TS_HLT] + volLoss[TS_MASH]);
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
