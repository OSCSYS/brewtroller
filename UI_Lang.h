#ifndef UI_LANG_H
#define UI_LANG_H

//**********************************************************************************
// UI Strings
//**********************************************************************************
const char OK[] PROGMEM = "Ok";
const char CANCEL[] PROGMEM = "Cancel";
const char EXIT[] PROGMEM = "Exit";
const char DELETE[] PROGMEM = "Delete";
const char ABORT[] PROGMEM = "Abort";
const char MENU[] PROGMEM = "Menu";
const char SPACE[] PROGMEM = " ";
const char INIT_EEPROM[] PROGMEM = "Initialize EEPROM";
const char CONTINUE[] PROGMEM = "Continue";
const char LABEL_BUTTONON[] PROGMEM = "On ";
const char LABEL_BUTTONOFF[] PROGMEM = "Off";
const char ON[] PROGMEM = "On";
const char OFF[] PROGMEM = "Off";

prog_char FILLHLT[] PROGMEM = "Fill HLT";
prog_char FILLMASH[] PROGMEM = "Fill Mash";
prog_char ADDGRAIN[] PROGMEM = "Add Grain";
prog_char MASHHEAT[] PROGMEM = "Mash Heat";
prog_char MASHIDLE[] PROGMEM = "Mash Idle";
prog_char SPARGEIN[] PROGMEM = "Sparge In";
prog_char SPARGEOUT[] PROGMEM = "Sparge Out";
prog_char BOILADDS[] PROGMEM = "Boil Additions";
prog_char STRIKETRANSFER[] PROGMEM = "Not Implemented";
prog_char CHILL[] PROGMEM = "Chill";
prog_char WORTOUT[] PROGMEM = "Wort Out";
prog_char WHIRLPOOL[] PROGMEM = "Whirlpool";
prog_char DRAIN[] PROGMEM = "Drain";
prog_char HLTHEAT[] PROGMEM = "HLT Heat";
prog_char HLTIDLE[] PROGMEM = "HLT Idle";
prog_char KETTLEHEAT[] PROGMEM = "Kettle Heat";
prog_char KETTLEIDLE[] PROGMEM = "Kettle Idle";
prog_char USER1[] PROGMEM = "User Profile 1";
prog_char USER2[] PROGMEM = "User Profile 2";
prog_char USER3[] PROGMEM = "User Profile 3";
prog_char ALARM[] PROGMEM = "Alarm";
prog_char HLTPWMACTIVE[] PROGMEM = "HLT PWM Active";
prog_char MASHPWMACTIVE[] PROGMEM = "Mash PWM Active";
prog_char KETTLEPWMACTIVE[] PROGMEM = "Kettle PWM Active";

prog_char DOUGHIN[] PROGMEM = "Dough In:";
prog_char ACID[] PROGMEM = "Acid Rest:";
prog_char PROTEIN[] PROGMEM = "Protein Rest:";
prog_char SACCH[] PROGMEM = "Sacch Rest:";
prog_char SACCH2[] PROGMEM = "Sacch2 Rest:";
prog_char MASHOUT[] PROGMEM = "Mash Out:";

PROGMEM const char *TITLE_MASHSTEP[] = {
  DOUGHIN,
  ACID,
  PROTEIN,
  SACCH,
  SACCH2,
  MASHOUT
};

PROGMEM const char *TITLE_VLV[] = {
  FILLHLT,
  FILLMASH,
  ADDGRAIN,
  MASHHEAT,
  MASHIDLE,
  SPARGEIN,
  SPARGEOUT,
  BOILADDS,
  STRIKETRANSFER,
  CHILL,
  WORTOUT,
  WHIRLPOOL,
  DRAIN,
  HLTHEAT,
  HLTIDLE,
  KETTLEHEAT,
  KETTLEIDLE,
  USER1,
  USER2,
  USER3,
  ALARM,
  HLTPWMACTIVE,
  MASHPWMACTIVE,
  KETTLEPWMACTIVE
};

const char ALLOFF[] PROGMEM = "All Off";
const char FILLBOTH[] PROGMEM = "Fill Both";
const char FLYSPARGE[] PROGMEM = "Fly Sparge";
const char WHIRLCHILL[] PROGMEM = "WhirlChill";

prog_char TITLE_VS_HLT[] PROGMEM = "HLT";
prog_char TITLE_VS_MASH[] PROGMEM = "Mash";
prog_char TITLE_VS_KETTLE[] PROGMEM = "Kettle";

PROGMEM const char *TITLE_VS[] = {
  TITLE_VS_HLT,
  TITLE_VS_MASH,
  TITLE_VS_KETTLE
};

const char TITLE_TS_H2OIN[] PROGMEM = "H2O In";
const char TITLE_TS_H2OOUT[] PROGMEM = "H2O Out";
const char TITLE_TS_WORTOUT[] PROGMEM = "Wort Out";
const char TITLE_TS_AUX1[] PROGMEM = "AUX 1";
const char TITLE_TS_AUX2[] PROGMEM = "AUX 2";
const char TITLE_TS_AUX3[] PROGMEM = "AUX 3";

PROGMEM const char *TITLE_TS[] = {
  TITLE_VS_HLT,
  TITLE_VS_MASH,
  TITLE_VS_KETTLE,
  TITLE_TS_H2OIN,
  TITLE_TS_H2OOUT,
  TITLE_TS_WORTOUT,
  TITLE_TS_AUX1,
  TITLE_TS_AUX2,
  TITLE_TS_AUX3
};

const char PIDCYCLE[] PROGMEM = " PID Cycle";
const char PIDGAIN[] PROGMEM = " PID Gain";
const char HYSTERESIS[] PROGMEM = "Hysteresis";
const char CAPACITY[] PROGMEM = "Capacity";
const char DEADSPACE[] PROGMEM = "Dead Space";
const char CALIBRATION[] PROGMEM = "Calibration";

const char BOIL_TEMP[] PROGMEM = "Boil Temp";
const char BOIL_POWER[] PROGMEM = "Boil Power";
const char EVAPORATION_RATE[] PROGMEM = "Evaporation Rate";
const char GRAIN_DISPLACEMENT[] PROGMEM = "Grain Displacement";
const char GRAIN_LIQUOR_LOSS[] PROGMEM = "Grain Liquor Loss";

const char HLTDESC[] PROGMEM = "Hot Liquor Tank";
const char MASHDESC[] PROGMEM = "Mash Tun";
const char SEC[] PROGMEM = "s";
#ifdef USEMETRIC
const char VOLUNIT[] PROGMEM = "l";
const char WTUNIT[] PROGMEM = "kg";
const char TUNIT[] PROGMEM = "C";
#else
const char VOLUNIT[] PROGMEM = "gal";
const char WTUNIT[] PROGMEM = "lb";
const char TUNIT[] PROGMEM = "F";
#endif

const char MIN[] PROGMEM = " min";

//**********************************************************************************
// UI Custom LCD Chars
//**********************************************************************************
const byte CHARFIELD[] PROGMEM = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARCURSOR[] PROGMEM = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
const byte CHARSEL[] PROGMEM = {B10001, B11111, B00000, B00000, B00000, B00000, B00000, B00000};

const byte BMP0[] PROGMEM = {B00000, B00000, B00000, B11111, B10001, B10001, B11111, B00001};
const byte BMP1[] PROGMEM = {B00000, B00000, B00000, B00000, B00000, B00011, B01100, B01111};
const byte BMP2[] PROGMEM = {B00000, B00000, B00000, B00000, B00000, B11100, B00011, B11111};
const byte BMP3[] PROGMEM = {B00100, B01100, B01111, B00111, B00100, B01100, B01111, B00111};
const byte BMP4[] PROGMEM = {B00010, B00011, B11111, B11110, B00010, B00011, B11111, B11110};

const byte UNLOCK_ICON[] PROGMEM = {B00110, B01001, B01001, B01000, B01111, B01111, B01111, B00000};
const byte PROG_ICON[] PROGMEM =   {B00001, B11101, B10101, B11101, B10001, B10001, B00001, B11111};
const byte BELL[] PROGMEM =        {B00100, B01110, B01110, B01110, B11111, B00000, B00100, B00000};

const byte BUTTON_OFF[] PROGMEM =          {B01110, B10001, B10001, B10001, B01110, B00000, B00000, B00000};
const byte BUTTON_ON[] PROGMEM =           {B01110, B11111, B11111, B11111, B01110, B00000, B00000, B00000};
const byte BUTTON_OFF_SELECTED[] PROGMEM = {B01110, B10001, B10001, B10001, B01110, B00000, B00100, B01110};
const byte BUTTON_ON_SELECTED[] PROGMEM =  {B01110, B11111, B11111, B11111, B01110, B00000, B00100, B01110};

#endif
