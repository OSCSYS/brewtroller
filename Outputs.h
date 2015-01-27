/*  
   Copyright (C) 2009 - 2012 Open Source Control Systems, Inc.

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


BrewTroller - Open Source Brewing Controller
Documentation, Forums and more information available at http://www.brewtroller.com
*/

#ifndef OT_Outputs_h
#define OT_Outputs_h

#include <Arduino.h>
#include "Config.h"
#include "HWProfile.h"
#include <pin.h>
#include <ModbusMaster.h>
  
//Includes trailing slash
#define OUTPUTBANK_NAME_MAXLEN 17
#define OUTPUTBANKS_MAXBANKS 4

class OutputBank
{
public:
  //OutputBank subclass may optionally (re)define the following
  virtual void init(void);
  virtual char* getOutputName(byte index, char* retString);
  //OutputBank subclass must define the following
  virtual void set(unsigned long) = 0;
  virtual char* getBankName(char* retSring) = 0;
  virtual byte getCount(void) = 0;
};

#ifdef OUTPUTBANK_GPIO
class OutputBankGPIO : public OutputBank
{
  private:
  pin* outputPins;
 
  public:
  OutputBankGPIO(void);
  ~OutputBankGPIO();

  void set(unsigned long outputsState);
  char* getBankName (char* retString);
  char* getOutputName (byte index, char* retString);
  byte getCount(void);
};
#endif

#ifdef OUTPUTBANK_MUX
class OutputBankMUX : public OutputBank
{
  private:
  pin muxLatchPin, muxDataPin, muxClockPin, muxEnablePin;
  
  public:
  OutputBankMUX(void);  
  void init(void);
  void set(unsigned long outputsState);  
  char* getBankName (char* retString);  
  byte getCount(void);
};
#endif

#ifdef OUTPUTBANK_MODBUS
class OutputBankMODBUS : public OutputBank
{
  private:
  ModbusMaster slave;
  byte slaveAddr, outputCount;
  unsigned int coilReg;

  public:
  OutputBankMODBUS(uint8_t addr, unsigned int coilStart, uint8_t coilCount);
  char* getBankName (char* retString);
  void set(unsigned long outputsState);
  byte getCount(void);

  byte detect(void);
  byte setAddr(byte newAddr);
  byte setIDMode(byte value);
  byte getIDMode(void);
};
#endif

class OutputSystem
{
  private:
  OutputBank** banks;
  byte bankCount;
  unsigned long outputState, discreetState, profileState, profileMask[OUTPUTPROFILE_SYSTEMCOUNT], outputEnableMask[OUTPUTENABLE_COUNT];
  
  void addBank(OutputBank* outputBank);
  
  public:
  OutputSystem(void);
  ~OutputSystem(void);
  
  void init(void);
  
  #ifdef OUTPUTBANK_MODBUS
  void newModbusBank(uint8_t slaveAddr, unsigned int coilReg, uint8_t coilCount);
  #endif
  
  byte getCount(void);
  byte getBankCount(void);  
  OutputBank* getBank(uint8_t bankIndex);
  void update(void);
  boolean getOutputState(byte index);
  unsigned long getOutputStateMask(void);
  boolean getOutputEnable(byte index);
  void setOutputEnable(byte enableIndex, byte outputIndex, boolean enableFlag);
  void setOutputEnableMask(byte enableIndex, unsigned long enableMask);
  boolean getProfileState(byte profileIndex);
  uint32_t getProfileStateMask(void);
  void setProfileState(byte profileIndex, boolean newState);
  void setProfileStateMask(unsigned long selectedProfileMask, boolean newState);
  unsigned long getProfileMask(byte profileIndex);
  boolean getProfileMaskBit(byte profileIndex, byte bitIndex);
  void setProfileMask(byte profileIndex, unsigned long newMask);
  void setProfileMaskBit(byte profileIndex, byte bitIndex, boolean value);
  boolean getDiscreetState(byte outputIndex);
  void setDiscreetState(byte outputIndex, boolean stateValue);
};

typedef enum {
  analogOutType_None,
  analogOutType_SWPWM,
  analogOutType_HWPWM,
  analogOutType_Modbus
} analogOutType;

typedef struct analogOutCfg_t {
  analogOutType type;
  union {
    struct analogOutCfg_SWPWM_t {
      byte index;
      byte period; //Time period in tenths of a second (0.0- 25.5s)
    } analogOutCfg_SWPWM;
    struct analogOutCfg_HWPWM_t {
      byte index; //HWProfile to provide array of Pins
    } analogOutCfg_HWPWM;
    struct analogOutCfg_Modbus_t {
      byte slaveAddr;
      unsigned int reg;
      unsigned long limit; //Max value
    } analogOutCfg_Modbus;
  } implementation;
};

class analogOutput {
  protected:
  byte value, limit;
  
  public:
  static analogOutput* create(analogOutCfg_t cfg);
  virtual void setValue(byte v);
  byte getLimit();
  virtual void init();
  virtual void update() = 0;
};

class analogOutput_SWPWM : public analogOutput {
  private:
  static OutputSystem* outputs;
  byte pinIndex;
  unsigned long sPeriod; //Start of PWM period: millis()
  //limit: (0-255 x 100ms)
  
  public:
  analogOutput_SWPWM(byte index, byte period);
  void setValue(byte v);
  void update();
  static void setup(OutputSystem* otOutputs);
};


class analogOutput_HWPWM : public analogOutput {
  private:
  byte pin;
  
  public:
  analogOutput_HWPWM(byte p);
  void setValue(byte v);
  void update();
  
  //Utility methods:
  static byte getCount();  
  static byte getPin(byte index);
  static byte getTimer(byte index);
  static char* getName(byte index, char* retString);
  static byte getTimerModes(byte timer);
  static byte getTimerValue(byte timer, byte index);
  static char * getTimerText(byte timer, byte index, char* retString);
};
#endif
