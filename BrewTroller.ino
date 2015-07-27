#define BUILD 12
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



/*
Compiled on Arduino-1.6.5-R2 (http://arduino.cc/en/Main/Software)

Support for BrewTroller/OpenTroller boards requires the following URL to be added
to the Additional Boards Manager URLS in Arduino Preferences:
https://github.com/OSCSYS/boards/raw/master/package_OSCSYS_Boards_index.json

Then use Tools - Board - Boards Manager to install OpenTroller ATMEGA1284P by OSCSYS
*/



//*****************************************************************************************************************************
// BEGIN CODE
//*****************************************************************************************************************************

#include <avr/pgmspace.h>
#include "LOCAL_PID_Beta6.h"
#include "LOCAL_Pin.h"
#include "LOCAL_ModbusMaster.h"
#include <Wire.h>
#include "LOCAL_Menu.h"

#include "BrewTrollerApplication.h"
#include "Vessel.h"
#include "HWProfile.h"
#include "Config.h"
#include "Enum.h"
#include "Outputs.h"
#include "Trigger.h"
#include "UI_LCD.h"
#include "UI_Lang.h"
#include <avr/eeprom.h>
#include <EEPROM.h>
#include "wiring_private.h"
#include "LOCAL_Encoder.h"
#ifdef RGBIO8_ENABLE
  #include "RGBIO8.h"
#endif
#include "Vol_Bubbler.h"

#define ARRAY_LENGTH(ARRAYOBJ) (sizeof(ARRAYOBJ) / sizeof(ARRAYOBJ[0]))

void(* softReset) (void) = 0;

const char BT[] PROGMEM = "BrewTroller";
const char BTVER[] PROGMEM = "2.7";

//**********************************************************************************
// Compile Time Logic
//**********************************************************************************

//Enable Mash Avergaing Logic if any Mash_AVG_AUXx options were enabled
#if defined MASH_AVG_AUX1 || defined MASH_AVG_AUX2 || defined MASH_AVG_AUX3
  #define MASH_AVG
#endif

#ifndef STRIKE_TEMP_OFFSET
  #define STRIKE_TEMP_OFFSET 0
#endif

#if COM_SERIAL0 == BTNIC || defined BTNIC_EMBEDDED
  #define BTNIC_PROTOCOL
#endif


#ifdef USEMETRIC
  #define EvapRateConversion 1000
#else
  #define EvapRateConversion 100
#endif


#if TS_ONEWIRE_RES == 12
  #define PID_UPDATE_INTERVAL 750
#elif TS_ONEWIRE_RES == 11
  #define PID_UPDATE_INTERVAL 375
#elif TS_ONEWIRE_RES == 10
  #define PID_UPDATE_INTERVAL 188
#elif TS_ONEWIRE_RES == 9
  #define PID_UPDATE_INTERVAL 94
#else
  // should not be this value, fail the compile
  #ERROR
#endif

#define PIDGAIN_DIV 100
#define PIDGAIN_DEC 2
#define PIDGAIN_LIM 65535



//**********************************************************************************
// Globals
//**********************************************************************************
#ifdef ESTOP_PIN
  pin *estopPin = NULL;
#endif

Trigger *trigger[USERTRIGGER_COUNT];

//8-byte Temperature Sensor Address x9 Sensors
byte tSensor[NUM_TS][8];
int temp[NUM_TS];

unsigned long prevSpargeVol[2] = {0, 0};

//Create the appropriate 'LCD' object for the hardware configuration (4-Bit GPIO, I2C)
#if defined UI_LCD_4BIT
  //#include "LOCAL_LiquidCrystalFP.h"
  
  #ifndef UI_DISPLAY_SETUP
    LCD4Bit LCD(LCD_RS_PIN, LCD_ENABLE_PIN, LCD_DATA4_PIN, LCD_DATA5_PIN, LCD_DATA6_PIN, LCD_DATA7_PIN);
  #else
    LCD4Bit LCD(LCD_RS_PIN, LCD_ENABLE_PIN, LCD_DATA4_PIN, LCD_DATA5_PIN, LCD_DATA6_PIN, LCD_DATA7_PIN, LCD_BRIGHT_PIN, LCD_CONTRAST_PIN);
  #endif
  
#elif defined UI_LCD_I2C
  LCDI2C LCD(UI_LCD_I2CADDR);
#endif
 
boolean autoValve[NUM_AV];
OutputSystem* outputs = NULL;

#ifdef RGBIO8_ENABLE
  RGBIO8* rgbio[RGBIO8_MAX_BOARDS];
#endif

//Output Globals
byte boilPwr;

//Timer Globals
unsigned long timerValue[2], lastTime[2];
boolean timerStatus[2], alarmStatus;

//Brew Step Logic Globals
ControlState boilControlState = CONTROLSTATE_OFF;

struct ProgramThread programThread[PROGRAMTHREAD_MAX];

struct BrewStepConfiguration brewStepConfiguration;

//Array items correspond with 16-bit masks where:
//Bit 1 (254) = Boil; Bit 2-12 (# Minutes); Bit 16 = Preboil; Bit 13-15 (Open); 
const byte hoptimes[] = { 254, 105, 90, 75, 60, 45, 30, 20, 15, 10, 5, 0, 255 };
byte pitchTemp;


void setup() {
  BrewTrollerApplication::getInstance()->init();
}

void loop() {
  BrewTrollerApplication::getInstance()->update(PRIORITYLEVEL_NORMALUI);
}

