#ifndef PVOUT_H
  #define PVOUT_H
  #include <pin.h>
  
  class PVOutGPIO
  {
    private:
    pin* valvePin;
    
    public:
    PVOutGPIO(byte pinCount) {
      valvePin = (pin *) malloc(pinCount * sizeof(pin));
    }

    ~PVOutGPIO() {
      free(valvePin);
    }
  
    void setup(byte pinIndex, byte digitalPin) {
      valvePin[pinIndex].setup(digitalPin, OUTPUT);
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
        delayMicroseconds(10);
        muxLatchPin.clear();
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
      delayMicroseconds(10);
      muxLatchPin.clear();
    }
  };
  
  class PVOutMODBUS
  {
    public:
    void init(void);
    void set(unsigned long);
  };
#endif //ifndef PVOUT_H
