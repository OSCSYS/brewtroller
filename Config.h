#ifndef BT_CONFIGURATION
#define BT_CONFIGURATION

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
//#define BTBOARD_3
#define BTBOARD_4
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
#define PIDLIMIT_STEAM 100 // note this is also the PID limit for the pump PWM output if PID_FLOW_CONTROL is enabled

//**********************************************************************************
// PID Feed Forward control
//**********************************************************************************
// This #define enables feed forward on the mash PID loop. The feed forward can be set to any 
// number of different temp sensors by using the #define for it below, to see sensor #defines see Enum.h 
// under TSensor and output (0-2) Array Element Constants 
// NOTE: not a good idea to use any sensor you average into the MASH sensor as your feed forward
//
//#define PID_FEED_FORWARD
#define FEED_FORWARD_SENSOR TS_AUX1

//**********************************************************************************
// PWM ouputs controled by timer rather than brew core loop
//**********************************************************************************
// This #define enables the PWM outputs to be controled by timer rather than the brew core loop.
// This means that we can have a higher frequency output, and that the timings of the PWM signal are more 
// accurate. This is required if you are goign to attempt to control a pump with a PWM output. 
// NOTE: The counter/timer is set to work with a 16mhz input frequency and is set to run at 8khz PWM output 
// frequency as the fastest possible frequency, (also note that the period cannot exceed 8.19 seconds). Also
// only two PWM outputs can run at 8khz, all the rest must run at a lower frequency as defiend above. The 
// two PWM outputs which will be 8khz can be defined below, comment them both out if none are that high. 
// Also, the reported period for the 8khz outputs is going to look like 1 seconds in both the UI and the log. 
// You will not however be able to set the the PWM frequency from the UI because it is set at 8khz, the value
// given in the UI will be ignored. The % output however will be reported properly through the UI and log. 
//#define PWM_BY_TIMER
//**********************************************************************************

//**********************************************************************************
// Flow rate calcs fed into PID controller for auto fly sparge
//**********************************************************************************
// This #define enables the feeding of the flow rate calcs based on the pressure sensors to be fed into the 
// PID code to control a pump for fly sparge to get a desired flow rate. Note that the PWM output used to 
// control the pump takes over the steam output, and thus the steam output cannot be used for steam. 
// Note: This code is designed to work with PWM_BY_TIMER 
// Note2: Given our current 10 bit adc and the average pressure sensor resolution for volume you only get about 
// 7 ADC clicks per quart, thus if you have your flow rate calcs set to happen to fast you'll always show a 0 flow 
// rate. You'll need at least 20 seconds between flow rate calcs to be able to measure this slow of a flow rate. 
// Note3: the Pump output must be set to PID for this to work as well.
// Note4: In the UI when you enter the Pump flow rate it's entered in 10ths of a quart per minute, so 1 quart per
// minute would be 10. 
//#define PID_FLOW_CONTROL
//#define PID_CONTROL_MANUAL  // modified manual control (still has to be set to PID in settings menu) in case you 
                            //just cant get PID to work
#define PID_FLOW_MIN 30     // this is the minimum PID output duty cycle % to be used when the setpoint is non zero
                            // this is used because under a certain duty cycle a pump wont even spin or just
                            // make foam, etc so we need the pump to at least move liquid before we try to 
                            // control it or your process + intregral variables can just run away while you're trying
                            // to spin up. 
//**********************************************************************************

//**********************************************************************************
// Fly sparge pump control to turn the sparge in pump on/off based on a hysteresis from volume of sparge out
//**********************************************************************************
// This #define will turn the fly sparge in valve config on when the hysteresis amount of fluid has been pumped
// into the kettle from the MLT. It will then shut off the pump when that equal amount of sparge water has been
// pumped out of the HLT. 
// Note: SPARGE_IN_HYSTERSIS is in 1000ths of a gallon or liter. 
//#define SPARGE_IN_PUMP_CONTROL
//#define SPARGE_IN_HYSTERESIS 250
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
// HLT_MAX_TEMP: Ceiling value for HLT (Actual max temp in C or F, Decimal values allowed)
// MASH_HEAT_LOSS: Acts as a floor value to ensure HLT temp is at least target + 
// specified value


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

// TS_ONEWIRE_GPIO: Direct pin connection on microcontroller (Default for BTBOARD_1,
// BTBOARD_22 and BTBOARD_3)
// TS_ONEWIRE_I2C: DS2482 OneWire Master over I2C (Default for BTBOARD_4)
//#define TS_ONEWIRE_GPIO
//#define TS_ONEWIRE_I2C

// TS_ONEWIRE_PPWR: Specifies whether parasite power is used for OneWire temperature
// sensors. Parasite power allows sensors to obtain their power from the data line
// but significantly increases the time required to read the temperature (94-750ms
// based on resolution versus 10ms with dedicated power).
#define TS_ONEWIRE_PPWR 1

// TS_ONEWIRE_RES: OneWire Temperature Sensor Resolution (9-bit - 12-bit). Valid
// options are: 9, 10, 11, 12). Unless parasite power is being used the recommended
// setting is 12-bit (for DS18B20 sensors). DS18S20 sensors can only operate at a max
// of 9 bit. When using parasite power decreasing the resolution reduces the 
// temperature conversion time: 
//   12-bit (0.0625C / 0.1125F) = 750ms 
//   11-bit (0.125C  / 0.225F ) = 375ms 
//   10-bit (0.25C   / 0.45F  ) = 188ms 
//    9-bit (0.5C    / 0.9F   ) =  94ms   
#define TS_ONEWIRE_RES 11

// TS_ONEWIRE_FASTREAD: Enables faster reads of temperatures by reading only the first
// 2 bytes of temperature data and ignoring CRC check.
#define TS_ONEWIRE_FASTREAD

// DS2482_ADDR: I2C Address of DS2482 OneWire Master (used for TS_OneWire_I2C)
// Should be 0x18, 0x19, 0x1A, 0x1B
#define DS2482_ADDR 0x1B
//**********************************************************************************


//**********************************************************************************
// Strike Temperature Correction
//**********************************************************************************
// STRIKE_TEMP_OFFSET: Adjusts strike temperature to compensate for thermal mass of
// mash tun. (Note: This option is used only when Mash Liquor Heat Source is set to
// HLT.)
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
// Serial Logging Options
//**********************************************************************************
// COMTYPE:   Specifies the communication type being used. 
// COMSCHEMA: Specifies the schema for a particular type
//  0 = ASCII Messages
//      0 - Original BT 2.0 Messages
//      1 - BT 2.1 Enhanced ASCII
//       Steam, Calc. Vol & Temp, BoilPower, Grain Temp, Delay Start, MLT Heat Source
//  1 = BTnic Messages - Non-Broadcasting, Single Byte Commands
//      0 - Original implementation
//      1 - With CRC
//  2 = Binary Messages
//      0 = Original implementation
//**********************************************************************************
#define COMTYPE   0
#define COMSCHEMA 0

// BAUD_RATE: The baud rate for the serial connection. Previous to BrewTroller 2.0
// Build 419 this was hard coded to 9600. Starting with Build 419 the default rate
// was increased to 115200 but can be manually set using this compile option.
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
// UI_LCD_I2C: Enables the I2C LCD interface instead of the 4 bit interface
//
//#define NOUI
//#define UI_NO_SETUP
//#define UI_LCD_I2C
//**********************************************************************************

//**********************************************************************************
// UI: ENCODER TYPE
//**********************************************************************************
// You must uncomment one and only one of the following ENCODER_ definitions
// Use ENCODER_ALPS for ALPS and Panasonic Encoders
// Use ENCODER_CUI for older CUI encoders
//
#define ENCODER_TYPE ALPS
//#define ENCODER_TYPE CUI
//**********************************************************************************

//**********************************************************************************
// UI: Home Screen Options
//**********************************************************************************
// LOGO_TROLL: Old Home screen with Troll icon
// LOGO_BREWTROLLER: New Home Screen based on new BrewTroller logo
//#define LOGO_TROLL
#define LOGO_BREWTROLLER

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
//#define BTPD_HLT_TEMP 0x20

// BTPD_MASH_TEMP: Displays Mash temp and setpoint on specified channel
//#define BTPD_MASH_TEMP 0x21

// BTPD_KETTLE_TEMP: Displays Kettle temp and setpoint on specified channel
//#define BTPD_KETTLE_TEMP 0x22

// BTPD_H2O_TEMPS: Displays H2O In and H2O Out temps on specified channels
//#define BTPD_H2O_TEMPS 0x23

// BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
//#define BTPD_FERM_TEMP 0x24

// BTPD_FERM_TEMP: Displays Beer Out temp and Pitch temp on specified channel
//#define BTPD_TIMERS 0x25

// BTPD_HLT_VOL: Displays current and target HLT volume
//#define BTPD_HLT_VOL 0x26

// BTPD_MASH_VOL: Displays current and target Mash volume
//#define BTPD_MASH_VOL 0x27

// BTPD_KETTLE_VOL: Displays current and target Kettle volume
//#define BTPD_KETTLE_VOL 0x28

// BTPD_STEAM_PRESS: Displays current and target Steam pressure
//#define BTPD_STEAM_PRESS 0x29
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





/***********************************************************************************
 * EXPERIMENTAL OPTIONS
 ***********************************************************************************
 The following options are experimental with little to no testing.
 **********************************************************************************/




   
//**********************************************************************************
// Steam Mash Infusion Support
//**********************************************************************************
// EXPERIMENTAL: Uncomment the following line to enable steam mash infusion support.
// USE CAUTION! TESTING REQUIRED.
//
//#define USESTEAM
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
// DEBUG
//**********************************************************************************
// DEBUG_TEMP_CONV_T: Enables logging of OneWire temperature sensor ADC time.
//#define DEBUG_TEMP_CONV_T

// DEBUG_VOL_READ: Enables logging of additional detail used in calculating volume.
//#define DEBUG_VOL_READ

// DEBUG_PID_GAIN: Enables logging of PID Gain settings as they are set.
//#define DEBUG_PID_GAIN

// DEBUG_TIMERALARM: Enables logging of Timer and Alarm values
//#define DEBUG_TIMERALARM

// DEBUG_VOLCALIB: Enables logging of Volume Calibration values
//#define DEBUG_VOLCALIB

// DEBUG_PROG_CALC_VOLS: Enables logging of PreBoil, Sparge, and Total water calcs 
// based on the running program
//#define DEBUG_PROG_CALC_VOLS

//**********************************************************************************

#endif

