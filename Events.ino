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


void eventHandler(enum EventIndex eventID, int eventParam) {
  //Global Event handler
  //EVENT_STEPINIT: Nothing to do here (Pass to UI handler below)
  //EVENT_STEPEXIT: Nothing to do here (Pass to UI handler below)
  if (eventID == EVENT_SETPOINT && !setpoint[eventParam])
    resetVesselHeat(eventParam);
  
  #ifndef NOUI
    //Pass Event Info to UI Event Handler
    uiEvent(eventID, eventParam);
  #endif

  //Pass Event Info to Com Event Handler
  comEvent(eventID, eventParam);

}

