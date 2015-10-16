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

#ifdef TS_ONEWIRE
  #ifdef TS_ONEWIRE_GPIO
    #include "LOCAL_OneWire.h"
    OneWire ds(TEMP_PIN);
  #endif
  #ifdef TS_ONEWIRE_I2C
    #include "LOCAL_DS2482.h"
    DS2482 ds(DS2482_ADDR);
  #endif
  //One Wire Bus on 
  
  void tempInit() {
    #ifdef TS_ONEWIRE_I2C
      ds.configure(DS2482_CONFIG_APU);
    #endif
    for (byte i = 0; i < NUM_TS; i++) {
      temp[i] = BAD_TEMP;

      if (validAddr(tSensor[i])) {
        byte resolution = getResolution(tSensor[i]);
        if (resolution && resolution != TS_ONEWIRE_RES)
          setResolution(tSensor[i], TS_ONEWIRE_RES);
      }
    }
  }


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

  void updateTemps() {
    if (convStart == 0) {
      ds.reset();
      ds.skip();
      ds.write(0x44, TS_ONEWIRE_PPWR); //Start conversion
      convStart = millis();   
    } else if (tsReady() || millis() - convStart >= CONV_DELAY) {
      for (byte i = 0; i < NUM_TS; i++) {
        if (validAddr(tSensor[i]))
          temp[i] = read_temp(tSensor[i]); 
        else 
          temp[i] = BAD_TEMP;
      }
      
      convStart = 0;
      
      #if defined MASH_AVG
        mashAvg();
      #endif
    }
  }

  boolean tsReady() {
    #if TS_ONEWIRE_PPWR == 0 //Poll if parasite power is disabled
      if (ds.read() == 0xFF) return 1;
    #endif
    return 0;
  }
  
  boolean validAddr(byte* addr) {
    for (byte i = 0; i < 8; i++) if (addr[i]) return 1;
    return 0;
  }
  
  //This function search for an address that is not currently assigned!
  void getDSAddr(byte addrRet[8]){
  //Leaving stub for external functions (serial and setup) that use this function
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
      if (
          scanAddr[0] == 0x28 ||  //DS18B20
          scanAddr[0] == 0x10     //DS18S20
         ) 
      {
        boolean found = 0;
        for (byte i = 0; i <  NUM_TS; i++) {
          boolean match = 1;
          for (byte j = 0; j < 8; j++) {
            //Try to confirm a match by checking every byte of the scanned address with those of each sensor.
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
      }
      limit++;
    }      
  }

void setResolution(byte *addr, byte resolution) {
  resolution = constrain(resolution, 9, 12);
  resolution = 0x1F + ((resolution - 9) << 5);

  ds.reset();
  ds.select(addr);
  ds.write(0x4E, TS_ONEWIRE_PPWR); //Write to scratchpad
  ds.write(0x4B, TS_ONEWIRE_PPWR); //Default value of TH reg (user byte 1)
  ds.write(0x46, TS_ONEWIRE_PPWR); //Default value of TL reg (user byte 2)
  ds.write(resolution, TS_ONEWIRE_PPWR); //Config Reg (12-bit)

  ds.reset();
  ds.select(addr);
  ds.write(0xBE, TS_ONEWIRE_PPWR); //Read scratchpad
  byte data;
  for (byte i = 0; i < 5; i++)
    data = ds.read();
  Serial.println(((data >> 5) & 3) + 9, DEC);

  ds.reset();
  ds.select(addr);
  ds.write(0x48, TS_ONEWIRE_PPWR); //Copy scratchpad to EEPROM
}

byte getResolution(byte *addr) {
  byte data;
  
  ds.reset();
  ds.select(addr);
  ds.write(0xB8, TS_ONEWIRE_PPWR); //Copy EEPROM to scratchpad
  
  
  ds.reset();
  ds.select(addr);
  ds.write(0xBE, TS_ONEWIRE_PPWR); //Read scratchpad
  for (byte i = 0; i < 5; i++)
    data = ds.read();

  if (data == 0xFF)
    return 0;
  return ((data >> 5) & 3) + 9;
}
  
//Returns Int representing hundreths of degree
  int read_temp(byte* addr) {
    long tempOut;
    byte data[9];
    ds.reset();
    ds.select(addr);   
    ds.write(0xBE, TS_ONEWIRE_PPWR); //Read Scratchpad
    #ifdef TS_ONEWIRE_FASTREAD
      for (byte i = 0; i < 2; i++)
        data[i] = ds.read();
      if (data[0] & data[1] == 0xFF)
        return BAD_TEMP;
    #else
      for (byte i = 0; i < 9; i++) data[i] = ds.read();
      if (ds.crc8( data, 8) != data[8]) return BAD_TEMP;
    #endif

    tempOut = (data[1] << 8) + data[0];
    
    if ( addr[0] == 0x10) tempOut = tempOut * 50; //9-bit DS18S20
    else tempOut = tempOut * 25 / 4; //12-bit DS18B20, etc.
      
    #ifdef USEMETRIC
      return int(tempOut);  
    #else
      return int((tempOut * 9 / 5) + 3200);
    #endif
  }
#else
  void tempInit() {}
  void updateTemps() {}
  void getDSAddr(byte addrRet[8]){};
#endif

#if defined MASH_AVG
void mashAvg() {
  byte sensorCount = 1;
  unsigned long avgTemp = temp[TS_MASH];
  #if defined MASH_AVG_AUX1
    if (temp[TS_AUX1] != BAD_TEMP) {
      avgTemp += temp[TS_AUX1];
      sensorCount++;
    }
  #endif
  #if defined MASH_AVG_AUX2
    if (temp[TS_AUX2] != BAD_TEMP) {
      avgTemp += temp[TS_AUX2];
      sensorCount++;
    }
  #endif
  #if defined MASH_AVG_AUX3
    if (temp[TS_AUX3] != BAD_TEMP) {
      avgTemp += temp[TS_AUX3];
      sensorCount++;
    }
  #endif
  temp[TS_MASH] = avgTemp / sensorCount;
}
#endif


