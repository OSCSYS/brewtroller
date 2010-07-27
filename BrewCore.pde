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


void brewCore() {
  //Timers: Timer.pde
  updateTimers();
  
  //Volumes: Volume.pde
  updateVols();
  
  #ifdef FLOWRATE_CALCS
    updateFlowRates();
  #endif
  
  //Log: Log.pde
  updateLog();
  
  //temps: Temp.pde
  updateTemps();
  
  steamPressure = readPressure(STEAMPRESS_APIN, steamPSens, steamZero);
  
  //Heat Outputs: Outputs.pde
  processHeatOutputs();
  
  //Auto Valve Logic: Outputs.pde
  processAutoValve();
  
  //Step Logic: StepLogic.pde
  stepCore();
  
  //BTPD Support
  #ifdef BTPD_SUPPORT
    updateBTPD();
  #endif
}
