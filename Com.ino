/*  
   Copyright (C) 2009, 2010 Matt Reba, Jeremiah Dillingham

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

*/

//**********************************************************************************
//Code Shared by all Schemas
//**********************************************************************************
void comInit() {
  #ifdef COM_SERIAL0
    Serial.begin(SERIAL0_BAUDRATE);
  #endif
  #ifdef RGBIO8_ENABLE
    RGBIO8_Init();
  #endif
}

void updateCom() {
  #ifdef COM_SERIAL0
    #if COM_SERIAL0 == BTNIC
      updateS0BTnic();
    #endif
  #endif
  #ifdef BTNIC_EMBEDDED
    updateI2CBTnic();
  #endif
  //BTPD Support
  #ifdef BTPD_SUPPORT
    updateBTPD();
  #endif
  #ifdef RGBIO8_ENABLE
    RGBIO8_Update();
  #endif
}

/********************************************************************************************************************
 * BTnic Instances
 ********************************************************************************************************************/
#ifdef BTNIC_PROTOCOL
  #include "Com_BTnic.h"
  
  #ifdef BTNIC_EMBEDDED
    BTnic btnicI2C;
    
    void updateI2CBTnic() {
      switch (btnicI2C.getState()) {
        case BTNIC_STATE_IDLE:
        case BTNIC_STATE_RX:
          while (1) {
            Wire.requestFrom(BTNIC_I2C_ADDR, 1);
            if (! Wire.available())
              break; //No data
            byte data = Wire.read();
            if (!data)
              break; //Null return: No data
            #ifdef DEBUG_BTNIC
              Serial.print("btnicEmb RX: ");
              Serial.print(data);
              Serial.print("(0x");
              Serial.print(data, HEX);
              Serial.print(", ");
              Serial.print(data, DEC);
              Serial.println(")");
            #endif
            btnicI2C.rx(data);
            if(btnicI2C.getState() != BTNIC_STATE_RX) break;
          }
          
        case BTNIC_STATE_TX:
          //TX Ready
          while(btnicI2C.getState() == BTNIC_STATE_TX) {
            byte maxLength = 32;
            Wire.beginTransmission(BTNIC_I2C_ADDR);
            while(maxLength-- && btnicI2C.getState() == BTNIC_STATE_TX) {
              byte data = btnicI2C.tx();
              #ifdef DEBUG_BTNIC
                Serial.print("btnicEmb TX: ");
                Serial.print(data);
                Serial.print("(0x");
                Serial.print(data, HEX);
                Serial.print(", ");
                Serial.print(data, DEC);
                Serial.println(")");
              #endif
              Wire.write(data);
            }
            Wire.endTransmission();
          }
          break;
      }
    }
  #endif
  
  #ifdef COM_SERIAL0
    #if COM_SERIAL0 == BTNIC /* BTnic over Serial0 */
      BTnic btnicS0;
      void updateS0BTnic() {
        switch (btnicS0.getState()) {
          case BTNIC_STATE_IDLE:
          case BTNIC_STATE_RX:
            while (Serial.available()) {
              btnicS0.rx(Serial.read());
              if(btnicS0.getState() != BTNIC_STATE_RX) break;
            }
            if(btnicS0.getState() != BTNIC_STATE_TX) break;
          case BTNIC_STATE_TX:
            //TX Ready
            while(btnicS0.getState() == BTNIC_STATE_TX) Serial.write(btnicS0.tx());
        }
      }
    #endif
  #endif
#endif


#ifdef RGBIO8_ENABLE
  RGBIO8 rgbio8s[RGBIO8_NUM_BOARDS];
  unsigned long lastRGBIO8 = 0;
  
  // Initializes the RGBIO8 system. If you want to provide custom IO mappings
  // this is the place to do it. See the CUSTOM CONFIGURATION section below for
  // further instructions.
  void RGBIO8_Init() {
    RGBIO8::setup(outputs);
    
    // Initialize and address each RGB board that is attached
    for (int i = 0; i < RGBIO8_NUM_BOARDS; i++) {
      rgbio8s[i].begin(0, RGBIO8_START_ADDR + i);
    }
    
    // Set the default coniguration. The user can override this with the
    // custom configuration information below.
    int ioIndex = 0;
    for (int i = 0; i < outputs->getCount() && (ioIndex / 8) < RGBIO8_NUM_BOARDS; i++, ioIndex++)
      rgbio8s[ioIndex / 8].assign(i, ioIndex % 8, 0);
    
    ////////////////////////////////////////////////////////////////////////
    // CUSTOM CONFIGURATION
    ////////////////////////////////////////////////////////////////////////
    // To provide your own custom IO mappings you will have to add code to
    // this section. The code is very simple and the mappings are very
    // powerful.
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
    
    // Recipe 0, used for Heat Outputs
    // Off:       0xF00 (Red)
    // Auto Off:  0xFFF (White)
    // Auto On:   0xF40 (Orange)
    // On:        0x0F0 (Green)
    RGBIO8::setOutputRecipe(0, 0xF00, 0xFFF, 0xF40, 0x0F0);
    
    // Recipe 1, used for Pump/Valve Outputs
    // Off:       0xF00 (Red)
    // Auto Off:  0xFFF (White)
    // Auto On:   0x00F (Blue)
    // On:        0x0F0 (Green)
    RGBIO8::setOutputRecipe(1, 0xF00, 0xFFF, 0x00F, 0x0F0);
  
    //
    // Now we move on to mappings. A mapping ties a given RGBIO8 channel to
    // an output. 
    // 
    // To create a mapping to an output:
    // assign(rgbioChannelNumber, outputNumber, recipeNumber);
    //
    // When creating a mapping, you have to specify which RGB board the mapping
    // belongs to. That is done by using rgbio8s[boardNumber]. before the
    // function calls above. Some example mappings are shown below:
    // 
    // Map board 0, channel 0 to output 0 using recipe 0:
    // rgbio8s[0].assign(0, 0, 0);
    // 
    // Map board 1, channel 3 to output 5 using recipe 1:
    // rgbio8s[1].assign(3, 5, 1);
    //
    // Add your custom mappings below this line
  }
  
  void RGBIO8_Update() {
    if (millis() > (lastRGBIO8 + RGBIO8_INTERVAL)) {
      for (int i = 0; i < RGBIO8_NUM_BOARDS; i++) {
        rgbio8s[i].update();
      }
      outputs->setProfileState(OUTPUTPROFILE_RGBIO, outputs->getProfileMask(OUTPUTPROFILE_RGBIO) ? 1 : 0);
      lastRGBIO8 = millis();
    }
  }
#endif


void comEvent(byte eventID, int eventParam) {
  #ifdef BTNIC_PROTOCOL
    #ifdef BTNIC_EMBEDDED
      btnicI2C.eventHandler(eventID, eventParam);
    #endif
    #ifdef COM_SERIAL0
      #if COM_SERIAL0 == BTNIC /* BTnic over Serial0 */
        btnicS0.eventHandler(eventID, eventParam);
      #endif
    #endif
  #endif
}
