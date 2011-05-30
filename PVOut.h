#ifndef PVOUT_H
  #define PVOUT_H
  #include <pin.h>
  
  class PVOutGPIO
  {
    private:
    pin valvePin[11];
    
    public:
    PVOutGPIO(
      byte pin1,
      byte pin2,
      byte pin3,
      byte pin4,
      byte pin5,
      byte pin6,
      byte pin7,
      byte pin8,
      byte pin9,
      byte pinA,
      byte pinB
    ) {
      valvePin[0].setup(pin1, OUTPUT);
      valvePin[1].setup(pin2, OUTPUT);
      valvePin[2].setup(pin3, OUTPUT);
      valvePin[3].setup(pin4, OUTPUT);
      valvePin[4].setup(pin5, OUTPUT);
      valvePin[5].setup(pin6, OUTPUT);
      valvePin[6].setup(pin7, OUTPUT);
      valvePin[7].setup(pin8, OUTPUT);
      valvePin[8].setup(pin9, OUTPUT);
      valvePin[9].setup(pinA, OUTPUT);
      valvePin[10].setup(pinB, OUTPUT);
    }
  
    void init(void) { 
      set(0);
    }
    
    void set(unsigned long vlvBits) { 
      for (byte i = 0; i < 11; i++) {
        if (vlvBits & (1<<i)) valvePin[i].set(); else valvePin[i].clear();
      }
    }
  };
  
  class PVOutMUX
  {
    private:
    pin muxLatchPin, muxDataPin, muxClockPin, muxEnablePin;
    boolean muxEnableLogic;
    
    public:
    PVOutMUX(byte latchPin, byte dataPin, byte clockPin, byte enablePin, boolean enableLogic) {
      muxLatchPin.setup(latchPin, OUTPUT);
      muxDataPin.setup(dataPin, OUTPUT);
      muxClockPin.setup(clockPin, OUTPUT);
      muxEnablePin.setup(enablePin, OUTPUT);
      muxEnableLogic = enableLogic;
    }
    
    void init(void) {
      if (muxEnableLogic) {
        //MUX in Reset State
        muxLatchPin.clear(); //Prepare to copy pin states
        muxEnablePin.clear(); //Force clear of pin registers
        muxLatchPin.set(); //Copy pin states from registers
        muxEnablePin.set(); //Disable clear
      } else {
        set(0);
        muxEnablePin.clear();
      }
    }
    
    void set(unsigned long vlvBits) {
      //ground latchPin and hold low for as long as you are transmitting
      muxLatchPin.clear();
      //clear everything out just in case to prepare shift register for bit shifting
      muxDataPin.clear();
      muxClockPin.clear();
    
      //for each bit in the long myDataOut
      for (byte i = 0; i < 32; i++)  {
        muxClockPin.clear();
        //create bitmask to grab the bit associated with our counter i and set data pin accordingly (NOTE: 32 - i causes bits to be sent most significant to least significant)
        if ( vlvBits & ((unsigned long)1<<(31 - i)) ) muxDataPin.set(); else muxDataPin.clear();
        //register shifts bits on upstroke of clock pin  
        muxClockPin.set();
        //zero the data pin after shift to prevent bleed through
        muxDataPin.clear();
      }
    
      //stop shifting
      muxClockPin.clear();
      muxLatchPin.set();
    }
  };
  
  class PVOutMODBUS
  {
    public:
    void init(void);
    void set(unsigned long);
  };
#endif //ifndef PVOUT_H
