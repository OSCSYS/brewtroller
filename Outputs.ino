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
unsigned long lastKettleOutSave = 0;
// set what the PID cycle time should be based on how fast the temp sensors will respond

void resetOutputs() {
  for (byte i = VS_HLT; i <= VS_KETTLE; i++)
    setSetpoint(i, 0);
  outputs->setProfileStateMask(0x00000000ul, 0);
  outputs->update();
}

//Called by setpoint event when setSetpoint() is called
//Likely not called directly for any reason
//OK, the vessel min ISRs call it to turn off outputs without clearing the setpoint.
void resetVesselHeat(byte vessel) {
  if (vessel == VS_KETTLE && boilControlState != CONTROLSTATE_OFF)
    setBoilControlState(CONTROLSTATE_OFF);
  outputs->setProfileState(vesselIdleProfile(vessel), 0);
  outputs->setProfileState(vesselHeatProfile(vessel), 0);
  outputs->setProfileState(vesselPWMActiveProfile(vessel), 0);
  PIDOutput[vessel] = 0;
  if (pwmOutput[vessel])
    pwmOutput[vessel]->setValue(0);
  heatStatus[vessel] = 0;
}

void updatePIDHeat(byte vessel) {
  //Do not compute PID for kettle if boil control is not in setpoint mode.
  if (vessel != VS_KETTLE || boilControlState == CONTROLSTATE_SETPOINT || boilControlState == CONTROLSTATE_OFF) {
    if (temp[vessel] == BAD_TEMP)
      PIDOutput[vessel] = 0;
    else {
      PIDInput[vessel] = temp[vessel];
      pid[vessel].Compute();
    }
  }
  
  #ifdef HLT_MIN_HEAT_VOL
    if(vessel == VS_HLT && volAvg[vessel] < HLT_MIN_HEAT_VOL)
      PIDOutput[vessel] = 0;
  #endif
  #ifdef MASH_MIN_HEAT_VOL
    if(vessel == VS_MASH && volAvg[vessel] < MASH_MIN_HEAT_VOL)
      PIDOutput[vessel] = 0;
  #endif
  #ifdef KETTLE_MIN_HEAT_VOL
    if(vessel == VS_KETTLE && volAvg[vessel] < KETTLE_MIN_HEAT_VOL)
      PIDOutput[vessel] = 0;
  #endif
  
  if (pwmOutput[vessel]) {
    pwmOutput[vessel]->setValue(PIDOutput[vessel]);
    pwmOutput[vessel]->update();
  }
  
  if (PIDOutput[vessel]) {
    outputs->setProfileState(vesselPWMActiveProfile(vessel), 1);
    heatStatus[vessel] = 1;
  } else {
    //Do not modify heatStatus; initial value is set in On/Off logic and only updated if PID is active
    outputs->setProfileState(vesselPWMActiveProfile(vessel), 0);
  }
}


/**
 * Called by processHeatOutputsNonPIDEnabled to process a heat output when heatStatus[vessel] == true.
 */
void updateOnOffHeatOn(byte vessel) {
  // determine if setpoint has ben reached, or there is a bad temp reading.
  // If it either condition, turn it off.

  if (temp[vessel] == BAD_TEMP || temp[vessel] >= setpoint[vessel]) { 
    outputs->setProfileState(vesselHeatProfile(vessel), 0);
    outputs->setProfileState(vesselIdleProfile(vessel), 1);
    heatStatus[vessel] = 0;
  } else { 
    // setpoint has not been reached, and temp reading is valid.
    // Insure that the correct heat pin is enabled, and heatStatus updated.
    outputs->setProfileState(vesselHeatProfile(vessel), 1);
    outputs->setProfileState(vesselIdleProfile(vessel), 0);
    heatStatus[vessel] = 1;
  }
}

void updateOnOffHeatOff(byte vessel) {
  // Determine is the vessel temperature is below the setpoint, accounting for hysteresis.
  if (temp[vessel] != BAD_TEMP && (setpoint[vessel] - temp[vessel]) >= hysteresis[vessel] * 10) {
      // The temperature of the vessel is below what we want, so insure the correct pin is turned on,
      // and the heatStatus is updated.
    outputs->setProfileState(vesselHeatProfile(vessel), 1);
    outputs->setProfileState(vesselIdleProfile(vessel), 0);
    heatStatus[vessel] = 1;
  } else {
    // The heat is maintaining currently desired value, so insure heat source is (still) off.
    outputs->setProfileState(vesselHeatProfile(vessel), 0);
    outputs->setProfileState(vesselIdleProfile(vessel), 1);
    heatStatus[vessel] = 0;
  }
}

void updateHeatOutputs() {
  updateBoilController();
  
  for (int vesselIndex = 0; vesselIndex <= VS_KETTLE; vesselIndex++) {
    if (setpoint[vesselIndex]) {
      //Call On/Off Update first to set heatstatus
      if (outputs->getProfileState(vesselHeatProfile(vesselIndex)))
        updateOnOffHeatOn(vesselIndex);
      else
        updateOnOffHeatOff(vesselIndex);

      //Only updates heatstatus if PID value is non-zero
      if (pwmOutput[vesselIndex])
        updatePIDHeat(vesselIndex);
    }
  }
}

  void updateAutoValve() {
    //Do Valves
    if (autoValve[AV_FILL]) {
      outputs->setProfileState(OUTPUTPROFILE_FILLHLT, (volAvg[VS_HLT] < tgtVol[VS_HLT]) ? 1 : 0);
      outputs->setProfileState(OUTPUTPROFILE_FILLMASH, (volAvg[VS_MASH] < tgtVol[VS_MASH]) ? 1 : 0);
    }
    
    if (autoValve[AV_SPARGEIN])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, (volAvg[VS_HLT] > tgtVol[VS_HLT]) ? 1 : 0);

    if (autoValve[AV_SPARGEOUT])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, (volAvg[VS_KETTLE] < tgtVol[VS_KETTLE]) ? 1 : 0);

    if (autoValve[AV_FLYSPARGE]) {
      if (volAvg[VS_KETTLE] < tgtVol[VS_KETTLE]) {
        if (brewStepConfiguration.flySpargeHysteresis) {
          if((long)volAvg[VS_KETTLE] - (long)prevSpargeVol[0] >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1);
             prevSpargeVol[0] = volAvg[VS_KETTLE];
          } else if((long)prevSpargeVol[1] - (long)volAvg[VS_HLT] >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
             prevSpargeVol[1] = volAvg[VS_HLT];
          }
        } else {
          outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1);
        }
        outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 1);
      } else {
        outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
        outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 0);
      }
    }
    if (autoValve[AV_CHILL]) {
      //Needs work
      /*
      //If Pumping beer
      if (vlvConfigIsActive(OUTPUTPROFILE_WORTOUT)) {
        //Cut beer if exceeds pitch + 1
        if (temp[TS_BEEROUT] > pitchTemp + 1.0) bitClear(actProfiles, OUTPUTPROFILE_WORTOUT);
      } else {
        //Enable beer if chiller H2O output is below pitch
        //ADD MIN DELAY!
        if (temp[TS_H2OOUT] < pitchTemp - 1.0) bitSet(actProfiles, OUTPUTPROFILE_WORTOUT);
      }
      
      //If chiller water is running
      if (vlvConfigIsActive(OUTPUTPROFILE_CHILL)) {
        //Cut H2O if beer below pitch - 1
        if (temp[TS_BEEROUT] < pitchTemp - 1.0) bitClear(actProfiles, OUTPUTPROFILE_CHILL);
      } else {
        //Enable H2O if chiller H2O output is at pitch
        //ADD MIN DELAY!
        if (temp[TS_H2OOUT] >= pitchTemp) bitSet(actProfiles, OUTPUTPROFILE_CHILL);
      }
      */
    }
  }
  
void updateBoilController () {
  if (boilControlState == CONTROLSTATE_AUTO) {
    if(temp[TS_KETTLE] < getBoilTemp()*SETPOINT_MULT)
      PIDOutput[VS_KETTLE] = pwmOutput[VS_KETTLE] ? pwmOutput[VS_KETTLE]->getLimit() : 0;
    else
      PIDOutput[VS_KETTLE] = pwmOutput[VS_KETTLE] ? (unsigned int)(pwmOutput[VS_KETTLE]->getLimit()) * boilPwr / 100: 0;
  }

  //Save Kettle output to EEPROM if different, check very minuite (to avoid excessive EEPROM writes)
  if ((millis() - lastKettleOutSave > 60000) && boilControlState == CONTROLSTATE_MANUAL) {
      lastKettleOutSave = millis();
      setBoilOutput((byte)PIDOutput[VS_KETTLE]);
    }
}

byte vesselHeatProfile(byte vessel) {
  if (vessel == VS_HLT)
    return OUTPUTPROFILE_HLTHEAT;
  else if (vessel == VS_MASH)
    return OUTPUTPROFILE_MASHHEAT;
  else if (vessel == VS_KETTLE)
    return OUTPUTPROFILE_KETTLEHEAT;
}

byte vesselIdleProfile(byte vessel) {
  if (vessel == VS_HLT)
    return OUTPUTPROFILE_HLTIDLE;
  else if (vessel == VS_MASH)
    return OUTPUTPROFILE_MASHIDLE;
  else if (vessel == VS_KETTLE)
    return OUTPUTPROFILE_KETTLEIDLE;
}

byte vesselPWMActiveProfile(byte vessel) {
    if (vessel == VS_HLT)
    return OUTPUTPROFILE_HLTPWMACTIVE;
  else if (vessel == VS_MASH)
    return OUTPUTPROFILE_MASHPWMACTIVE;
  else if (vessel == VS_KETTLE)
    return OUTPUTPROFILE_KETTLEPWMACTIVE;
}

byte autoValveBitmask(void) {
  byte modeMask = 0;
  for (byte i = AV_FILL; i < NUM_AV; i++)
    if (autoValve[i]) modeMask |= 1<<i;
  return modeMask;
}

byte getHeatPower (byte vessel) {
  return (pwmOutput[vessel] ? ((unsigned int)(pwmOutput[vessel]->getValue()) * 100 / pwmOutput[vessel]->getLimit()) : (heatStatus[vessel] ? 100 : 0));
}

#ifdef ESTOP_PIN
boolean isEStop() {
  return (outputs->getOutputEnableMask(OUTPUTENABLE_ESTOP) == outputs->getProfileMask(OUTPUTPROFILE_ALARM));
}
#endif
