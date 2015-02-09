/*
OpenTroller EX1 Hardware Configuration
*/

#ifndef BT_HWPROFILE
#define BT_HWPROFILE
  
  //**********************************************************************************
  // ENCODER TYPE
  //**********************************************************************************
  // You must uncomment one and only one of the following ENCODER_ definitions
  // Use ENCODER_ALPS for ALPS and Panasonic Encoders
  // Use ENCODER_CUI for older CUI encoders
  //
  //#define ENCODER_TYPE ALPS
  #define ENCODER_TYPE CUI
  //**********************************************************************************
  
  #define ENCA_PIN 3
  #define ENCB_PIN 2
  #define ENTER_PIN 1
  #define ENCODER_ACTIVELOW
  
  #define OUTPUTBANK_GPIO
  #define OUTPUTBANK_GPIO_BANKNAME "EX1"
  #define OUTPUTBANK_GPIO_COUNT 7
  #define OUTPUTBANK_GPIO_PINS {22, 15, 21, 18, 20, 19, 27}
  #define OUTPUTBANK_GPIO_OUTPUTNAMES "Out 1\0Out 2\0Out 3\0Out 4\0Out 5\0Out 6\0Alarm"
    
  #define OUTPUTBANK_MODBUS

  #define RS485_SERIAL_PORT 1
  #define RS485_RTS_PIN    12

  // BTPD_SUPPORT: Enables use of BrewTroller PID Display devices on I2C bus
  #define BTPD_SUPPORT
  
  // BTNIC_EMBEDDED: Enables use of on-board I2C Ethernet module
  #define BTNIC_EMBEDDED
  
  #define HEARTBEAT
  #define HEARTBEAT_PIN 0
  
  #define UI_LCD_4BIT
  #define LCD_RS_PIN 4
  #define LCD_ENABLE_PIN 23
  #define LCD_DATA4_PIN 28
  #define LCD_DATA5_PIN 29
  #define LCD_DATA6_PIN 30
  #define LCD_DATA7_PIN 31
  
  #define UI_DISPLAY_SETUP
  #define LCD_BRIGHT_PIN 13
  #define LCD_CONTRAST_PIN 14
  #define LCD_DEFAULT_CONTRAST 100
  #define LCD_DEFAULT_BRIGHTNESS 255
    
  //**********************************************************************************
  // OneWire Temperature Sensor Options
  //**********************************************************************************
  // TS_ONEWIRE: Enables use of OneWire Temperature Sensors (Future logic may
  // support alternatives temperature sensor options.)
  #define TS_ONEWIRE
  #define TS_ONEWIRE_I2C

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
  // Serial0 Communication Options
  //**********************************************************************************
  // COM_SERIAL0: Specifies the communication type being used (Pick One):
  //  ASCII  = Original BrewTroller serial command protocol used with BTRemote and BTLog
  //  BTNIC  = BTnic (Lighterweight implementation of ASCII protocol using single-byte
  //           commands. This protocol is used with BTnic Modules and software for
  //           network connectivity.
  //  BINARY = Binary Messages
  //**********************************************************************************
  
  //#define COM_SERIAL0  ASCII
  #define COM_SERIAL0  BTNIC
  //#define COM_SERIAL0 BINARY
  
  // BAUD_RATE: The baud rate for the Serial0 connection. Previous to BrewTroller 2.0
  // Build 419 this was hard coded to 9600. Starting with Build 419 the default rate
  // was increased to 115200 but can be manually set using this compile option.
  #define SERIAL0_BAUDRATE 115200
  

  #define RS485_MASTER
  #define RS485_RXTX_PIN 12

#endif
