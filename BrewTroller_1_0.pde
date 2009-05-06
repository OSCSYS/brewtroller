#define BUILD 200 
/*
BrewTroller - Open Source Brewing Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com

Compiled on Arduino-0015 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

#include <avr/pgmspace.h>
#include <PID_Beta6.h>

//Pin and Interrupt Definitions
#define ENCA_PIN 2
#define ENCB_PIN 4
#define TEMP_PIN 5
#define ENTER_PIN 11
#define ALARM_PIN 15
#define ENTER_INT 1
#define ENCA_INT 2
#define VALVE1_PIN 6
#define VALVE2_PIN 7
#define VALVE3_PIN 8
#define VALVE4_PIN 9
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

//TSensor and Output (0-2) Array Element Constants
#define TS_HLT 0
#define TS_MASH 1
#define TS_KETTLE 2
#define TS_H2OIN 3
#define TS_H2OOUT 4
#define TS_BEEROUT 5

//Valve Array Element Constants and Variables
#define VLV_ALLOFF 0
#define VLV_FILLHLT 1
#define VLV_FILLMASH 2
#define VLV_MASHHEAT 3
#define VLV_MASHIDLE 4
#define VLV_SPARGEIN 5
#define VLV_SPARGEOUT 6
#define VLV_CHILLH2O 7
#define VLV_CHILLBEER 8

//Unit Definitions
//International: Celcius, Liter, Kilogram
//US: Fahrenheit, Gallon, US Pound
#define UNIT_INTL 0
#define UNIT_US 1

//Encoder Types
#define ENC_CUI 0
#define ENC_ALPS 1


//System Types
#define SYS_DIRECT 0
#define SYS_HERMS 1
#define SYS_STEAM 2

//Heat Output Pin Array
byte heatPin[3] = { HLTHEAT_PIN, MASHHEAT_PIN, KETTLEHEAT_PIN };

//Encoder Globals
byte encMode = 0;
int encCount;
byte encMin;
byte encMax;
byte enterStatus = 0;

//8-byte Temperature Sensor Address x6 Sensors
byte tSensor[6][8];

//Unit Globals (Volume in thousandths)
boolean unit;
unsigned long capacity[3];
unsigned long volume[3];
unsigned int volLoss[3];
//Rate of Evaporation (Percent per hour)
byte evapRate;

//Output Globals
byte sysType = SYS_DIRECT;
boolean PIDEnabled[3] = { 0, 0, 0 };

//Shared menuOptions Array
char menuopts[16][20];

double PIDInput[3], PIDOutput[3], setpoint[3];
byte PIDp[3], PIDi[3], PIDd[3], PIDCycle[3], hysteresis[3];

PID pid[3] = {
  PID(&PIDInput[TS_HLT], &PIDOutput[TS_HLT], &setpoint[TS_HLT], 3, 4, 1),
  PID(&PIDInput[TS_MASH], &PIDOutput[TS_MASH], &setpoint[TS_MASH], 3, 4, 1),
  PID(&PIDInput[TS_KETTLE], &PIDOutput[TS_KETTLE], &setpoint[TS_KETTLE], 3, 4, 1)
};

//Timer Globals
unsigned long timerValue = 0;
unsigned long lastTime = 0;
unsigned long timerLastWrite = 0;
boolean timerStatus = 0;
boolean alarmStatus = 0;
  
void setup() {
  pinMode(ENCA_PIN, INPUT);
  pinMode(ENCB_PIN, INPUT);
  pinMode(ENTER_PIN, INPUT);
  pinMode(ALARM_PIN, OUTPUT);
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
  pinMode(HLTHEAT_PIN, OUTPUT);
  pinMode(MASHHEAT_PIN, OUTPUT);
  pinMode(KETTLEHEAT_PIN, OUTPUT);
  resetOutputs();
  initLCD();
  //Memory Check
  //char buf[6]; printLCD(0,0,itoa(availableMemory(), buf, 10)); delay (5000);
  
  //Check for cfgVersion variable and format EEPROM if necessary
  checkConfig();
  
  //Load global variable values stored in EEPROM
  loadSetup();
  initEncoder();

  switch(getPwrRecovery()) {
    case 1: doAutoBrew(); break;
    case 2: doMon(); break;
    default: splashScreen(); break;
  }
}

void loop() {
  strcpy_P(menuopts[0], PSTR("AutoBrew"));
  strcpy_P(menuopts[1], PSTR("Brew Monitor"));
  strcpy_P(menuopts[2], PSTR("System Setup"));
 
  switch (scrollMenu("BrewTroller", menuopts, 3, 0)) {
    case 0: doAutoBrew(); break;
    case 1: doMon(); break;
    case 2: menuSetup(); break;
  }
}

void splashScreen() {
  char buf[6];
  clearLCD();
  { 
    const byte bmpByte[] = {
      B00000,
      B00000,
      B00000, 
      B00000, 
      B00011, 
      B01111, 
      B11111, 
      B11111
    }; 
    lcdSetCustChar(0, bmpByte);
  }
  { 
    const byte bmpByte[] = {
      B00000, 
      B00000, 
      B00000, 
      B00000, 
      B11100, 
      B11110, 
      B11111, 
      B11111
    };
    lcdSetCustChar(1, bmpByte);
  }
  { 
    const byte bmpByte[] = {
      B00001, 
      B00011, 
      B00111, 
      B01111, 
      B00001, 
      B00011, 
      B01111, 
      B11111
    }; 
    lcdSetCustChar(2, bmpByte); 
  }
  { 
    const byte bmpByte[] = {
      B11111, 
      B11111, 
      B10001, 
      B00011, 
      B01111, 
      B11111, 
      B11111, 
      B11111
    }; 
    lcdSetCustChar(3, bmpByte); 
  }
  { 
    const byte bmpByte[] = {
      B11111, 
      B11111, 
      B11111, 
      B11111, 
      B11111, 
      B11111, 
      B11111, 
      B11111
    }; 
    lcdSetCustChar(4, bmpByte); 
  }
  { 
    const byte bmpByte[] = {
      B01111, 
      B01110, 
      B01100, 
      B00001, 
      B01111, 
      B00111, 
      B00011, 
      B11101
    }; 
    lcdSetCustChar(5, bmpByte); 
  }
  { 
    const byte bmpByte[] = {
      B11111, 
      B00111, 
      B00111, 
      B11111, 
      B11111, 
      B11111, 
      B11110, 
      B11001
    }; 
    lcdSetCustChar(6, bmpByte); 
  }
  { 
    const byte bmpByte[] = {
      B11111, 
      B11111, 
      B11110, 
      B11101, 
      B11011, 
      B00111, 
      B11111, 
      B11111
    }; 
    lcdSetCustChar(7, bmpByte); 
  }

  lcdWriteCustChar(0, 1, 0);
  lcdWriteCustChar(0, 2, 1);
  lcdWriteCustChar(1, 0, 2); 
  lcdWriteCustChar(1, 1, 3); 
  lcdWriteCustChar(1, 2, 4); 
  lcdWriteCustChar(2, 0, 5); 
  lcdWriteCustChar(2, 1, 6); 
  lcdWriteCustChar(2, 2, 7); 
  printLCD_P(0, 4, PSTR("BrewTroller v1.0"));
  printLCD_P(1, 10, PSTR("Build "));
  printLCDPad(1, 16, itoa(BUILD, buf, 10), 4, '0');
  printLCD_P(3, 1, PSTR("www.brewtroller.com"));
  while(!enterStatus) delay(250);
  enterStatus = 0;
}
