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
#define VLV_HLTHEAT 13
#define VLV_HLTIDLE 14
#define VLV_KETTLEHEAT 15
#define VLV_KETTLEIDLE 16
#define VLV_USER1 17
#define VLV_USER2 18
#define VLV_USER3 19
#define NUM_VLVCFGS 20

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
#define EVENT_STEPEXIT 1
#define EVENT_SETPOINT 2
#define EVENT_ESTOP 3

//Log Constants
#define CMD_MSG_FIELDS 25
#define CMD_FIELD_CHARS 21

#define NUM_PROGRAMS 20

#define BT_I2C_ADDR 0x10
#define BTNIC_I2C_ADDR 0x11

#define ASCII 0
#define BTNIC 1
#define BINARY 2

#define TRIGGER_ESTOP 0
#define TRIGGER_SPARGEMAX 1
#define TRIGGER_HLTMIN 2
#define TRIGGER_MASHMIN 3
#define TRIGGER_KETTLEMIN 4

typedef enum {
  CONTROLSTATE_OFF,
  CONTROLSTATE_AUTO,
  CONTROLSTATE_ON,
  NUM_CONTROLSTATES
} ControlState;

#endif
