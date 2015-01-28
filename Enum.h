#ifndef BT_ENUM
#define BT_ENUM

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
  #define BAD_TEMP -32768

  #define VS_HLT 0
  #define VS_MASH 1
  #define VS_KETTLE 2
  #define VS_STEAM 3
  #define VS_PUMP 3

//Auto-Valve Modes
  #define AV_FILL 0
  #define AV_MASH 1
  #define AV_SPARGEIN 2
  #define AV_SPARGEOUT 3
  #define AV_FLYSPARGE 4
  #define AV_CHILL 5
  #define AV_HLT 6
  #define AV_KETTLE 7
  #define NUM_AV 8

  //Valve Array Element Constants and Variables
  #define VLV_ALL 0xFFFFFFFF
  enum OutputProfileIndex {
    OUTPUTPROFILE_FILLHLT,
    OUTPUTPROFILE_FILLMASH,
    OUTPUTPROFILE_ADDGRAIN,
    OUTPUTPROFILE_MASHHEAT,
    OUTPUTPROFILE_MASHIDLE,
    OUTPUTPROFILE_SPARGEIN,
    OUTPUTPROFILE_SPARGEOUT,
    OUTPUTPROFILE_HOPADD,
    OUTPUTPROFILE_KETTLELID,
    OUTPUTPROFILE_CHILLH2O,
    OUTPUTPROFILE_CHILLBEER,
    OUTPUTPROFILE_BOILRECIRC,
    OUTPUTPROFILE_DRAIN,
    OUTPUTPROFILE_HLTHEAT,
    OUTPUTPROFILE_HLTIDLE,
    OUTPUTPROFILE_KETTLEHEAT,
    OUTPUTPROFILE_KETTLEIDLE,
    OUTPUTPROFILE_USER1,
    OUTPUTPROFILE_USER2,
    OUTPUTPROFILE_USER3,
    OUTPUTPROFILE_ALARM,
    OUTPUTPROFILE_USERCOUNT,                          //The number of user configurable output profiles
    OUTPUTPROFILE_BTNIC,                              //Dymanic profile used by BTNIC logic to turn on outputs (not implemented)
    OUTPUTPROFILE_RGBIO,                              //Dymanic profile used by RGBIO logic to turn on outputs
    OUTPUTPROFILE_SYSTEMTEST,                         //Used to test output profiles
    OUTPUTPROFILE_SYSTEMCOUNT
  };
  
  enum OutputEnableIndex {
    OUTPUTENABLE_ESTOP,          //Used by EStop logic to disable all outputs
    OUTPUTENABLE_BTNIC,          //Used by BTNIC logic to force off specific outputs (not implemented)
    OUTPUTENABLE_RGBIO,          //Used by RGBIO logic to force off specific outputs
    OUTPUTENABLE_VESSELMIN,      //Used by vessel minimum volume and triggers to disable specific outputs
    OUTPUTENABLE_SYSTEMTEST,     //Used to test output profiles by forcing off outputs not in the mask being tested
    OUTPUTENABLE_COUNT
  };

//Timers
#define TIMER_MASH 0
#define TIMER_BOIL 1

//Brew Steps
enum BrewStepIndex {
  BREWSTEP_FILL,
  BREWSTEP_DELAY,
  BREWSTEP_PREHEAT,
  BREWSTEP_GRAININ,
  BREWSTEP_REFILL,
  BREWSTEP_DOUGHIN,
  BREWSTEP_ACID,
  BREWSTEP_PROTEIN,
  BREWSTEP_SACCH,
  BREWSTEP_SACCH2,
  BREWSTEP_MASHOUT,
  BREWSTEP_MASHHOLD,
  BREWSTEP_SPARGE,
  BREWSTEP_BOIL,
  BREWSTEP_CHILL,
  BREWSTEP_COUNT,
  BREWSTEP_NONE = 255
};

enum StepSignal {
  STEPSIGNAL_INIT,
  STEPSIGNAL_UPDATE,
  STEPSIGNAL_ADVANCE,
  STEPSIGNAL_ABORT
};

#define PROGRAMTHREAD_MAX 2
#define PROGRAMTHREAD_NONE 255

#define RECIPE_MAX 20
#define RECIPE_NONE 255

enum MashStepIndex {
  MASHSTEP_DOUGHIN,
  MASHSTEP_ACID,
  MASHSTEP_PROTEIN,
  MASHSTEP_SACCH,
  MASHSTEP_SACCH2,
  MASHSTEP_MASHOUT,
  MASHSTEP_COUNT
};

//Zones
enum ZoneIndex {
  ZONE_MASH,
  ZONE_BOIL
};

//Events
#define EVENT_STEPINIT 0
#define EVENT_STEPEXIT 1
#define EVENT_SETPOINT 2
#define EVENT_ESTOP 3

//Log Constants
#define CMD_MSG_FIELDS 25
#define CMD_FIELD_CHARS 21

#define BT_I2C_ADDR 0x10
#define BTNIC_I2C_ADDR 0x11

#define ASCII 0
#define BTNIC 1
#define BINARY 2

typedef enum {
  TRIGGER_ESTOP,
  TRIGGER_SPARGEMAX,
  TRIGGER_HLTMIN,
  TRIGGER_MASHMIN,
  TRIGGER_KETTLEMIN,
  NUM_TRIGGERS
} TriggerType;

typedef enum {
  CONTROLSTATE_OFF,
  CONTROLSTATE_AUTO,
  CONTROLSTATE_ON,
  NUM_CONTROLSTATES
} ControlState;

#endif
