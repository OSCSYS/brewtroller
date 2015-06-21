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

  FermTroller - Open Source Fermentation Computer
  Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
  Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

  Documentation, Forums and more information available at http://www.brewtroller.com

  Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
  With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
  using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
  using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)


  Original Author:  Matt Reba & Jason Vreeland (CodeRage)
  Modified By:      Tom Harkaway, Feb, 2011

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


#include "LOCAL_Pin.h"
#include <Wire.h>
#include "LOCAL_Encoder.h"

// encoder object c'tor
//
encoder::encoder(void)
{
	_count = 0;
	_min = 0;
	_max = 0;
	_wrap = 0;
	i2cAddress = 0;
}

// initialize encoder using External Interrupt method
//  encType - ALPS or CUI
//  encE, encA, encB - pin numbers for enter, phaseA, and phaseB
//  intE, intA - external interrupt numbers of enter and phaseA
//
//  Note: encE & encA must be on INT pins
//
void encoder::begin(byte encType, 
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
void encoder::begin(byte encType, byte encE, byte encA, byte encB)
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


// Deprecated initialize encoder using PinChange Interrupt method
//
//  Note the following definition is provided for backwards compatibility
//    and  assumes the EncA pin and interrupt number match which is a rare
//    scenario. 
//
// This method should not be used for new implementations.
//
void encoder::begin(byte encA, byte encB, byte encE, byte enterInt, byte encType)
{
  begin(encType, encE, encA, encB, enterInt, encA);
}

//Begin for I2C Encoder
void encoder::begin(byte i2cAddr) {
 	i2cAddress = i2cAddr;
}

//Detaches the Encoder ISRs
void encoder::end(void)
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

void encoder::setMin(int min) {
	if(i2cAddress) return i2cSetMin(min);
	_min = min; 
}

void encoder::setMax(int max) {
	if(i2cAddress) return i2cSetMax(max);
	_max = max;
}

void encoder::setWrap(bool wrap) {
	if(i2cAddress) return i2cSetWrap(wrap);
	_wrap = wrap;
}

void encoder::setCount(int count)  {
	if(i2cAddress) return i2cSetCount(count);
	_count = _lastCount = count;
}

void encoder::clearCount(void) {
	if(i2cAddress) return i2cClearCount();
	_count = _min;
}

int  encoder::getCount(void) {
	if(i2cAddress) return i2cGetCount();
	return _count;
}

byte encoder::getEnterState(void) {
	if(i2cAddress) return i2cGetEnterState();
	return _enterState;
}

void encoder::clearEnterState(void)  {
	if(i2cAddress) return i2cClearEnterState();
	_enterState = 0;
}


// set activeLow state
//
void encoder::setActiveLow(bool state)
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
byte  encoder::getEncoderState()
{
	if(i2cAddress) return i2cGetEnterState();
	byte btVal = 0;
	if (_ePin.get()) btVal |= 0x01;
	if (_aPin.get()) btVal |= 0x02;
	if (_bPin.get()) btVal |= 0x04;
	if (isEnterPinPressed()) btVal |= 0x08;
	btVal |= _enterState << 4;
	return btVal;
}



// encoder::getDelta()
//  - compares the current count to the last count
//  - updates last count to the current count
//  - returns the difference
//
int encoder::getDelta(void)
{
	if(i2cAddress) return i2cGetDelta();
	int delta,
		count;

	count = getCount();

	delta = count - _lastCount;
	_lastCount = count;

	return delta;
}


// encoder::change()
//  If the count has not changed since the last time change was called
//    return -1
//  else 
//    update the last count and return the new count
//
int encoder::change(void)
{
	if(i2cAddress) return i2cChange();
	return (getDelta()==0) ? -1 : _count;
}


// return ok state
//  if enterState == 1, reset enterState and return true
//
bool encoder::ok(void)
{
	if(i2cAddress) return i2cOk();
	bool okActive = (_enterState == 1);
	if (okActive) _enterState = 0;
	return okActive;
}


// return cancel state
//  if enterState == 2, reset enterState and return true
//
bool encoder::cancel(void)
{
	if(i2cAddress) return i2cCancel();
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
void encoder::alpsHandler(void) 
{
  	if(_aPin.get() == _bPin.get())
		decCount();
	else
		incCount();
} 

// CUI phaseA change handler
//
void encoder::cuiHandler(void) 
{
	//Read EncB
	if(_bPin.get() == LOW)
		incCount();
	else
		decCount();
} 

void encoder::enterHandler(void) 
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

void encoder::i2cSetMin(int val) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x40);
	Wire.write(val>>8);
	Wire.write(val&255);
	Wire.endTransmission();
}

void encoder::i2cSetMax(int val) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x41);
	Wire.write(val>>8);
	Wire.write(val&255);
	Wire.endTransmission();
}

void encoder::i2cSetWrap(bool val) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x42);
	Wire.write(val);
	Wire.endTransmission();
}

void encoder::i2cSetCount(int val) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x43);
	Wire.write(val>>8);
	Wire.write(val&255);
	Wire.endTransmission();
}

void encoder::i2cClearCount(void) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x44);
	Wire.endTransmission();
}

void encoder::i2cClearEnterState(void) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x45);
	Wire.endTransmission();
}

int  encoder::i2cGetCount(void) {
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

int  encoder::i2cChange(void) {
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

int  encoder::i2cGetDelta(void) {
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

byte encoder::i2cGetEnterState(void) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x49);
	Wire.endTransmission();
	Wire.requestFrom(i2cAddress, (uint8_t) 1);
	while(Wire.available())
	{
		return Wire.read();
	}
}

bool encoder::i2cOk(void) {
	Wire.beginTransmission(i2cAddress);
	Wire.write(0x4A);
	Wire.endTransmission();
	Wire.requestFrom(i2cAddress, (uint8_t) 1);
	while(Wire.available())
	{
		return Wire.read();
	}
}

bool encoder::i2cCancel(void) {
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
encoder Encoder;


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

