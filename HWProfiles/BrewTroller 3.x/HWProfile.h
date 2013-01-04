/*
BrewTroller 3.x Hardware Configuration
*/

#ifndef BT_HWPROFILE
#define BT_HWPROFILE
  #include "Config.h"
  
  //**********************************************************************************
  // ENCODER TYPE
  //**********************************************************************************
  // You must uncomment one and only one of the following ENCODER_ definitions
  // Use ENCODER_ALPS for ALPS and Panasonic Encoders
  // Use ENCODER_CUI for older CUI encoders
  //
  #define ENCODER_TYPE ALPS
  //#define ENCODER_TYPE CUI
  //**********************************************************************************
  
  #define ENCODER_OLD_CONSTRUCTOR
  #define ENCA_PIN 2
  #define ENCB_PIN 4
  #define ENTER_PIN 11
  #define ENTER_INT 1
  #define ENCA_INT 2
  
  #define HLTHEAT_PIN 0
  #define MASHHEAT_PIN 1
  #define KETTLEHEAT_PIN 3
  #define STEAMHEAT_PIN 6
  #define PWMPUMP_PIN 6
  
  #define ALARM_PIN 15
  
  #define PVOUT_TYPE_MUX
  #define PVOUT_COUNT 16 //16 Outputs
    
  #define MUX_LATCH_PIN 12
  #define MUX_CLOCK_PIN 13
  #define MUX_DATA_PIN 14
  #define MUX_ENABLE_PIN 10
  #define MUX_ENABLE_LOGIC 0
  
  #define HLTVOL_APIN 0
  #define MASHVOL_APIN 1
  #define KETTLEVOL_APIN 2
  #define STEAMPRESS_APIN 3
  
//**********************************************************************************
// OneWire Temperature Sensor Options
//**********************************************************************************
// TS_ONEWIRE: Enables use of OneWire Temperature Sensors (Future logic may
// support alternatives temperature sensor options.)
#define TS_ONEWIRE
#define TS_ONEWIRE_GPIO
#define TEMP_PIN 5

// 1-Wire I2C Option: BT 3.x boards with I2C ports can use the BT 4.0 1-Wire Module
// via a custom cable. To use this option comment out '#define TS_ONEWIRE_GPIO'
// above and uncomment the following lines:
//#define TS_ONEWIRE_I2C
//#define DS2482_ADDR 0x1B //Should be 0x18, 0x19, 0x1A or 0x1B

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
//**********************************************************************************
  
  #define UI_LCD_4BIT
  #define LCD_RS_PIN 18
  #define LCD_ENABLE_PIN 19
  #define LCD_DATA4_PIN 20
  #define LCD_DATA5_PIN 21
  #define LCD_DATA6_PIN 22
  #define LCD_DATA7_PIN 23

#endif
