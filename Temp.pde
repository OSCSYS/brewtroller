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
#ifdef TS_ONEWIRE
  #include <OneWire.h>
  //One Wire Bus on 
  OneWire ds(TEMP_PIN);
  unsigned long convStart;
  
  #if TS_ONEWIRE_RES == 12
    #define CONV_DELAY 750
  #elif TS_ONEWIRE_RES == 11
    #define CONV_DELAY 375
  #elif TS_ONEWIRE_RES == 10
    #define CONV_DELAY 188
  #else //Default to 9-bit
    #define CONV_DELAY 94
  #endif
#endif

void tempInit() {
  ds.reset();
  ds.skip();
  ds.write(0x4E, TS_ONEWIRE_PPWR); //Write to scratchpad
  ds.write(0x4B, TS_ONEWIRE_PPWR); //Default value of TH reg (user byte 1)
  ds.write(0x46, TS_ONEWIRE_PPWR); //Default value of TL reg (user byte 2)

  #if TS_ONEWIRE_RES == 12
    ds.write(0x7F, TS_ONEWIRE_PPWR); //Config Reg (12-bit)
  #elif TS_ONEWIRE_RES == 11
    ds.write(0x5F, TS_ONEWIRE_PPWR); //Config Reg (11-bit)
  #elif TS_ONEWIRE_RES == 10
    ds.write(0x3F, TS_ONEWIRE_PPWR); //Config Reg (10-bit)
  #else //Default to 9-bit
    ds.write(0x1F, TS_ONEWIRE_PPWR); //Config Reg (9-bit)
  #endif

  ds.reset();
  ds.skip();
  ds.write(0x48, TS_ONEWIRE_PPWR); //Copy scratchpad to EEPROM
}


void updateTemps() {
#ifdef TS_ONEWIRE
  if (convStart == 0) {
    ds.reset();
    ds.skip();
    ds.write(0x44, TS_ONEWIRE_PPWR); //Start conversion
    convStart = millis();   
  } else if (tsReady() || millis() - convStart >= CONV_DELAY) {
    #ifdef DEBUG_TEMP_CONV_T
      convStart = millis() - convStart;
      logStart_P(LOGDEBUG);
      logField_P(PSTR("TEMP_CONV_T"));
      logFieldI(convStart);
      logEnd();
    #endif
    for (byte i = TS_HLT; i <= TS_AUX3; i++) temp[i] = read_temp(tSensor[i]);
    convStart = 0;
    
    #if defined MASH_AVG
      mashAvg();
    #endif
  }
#endif
}

#if defined MASH_AVG
void mashAvg() {
  byte sensorCount = 1;
  unsigned long avgTemp = temp[TS_MASH];
  #if defined MASH_AVG_AUX1
    if (temp[TS_AUX1] != -32768) {
      avgTemp += temp[TS_AUX1];
      sensorCount++;
    }
  #endif
  #if defined MASH_AVG_AUX2
    if (temp[TS_AUX2] != -32768) {
      avgTemp += temp[TS_AUX2];
      sensorCount++;
    }
  #endif
  #if defined MASH_AVG_AUX3
    if (temp[TS_AUX3] != -32768) {
      avgTemp += temp[TS_AUX3];
      sensorCount++;
    }
  #endif
  temp[TS_MASH] = avgTemp / sensorCount;
}
#endif

boolean tsReady() {
  #if TS_ONEWIRE_PPWR == 0 //Poll if parasite power is disabled
    if (ds.read() == 0xFF) return 1;
  #endif
  return 0;
}

void getDSAddr(byte addrRet[8]){
//Leaving stub for external functions (serial and setup) that use this function
#ifdef TS_ONEWIRE
  byte scanAddr[8];
  ds.reset_search();
  byte limit = 0;
  //Scan at most 20 sensors (In case the One Wire Search loop issue occurs)
  while (limit <= 20) {
    if (!ds.search(scanAddr)) {
      //No Sensor found, Return
      ds.reset_search();
      return;
    }
    boolean found = 0;
    for (byte i = TS_HLT; i <= TS_AUX3; i++) {
      boolean match = 1;
      for (byte j = 0; j < 8; j++) {
        if (scanAddr[j] != tSensor[i][j]) {
          match = 0;
          break;
        }
      }
      if (match) { 
        found = 1;
        break;
      }
    }
    if (!found) {
      for (byte k = 0; k < 8; k++) addrRet[k] = scanAddr[k];
      return;
    }
    limit++;
  }
#endif
}

#ifdef TS_ONEWIRE
//Returns Int representing hundreths of degree
int read_temp(byte* addr) {
  int tempOut;
  byte data[9];
  ds.reset();
  ds.select(addr);   
  ds.write(0xBE, TS_ONEWIRE_PPWR); //Read Scratchpad
  for (byte i = 0; i < 9; i++) data[i] = ds.read();
  if (OneWire::crc8( data, 8) != data[8]) return -32768;
  
  tempOut = (data[1] << 8) + data[0];

  if ( addr[0] == 0x10) tempOut = tempOut * 50; //9-bit DS18S20
  else tempOut = tempOut * 25 / 4; //12-bit DS18B20, etc.
  
  #ifdef USEMETRIC
    return tempOut;  
  #else
    return (tempOut * 9 / 5) + 3200;
  #endif
}
#endif
