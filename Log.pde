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

//**********************************************************************************
//Code Shared by all Schemas
//**********************************************************************************
#include "Config.h"
#include "Enum.h"

void logInit() {
  #if defined USESERIAL
    Serial.begin(BAUD_RATE);
    //Always identify
    if (logData)
      logASCIIVersion();
  #endif
}

#if defined USESERIAL
void logASCIIVersion() {
  printFieldUL(millis());   // timestamp
  printFieldPS(LOGSYS);     // keyword "SYS"
  Serial.print("VER\t");  // Version record
  printFieldPS(BTVER);      // BT Version
  printFieldUL(BUILD);      // Build #
  #if COMTYPE > 0 || COMSCHEMA > 0
    printFieldUL(COMTYPE);  // Protocol Type
    printFieldUL(COMSCHEMA);// Protocol Schema
    #ifdef USEMETRIC      // Metric or US units
      Serial.print("0");
    #else
      Serial.print("1");
    #endif
  #endif
  Serial.println();
}

void printFieldUL (unsigned long uLong) {
  Serial.print(uLong, DEC);
  Serial.print("\t");
}

void printFieldPS (const char *sText) {
  while (pgm_read_byte(sText) != 0) Serial.print(pgm_read_byte(sText++));
  Serial.print("\t");
}

#endif
