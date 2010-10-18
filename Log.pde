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

  Update 9/22/2010 to support enhanced functions and mutiple schemas.
  
*/

//**********************************************************************************
//Code Shared by all Schemas
//**********************************************************************************
#include "Config.h"
#include "Enum.h"

void logInit() {
  #if defined USESERIAL
    Serial.begin(BAUD_RATE);
    //Always identify
    logVersion();
  #endif
}

void logVersion() {
  logStart_P(LOGSYS);
  logField_P(PSTR("VER"));
  logField_P(BTVER);
  logField(itoa(BUILD, buf, 10));
  #if COMSCHEMA > 0 
    logField(itoa(COMSCHEMA, buf, 10));
    #ifdef USEMETRIC
      logFieldI(0);
    #else
      logFieldI(1);
    #endif
  #endif
  logEnd();
}

