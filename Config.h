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
// Mash Temperature Adjustment
//**********************************************************************************
// MASH_AVG_AUXx: Uncomment one or more of the following lines to include averaging
// of AUX1, AUX2 and/or AUX3 temp sensors with mash temp sensor.
//#define MASH_AVG_AUX1
//#define MASH_AVG_AUX2
//#define MASH_AVG_AUX3
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
// Settings below this bar are likely to remain compile options
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
// Brewing Calculation Factors
//**********************************************************************************
// VOL_SHRINKAGE: The amount of liquid volume reduced as a result of decrease in temperature. 
// This value used to be .96 in BrewTroller 2.4 and earlier versions but this value should
// not be used in volume calculations for water at ground temperature when targeting pitch temps.
// A value of '1' (default) will eliminate this from brewing calculations.
#define VOL_SHRINKAGE 1
//#define VOL_SHRINKAGE .96


//**********************************************************************************
// RS485/Modbus Configuration
//**********************************************************************************
// Used only if OUTPUTBANK_MODBUS is defined in HWProfile.h

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

//**********************************************************************************
// RGBIO8 Support
//**********************************************************************************
#define RGBIO8_ENABLE

#endif

