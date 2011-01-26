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

#include "Config.h"
#include "Enum.h"

void eventHandler(byte eventID, int eventParam) {
  //Global Event handler
  if (eventID == EVENT_STEPINIT) {
    //Nothing to do here (Pass to UI handler below)
  }
  else if (eventID == EVENT_SETPOINT) {
    //Setpoint Change (Update AutoValve Logic)
    byte avProfile = vesselAV(eventParam);
    byte vlvHeat = vesselVLVHeat(eventParam);
    byte vlvIdle = vesselVLVIdle(eventParam);
    
    if (setpoint[eventParam]) autoValve[avProfile] = 1;
    else { 
      autoValve[avProfile] = 0; 
      if (vlvConfigIsActive(vlvIdle)) bitClear(actProfiles, vlvIdle);
      if (vlvConfigIsActive(vlvHeat)) bitClear(actProfiles, vlvHeat);
    } 
  }
  
  #ifndef NOUI
  //Pass Event Info to UI Even Handler
  uiEvent(eventID, eventParam);
#endif
}
