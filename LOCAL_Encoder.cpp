/*
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

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

  Encoder Library
  Original Author:  Jason Vreeland (CodeRage)
  Modified By:      

    Matt Reba
    Tom Harkaway, Feb, 2011
    
  Modifications:

  1. Modified existing begin() method. 
    - Change order of parameter
    - Added an boolean "ActiveLow" parameter to specify if the encoder's switches
      are wired active-low (i.e. switch to ground). If it is active-low, the sense
      of the enter switch is reversed.
    - Require that the external interrupt number for both EncE and EncA be specified.

  2. Added a new begin() method that uses PinChange interrupts rather than External 
     interrupts for the EncE and EncA switches. Uses new PCInt functions added
     to FastPin library

  3. Modified Cancel logic so it triggers as soon as the cancel timeout had been reached
     rather than wait for enter to be released.

  4. General reorganization and additional comments.

***********************************************************/

#include "LOCAL_Encoder.h"

#ifdef ENCODER_I2C
  encoderI2C::encoderI2C(void) {
    i2cAddress = 0;
  }
  
  void encoderI2C::begin(byte i2cAddr) {
    i2cAddress = i2cAddr;
  }
  
  void encoderI2C::end(void) {}
  
  void encoderI2C::setMin(int val) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x40);
    Wire.write(val>>8);
    Wire.write(val&255);
    Wire.endTransmission();
  }
  
  void encoderI2C::setMax(int val) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x41);
    Wire.write(val>>8);
    Wire.write(val&255);
    Wire.endTransmission();
  }
  
  void encoderI2C::setWrap(bool val) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x42);
    Wire.write(val);
    Wire.endTransmission();
  }
  
  void encoderI2C::setCount(int val) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x43);
    Wire.write(val>>8);
    Wire.write(val&255);
    Wire.endTransmission();
  }
  
  void encoderI2C::clearCount(void) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x44);
    Wire.endTransmission();
  }
  
  void encoderI2C::clearEnterState(void) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x45);
    Wire.endTransmission();
  }
  
  int  encoderI2C::getCount(void) {
    int retValue;
    uint8_t * p = (uint8_t *) &retValue;
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x46);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 2);
    while (Wire.available())
    {
      *(p++) = Wire.read();
    }
    return retValue;
  }
  
  int  encoderI2C::change(void) {
    int retValue;
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x47);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 2);
    if (Wire.available() > 1)
    {
      retValue = Wire.read();
      retValue |= (((int)(Wire.read())) << 8);
    }
    else return -1; //Call failed so return 'No Change'
    return retValue;
  }
  
  int  encoderI2C::getDelta(void) {
    int retValue;
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x48);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 2);
    if (Wire.available() > 1)
    {
      retValue = Wire.read();
      retValue |= (((int)(Wire.read())) << 8);
    }
    return retValue;
  }
  
  byte encoderI2C::getEnterState(void) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x49);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 1);
    while(Wire.available())
    {
      return Wire.read();
    }
  }
  
  bool encoderI2C::ok(void) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x4A);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 1);
    while(Wire.available())
    {
      return Wire.read();
    }
  }
  
  bool encoderI2C::cancel(void) {
    Wire.beginTransmission(i2cAddress);
    Wire.write(0x4B);
    Wire.endTransmission();
    Wire.requestFrom(i2cAddress, (uint8_t) 1);
    while(Wire.available())
    {
      return Wire.read();
    }
  }
  
  
  // The one and only Global Encoder Object
  encoderI2C Encoder;
#else
  encoderGPIO::encoderGPIO(void)
  {
  	_count = 0;
  	_min = 0;
  	_max = 0;
  	_wrap = 0;
  }
  
  // initialize encoder using External Interrupt method
  //  encType - ALPS or CUI
  //  encE, encA, encB - pin numbers for enter, phaseA, and phaseB
  //  intE, intA - external interrupt numbers of enter and phaseA
  //
  //  Note: encE & encA must be on INT pins
  //
  void encoderGPIO::begin(byte encType, 
                      byte encE, byte encA, byte encB,
                      byte intE, byte intA)
  {
  	_count = 0;
  
    _type = encType;
  
  	_ePin.setup(encE,INPUT);
    _aPin.setup(encA,INPUT);
    _bPin.setup(encB,INPUT);
  
    _intE = intE;
    _intA = intA;
  
    _activeLow = false;
  
  	// attach External Interrupts
    noInterrupts();
    _intMode = EXTERNAL_INT;
    attachInterrupt(_intE, enterISR, CHANGE);
    if(_type == ALPS)
      attachInterrupt(_intA, alpsISR, CHANGE);
    else if(_type == CUI)
      attachInterrupt(_intA, cuiISR, RISING);
    interrupts();
  }
  
  
  // initialize encoder using PinChange Interrupt method
  //  encType - ALPS or CUI
  //  encE, encA, encB - pin numbers for enter, phaseA, and phaseB
  //
  //  Note: encE & encA must be on the same Port
  //  Note: Uses PinChangeInt library 
  //
  void encoderGPIO::begin(byte encType, byte encE, byte encA, byte encB)
  {
    _count = 0;
  
    _type = encType;
   
    _ePin.setup(encE, INPUT);
    _aPin.setup(encA, INPUT);
    _bPin.setup(encB, INPUT);
  
    _activeLow = false;
  
    // attach PinChange Interrupts
    noInterrupts();
    _intMode = PINCHANCE_INT;
    _ePin.attachPCInt(CHANGE, enterISR);
    if (encType == ALPS)
      _aPin.attachPCInt(CHANGE, alpsISR);
    else
      _aPin.attachPCInt(RISING, cuiISR);
    interrupts();
  }
  
  //Detaches the Encoder ISRs
  void encoderGPIO::end(void)
  {
    noInterrupts();
    if (_intMode = PINCHANCE_INT)
    {
      _ePin.detachPCInt();
      _aPin.detachPCInt();
    }
    else
    {
      detachInterrupt(_intA);
      detachInterrupt(_intE);
    }
    interrupts();
  }
  
  void encoderGPIO::setMin(int min) {
  	_min = min; 
  }
  
  void encoderGPIO::setMax(int max) {
  	_max = max;
  }
  
  void encoderGPIO::setWrap(bool wrap) {
  	_wrap = wrap;
  }
  
  void encoderGPIO::setCount(int count)  {
  	_count = _lastCount = count;
  }
  
  void encoderGPIO::clearCount(void) {
  	_count = _min;
  }
  
  int  encoderGPIO::getCount(void) {
  	return _count;
  }
  
  byte encoderGPIO::getEnterState(void) {
  	return _enterState;
  }
  
  void encoderGPIO::clearEnterState(void)  {
  	_enterState = 0;
  }
  
  
  // set activeLow state
  //
  void encoderGPIO::setActiveLow(bool state)
  {
    _activeLow = state;
    if (_activeLow)
    {
      // turn on output to enable pull-ups
      _aPin.set();
      _bPin.set();
      _ePin.set();
    }
    else
    {
      _aPin.clear();
      _bPin.clear();
      _ePin.clear();
    }
  }
  
  
  // return value of encoder pins
  //  bit-0 enter
  //  bit-1 phase A
  //  bit-2 phase B
  //
  byte  encoderGPIO::getEncoderState()
  {
  	byte btVal = 0;
  	if (_ePin.get()) btVal |= 0x01;
  	if (_aPin.get()) btVal |= 0x02;
  	if (_bPin.get()) btVal |= 0x04;
  	if (isEnterPinPressed()) btVal |= 0x08;
  	btVal |= _enterState << 4;
  	return btVal;
  }
  
  
  
  // encoderGPIO::getDelta()
  //  - compares the current count to the last count
  //  - updates last count to the current count
  //  - returns the difference
  //
  int encoderGPIO::getDelta(void)
  {
  	int delta,
  		count;
  
  	count = getCount();
  
  	delta = count - _lastCount;
  	_lastCount = count;
  
  	return delta;
  }
  
  
  // encoderGPIO::change()
  //  If the count has not changed since the last time change was called
  //    return -1
  //  else 
  //    update the last count and return the new count
  //
  int encoderGPIO::change(void)
  {
  	return (getDelta()==0) ? -1 : _count;
  }
  
  
  // return ok state
  //  if enterState == 1, reset enterState and return true
  //
  bool encoderGPIO::ok(void)
  {
  	bool okActive = (_enterState == 1);
  	if (okActive) _enterState = 0;
  	return okActive;
  }
  
  
  // return cancel state
  //  if enterState == 2, reset enterState and return true
  //
  bool encoderGPIO::cancel(void)
  {
  	// check if cancel has already been detected and reported
  	if (_enterState == 3)
  	return false;
  
  //Removing due to I2C encoder logic
  //	noInterrupts();
  
  	bool cancelState = (_enterState == 2);
  	if (cancelState)
  	{
  		// enter ISR has detected cancel condition
  		_enterState = 0;
  	}
  	else if (isEnterPinPressed() && isTimeElapsed(millis(), ENTER_LONG_PUSH))
  	{
  		// cancel condition detected
  		cancelState = true;
  		_enterState = 3;  // 3=cancel detected prior to release (used by ISR)
  	}
  //	interrupts();
  	return cancelState;
  }
  
  // ALPS phaseA change handler
  //
  void encoderGPIO::alpsHandler(void) 
  {
    	if(_aPin.get() == _bPin.get())
  		decCount();
  	else
  		incCount();
  } 
  
  // CUI phaseA change handler
  //
  void encoderGPIO::cuiHandler(void) 
  {
  	//Read EncB
  	if(_bPin.get() == LOW)
  		incCount();
  	else
  		decCount();
  } 
  
  void encoderGPIO::enterHandler(void) 
  {
  	volatile long time = millis();
  
    // test state of _ePin conditioned by  _activeLow
    if (isEnterPinPressed())
    {  
      // enter button pushed in, set the time stamp
  		_enterStartTime = time;
  	}
    else
  	{
      if (_enterState == 3)
      {
        _enterState = 0;
      }
      else if (isTimeElapsed(time, ENTER_LONG_PUSH))
  		{
        // enter button released, check time since pressed
  			// > long push, Cancel
        _enterState = 2;
  		}
  		else if (isTimeElapsed(time, ENTER_SHORT_PUSH)) 
  		{
  			// < long push, but > short Push
        _enterState = 1;
  		}
    }
  }
  
  // The one and only Global Encoder Object
  encoderGPIO Encoder;
  
  
  // ALPS Encoder Function Interrupt Service Routine wrapper
  void alpsISR(void)
  {
  	Encoder.alpsHandler();
  }
  
  // CUI Encoder Function Interrupt Service Routine wrapper
  void cuiISR(void)
  {
  	Encoder.cuiHandler();
  }
  
  // Enter Function Interrupt Service Routine wrapper
  void enterISR(void)
  {
  	Encoder.enterHandler();
  }
#endif
