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

#include "Outputs.h"

  void OutputBank::init(void) { }
  char* OutputBank::getOutputName(byte index, char* retString) {
    char strIndex[3];
    strlcpy(retString, "Out ", OUTPUT_NAME_MAXLEN);
    strlcat(retString, itoa(index + 1, strIndex, 10), OUTPUT_NAME_MAXLEN);
    return retString;
  }

#ifdef OUTPUTBANK_GPIO
  OutputBankGPIO::OutputBankGPIO(void) {
    outputPins = (pin *) malloc(OUTPUTBANK_GPIO_COUNT * sizeof(pin));
    byte pinNums[OUTPUTBANK_GPIO_COUNT] = OUTPUTBANK_GPIO_PINS;
    for (byte i = 0; i < OUTPUTBANK_GPIO_COUNT; i++) outputPins[i].setup(pinNums[i], OUTPUT);
  }

  OutputBankGPIO::~OutputBankGPIO() {
    free(outputPins);
  }

  void OutputBankGPIO::set(unsigned long outputsState) {
    for (byte i = 0; i < OUTPUTBANK_GPIO_COUNT; i++) {
      outputPins[i].set((outputsState>>i) & 1);
    }
  }
  
  char* OutputBankGPIO::getBankName (char* retString) {
    char bankName[] = OUTPUTBANK_GPIO_BANKNAME;
    strlcpy(retString, bankName, OUTPUTBANK_NAME_MAXLEN);
    return retString;
  }
  
  char* OutputBankGPIO::getOutputName (byte index, char* retString) {
    if (index < OUTPUTBANK_GPIO_COUNT) {
      char outputNames[] = OUTPUTBANK_GPIO_OUTPUTNAMES;
      char* pos = outputNames;
      for (byte i = 0; i <= index; i++) {
        strlcpy(retString, pos, OUTPUT_NAME_MAXLEN);
        pos += strlen(retString) + 1;
      }
    }
    else retString[0] = '\0';
    return retString;
  }
  
  byte OutputBankGPIO::getCount(void) { return OUTPUTBANK_GPIO_COUNT; }
#endif

#ifdef OUTPUTBANK_MUX
  OutputBankMUX::OutputBankMUX(void) {
    muxLatchPin.setup(OUTPUTBANK_MUX_LATCHPIN, OUTPUT);
    muxDataPin.setup(OUTPUTBANK_MUX_DATAPIN, OUTPUT);
    muxClockPin.setup(OUTPUTBANK_MUX_CLOCKPIN, OUTPUT);
    muxEnablePin.setup(OUTPUTBANK_MUX_ENABLEPIN, OUTPUT);
  }
  
  void OutputBankMUX::init(void) {
    #ifdef OUTPUTBANK_MUX_ENABLELOGIC
      //MUX in Reset State
      muxLatchPin.clear(); //Prepare to copy pin states
      muxEnablePin.clear(); //Force clear of pin registers
      muxLatchPin.set();
      delayMicroseconds(10);
      muxLatchPin.clear();
      muxEnablePin.set(); //Disable clear
    #else
      outputsState = 0;
      update();
      muxEnablePin.clear();
    #endif
  }
  
  void OutputBankMUX::set(unsigned long outputsState) {
    //ground latchPin and hold low for as long as you are transmitting
    muxLatchPin.clear();
    //clear everything out just in case to prepare shift register for bit shifting
    muxDataPin.clear();
    muxClockPin.clear();
  
    for (byte i = OUTPUTBANK_MUX_COUNT; i > 0; i--)  {
      muxClockPin.clear();
      muxDataPin.set(outputsState & ((unsigned long)1<<(i - 1)));
      muxClockPin.set();
      muxDataPin.clear();
    }
  
    //stop shifting
    muxClockPin.clear();
    muxLatchPin.set();
    delayMicroseconds(10);
    muxLatchPin.clear();
  }
  
  char* OutputBankMUX::getBankName (char* retString) {
    char bankName[] = OUTPUTBANK_MUX_BANKNAME;
    strlcpy(retString, bankName, OUTPUTBANK_NAME_MAXLEN);
    return retString;
  }
  
  byte OutputBankMUX::getCount(void) { return OUTPUTBANK_MUX_COUNT; }
#endif

#ifdef OUTPUTBANK_MODBUS
  OutputBankMODBUS::OutputBankMODBUS(uint8_t addr, unsigned int coilStart, uint8_t coilCount) {
    slaveAddr = addr;
    slave = ModbusMaster(RS485_SERIAL_PORT, slaveAddr);
    #ifdef RS485_RTS_PIN
      slave.setupRTS(RS485_RTS_PIN);
    #endif
    slave.begin(RS485_BAUDRATE, RS485_PARITY);
    //Modbus Coil Register index starts at 1 but is transmitted with a 0 index
    coilReg = coilStart - 1;
    outputCount = coilCount;
  }
 
  char* OutputBankMODBUS::getBankName (char* retString) {
    char bankName[14] = "MB#";
    char strAddr[6];
    strlcpy(retString, bankName, OUTPUTBANK_NAME_MAXLEN);
    strlcat(retString, itoa(slaveAddr, strAddr, 16), OUTPUTBANK_NAME_MAXLEN);
    strlcat(retString, "-", OUTPUTBANK_NAME_MAXLEN);
    strlcat(retString, itoa(coilReg + 1, strAddr, 10), OUTPUTBANK_NAME_MAXLEN);
    return retString;
  }
  
  void OutputBankMODBUS::set(unsigned long outputsState) {
    byte outputPos = 0;
    byte bytePos = 0;
    while (outputPos < outputCount) {
      byte byteData = 0;
      byte bitPos = 0;
      while (outputPos < outputCount && bitPos < 8) {
        bitWrite(byteData, bitPos++, (outputsState >> outputPos++) & 1);
      }
      slave.setTransmitBuffer(bytePos++, byteData);
    }
    slave.writeMultipleCoils(coilReg, outputCount);
  }
  
  byte OutputBankMODBUS::getCount(void) { return outputCount; }
  
  byte OutputBankMODBUS::detect(void) {
      return slave.readCoils(coilReg, outputCount);
  }
  
  byte OutputBankMODBUS::setAddr(byte newAddr) {
    byte result = 0;
    result |= slave.writeSingleRegister(OUTPUTBANK_MODBUS_REGSLAVEADDR, newAddr);
    if (!result) {
      slave.writeSingleRegister(OUTPUTBANK_MODBUS_REGRESTART, 1);
      slaveAddr = newAddr;
    }
    return result;
  }
  
  byte OutputBankMODBUS::setIDMode(byte value) { return slave.writeSingleRegister(OUTPUTBANK_MODBUS_REGIDMODE, value); }

  byte OutputBankMODBUS::getIDMode() { 
    if (slave.readHoldingRegisters(OUTPUTBANK_MODBUS_REGIDMODE, 1) == 0)
      return slave.getResponseBuffer(0);
    return 0;
  }
  
#endif

  void OutputSystem::addBank(OutputBank* outputBank) {
    if (bankCount < OUTPUTBANKS_MAXBANKS) {
      banks[bankCount++] = outputBank;
    }
  }

  OutputSystem::OutputSystem(void) {
    banks = new OutputBank* [OUTPUTBANKS_MAXBANKS];
    for (uint8_t i = 0; i < OUTPUTBANKS_MAXBANKS; i++) {
      banks[i] = NULL;
    }
    bankCount = 0;
    #ifdef OUTPUTBANK_GPIO
      addBank(new OutputBankGPIO());
    #endif

    #if defined OUTPUTBANK_MUX
      addBank(new OutputBankMUX());
    #endif
  }

  OutputSystem::~OutputSystem(void) {
    delete [] banks;
  }
  
  void OutputSystem::init(void) {
    outputState = profileState = discreetState = 0;
    for (byte i = 0; i < OUTPUTENABLE_COUNT; i++)
      outputEnableMask[i] = 0xFFFFFFFFul;
    for (byte i = 0; i < OUTPUTPROFILE_SYSTEMCOUNT; i++)
      profileMask[i] = 0;
    byte bIndex = 0;
    while (bIndex < bankCount)
      banks[bIndex++]->init();
    update();
  }
  
  #ifdef OUTPUTBANK_MODBUS
  void OutputSystem::newModbusBank(uint8_t slaveAddr, unsigned int coilReg, uint8_t coilCount){
    addBank(new OutputBankMODBUS(slaveAddr, coilReg, coilCount));
  }
  #endif
  
  byte OutputSystem::getCount(void){
    if (!bankCount)
      return 0;
    byte count = 0;
    for (byte i = 0; i < bankCount; i++)
      count += banks[i]->getCount();
    return count;
  }
  
  byte OutputSystem::getBankCount(void){
    return bankCount;
  }
  
  OutputBank* OutputSystem::getBank(uint8_t bankIndex){
    return banks[bankIndex];
  }

  char* OutputSystem::getOutputBankName(byte outputIndex, char* retString) {
    byte outputCount = 0;
    for (byte i = 0; i < bankCount; i++) {
      outputCount += banks[i]->getCount();
      if (outputCount >= outputIndex + 1)
        return banks[i]->getBankName(retString);
    }
    return retString;
  }
  
  char* OutputSystem::getOutputName(byte outputIndex, char* retString) {
    byte outputCount = 0;
    for (byte i = 0; i < bankCount; i++) {
      outputCount += banks[i]->getCount();
      if (outputCount >= outputIndex + 1)
        return banks[i]->getOutputName(outputIndex - (outputCount - banks[i]->getCount()), retString);
    }
    return retString;
  }

  
  void OutputSystem::update(void) {
    //Start with discreet outputs
    unsigned long newState = discreetState;
    
    //Apply all active valve profiles
    for (byte p = 0; p < OUTPUTPROFILE_SYSTEMCOUNT; p++) {
      if (getProfileState(p))
        newState |= profileMask[p];
    }
    
    //Apply output enable masks
    for (byte i = 0; i < OUTPUTENABLE_COUNT; i++)
      newState &= outputEnableMask[i];
    
    outputState = newState;
    
    //Push new state to banks
    byte bIndex = 0;
    byte oIndex = 0;
    while (bIndex < bankCount && oIndex < 32) {
      unsigned long mask = 0;
      for (byte i = 0; i < banks[bIndex]->getCount(); i++)
        mask |= (unsigned long) 1 << i;
      banks[bIndex]->set(newState & mask);
      newState = newState >> banks[bIndex++]->getCount();
    }
  }
 
  boolean OutputSystem::getOutputState(byte outputIndex) {
    return (outputState >> outputIndex) & 1;
  }
  
  unsigned long OutputSystem::getOutputStateMask() {
    return outputState;
  }
  
  boolean OutputSystem::getOutputEnable(byte enableIndex, byte outputIndex) {
    return (outputEnableMask[enableIndex] >> outputIndex) & 1;
  }
  
  unsigned long OutputSystem::getOutputEnableMask(byte enableIndex){
    return outputEnableMask[enableIndex];
  }
  
  void OutputSystem::setOutputEnable(byte enableIndex, byte outputIndex, boolean enableFlag) {
    unsigned long mask = (unsigned long)1 << outputIndex;
    
    if (enableFlag)
      outputEnableMask[enableIndex] |= mask;
    else
      outputEnableMask[enableIndex] &= ~mask;
  }
  
  void OutputSystem::setOutputEnableMask(byte enableIndex, unsigned long enableMask) {
    outputEnableMask[enableIndex] = enableMask;
  }
  
  boolean OutputSystem::getProfileState(byte profileIndex){
    return (profileState >> profileIndex) & 1;
  }
  
  uint32_t OutputSystem::getProfileStateMask(void) {
    return profileState;
  }

  void OutputSystem::setProfileState(byte profileIndex, boolean newState){
    unsigned long mask = (unsigned long)1 << profileIndex;
    
    if (newState)
      profileState |= mask;
    else
      profileState &= ~mask;
  }
  
  void OutputSystem::setProfileStateMask(unsigned long selectedProfileMask, boolean newState) {
    if (newState)
      profileState |= selectedProfileMask;
    else
      profileState &= !selectedProfileMask;
  }
  
  unsigned long OutputSystem::getProfileMask(byte profileIndex) {
    return profileMask[profileIndex];
  }
  
  boolean OutputSystem::getProfileMaskBit(byte profileIndex, byte bitIndex) {
    return (profileMask[profileIndex] >> bitIndex) & 1;
  }
  
  void OutputSystem::setProfileMask(byte profileIndex, unsigned long newMask){
    profileMask[profileIndex] = newMask;
  }
  
  void OutputSystem::setProfileMaskBit(byte profileIndex, byte bitIndex, boolean value) {
    unsigned long mask = (unsigned long)1 << bitIndex;
    
    if (value)
      profileMask[profileIndex] |= mask;
    else
      profileMask[profileIndex] &= ~mask;
  }
  boolean OutputSystem::getDiscreetState(byte outputIndex) {
    return (discreetState >> outputIndex) & 1;
  }
  
  void OutputSystem::setDiscreetState(byte outputIndex, boolean stateValue) {
    unsigned long mask = (unsigned long)1 << outputIndex;
    
    if (stateValue)
      discreetState |= mask;
    else
      discreetState &= ~mask;
  }
  
  void analogOutput::setValue(byte v) { value = v; }
  byte analogOutput::getLimit() { return limit; }
  byte analogOutput::getValue() { return value; }
  void analogOutput::init() {}


  analogOutput_SWPWM::analogOutput_SWPWM(byte index, byte p, byte resolution) {
    pinIndex = index;
    limit = resolution;
    period = p;
  }
  
  OutputSystem* analogOutput_SWPWM::outputs = NULL;
  void analogOutput_SWPWM::setup(OutputSystem* o)
  {
    analogOutput_SWPWM::outputs = o;
  }
  
  void analogOutput_SWPWM::setValue(byte v) {
    //Transition from inactive to active
    if (!value && v) { sPeriod = millis(); }
    value = v;
    if (!value) outputs->setDiscreetState(pinIndex, 0);
  }
  
  void analogOutput_SWPWM::update() {
    if (value) { 
      unsigned long sUpdated = millis();
      if (sUpdated - sPeriod > period * 100)
        sPeriod = sUpdated;
      outputs->setDiscreetState(pinIndex, (sUpdated - sPeriod < (unsigned long)period * 100 * value / limit) ? 1 : 0);
    }
  }

#ifdef ANALOGOUTPUTS_HWPWM
  analogOutput_HWPWM::analogOutput_HWPWM(byte p) {
    pin = p;
  }
  
  void analogOutput_HWPWM::setValue(byte v) { analogWrite(pin, v);  }
  void analogOutput_HWPWM::update() {  }
  
  //Utility methods:
  byte analogOutput_HWPWM::getCount() { 
      return ANALOGOUTPUTS_HWPWM_PINCOUNT;
  }
  
  byte analogOutput_HWPWM::getPin(byte index) {
    if (index < ANALOGOUTPUTS_HWPWM_PINCOUNT) {
      byte pins[] = ANALOGOUTPUTS_HWPWM_PINS;
      return pins[index];
    }
    return 255;
  }

  byte analogOutput_HWPWM::getTimer(byte index) { 
    if (index < ANALOGOUTPUTS_HWPWM_PINCOUNT) {
      byte timers[] = ANALOGOUTPUTS_HWPWM_TIMERS;
      return timers[index];
    }
    return 255;
  }

  char* analogOutput_HWPWM::getName(byte index, char* retString) {
    if (index < ANALOGOUTPUTS_HWPWM_PINCOUNT) {
      char names[] = ANALOGOUTPUTS_HWPWM_NAMES;
      char* pos = names;
      for (byte i = 0; i <= index; i++) {
        strlcpy(retString, pos, OUTPUT_NAME_MAXLEN);
        pos += strlen(retString) + 1;
      }
    }
    else retString[0] = '\0';
    return retString;
  }
  
  byte analogOutput_HWPWM::getTimerModes(byte timer) { 
    if (timer == 0) return 1;
    else if (timer == 1) return 5;
    else if (timer == 2) return 7;
    else return 0;
  }

  byte analogOutput_HWPWM::getTimerValue(byte timer, byte index) {
    if (timer == 0) { return 0x03; } //Timer 0 always equals 1KHz
    else if ((timer == 1 && index < 5) || (timer == 2 && index < 7)) { return index; } //Timer 1 values 1-5, Timer 2 values 1-7
    else return 0;
  }
  
  char * analogOutput_HWPWM::getTimerText(byte timer, byte index, char* retString) {
    unsigned int freqs[3][7] = {
      {977, 0, 0, 0, 0, 0, 0},                //Timer0
      {31250, 3906, 488, 122, 30, 0, 0},      //Timer1
      {31250, 3906, 977, 488, 244, 122, 30}   //Timer2
    };
    unsigned int value = 0;
    if (index < 7) { value = freqs[timer][index]; }
    if (value == 0) strcpy(retString, "Invalid Mode");
    else if (value > 1000) {
      char sFreq[3];
      itoa(round(value/1000), sFreq, 10);
      strcpy(retString, sFreq);
      strcat(retString, " kHz");
    }
    else {
      char sFreq[4];
      itoa(value, sFreq, 10);
      strcpy(retString, sFreq);
      strcat(retString, " Hz");
    }
    return retString;
  }
#endif

