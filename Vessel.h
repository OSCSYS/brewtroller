#ifndef Vessel_h
#define Vessel_h

#include "LOCAL_PID_Beta6.h"
#include "Outputs.h"

struct Calibration {
  unsigned int inputValue;
  unsigned long outputValue;
};

class Vessel {
  private:
    PID *pid;
    double PIDInput, PIDOutput, setpoint;
    analogOutput *pwmOutput;
    byte pwmActiveProfile, heatProfile, idleProfile;
    int *temperature;
    byte vSensor;
    unsigned long targetVolume, volume;
    long flowRate;  //Thousandths of gal/l per minute
    struct Calibration volumeCalibration[10];
    byte hysteresis;
    boolean heatStatus;
    boolean preheated;
    unsigned int volumeReadings[VOLUME_READ_COUNT], lastFlowrateVolume;
    unsigned long lastVolumeRead, lastFlowrateRead;
    byte volumeReadCursor;

    void updateHeat(void);
    void setHeatStatus(boolean status);
    void updatePIDHeat(void);
    void updateVolume(void);
    void updateFlowRate(void);
    unsigned long calibrateVolume(unsigned int aValue);

  public:
    Vessel(int *t, byte pwmActive, byte heat, byte idle);
    ~Vessel(void);
    void update(void);
    PID* getPID(void);
    analogOutput* getPWMOutput(void);
    void setPWMOutput(analogOutput *aout);
    double getSetpoint(void);
    double setSetpoint(double value);
    byte getHysteresis(void);
    void setHysteresis(byte value);
    unsigned long getTemperature(void);
    unsigned long getVolume(void);
    unsigned long getTargetVolume(void);
    long getFlowRate(void);
    byte getHeatPower(void);
    struct Calibration getVolumeCalibration(byte index);
    unsigned int getRawVolumeValue(void);
};

#endif
