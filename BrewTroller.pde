#define BUILD 377 
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
// ENCODER TYPE
//**********************************************************************************
// You must uncomment one and only one of the following ENCODER_ definitions
// Use ENCODER_ALPS for ALPS and Panasonic Encoders
// Use ENCODER_CUI for older CUI encoders
//
#define ENCODER_ALPS
//#define ENCODER_CUI
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
// OPTIONAL MODULES
//**********************************************************************************
// Comment out any of the following lines to disable a module. This is handy to see
// how much space these chunks of code use.
//
#define MODULE_BREWMONITOR
#define MODULE_DEFAULTABPROGS

//**********************************************************************************

//**********************************************************************************
// LCD Timing Fix
//**********************************************************************************
// Some LCDs seem to have issues with displaying garbled characters but introducing
// a delay seems to help or resolve completely. You may comment out the following
// lines to remove this delay between a print of each character.
//
//#define LCD_DELAY_CURSOR 60
//#define LCD_DELAY_CHAR 60
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

#define VS_HLT 0
#define VS_MASH 1
#define VS_KETTLE 2
#define VS_STEAM 3

//Auto-Valve Modes
#define AV_OFF 0
#define AV_FILL 1
#define AV_MASH 2
#define AV_SPARGE 3
#define AV_CHILL 4

//Valve Array Element Constants and Variables
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

//Heat Output Pin Array
byte heatPin[4] = { HLTHEAT_PIN, MASHHEAT_PIN, KETTLEHEAT_PIN, STEAMHEAT_PIN };

//Volume Sensor Pin Array
byte vSensor[3] = { HLTVOL_APIN, MASHVOL_APIN, KETTLEVOL_APIN};

//Encoder Globals
int encCount;
byte encMin;
byte encMax;
byte enterStatus = 0;

//8-byte Temperature Sensor Address x6 Sensors
byte tSensor[8][8];
float temp[8];
unsigned long convStart = 0;

//Volume
unsigned long capacity[3];
unsigned long volume[3];
unsigned int volLoss[3];
unsigned long tgtVol[3];
unsigned int calibVals[3][10];
unsigned long calibVols[3][10];
unsigned int zeroVol[3];
unsigned long volAvg[3];
unsigned long volReadings[3][5];
byte volCount;
unsigned long lastVolChk;
//Where to heat mash water (affects volume calcs)
byte MLHeatSrc;

//Valve Variables
unsigned long vlvConfig[13];
unsigned long vlvBits;
byte autoValve;

//Rate of Evaporation (Percent per hour)
byte evapRate;

//Shared menuOptions Array
char menuopts[21][20];

//Common Buffer
char buf[11];

//Output Globals
double PIDInput[4], PIDOutput[4], setpoint[4];
byte PIDp[4], PIDi[4], PIDd[4], PIDCycle[4], hysteresis[4];
unsigned long cycleStart[4];
boolean heatStatus[4];
boolean PIDEnabled[4];
byte pitchTemp;
byte steamTgt;
unsigned int steamPSens;
unsigned int steamZero;
float steamPressure;

PID pid[4] = {
  PID(&PIDInput[VS_HLT], &PIDOutput[VS_HLT], &setpoint[VS_HLT], 3, 4, 1),
  PID(&PIDInput[VS_MASH], &PIDOutput[VS_MASH], &setpoint[VS_MASH], 3, 4, 1),
  PID(&PIDInput[VS_KETTLE], &PIDOutput[VS_KETTLE], &setpoint[VS_KETTLE], 3, 4, 1),
  PID(&PIDInput[VS_STEAM], &PIDOutput[VS_STEAM], &setpoint[VS_STEAM], 3, 4, 1)
};

//Timer Globals
unsigned long timerValue = 0;
unsigned long lastTime = 0;
unsigned long timerLastWrite = 0;
boolean timerStatus = 0;
boolean alarmStatus = 0;

char msg[25][21];
byte msgField = 0;
boolean msgQueued = 0;

byte pwrRecovery;
byte recoveryStep;

unsigned long lastLog;
byte logCount;

const char BT[] PROGMEM = "BrewTroller";
const char BTVER[] PROGMEM = "v1.2";

//Log Message Classes
const char LOGAB[] PROGMEM = "AB";
const char LOGCMD[] PROGMEM = "CMD";
const char LOGDEBUG[] PROGMEM = "DEBUG";
const char LOGSYS[] PROGMEM = "SYSTEM";
const char LOGGLB[] PROGMEM = "GLOBAL";
const char LOGDATA[] PROGMEM = "DATA";

//Other PROGMEM Repeated Strings
const char PWRLOSSRECOVER[] PROGMEM = "PLR";
const char CANCEL[] PROGMEM = "Cancel";
const char EXIT[] PROGMEM = "Exit";
const char SPACE[] PROGMEM = " ";
const char INIT_EEPROM[] PROGMEM = "Initialize EEPROM";
const char SKIPSTEP[] PROGMEM = "Skip Step";
const char LOGSPLASH[] PROGMEM = "SPLASH";
const char CONTINUE[] PROGMEM = "Continue";
const char AUTOFILL[] PROGMEM = "Auto";
const char FILLHLT[] PROGMEM = "Fill HLT";
const char FILLMASH[] PROGMEM = "Fill Mash";
const char FILLBOTH[] PROGMEM = "Fill Both";
const char ALLOFF[] PROGMEM = "All Off";
const char ABORT[] PROGMEM = "Abort";
const char ADDGRAIN[] PROGMEM = "Add Grain";
const char MASHHEAT[] PROGMEM = "Mash Heat";
const char MASHIDLE[] PROGMEM = "Mash Idle";
const char SPARGEIN[] PROGMEM = "Sparge In";
const char SPARGEOUT[] PROGMEM = "Sparge Out";
const char FLYSPARGE[] PROGMEM = "Fly Sparge";
const char BOILADDS[] PROGMEM = "Boil Additions";
const char CHILLNORM[] PROGMEM = "Chiller Both";
const char CHILLH2O[] PROGMEM = "Chiller H2O";
const char CHILLBEER[] PROGMEM = "Chiller Beer";
const char BOILRECIRC[] PROGMEM = "Boil Recirc";
const char DRAIN[] PROGMEM = "Drain";
const char HLTCYCLE[] PROGMEM = "HLT PID Cycle";
const char HLTGAIN[] PROGMEM = "HLT PID Gain";
const char HLTHY[] PROGMEM = "HLT Hysteresis";
const char MASHCYCLE[] PROGMEM = "Mash PID Cycle";
const char MASHGAIN[] PROGMEM = "Mash PID Gain";
const char MASHHY[] PROGMEM = "Mash Hysteresis";
const char KETTLECYCLE[] PROGMEM = "Kettle PID Cycle";
const char KETTLEGAIN[] PROGMEM = "Kettle PID Gain";
const char KETTLEHY[] PROGMEM = "Kettle Hysteresis";
const char STEAMCYCLE[] PROGMEM = "Steam PID Cycle";
const char STEAMGAIN[] PROGMEM = "Steam PID Gain";
const char STEAMPRESS[] PROGMEM = "Steam Target";
const char STEAMSENSOR[] PROGMEM = "Steam Sensor Sens";
const char STEAMZERO[] PROGMEM = "Steam Zero Calib";
const char HLTDESC[] PROGMEM = "Hot Liquor Tank";
const char MASHDESC[] PROGMEM = "Mash Tun";

#ifdef USEMETRIC
const char VOLUNIT[] PROGMEM = "l";
const char WTUNIT[] PROGMEM = "kg";
const char TUNIT[] PROGMEM = "C";
const char PUNIT[] PROGMEM = "kPa";
#else
const char VOLUNIT[] PROGMEM = "gal";
const char WTUNIT[] PROGMEM = "lb";
const char TUNIT[] PROGMEM = "F";
const char PUNIT[] PROGMEM = "psi";
#endif

const char SEC[] PROGMEM = "s";

//Custom LCD Chars
const byte CHARFIELD[] PROGMEM = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARCURSOR[] PROGMEM = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARSEL[] PROGMEM = {B10001, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte BMP0[] PROGMEM = {B00000, B00000, B00000, B00000, B00011, B01111, B11111, B11111};
const byte BMP1[] PROGMEM = {B00000, B00000, B00000, B00000, B11100, B11110, B11111, B11111};
const byte BMP2[] PROGMEM = {B00001, B00011, B00111, B01111, B00001, B00011, B01111, B11111};
const byte BMP3[] PROGMEM = {B11111, B11111, B10001, B00011, B01111, B11111, B11111, B11111};
const byte BMP4[] PROGMEM = {B11111, B11111, B11111, B11111, B11111, B11111, B11111, B11111};
const byte BMP5[] PROGMEM = {B01111, B01110, B01100, B00001, B01111, B00111, B00011, B11101};
const byte BMP6[] PROGMEM = {B11111, B00111, B00111, B11111, B11111, B11111, B11110, B11001};
const byte BMP7[] PROGMEM = {B11111, B11111, B11110, B11101, B11011, B00111, B11111, B11111};
  
void setup() {
#if defined USESERIAL
  Serial.begin(9600);
  Serial.println();
#endif
  logStart_P(LOGSYS);
  logField_P(PSTR("VER"));
  logField_P(BTVER);
  logField(itoa(BUILD, buf, 10));
  logEnd();
  
  pinMode(ENCA_PIN, INPUT);
  pinMode(ENCB_PIN, INPUT);
  pinMode(ENTER_PIN, INPUT);
  pinMode(ALARM_PIN, OUTPUT);
#if MUXBOARDS > 0
  pinMode(MUX_LATCH_PIN, OUTPUT);
  pinMode(MUX_CLOCK_PIN, OUTPUT);
  pinMode(MUX_DATA_PIN, OUTPUT);
  pinMode(MUX_OE_PIN, OUTPUT);
#endif
#ifdef ONBOARDPV
  pinMode(VALVE1_PIN, OUTPUT);
  pinMode(VALVE2_PIN, OUTPUT);
  pinMode(VALVE3_PIN, OUTPUT);
  pinMode(VALVE4_PIN, OUTPUT);
  pinMode(VALVE5_PIN, OUTPUT);
  pinMode(VALVE6_PIN, OUTPUT);
  pinMode(VALVE7_PIN, OUTPUT);
  pinMode(VALVE8_PIN, OUTPUT);
  pinMode(VALVE9_PIN, OUTPUT);
  pinMode(VALVEA_PIN, OUTPUT);
  pinMode(VALVEB_PIN, OUTPUT);
#endif
  pinMode(HLTHEAT_PIN, OUTPUT);
  pinMode(MASHHEAT_PIN, OUTPUT);
  pinMode(KETTLEHEAT_PIN, OUTPUT);
#ifdef USESTEAM
  pinMode(STEAMHEAT_PIN, OUTPUT);
#endif
  resetOutputs();
  
  initLCD();
  
  //Encoder Setup
  #ifdef ENCODER_ALPS
    attachInterrupt(2, doEncoderALPS, CHANGE);
  #endif
  #ifdef ENCODER_CUI
    attachInterrupt(2, doEncoderCUI, RISING);
  #endif
  attachInterrupt(1, doEnter, CHANGE);

  //Memory Check
  //printLCD(0,0,itoa(availableMemory(), buf, 10)); delay (5000);
  
  //Check for cfgVersion variable and format EEPROM if necessary
  checkConfig();
  
  //Load global variable values stored in EEPROM
  loadSetup();


  pid[VS_HLT].SetInputLimits(0, 255);
  pid[VS_HLT].SetOutputLimits(0, PIDCycle[VS_HLT] * 10 * PIDLIMIT_HLT);
  pid[VS_HLT].SetTunings(PIDp[VS_HLT], PIDi[VS_HLT], PIDd[VS_HLT]);

  pid[VS_MASH].SetInputLimits(0, 255);
  pid[VS_MASH].SetOutputLimits(0, PIDCycle[VS_MASH] * 10 * PIDLIMIT_MASH);
  pid[VS_MASH].SetTunings(PIDp[VS_MASH], PIDi[VS_MASH], PIDd[VS_MASH]);
  
  pid[VS_KETTLE].SetInputLimits(0, 255);
  pid[VS_KETTLE].SetOutputLimits(0, PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE);
  pid[VS_KETTLE].SetTunings(PIDp[VS_KETTLE], PIDi[VS_KETTLE], PIDd[VS_KETTLE]);
  
  #ifdef USEMETRIC
    pid[VS_STEAM].SetInputLimits(0, 50000 / steamPSens);
  #else
    pid[VS_STEAM].SetInputLimits(0, 7250 / steamPSens);
  #endif
  pid[VS_STEAM].SetOutputLimits(0, PIDCycle[VS_STEAM] * 10 * PIDLIMIT_STEAM);
  pid[VS_STEAM].SetTunings(PIDp[VS_STEAM], PIDi[VS_STEAM], PIDd[VS_STEAM]);
    
  if (pwrRecovery == 1) {
    logPLR();
    doAutoBrew();
  } else if (pwrRecovery == 2) {
    logPLR();
    doMon();
  } else {
    splashScreen();
  }
}

void loop() {
  strcpy_P(menuopts[0], PSTR("AutoBrew"));
  strcpy_P(menuopts[1], PSTR("Brew Monitor"));
  strcpy_P(menuopts[2], PSTR("System Setup"));
 
  byte lastoption = scrollMenu("BrewTroller", 3, 0);
  if (lastoption == 0) doAutoBrew();
  else if (lastoption == 1) doMon();
  else if (lastoption == 2) menuSetup();
}

void splashScreen() {
  clearLCD();
  lcdSetCustChar_P(0, BMP0);
  lcdSetCustChar_P(1, BMP1);
  lcdSetCustChar_P(2, BMP2);
  lcdSetCustChar_P(3, BMP3);
  lcdSetCustChar_P(4, BMP4);
  lcdSetCustChar_P(5, BMP5);
  lcdSetCustChar_P(6, BMP6);
  lcdSetCustChar_P(7, BMP7);
  lcdWriteCustChar(0, 1, 0);
  lcdWriteCustChar(0, 2, 1);
  lcdWriteCustChar(1, 0, 2); 
  lcdWriteCustChar(1, 1, 3); 
  lcdWriteCustChar(1, 2, 4); 
  lcdWriteCustChar(2, 0, 5); 
  lcdWriteCustChar(2, 1, 6); 
  lcdWriteCustChar(2, 2, 7); 
  printLCD_P(0, 4, BT);
  printLCD_P(0, 16, BTVER);
  printLCD_P(1, 10, PSTR("Build "));
  printLCDLPad(1, 16, itoa(BUILD, buf, 10), 4, '0');
  printLCD_P(3, 1, PSTR("www.brewtroller.com"));

  while(!enterStatus) {
    if (chkMsg()) rejectMsg(LOGGLB);
    brewCore();
  }
  enterStatus = 0;
}
