/***********************************************************

  FastPin Library

  Copyright (C) 2009-2011 Matt Reba, Jermeiah Dillingham

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

    Documentation, Forums and more information available at http://www.brewtroller.com

    Original Author:
    Modified By:      Tom Harkaway, Feb, 2011

    Modifications:

      Generalize FastPin library so that it can be used on Arduino platforms, specifically
      the Arduino Mega.

      Incorporate PinChange interrupt (PCInt) support. On the BrewTroller, all 32 pins can
      be configured as PCInt pins. That is not true of other Arduino platforms, such as 
      the Adrunio Mega.
*/

#ifndef _PIN_H
#define _PIN_H

// Uncomment to add access to debug routines to Serial debug dump routines
//#define FASTPIN_DEBUG

#include <pins_arduino.h>
#include <avr/io.h>
#include <Arduino.h>

#if defined(__AVR_ATmega644P__) || defined(__AVR_ATmega1284P__)   // Sanguino
#define MAX_PIN 31
#elif defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)  // Arduino ATMega
#define MAX_PIN 69
#elif defined(__AVR_ATmega168__)  || defined(__AVR_ATmega168P__) // Arduino ATMega
#define MAX_PIN 20
#else
#error FastPin only defined for ATMega (1280/2560) and Sanguino (644P/1284P) processors
#endif

// Port IDs
//
#define NOT_A_PORT 0
#define PA 1
#define PB 2
#define PC 3
#define PD 4
#define PE 5
#define PF 6
#define PG 7
#define PH 8
#define PJ 10
#define PK 11
#define PL 12

#define NO_PCINT 255


typedef void (*PCIntvoidFuncPtr)(void);


/********************************************************/
// PinChange Interrupt Support Classes
//

// Uncomment the line below to limit the Pin Change handler to servicing a single interrupt
//#define	DISABLE_PCINT_MULTI_SERVICE

// Define the value MAX_PIN_CHANGE_PINS to limit the number of pins that may be configured for PCINT
//
#define	MAX_PIN_CHANGE_PINS 8

// Declare PCINT ports without pin change interrupts used
//
//#define	NO_PCINT0_PINCHANGES 1
//#define	NO_PCINT1_PINCHANGES 1
//#define	NO_PBINC2_PINCHANGES 1
//#define	NO_PCINT3_PINCHANGES 1


// PCI_Port class 
//  Manages the collection PinChangeInterrupts (PCI) for a given port. 
//
class PCI_Port 
{
  // constructor
  PCI_Port(int index, int port, volatile uint8_t& maskReg) :
      _index(index),
      _inputReg(*portInputRegister(port)),
      _pcmskReg(maskReg),
      _pcicrBit(1 << index),
      _lastVal(0)	
  {
    for (int i = 0; i < 9; i++) 
      _pcIntPinArray[i] = NULL;
  }

public:
  static PCI_Port	s_pcIntPorts[]; // static PCI_Port Array

  void PCintHandler();              // PinChange Interrupt Handler
  void PCintHandler2();              // PinChange Interrupt Handler

protected:

  // embedded PCI_Pin class
  //
  class PCI_Pin 
  {
  public:
    PCI_Pin() :
        _pinID(0),
        _pinMask(0),
        _pinMode(0),
        _func((PCIntvoidFuncPtr)NULL)
  { }

    uint8_t _pinID;    // pin number
    uint8_t _pinMask;  // bit mask 
    uint8_t _pinMode;  // CHANGE, RISING, FALLING

    PCIntvoidFuncPtr _func; // user function 

    // static PCintPins Array
    static PCI_Pin s_pcIntPins[MAX_PIN_CHANGE_PINS];

  }; // PCI_Pin class

public:
  int  addPin(uint8_t pin, uint8_t mode, uint8_t mask, PCIntvoidFuncPtr userFunc);
  bool delPin(uint8_t pinID);

protected:
  uint8_t              _index;
  volatile byte&		_inputReg;  // port input register (will need to move to PCI_Pin)
  volatile byte&		_pcmskReg;  // port bit Mask Register
  const byte			  _pcicrBit;  // PCI enable bit
  byte			        _lastVal;   // last input value

  //// PCI_Pin array for this port
  PCI_Pin*	_pcIntPinArray[9];	// extra entry is a barrier

public:
#ifdef FASTPIN_DEBUG
  int getIndex() { return _index; }
  void dumpPCIntPin(PCI_Pin* pPin);
  void dumpPCIntPinArray();
#endif

};  // PCI_Port class


/********************************************************/
// Fast Access I/O Pin Class
//


class pin
{
public:
	pin(void);
	pin(byte);
	pin(uint8_t pinID, uint8_t pinDir);
	void setup(uint8_t pin, uint8_t pinDir);

  void setPin(byte);
  void setDir(byte);

	void set(byte);
	void set(void);
	void clear(void);
	bool get(void);
        void toggle(void);
	
  uint8_t getPin(void)   { return _pinID; }
  uint8_t getDir(void)   { return _dir; }
  uint8_t getPort(void)  { return _port; }
  uint8_t getMask(void)  { return _mask; }

  int  attachPCInt(int modePC, PCIntvoidFuncPtr userFunc);
  bool detachPCInt();

private:
	uint8_t _pinID;  // pin number
	uint8_t _dir;    // direction
	uint8_t _port;   // port ID
	uint8_t _mask;   // mask

};


// Mapping of PIN ID to PCInt port
//
extern const uint8_t PROGMEM digitalpin_to_pcint_PGM[];
#define digitalPinToPCINT(P) ( pgm_read_byte( digitalpin_to_pcint_PGM + (P) ) )


#endif
