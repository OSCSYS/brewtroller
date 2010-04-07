#define BUILD 387 
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

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

//*****************************************************************************************************************************
// USER COMPILE OPTIONS
//*****************************************************************************************************************************

//**********************************************************************************
// UNIT (Metric/US)
//**********************************************************************************
// By default BrewTroller will use US Units
// Uncomment USEMETRIC below to use metric instead
//
//#define USEMETRIC
//**********************************************************************************

//**********************************************************************************
// BrewTroller Board Version
//**********************************************************************************
// Certain pins have moved from one board version to the next. Uncomment one of the
// following definitions to to indifty what board you are using.
// Use BTBOARD_1 for 1.0 - 2.1 boards without the pump/valve 3 & 4 remapping fix
// Use BTBOARD_2.2 for 2.2 boards and earlier boards that have the PV 3-4 remapping
// Use BTBOARD_3 for 3.0 boards
//
//#define BTBOARD_1
//#define BTBOARD_2.2
#define BTBOARD_3
//**********************************************************************************

//**********************************************************************************
// MUX Boards
//**********************************************************************************
// Uncomment one of the following lines to enable MUX'ing of Pump/Valve Outputs
// Note: MUX'ing requires 1-4 expansion boards providing 8-32 pump/valve outputs
// To use the original 11 Pump/valve outputs included in BrewTroller 1.0 - 2.0 leave
// all lines commented. If you are using BTBOARD_3, MUXBOARDS 2 is used automatically
// but you can override the default by specifying a value below.
//
//#define MUXBOARDS 1
//#define MUXBOARDS 2
//#define MUXBOARDS 3
//#define MUXBOARDS 4
//**********************************************************************************

//**********************************************************************************
// Steam Mash Infusion Support
//**********************************************************************************
// Uncomment the following line to enable steam mash infusion support. Note: Steam
// support will disable onboard pump/valve outputs requiring the use of MUX boards
//
//#define USESTEAM
//**********************************************************************************

//**********************************************************************************
// PID Output Power Limit
//**********************************************************************************
// These settings can be used to limit the PID output of the the specified heat
// output. Enter a percentage (0-100)
//
#define PIDLIMIT_HLT 100
#define PIDLIMIT_MASH 100
#define PIDLIMIT_KETTLE 100
#define PIDLIMIT_STEAM 100
//**********************************************************************************

//**********************************************************************************
// Kettle Lid Control
//**********************************************************************************
// The kettle lid Valve Profile can be used to automate covering of the boil kettle.
// The kettle lid profile is activated in the Chill stage of AutoBrew when the
// kettle temperature is less than the threshhold specified below.
//
#ifdef USEMETRIC
  //Celcius
  #define KETTLELID_THRESH 80
#else
  //Fahrenheit
  #define KETTLELID_THRESH 176
#endif
//**********************************************************************************

//**********************************************************************************
// Hop Addition Valve Profile
//**********************************************************************************
// A valve profile is activated based on the boil additions schedule during the boil
// stage of AutoBrew. The parameter below is used to define how long (in milliseconds)
// the profile stays active during each addition.
// Note: This value is also applied at the end of boil if a 0 Min boil addition is
// included in the schedule. The delay at the end is implemented using the delay() 
// function which will freeze all other processing of AutoBrew operations at the end
// of boil for the specified number of milliseconds.

#define HOPADD_DELAY 5000
//**********************************************************************************

//**********************************************************************************
// Smart HERMS HLT
//**********************************************************************************
// SMART_HERMS_HLT: Varies HLT setpoint based on mash target + variance
// MASH_HEAT_LOSS: acts a s a floor value to ensure HLT temp is at least target + 
// specified value
// HLT_MAX_TEMP: Ceiling value for HLT

//#define SMART_HERMS_HLT
#define MASH_HEAT_LOSS 0
#define HLT_MAX_TEMP 180
//**********************************************************************************

//**********************************************************************************
// Strike Temperature Correction
//**********************************************************************************
// STRIKE_TEMP_OFFSET: Adjusts strike temperature to compensate for thermal mass of
// mash tun. (Note: This option is used only when Mash Liquor Heat Source is set to
// HLT.)

//#define STRIKE_TEMP_OFFSET 1

//**********************************************************************************

//**********************************************************************************
// Pre-Boil Alarm
//**********************************************************************************
// PREBOIL_ALARM: Triggers the alarm during the boil stage when the defined
// temperature is reached

//#define PREBOIL_ALARM 205
//**********************************************************************************

//**********************************************************************************
// Auto Boil Recirc
//**********************************************************************************
// AUTO_BOIL_RECIRC: Activates the BOIL RECIRC valve profile during the last minutes
// of the AutoBrew Boil stage as defined below (ie AUTO_BOIL_RECIRC 20 will enable
// BOIL RECIRC for the last twenty minutes of boil. Warning: if you do not have a
// valve config that will reroute wort back to the kettle there is a great risk of
// losing wort or causing personal injury when this profile is enabled

//#define AUTO_BOIL_RECIRC 20
//**********************************************************************************

//**********************************************************************************
// LOG INTERVAL
//**********************************************************************************
// Specifies how often data is logged via serial in milliseconds. If real time
// display of data is being used a smaller interval is best (1000 ms). A larger
// interval can be used for logging applications to reduce log file size (5000 ms).

#define LOG_INTERVAL 2000
//**********************************************************************************


//**********************************************************************************
// UI Support
//**********************************************************************************
// Uncomment the following line to disable built-in user interface 
//
//#define NOUI
//**********************************************************************************


//**********************************************************************************
// Brew Step Automation
//**********************************************************************************
// Uncomment the following line(s) to enable various steps to start/stop 
// automatically 
//
// AUTO_FILL: This option will enable the Fill AutoValve logic at the start of the
// Fill step. The Fill step will automatically exit once target volumes have been
// reached.
// #define AUTO_FILL

// AUTO_MASH_HOLD_EXIT: By default the user must manually exit the Mash Hold step.
// This prevents the mash from cooling if the brewer is not present at the end of
// the last mash step. Use this option to automatically exit the mash hold step if
// the boil zone is inactive.
// #define AUTO_MASH_HOLD_EXIT
//**********************************************************************************


//**********************************************************************************
// DEBUG
//**********************************************************************************
// Enables Serial Out with Additional Debug Data
//
//#define DEBUG
//**********************************************************************************


//*****************************************************************************************************************************
// BEGIN CODE
//*****************************************************************************************************************************
#include <avr/pgmspace.h>
#include <PID_Beta6.h>
#include <pin.h>

void(* softReset) (void) = 0;

//**********************************************************************************
//Compile Time Logic
//**********************************************************************************

// Disable On board pump/valve outputs for BT Board 3.0 and older boards using steam
// Set MUXBOARDS 0 for boards without on board or MUX Pump/valve outputs
#if defined BTBOARD_3 && !defined MUXBOARDS
  #define MUXBOARDS 2
#endif

#if !defined BTBOARD_3 && !defined USESTEAM && !defined MUXBOARDS
  #define ONBOARDPV
#else
  #if !defined MUXBOARDS
    #define MUXBOARDS 0
  #endif
#endif



//Enable Serial on BTBOARD_2.2+ boards or if DEBUG is set
#if !defined BTBOARD_1 || defined DEBUG
  #define USESERIAL
#endif

//Pin and Interrupt Definitions
#define ENCA_PIN 2
#define ENCB_PIN 4
#define TEMP_PIN 5

#define ENTER_PIN 11
#define ALARM_PIN 15
#define ENTER_INT 1
#define ENCA_INT 2

//P/V Ouput Defines
#define MUX_LATCH_PIN 12
#define MUX_CLOCK_PIN 13
#define MUX_DATA_PIN 14
#define MUX_OE_PIN 10

#define VALVE1_PIN 6
#define VALVE2_PIN 7

#ifdef BTBOARD_2.2
  #define VALVE3_PIN 25
  #define VALVE4_PIN 26
#else
  #define VALVE3_PIN 8
  #define VALVE4_PIN 9
#endif

#define VALVE5_PIN 10
#define VALVE6_PIN 12
#define VALVE7_PIN 13
#define VALVE8_PIN 14
#define VALVE9_PIN 24
#define VALVEA_PIN 18
#define VALVEB_PIN 16

#define HLTHEAT_PIN 0
#define MASHHEAT_PIN 1
#define KETTLEHEAT_PIN 3
#define STEAMHEAT_PIN 6

//Reverse pin swap on 2.x boards
#ifdef BTBOARD_2.2
  #define HLTVOL_APIN 2
  #define KETTLEVOL_APIN 0
#else
  #define HLTVOL_APIN 0
  #define KETTLEVOL_APIN 2
#endif

#define MASHVOL_APIN 1
#define STEAMPRESS_APIN 3

//TSensor and Output (0-2) Array Element Constants
#define TS_HLT 0
#define TS_MASH 1
#define TS_KETTLE 2
#define TS_H2OIN 3
#define TS_H2OOUT 4
#define TS_BEEROUT 5
#define TS_AUX1 6
#define TS_AUX2 7
#define TS_AUX3 8

#define VS_HLT 0
#define VS_MASH 1
#define VS_KETTLE 2
#define VS_STEAM 3

//Auto-Valve Modes
#define AV_FILL 0
#define AV_MASH 1
#define AV_SPARGE 2
#define AV_CHILL 3
#define NUM_AV 4

//Valve Array Element Constants and Variables
#define VLV_ALL 4294967295
#define VLV_FILLHLT 0
#define VLV_FILLMASH 1
#define VLV_ADDGRAIN 2
#define VLV_MASHHEAT 3
#define VLV_MASHIDLE 4
#define VLV_SPARGEIN 5
#define VLV_SPARGEOUT 6
#define VLV_HOPADD 7
#define VLV_KETTLELID 8
#define VLV_CHILLH2O 9
#define VLV_CHILLBEER 10
#define VLV_BOILRECIRC 11
#define VLV_DRAIN 12

//Timers
#define TIMER_MASH 0
#define TIMER_BOIL 1

//Brew Steps
#define NUM_BREW_STEPS 15

#define STEP_FILL 0
#define STEP_DELAY 1
#define STEP_PREHEAT 2
#define STEP_ADDGRAIN 3
#define STEP_REFILL 4
#define STEP_DOUGHIN 5
#define STEP_ACID 6
#define STEP_PROTEIN 7
#define STEP_SACCH 8
#define STEP_SACCH2 9
#define STEP_MASHOUT 10
#define STEP_MASHHOLD 11
#define STEP_SPARGE 12
#define STEP_BOIL 13
#define STEP_CHILL 14

#define MASH_DOUGHIN 0
#define MASH_ACID 1
#define MASH_PROTEIN 2
#define MASH_SACCH 3
#define MASH_SACCH2 4
#define MASH_MASHOUT 5

//Zones
#define ZONE_MASH 0
#define ZONE_BOIL 1

//Events
#define EVENT_STEPINIT 0

//Heat Output Pin Array
pin heatPin[4], alarmPin;

#ifdef ONBOARDPV
  pin valvePin[11];
#endif

#if MUXBOARDS > 0
  pin muxLatchPin, muxDataPin, muxClockPin, muxOEPin;
#endif

//Volume Sensor Pin Array
byte vSensor[3] = { HLTVOL_APIN, MASHVOL_APIN, KETTLEVOL_APIN};

//8-byte Temperature Sensor Address x9 Sensors
byte tSensor[9][8];
float temp[9];

//Volume
unsigned long tgtVol[3], volAvg[3], calibVols[3][10];
unsigned int calibVals[3][10];

//Valve Variables
unsigned long vlvConfig[13], vlvBits;
boolean autoValve[NUM_AV];

//Shared buffers
char menuopts[21][20], buf[20];

//Output Globals
double PIDInput[4], PIDOutput[4], setpoint[4];
byte PIDCycle[4], hysteresis[4];
unsigned long cycleStart[4];
boolean heatStatus[4], PIDEnabled[4];
unsigned int steamPSens, steamZero;
float steamPressure;
byte steamTgt, boilPwr;

PID pid[4] = {
  PID(&PIDInput[VS_HLT], &PIDOutput[VS_HLT], &setpoint[VS_HLT], 3, 4, 1),
  PID(&PIDInput[VS_MASH], &PIDOutput[VS_MASH], &setpoint[VS_MASH], 3, 4, 1),
  PID(&PIDInput[VS_KETTLE], &PIDOutput[VS_KETTLE], &setpoint[VS_KETTLE], 3, 4, 1),
  PID(&PIDInput[VS_STEAM], &PIDOutput[VS_STEAM], &setpoint[VS_STEAM], 3, 4, 1)
};

//Timer Globals
unsigned long timerValue[2], lastTime[2];
boolean timerStatus[2], alarmStatus;

//Log Globals
boolean logData = 0;
boolean msgQueued;
unsigned long lastLog;
byte logCount, msgField;
char msg[25][21];

//Brew Step Logic Globals
//Active program for each brew step
#define PROGRAM_IDLE 255
byte stepProgram[NUM_BREW_STEPS];
boolean preheated[4], doAutoBoil;

//Bit 1 = Boil; Bit 2-11 (See Below); Bit 12 = End of Boil; Bit 13-15 (Open); Bit 16 = Preboil (If Compile Option Enabled)
unsigned int hoptimes[10] = { 105, 90, 75, 60, 45, 30, 20, 15, 10, 5 };


const char BT[] PROGMEM = "BrewTroller";
const char BTVER[] PROGMEM = "1.3";

//Log Strings
const char LOGCMD[] PROGMEM = "CMD";
const char LOGDEBUG[] PROGMEM = "DEBUG";
const char LOGSYS[] PROGMEM = "SYSTEM";
const char LOGGLB[] PROGMEM = "GLOBAL";
const char LOGDATA[] PROGMEM = "DATA";

void setup() {
  //Initialize Brew Steps to 'Idle'
  for(byte brewStep = 0; brewStep < NUM_BREW_STEPS; brewStep++) stepProgram[brewStep] = PROGRAM_IDLE;
  
  //Log initialization (Log.pde)
  logInit();
  
  //Pin initialization (Outputs.pde)
  pinInit();
  
  //User Interface Initialization (UI.pde)
  #ifndef NOUI
    uiInit();
  #endif

  //Check for cfgVersion variable and update EEPROM if necessary (EEPROM.pde)
  checkConfig();
  
  //Load global variable values stored in EEPROM (EEPROM.pde)
  loadSetup();

  //PID Initialization (Outputs.pde)
  pidInit();

  //Load last saved EEPROM value for valve configuration
  setValves(getValveRecovery(), 1);
}

void loop() {
  //User Interface Processing (UI.pde)
  #ifndef NOUI
    uiCore();
  #endif
  
  //Core BrewTroller process code (BrewCore.pde)
  brewCore();
}
