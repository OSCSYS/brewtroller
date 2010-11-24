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
    if (eventParam == VS_HLT) { 
      if (setpoint[VS_HLT]) autoValve[AV_HLT] = 1; 
      else { 
        autoValve[AV_HLT] = 0; 
        if (vlvConfigIsActive(VLV_HLTHEAT)) bitClear(actProfiles, VLV_HLTHEAT);
      } 
    }
    else if (eventParam == VS_MASH) { 
      if (setpoint[VS_MASH]) autoValve[AV_MASH] = 1; 
      else { 
        autoValve[AV_MASH] = 0; 
        if (vlvConfigIsActive(VLV_MASHIDLE)) bitClear(actProfiles, VLV_MASHIDLE);
        if (vlvConfigIsActive(VLV_MASHHEAT)) bitClear(actProfiles, VLV_MASHHEAT);
      } 
    }
  }

  
  #ifndef NOUI
  //Pass Event Info to UI Even Handler
  uiEvent(eventID, eventParam);
#endif
}
