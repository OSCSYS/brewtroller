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

unsigned long volReadings[3][VOLUME_READ_COUNT], prevFlowVol[3];
unsigned long lastVolChk, lastFlowChk;
byte volCount;

void updateVols() {
  //Check volume on VOLUME_READ_INTERVAL and update vol with average of VOLUME_READ_COUNT readings
  if (millis() - lastVolChk > VOLUME_READ_INTERVAL) {
    for (byte i = VS_HLT; i <= VS_KETTLE; i++) {
      volReadings[i][volCount] = readVolume(vSensor[i], calibVols[i], calibVals[i]);
	  unsigned long volAvgTemp = volReadings[i][0];
	  for (byte j = 1; j < VOLUME_READ_COUNT; j++)
	  volAvgTemp += volReadings[i][j];
	  volAvg[i] = volAvgTemp / VOLUME_READ_COUNT; 
    }
    volCount++;
    if (volCount >= VOLUME_READ_COUNT) volCount = 0;
    lastVolChk = millis();
  }
}

#ifdef FLOWRATE_CALCS
void updateFlowRates() {
  //Check flowrate periodically (FLOWRATE_READ_INTERVAL)
  if (millis() - lastFlowChk > FLOWRATE_READ_INTERVAL) {
    for (byte i = VS_HLT; i <= VS_KETTLE; i++) {
      flowRate[i] = (prevFlowVol[i] - volAvg[i]) * (millis() - lastFlowChk) * 3 / 50;
      prevFlowVol[i] = volAvg[i];
    }
    lastFlowChk = millis();
  }
}
#endif

unsigned long readVolume( byte pin, unsigned long calibrationVols[10], unsigned int calibrationValues[10] ) {
  unsigned int aValue = analogRead(pin);
  unsigned long retValue;
  #ifdef DEBUG_VOL_READ
    logStart_P(LOGDEBUG);
    logField_P(PSTR("VOL_READ"));
    logFieldI(pin);
    logFieldI(aValue);
  #endif
  
  byte upperCal = 0;
  byte lowerCal = 0;
  byte lowerCal2 = 0;
  for (byte i = 0; i < 10; i++) {
    if (aValue == calibrationValues[i]) { 
      upperCal = i;
      lowerCal = i;
      lowerCal2 = i;
      break;
    } else if (aValue > calibrationValues[i]) {
        if (aValue < calibrationValues[lowerCal]) lowerCal = i;
        else if (calibrationValues[i] > calibrationValues[lowerCal]) { 
          if (aValue < calibrationValues[lowerCal2] || calibrationValues[lowerCal] > calibrationValues[lowerCal2]) lowerCal2 = lowerCal;
          lowerCal = i; 
        } else if (aValue < calibrationValues[lowerCal2] || calibrationValues[i] > calibrationValues[lowerCal2]) lowerCal2 = i;
    } else if (aValue < calibrationValues[i]) {
      if (aValue > calibrationValues[upperCal]) upperCal = i;
      else if (calibrationValues[i] < calibrationValues[upperCal]) upperCal = i;
    }
  }
  
  #ifdef DEBUG_VOL_READ
    logFieldI(aValue);
    logFieldI(upperCal);
    logFieldI(lowerCal);
    logFieldI(lowerCal2);
  #endif
  
  //If no calibrations exist return zero
  if (calibrationValues[upperCal] == 0 && calibrationValues[lowerCal] == 0) retValue = 0;

  //If the value matches a calibration point return that value
  else if (aValue == calibrationValues[lowerCal]) retValue = calibrationVols[lowerCal];
  else if (aValue == calibrationValues[upperCal]) retValue = calibrationVols[upperCal];
  
  //If read value is greater than all calibrations plot value based on two closest lesser values
  else if (aValue > calibrationValues[upperCal] && calibrationValues[lowerCal] > calibrationValues[lowerCal2]) retValue = round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[lowerCal] - calibrationValues[lowerCal2]) * (calibrationVols[lowerCal] - calibrationVols[lowerCal2])) + calibrationVols[lowerCal];
  
  //If read value exceeds all calibrations and only one lower calibration point is available plot value based on zero and closest lesser value
  else if (aValue > calibrationValues[upperCal]) retValue = round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[lowerCal]) * (calibrationVols[lowerCal])) + calibrationVols[lowerCal];
  
  //If read value is less than all calibrations plot value between zero and closest greater value
  else if (aValue < calibrationValues[lowerCal]) retValue = round((float) aValue / (float) calibrationValues[upperCal] * calibrationVols[upperCal]);
  
  //Otherwise plot value between lower and greater calibrations
  else retValue = round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[upperCal] - calibrationValues[lowerCal]) * (calibrationVols[upperCal] - calibrationVols[lowerCal])) + calibrationVols[lowerCal];

  #ifdef DEBUG_VOL_READ
    logFieldI(retValue);
    logEnd();
  #endif
  return retValue;
}

//Read Analog value of aPin and calculate kPA or psi based on unit and sensitivity (sens in tenths of mv per kpa)
unsigned long readPressure( byte aPin, unsigned int sens, unsigned int zero) {
  if (sens == 0) return 999;
  unsigned long retValue = (analogRead(aPin) - zero) * 500000 / sens * 25 / 256;
  #ifdef USEMETRIC
    return retValue; 
  #else
    return retValue * 29 / 200; 
  #endif
}
