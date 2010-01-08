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

Compiled on Arduino-0015 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

#include <OneWire.h>
//One Wire Bus on 
OneWire ds(5);

/* The following function is currently not in use:
float get_temp(boolean tUnit, byte* addr) //Unit 1 for F and 0 for C
{
  byte present = 0;
  byte i;
  byte data[12];
  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(750);               // we have to wait 750ms for the DS18S20's
  present = ds.reset();
  ds.select(addr);   
  ds.write(0xBE);         // Read Scratchpad
  for ( i = 0; i < 9; i++) { // we need 9 bytes
    data[i] = ds.read();
  }
  if ( addr[0] != 0x28) {
  rawtemp = (data[1] << 8) + data[0];
  temp = (float)rawtemp * 0.5;
  if (tUnit == 1) temp= (temp * 1.8) + 32.0;
  return temp;
 } else {
  rawtemp = (data[1] << 8) + data[0]; 
  temp = (float)rawtemp * 0.0625;
  if (tUnit == 1) temp= (temp * 1.8) + 32.0;
  return temp;
  }
}
*/

void getDSAddr(byte addrRet[8]){
  byte scanAddr[8];
  ds.reset_search();
  byte limit = 0;
  //Scan at most 10 sensors (In case the One Wire Search loop issue occurs)
  while (limit <= 10) {
    if (!ds.search(scanAddr)) {
      //No Sensor found, Return
      ds.reset_search();
      return;
    }
    boolean found = 0;
    for (int i = TS_HLT; i <= TS_BEEROUT; i++) {
      if (scanAddr[0] == tSensor[i][0] &&
          scanAddr[1] == tSensor[i][1] &&
          scanAddr[2] == tSensor[i][2] &&
          scanAddr[3] == tSensor[i][3] &&
          scanAddr[4] == tSensor[i][4] &&
          scanAddr[5] == tSensor[i][5] &&
          scanAddr[6] == tSensor[i][6] &&
          scanAddr[7] == tSensor[i][7])
      { 
          found = 1;
          break;
      }
    }
    if (!found) {
      for (int i = 0; i < 8; i++) addrRet[i] = scanAddr[i];
      return;
    }
    limit++;
  }
}

/* This function is currently not in use:
void setDS9bit(void) {
  ds.reset();
  ds.skip();    
  ds.write(0x4E);  
  ds.write(0x4B);    // default value of TH reg (user byte 1)
  ds.write(0x46);    // default value of TL reg (user byte 2)
  //ds.write(0x7F);    // 12-bit
  //ds.write(0x5F);    // 11-bit
  //ds.write(0x3F);    // 10-bit
  ds.write(0x1F);    // 9-bit
}
*/

void convertAll() {
  ds.reset();
  ds.skip();
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
}

float read_temp(int tUnit, byte* addr) { //Unit 1 for F and 0 for C
  float temp;
  int rawtemp;
  byte i;
  byte data[12];
  ds.reset();
  ds.select(addr);   
  ds.write(0xBE);         // Read Scratchpad
  for ( i = 0; i < 9; i++) data[i] = ds.read();
  if ( OneWire::crc8( data, 8) != data[8]) return -1;
  
  rawtemp = (data[1] << 8) + data[0];
  if ( addr[0] != 0x28) temp = (float)rawtemp * 0.5; else temp = (float)rawtemp * 0.0625;
  if (tUnit) temp = (temp * 1.8) + 32.0;
  return temp;

}
