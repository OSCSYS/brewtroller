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

void brewCore() {
  #ifdef HEARTBEAT
    heartbeat();
  #endif
  
  #ifndef NOUI
    updateLCD();
  #endif
  
  //Timers: Timer.pde
  updateTimers();
  
  //temps: Temp.pde
  updateTemps();
 
  //Alarm update allows to have a beeping alarm
  updateBuzzer();
 
  //Heat Outputs: Outputs.pde
  processHeatOutputs();
  
  //Volumes: Volume.pde
  updateVols();

  //Log: Log.pde
  updateLog();  

  #ifdef FLOWRATE_CALCS
    updateFlowRates();
  #endif

  #ifndef PID_FLOW_CONTROL
  steamPressure = readPressure(STEAMPRESS_APIN, steamPSens, steamZero);
  #endif
  
  //Step Logic: StepLogic.pde
  stepCore();

  //Auto Valve Logic: Outputs.pde
  processAutoValve();
  
  //Set Valve Outputs based on active valve profiles (if changed): Outputs.pde
  updateValves();
  
  //BTPD Support
  #ifdef BTPD_SUPPORT
    updateBTPD();
  #endif
}

unsigned long hbStart = 0;
void heartbeat() {
  if (millis() - hbStart > 750) {
    hbPin.toggle();
    hbStart = millis();
  }
}
