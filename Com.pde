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

//**********************************************************************************
//Code Shared by all Schemas
//**********************************************************************************
#include "Config.h"
#include "Enum.h"

void comInit() {
  #if defined COM_SERIAL0
    Serial.begin(SERIAL0_BAUDRATE);
    //Always identify
    if (logData)
      logASCIIVersion();
  #endif
}

#if defined COM_SERIAL0
void logASCIIVersion() {
  printFieldUL(millis());   // timestamp
  printFieldPS(LOGSYS);     // keyword "SYS"
  Serial.print("VER\t");  // Version record
  printFieldPS(BTVER);      // BT Version
  printFieldUL(BUILD);      // Build #
  #if COM_SERIAL0 == BTNIC || (COM_SERIAL0 == ASCII && COMSCHEMA > 0)
    printFieldUL(COM_SERIAL0);  // Protocol Type
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

void updateCom() {
  
  #ifdef COM_SERIAL0
    #if COM_SERIAL0 == ASCII
      updateS0ASCII(); /* Log_ASCII.pde */
    #elif COM_SERIAL0 == BTNIC
      updateS0BTnic();
    #endif
  #endif
  #ifdef BTNIC_EMBEDDED
    updateI2CBTnic();
  #endif
  //BTPD Support
  #ifdef BTPD_SUPPORT
    updateBTPD();
  #endif
  
}

/********************************************************************************************************************
 * BTnic Instances
 ********************************************************************************************************************/
#ifdef BTNIC_PROTOCOL
  #include "Com_BTnic.h"
  
  #ifdef BTNIC_EMBEDDED
    BTnic btnicI2C;
    void updateI2CBTnic() {
      
    }
  #endif
  
  #ifdef COM_SERIAL0
    #if COM_SERIAL0 == BTNIC /* BTnic over Serial0 */
      BTnic btnicS0;
      void updateS0BTnic() {
        if(btnicS0.getState() == BTNIC_STATE_RX) {
          while (Serial.available()) {
            btnicS0.rx(Serial.read());
            if(btnicS0.getState() == BTNIC_STATE_TX) break;
          }
        }
        if(btnicS0.getState() == BTNIC_STATE_TX) {
          //TX Ready
          Serial.print(millis(),DEC);
          Serial.write(0x09);
          while(btnicS0.getState() == BTNIC_STATE_TX) Serial.write(btnicS0.tx());
          Serial.write(0x0D); //Carriage Return
          Serial.write(0x0A); //New Line
        }
      }
    #endif
  #endif
#endif


void comEvent(byte eventID, int eventParam) {
  #ifdef BTNIC_PROTOCOL
    #ifdef BTNIC_EMBEDDED
      btnicI2C.eventHandler(eventID, eventParam);
    #endif
    #ifdef COM_SERIAL0
      #if COM_SERIAL0 == BTNIC /* BTnic over Serial0 */
        btnicS0.eventHandler(eventID, eventParam);
      #endif
    #endif
  #endif
}
