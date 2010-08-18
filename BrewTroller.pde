#define BUILD 446 
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

/*
Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
  With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)

  Using the following libraries:
    PID  v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
    OneWire 2.0 (http://www.pjrc.com/teensy/arduino_libraries/OneWire.zip)
    Encoder by CodeRage ()
    FastPin and modified LiquidCrystal with FastPin by CodeRage (http://www.brewtroller.com/forum/showthread.php?t=626)
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
// Use BTBOARD_22 for 2.2 boards and earlier boards that have the PV 3-4 remapping
// Use BTBOARD_3 for 3.0 boards
//
//#define BTBOARD_1
//#define BTBOARD_22
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
// Vessel Options
//**********************************************************************************
// BrewTroller was designed to support three vessles (HLT, Mash and Kettle). This
// sections provides support for specific systems that differ from this model.

// HLT_AS_KETTLE: This option remaps the Kettle temp sensor, volume sensor and heat
// output to the HLT's devices to  allow the HLT to be reused as a kettle.
//#define HLT_AS_KETTLE

// MASH_PREHEAT_SENSOR: This option allows for an alternate temperature sensor to
// control the mash heat output during the Preheat step. This is used to control the
// water temperature on dedicated HEX vessel during preheat. After preheat the
// actual mash temperature sensor would be used to control the mash heat output.
// aka 'Yorg Option 1'
//#define MASH_PREHEAT_SENSOR TS_AUX1

// MASH_PREHEAT_STRIKE/MASH_PREHEAT_STEP1: Use one of the following two options to
// override the zero setpoint for the mash tun when the 'Heat Strike In' program 
// option is set to HLT. STRIKE will use the calculated strike temp. STEP1 will use
// the first mash step temp. aka 'Yorg Option 2'
//#define MASH_PREHEAT_STRIKE
//#define MASH_PREHEAT_STEP1
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
// The kettle lid profile is activated in the Chill step of a program when the
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
// OneWire Temperature Sensor Options
//**********************************************************************************
// TS_ONEWIRE: Enables use of OneWire Temperature Sensors (Future logic may
// support alternatives temperature sensor options.)
#define TS_ONEWIRE

// TS_ONEWIRE_PPWR: Specifies whether parasite power is used for OneWire temperature
// sensors. Parasite power allows sensors to obtain their power from the data line
// but significantly increases the time required to read the temperature (94-750ms
// based on resolution versus 10ms with dedicated power).
#define TS_ONEWIRE_PPWR 0

// TS_ONEWIRE_RES: OneWire Temperature Sensor Resolution (9-bit - 12-bit). Valid
// options are: 9, 10, 11, 12). Unless parasite power is being used the recommended
// setting is 12-bit. When using parasite power decreasing the resolution reduces
// the temperature conversion time: 
//   12-bit (0.0625C / 0.1125F) = 750ms 
//   11-bit (0.125C  / 0.225F ) = 375ms 
//   10-bit (0.25C   / 0.45F  ) = 188ms 
//    9-bit (0.5C    / 0.9F   ) =  94ms   
#define TS_ONEWIRE_RES 11
//**********************************************************************************


//**********************************************************************************
// Strike Temperature Correction
//**********************************************************************************
// STRIKE_TEMP_OFFSET: Adjusts strike temperature to compensate for thermal mass of
// mash tun. (Note: This option is used only when Mash Liquor Heat Source is set to
// HLT.) Specify correction in whole degrees.

//#define STRIKE_TEMP_OFFSET 1

//**********************************************************************************


//**********************************************************************************
// Mash Temperature Adjustment
//**********************************************************************************
// MASH_AVG_AUXx: Uncomment one or more of the following lines to include averaging
// of AUX1, AUX2 and/or AUX3 temp sensors with mash temp sensor.
//#define MASH_AVG_AUX1
//#define MASH_AVG_AUX2
//#define MASH_AVG_AUX3
//**********************************************************************************


//**********************************************************************************
// Sparge Options
//**********************************************************************************
// BATCH_SPARGE: Uses batch sparge logic instead of fly sparge logic for programs.
//#define BATCH_SPARGE

// BATCH_VOLUME_OFFSET: Adjusts batch volume calculations to increase or reduce the
// volume of batch sparges.
//#define BATCH_VOLUME_OFFSET 0

// BATCH_SPARGE_RECIRC: Specifies the number of seconds to run the Mash Heat valve
// profile between batch sparges.
//#define BATCH_SPARGE_RECIRC 60
//**********************************************************************************


//**********************************************************************************
// Pre-Boil Alarm
//**********************************************************************************
// PREBOIL_ALARM: Triggers the alarm during the boil stage when the defined
// temperature is reached

//#define PREBOIL_ALARM 205
//**********************************************************************************


//**********************************************************************************
// Serial Logging Options
//**********************************************************************************
// BAUD_RATE: The baud rate for the serial connection. Breviouis to BrewTroller 2.0
// Build 419 this was hard coded to 9600. Starting with Build 419 the default rate
// was increased to 115200 but can be manually set using this compile option
#define BAUD_RATE 115200

// LOG_INTERVAL: Specifies how often data is logged via serial in milliseconds. If
// real time display of data is being used a smaller interval is best (1000 ms). A
// larger interval can be used for logging applications to reduce log file size 
// (5000 ms).
#define LOG_INTERVAL 2000

// LOG_INITSTATUS: Sets whether logging is enabled on bootup. Log status can be
// toggled using the SET_LOGSTATUS command.
#define LOG_INITSTATUS 1
//**********************************************************************************


//**********************************************************************************
// UI Support
//**********************************************************************************
// NOUI: Disable built-in user interface 
// UI_NO_SETUP: 'Light UI' removes system setup code to reduce compile size (~8 KB)
//
//#define NOUI
//#define UI_NO_SETUP
//**********************************************************************************


//**********************************************************************************
// BrewTroller PID Display (BTPD)
//**********************************************************************************
// BTPD is an external LED display developed by BrewTroller forum member vonnieda. 
// It is a 2 line, 4 digit (8 digits total) LED display with one line red and one
// line green. The digits are about a half inch high and can easily be seen across
// the room. The display connects to the BrewTroller via the I2C header and can be
// daisy chained to use as many as you like, theoretically up to 127 but in practice
// probably 10 or so.

// BTPD_SUPPORT: Enables use of BrewTroller PID Display devices on I2C bus
//#define BTPD_SUPPORT

// BTPD_INTERVAL: Specifies how often BTPD devices are updated in milliseconds.
#define BTPD_INTERVAL 1000

// BTPD_HLT_TEMP: Displays HLT temp and setpoint on specified channel
#define BTPD_HLT_TEMP 0x20

// BTPD_MASH_TEMP: Displays Mash temp and setpoint on specified channel
#define BTPD_MASH_TEMP 0x21

// BTPD_KETTLE_TEMP: Displays Kettle temp and setpoint on specified channel
#define BTPD_KETTLE_TEMP 0x22

// BTPD_H2O_TEMPS: Displays H2O In and H2O Out temps on specified channels
#define BTPD_H2O_TEMPS 0x23

// BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
#define BTPD_FERM_TEMP 0x24

// BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
#define BTPD_TIMERS 0x25

// BTPD_HLT_VOL: Displays current and target HLT volume
#define BTPD_HLT_VOL 0x26

// BTPD_MASH_VOL: Displays current and target Mash volume
#define BTPD_MASH_VOL 0x27

// BTPD_KETTLE_VOL: Displays current and target Kettle volume
#define BTPD_KETTLE_VOL 0x28

// BTPD_STEAM_PRESS: Displays current and target Steam pressure
#define BTPD_STEAM_PRESS 0x29
//**********************************************************************************

//**********************************************************************************
// Brew Step Automation
//**********************************************************************************
// Uncomment the following line(s) to enable various steps to start/stop 
// automatically 
//
// AUTO_FILL_START: This option will enable the Fill AutoValve logic at the start of
// the Fill step. 
//#define AUTO_FILL_START

// AUTO_FILL_EXIT: This option will automatically exit the Fill step once target 
// volumes have been reached.
//#define AUTO_FILL_EXIT

// AUTO_ML_XFER: This option will enable the Sparge In AutoValve logic at the start
// of the Grain In step if the Mash Liquor Heat Source is set to HLT. This is used
// to transfer preheated mash liquor from HLT to Mash Tun.
//#define AUTO_ML_XFER

// AUTO_GRAININ_EXIT: This option will automatically exit the Grain In step after
// the specified number of seconds. Use this setting if your grain is automatically 
// added to the mash tun using the Add Grain valve profile. You can also specify a
// value of 0 to exit the Grain In step automatically with no additional delay.
// The Grain In step will not process exit logic until the mash liquor transfer is
// completed when the mash Liquor Heat Source is set to HLT.
//#define AUTO_GRAININ_EXIT 0

// AUTO_MASH_HOLD_EXIT: By default the user must manually exit the Mash Hold step.
// This prevents the mash from cooling if the brewer is not present at the end of
// the last mash step. Use this option to automatically exit the mash hold step if
// the boil zone is inactive.
//#define AUTO_MASH_HOLD_EXIT

// AUTO_SPARGE_START: This option will automatically enable batch or fly sparge
// logic at the start of the sparge step.
//#define AUTO_SPARGE_START

// AUTO_SPARGE_EXIT: This option will automatically advance the sparge step when
// target preboil volume is reached.
//#define AUTO_SPARGE_EXIT

// AUTO_BOIL_RECIRC: Activates the BOIL RECIRC valve profile during the last minutes
// of the AutoBrew Boil stage as defined below (ie AUTO_BOIL_RECIRC 20 will enable
// BOIL RECIRC for the last twenty minutes of boil. Warning: if you do not have a
// valve config that will reroute wort back to the kettle there is a great risk of
// losing wort or causing personal injury when this profile is enabled
//#define AUTO_BOIL_RECIRC 20
//**********************************************************************************


//**********************************************************************************
// Volume Averaging Settings
//**********************************************************************************
// VOLUME_READ_INTERVAL: Time in ms between volume readings
// VOLUME_READ_COUNT: Number of individual volume readings to average when 
// calculating a vessel's volume
//
#define VOLUME_READ_INTERVAL 200
#define VOLUME_READ_COUNT 5
//**********************************************************************************


//**********************************************************************************
// Flow Rate Calculation
//**********************************************************************************
// FLOWRATE_CALCS: Enables calculation of flow rates for each vessel based on
// volume changes over a specified interval
// FLOWRATE_READ_INTERVAL: Time in ms between flowrate calculation updates
//
#define FLOWRATE_CALCS
#define FLOWRATE_READ_INTERVAL 1000
//**********************************************************************************

//**********************************************************************************
// DEBUG
//**********************************************************************************
// DEBUG_TEMP_CONV_T: Enables logging of OneWire temperature sensor ADC time.
//#define DEBUG_TEMP_CONV_T

// DEBUG_VOL_READ: Enables logging of additional detail used in calculating volume.
//#define DEBUG_VOL_READ

// DEBUG_PID_GAIN: Enables logging of PID Gain settings as they are set.
//#define DEBUG_PID_GAIN
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

//Enable Serial on BTBOARD_22+ boards or if DEBUG is set
#if !defined BTBOARD_1
  #define USESERIAL
#endif

//Enable Mash Avergaing Logic if any Mash_AVG_AUXx options were enabled
#if defined MASH_AVG_AUX1 || defined MASH_AVG_AUX2 || defined MASH_AVG_AUX3
  #define MASH_AVG
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

#ifdef BTBOARD_22
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
#ifdef BTBOARD_22
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
#define NUM_TS 9

#define VS_HLT 0
#define VS_MASH 1
#define VS_KETTLE 2
#define VS_STEAM 3

//Auto-Valve Modes
#define AV_FILL 0
#define AV_MASH 1
#define AV_SPARGEIN 2
#define AV_SPARGEOUT 3
#define AV_FLYSPARGE 4
#define AV_CHILL 5
#define NUM_AV 6

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
#define EVENT_SETPOINT 1

//Heat Output Pin Array
pin heatPin[4], alarmPin;

#ifdef ONBOARDPV
  pin valvePin[11];
#endif

#if MUXBOARDS > 0
  pin muxLatchPin, muxDataPin, muxClockPin, muxOEPin;
#endif

//Volume Sensor Pin Array
#ifdef HLT_AS_KETTLE
  byte vSensor[3] = { HLTVOL_APIN, MASHVOL_APIN, HLTVOL_APIN};
#else
  byte vSensor[3] = { HLTVOL_APIN, MASHVOL_APIN, KETTLEVOL_APIN};
#endif

//8-byte Temperature Sensor Address x9 Sensors
byte tSensor[9][8];
int temp[9];

//Volume in (thousandths of gal/l)
unsigned long tgtVol[3], volAvg[3], calibVols[3][10];
unsigned int calibVals[3][10];

#ifdef FLOWRATE_CALCS
//Flowrate in thousandths of gal/l per minute
long flowRate[3];
#endif

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
//Steam Pressure in thousandths
unsigned long steamPressure;
byte boilPwr;

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
boolean logData = LOG_INITSTATUS;
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
byte pitchTemp;

const char BT[] PROGMEM = "BrewTroller";
const char BTVER[] PROGMEM = "2.0";

//Log Strings
const char LOGCMD[] PROGMEM = "CMD";
const char LOGDEBUG[] PROGMEM = "DEBUG";
const char LOGSYS[] PROGMEM = "SYS";
const char LOGCFG[] PROGMEM = "CFG";
const char LOGDATA[] PROGMEM = "DATA";

void setup() {
  //Initialize Brew Steps to 'Idle'
  for(byte brewStep = 0; brewStep < NUM_BREW_STEPS; brewStep++) stepProgram[brewStep] = PROGRAM_IDLE;
  
  //Log initialization (Log.pde)
  logInit();

  //Pin initialization (Outputs.pde)
  pinInit();
  
  tempInit();
  
  //User Interface Initialization (UI.pde)
  #ifndef NOUI
    uiInit();
  #endif

  #ifdef BTPD_SUPPORT
    btpdInit();
  #endif

  //Check for cfgVersion variable and update EEPROM if necessary (EEPROM.pde)
  checkConfig();

  //Load global variable values stored in EEPROM (EEPROM.pde)
  loadSetup();

  //PID Initialization (Outputs.pde)
  pidInit();

}

void loop() {
  //User Interface Processing (UI.pde)
  #ifndef NOUI
    uiCore();
  #endif
  
  //Core BrewTroller process code (BrewCore.pde)
  brewCore();
}
