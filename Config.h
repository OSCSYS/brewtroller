#ifndef BT_CONFIGURATION
#define BT_CONFIGURATION
#include "Enum.h"

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
// Brewing Calculation Factors
//**********************************************************************************
// GRAIN2VOL: The amount of volume in l/kg or gal/lb that grain occupies in the mash
// Conservatively 1 lb = 0.15 gal 
// Aggressively 1 lb = 0.093 gal
#ifdef USEMETRIC
  #define GRAIN2VOL 1.25
#else
  #define GRAIN2VOL .15
#endif

// GRAIN_VOL_LOSS: The amount of liquid volume lost with spent grain. This value can
// vary by grain types, crush, etc.
// Default values are pretty conservative (err on more absorbtion)
// Ray Daniels suggests .20, Denny Conn suggests .10
#ifdef USEMETRIC
  #define GRAIN_VOL_LOSS 1.7884
#else
  #define GRAIN_VOL_LOSS .2143
#endif

// VOL_SHRINKAGE: The amount of liquid volume reduced as a result of decrease in temperature. 
// This value used to be .96 in BrewTroller 2.4 and earlier versions but this value should
// not be used in volume calculations for water at ground temperature when targeting pitch temps.
// A value of '1' (default) will eliminate this from brewing calculations.
#define VOL_SHRINKAGE 1
//#define VOL_SHRINKAGE .96


//**********************************************************************************
// Fly sparge pump control to turn the sparge in pump on/off based on a hysteresis from volume of sparge out
//**********************************************************************************
// This #define will turn the fly sparge in valve config on when the hysteresis amount of fluid has been pumped
// into the kettle from the MLT. It will then shut off the pump when that equal amount of sparge water has been
// pumped out of the HLT. 
// Note: SPARGE_IN_HYSTERSIS is in 1000ths of a gallon or liter. 
//#define SPARGE_IN_PUMP_CONTROL
#define SPARGE_IN_HYSTERESIS 250
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
#define HOPADD_DELAY 0
//**********************************************************************************

//**********************************************************************************
// Smart HERMS HLT
//**********************************************************************************
// SMART_HERMS_HLT: Varies HLT setpoint based on mash target + variance
// HLT_MAX_TEMP: Ceiling value for HLT (Actual max temp in C or F, Decimal values allowed)
// MASH_HEAT_LOSS: Acts as a floor value to ensure HLT temp is at least target + 
// specified value
// SMART_HERMS_PREHEAT: Enabling this sub-option will cause SMART_HERMS_HLT
// logic to be enabled during preheat. By default, a recipe's HLT Temp setting is used
// during preheat.

//#define SMART_HERMS_HLT
#define MASH_HEAT_LOSS 0
#define HLT_MAX_TEMP 180
//#define SMART_HERMS_PREHEAT
//**********************************************************************************

//**********************************************************************************
// Strike Temperature Correction
//**********************************************************************************
// STRIKE_TEMP_OFFSET: Adjusts strike temperature to compensate for thermal mass of
// mash tun.
// Value may be positive or negative. Decimal values are allowed.

#define STRIKE_TEMP_OFFSET 0

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
// Stop fly sparge removing water from HLT at this volume
//**********************************************************************************
// This feature was added because the dead space for the HLT may be less than the space lost in the tubing. 
// In particular if you're flushing your RIMS tube wort with fly sparge in water the water in the RIMS tube 
// will need to be added to the HLT dead space even though the dead space of water actually left in the 
// HLT will be less than that and we want to continue fly sparging until it's that low. 
// NOTE: volume is in thousands of a gallon
//#define HLT_FLY_SPARGE_STOP
//#define HLT_FLY_SPARGE_STOP_VOLUME 250
//**********************************************************************************


//**********************************************************************************
// Pre-Boil Alarm
//**********************************************************************************
// PREBOIL_ALARM: Triggers the alarm during the boil stage when the defined
// temperature is reached

#define PREBOIL_ALARM 205
//**********************************************************************************

//**********************************************************************************
// Buzzer modulation parameters
//**********************************************************************************
// These parameters allow the alarm sound to be modulated. 
// The modulation occurs when the BUZZER_CYCLE_TIME value is larger than the BUZZER_ON_TIME
// When the BUZZER_CYCLE_TIME is zero there is no modulation so the buzzer will buzz  
// a steady sound
//
//#define BUZZER_CYCLE_TIME 1200 //the value is in milliseconds for the ON and OFF buzzer cycle
//#define BUZZER_ON_TIME 500     //the duration in milliseconds where the alarm will stay on
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
// You need to set the addresses of each display in the Com_BTPD.h file.

// BTPD_INTERVAL: Specifies how often BTPD devices are updated in milliseconds
#define BTPD_INTERVAL 500

// Show temperature and volume per kettle on the same display.  Every other update
// interval the display will switch from temperature to volume.  Make sure that the
// values in Com_BTPD.h use the same address per kettle for both volume and temperature.
//#define BTPD_ALTERNATE_TEMP_VOLUME

//**********************************************************************************

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

// AUTO_REFILL_START: This option will enable the Fill AutoValve logic at the start of the 
// ReFill steip
//#define AUTO_REFILL_START

// AUTO_FILL_EXIT: This option will automatically exit the Fill step once target 
// volumes have been reached.
//#define AUTO_FILL_EXIT

// AUTO_PREHEAT_EXIT: By default the user must manually exit the Preheat step.
// This prevents the strike water from cooling if the brewer is not present at the
// end of preheat. Use this option to automatically exit preheat if desired.
//#define AUTO_PREHEAT_EXIT

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

// AUTO_MASH_HOLD_EXIT_AT_SPARGE_TEMP This option, assuming the AUTO_MASH_HOLD_EXIT
// option is turned on (else does nothing) wont allow the auto mash hold exit to occur until
// the HLT has reached the sparge temp of the currently active program. 
//#define AUTO_MASH_HOLD_EXIT_AT_SPARGE_TEMP

// AUTO_SPARGE_START: This option will automatically enable batch or fly sparge
// logic at the start of the sparge step.
//#define AUTO_SPARGE_START

// AUTO_SPARGE_EXIT: This option will automatically advance the sparge step when
// target preboil volume is reached.
//#define AUTO_SPARGE_EXIT

// AUTO_BOIL_RECIRC: Activates the WHIRLPOOL valve profile during the last minutes
// of the Boil step during program execution as defined below (ie AUTO_BOIL_RECIRC
// 20 will enable BOIL RECIRC for the last twenty minutes of boil.
//#define AUTO_BOIL_RECIRC 20
//**********************************************************************************

//**********************************************************************************
// Delay setting the first setpoint for the MLT for a RIMS tube so the RIMS tube can be full before power on
//**********************************************************************************
// This code will add a delay of RIMS_DELAY (in miliseconds) to expire before the first MLT setpoint is set. This is to allow the RIMS
// tube to be filled up with the recirc pump and come to a steady state before turning on the power. 
//NOTE: Do not use this code if you do not have a dough in time set that is longer than the RIMS_DELAY for any program 
// start. 
//#define RIMS_MLT_SETPOINT_DELAY
#define RIMS_DELAY 60000
//**********************************

//**********************************************************************************
// Volume Sensor Settings
//**********************************************************************************
// VOLUME_MANUAL: Modifies the user interface to show target volumes instead of
// current volumes for people who are not using volume sensors. The target
// volume information will be shown during Add Grain and during Sparge.
//
//#define VOLUME_MANUAL
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
//#define FLOWRATE_CALCS
#define FLOWRATE_READ_INTERVAL 1000
//**********************************************************************************


//**********************************************************************************
// RS485/Modbus Configuration
//**********************************************************************************
  #define RS485_BAUDRATE    76800
  #define RS485_PARITY      SERIAL_8E1
  
  #define OUTPUTBANK_MODBUS_MAXBOARDS     4
  #define OUTPUTBANK_MODBUS_DEFCOILREG    1000
  #define OUTPUTBANK_MODBUS_DEFCOILCOUNT  8
  #define OUTPUTBANK_MODBUS_BASEADDR      10
  #define OUTPUTBANK_MODBUS_ADDRNONE 255
  #define OUTPUTBANK_MODBUS_ADDRINIT 247
  #define OUTPUTBANK_MODBUS_REGIDMODE 9000
  #define OUTPUTBANK_MODBUS_REGSLAVEADDR 9001
  #define OUTPUTBANK_MODBUS_REGRESTART 9002

/***********************************************************************************
 * EXPERIMENTAL OPTIONS
 ***********************************************************************************
 The following options are experimental with little to no testing.
 **********************************************************************************/

//**********************************************************************************
// Min HLT refill volume
//**********************************************************************************
// EXPERIMENTAL: Uncomment the following line to enable forcing a minimum refill amount in the HLT
// during the refill step. This is so that you can make any amount of sparge water needed by making
// sure your heating elements are covered by water so they can heat your sparge water even if you're
// only going to use 0.25 gallons of it or some other small amount of sparge water.
// NOTE: Volume is in thousandths of a Gallons/Liters
// USE CAUTION! TESTING REQUIRED.
//
//#define HLT_MIN_REFILL
//#define HLT_MIN_REFILL_VOL 4000
//**********************************************************************************


//**********************************************************************************
// HLT Heat During Sparge
//**********************************************************************************
// HLT_HEAT_SPARGE: Enables the HLT setpoint during the sparge until a minimum
// volume level is reached.
// HLT_MIN_SPARGE: Minimum HLT volume trigger to disable the HLT Setpoint during
// sparge. Value represents thousandths of Gallons/Litres.
//
//  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//  !! WARNING: ENABLING THIS OPTION WITHOUT VOLUME LEVEL SENSING OR USING A MINIMUM !!
//  !! HLT VOLUME FLOAT SWITCH WILL RESULT IN DRY FIRING THE HLT AND CAUSING DAMAGE  !!
//  !! AND/OR PERSONAL HARM!                                                         !!
//  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

//#define HLT_HEAT_SPARGE
//#define HLT_MIN_SPARGE 2000
//**********************************************************************************

//**********************************************************************************
// RGB Board options
//**********************************************************************************
// The RGB Board allows you to have RGB LEDs show the status of 8 heat or PV outputs
// and allows you to have up to 8 switches connected to control them. You can connect
// multiple RGB boards to the BrewTroller to expand the number of inputs and outputs.
//
// Each numbered output provides the 4 neccesary connections for a common anode RGB
// LED. Each numbered input provides 2 commons, an auto and a manual input connection
// for connecting a 3 position toggle switch, or similar switch.
//
// RGBIO assignments are configured at runtime in System Setup
//
    // The system is configured by providing input and output mappings
    // for heat outputs and pump/valve outputs-> Each of these outputs
    // can be in one of four states:
    // Off:       The output is forced off, no matter what other systems attempt.
    // Auto Off:  The output is under auto control of BrewTroller, and is
    //            currently set to off. It may turn on at any time.
    // Auto On:   The output is under auto control of BrewTroller, and is
    //            currently set to on. It may turn off at any time.
    // On:        The output is forced on and is not under control of 
    //            BrewTroller.
    // 
    // The first thing that is configured are output "recipes". These recipes
    // define the color that will be shown for each of the states above.
    // 
    // Often times you will see colors on a web page expressed in RGB
    // hexidecimal, such as #FF0000 meaning bright red or #FFFF00 meaning
    // bright yellow. The RGBIO8 board uses a similar system for color,
    // except it uses 3 digits instead of 6. In most cases, if you find
    // a color you like that is in the #ABCDEF format, you can convert it
    // to the right code for RGBIO8 by removing the second, fourth and
    // last digit. So, for instance, #ABCDEF would become #ACE.
    // 
    // The system has room for four recipes, so you can create 4 different
    // color schemes that map to your outputs->
    // 
    // By default we use two recipes. One for heat outputs and another for
    // pump/valve outputs-> They are listed below. If you like, you can just
    // change the colors in a recipe, or you can create entirely new recipes.
    
// Enables the RGBIO8 system.
//
#define RGBIO8_ENABLE
//
//
//**********************************************************************************

#endif

