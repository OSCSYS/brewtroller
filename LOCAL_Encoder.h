#ifndef _LOCAL_ENCODER_H
#define _LOCAL_ENCODER_H

  #include <Arduino.h>
  #include "HWProfile.h"

  #ifdef ENCODER_I2C
    #include <Wire.h>
  
    class encoderI2C
    {
    private:
      uint8_t i2cAddress;
      
    public:
      byte getEncoderState();   // return the Encoder State
  
      encoderI2C(void);
      void begin(byte i2cAddr);
      void end(void);
  
      void setMin(int min);
      void setMax(int max);
      void setWrap(bool wrap);
      void setCount(int count);
      void clearCount(void);
      int  getCount(void);
      int  change(void);
      int  getDelta(void);
      byte getEnterState(void);
      void clearEnterState(void);
      bool ok(void);
      bool cancel(void);      
    };
    extern encoderI2C Encoder;
  #else
  
  	#define ALPS		0
  	#define CUI			1
  
  	#define EXTERNAL_INT	0
  	#define PINCHANCE_INT 1
  
  	#define CUI_DEBOUNCE		50
  
  	#define ENTER_SHORT_PUSH	50
  	#define ENTER_LONG_PUSH	1000
  
  	#include "LOCAL_Pin.h"
  
  	//ISR wrappers
  	void alpsISR();
  	void cuiISR();
  	void enterISR();
  	
  	class encoderGPIO
  	{
  	private:
  		pin   _aPin;
  		pin   _bPin;
  		pin   _ePin;
  
  		byte  _intA;
  		byte  _intE;
  
  		byte 	_type;      // encoder type (ALPS or CUI)
  		bool  _activeLow; // reverses sense of _ePin
  		byte  _intMode;   // true if using PinChange interrupts
  
  		int	  _lastCount;   // last value of count, used to determine delta
  
  		int   _min;
  		int 	_max;
  		bool 	_wrap;        // true if count should wrap
  
  		volatile int _count;
  		volatile byte _enterState;  // 0 - enter inactive
  								  // 1 - "ok" enter pressed longer than SHORT but shorter than LONG
  								  // 2 - "cancel" detected in ISR
  								  // 3 - "cancel" detected in cancel() method
  
  		volatile unsigned long	_enterStartTime;  // mSec when enter active
  		
  	public:
  		byte getEncoderState();   // return the Encoder State
  
  		encoderGPIO(void);
  		void begin(byte type, byte encE, byte encA, byte encB, byte intE, byte intA);
  		void begin(byte type, byte encE, byte encA, byte encB);
  		void begin(byte encA, byte encB, byte encE, byte enterInt, byte encType);
  		void end(void);
  
  		void setMin(int min);
  		void setMax(int max);
  		void setWrap(bool wrap);
  		void setCount(int count);
  		void clearCount(void);
  		int  getCount(void);
  		void setActiveLow(bool state);
  		int  change(void);
  		int  getDelta(void);
  		byte getEnterState(void);
  		void clearEnterState(void);
  		bool ok(void);
  		bool cancel(void);
  
  	private:
  		inline void incCount(void) { if (++_count > _max) _count = (_wrap) ? _min : _max; }
  		inline void decCount(void) { if (--_count < _min) _count = (_wrap) ? _max : _min; }
  		inline bool isEnterPinPressed(void) { return _activeLow ? !_ePin.get() : _ePin.get(); } 
  		inline bool isTimeElapsed(unsigned long curTime, unsigned long duration) { return (curTime - _enterStartTime) > duration; }  
  		
  	public:
  		//Interrupt Handlers
  		void enterHandler(void);
  		void alpsHandler(void);
  		void cuiHandler(void);
  	};
  	extern encoderGPIO Encoder;
  #endif
#endif
