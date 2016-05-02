#include "Vessel.h"

Vessel::Vessel(int *t, byte pwmActive, byte heat, byte idle) {
  temperature = t;
  pwmActiveProfile = pwmActive;
  heatProfile = heat;
  idleProfile = idle;
  pid = new PID(&PIDInput, &PIDOutput, &PIDSetpoint, 1, 0, 0, DIRECT);
  #ifdef PID_AUTOTUNE
    aTune = new PID_ATune(&PIDInput, &PIDOutput);
    ATuneModeRemember = MANUAL;
    tuning = false;
  #endif
  pwmOutput = NULL;
  vSensor = INDEX_NONE;
  targetVolume = 0;
  volume = 0;

  PIDInput = 0;
  PIDOutput = 0;
  PIDSetpoint = 0;
  setpoint = 0;
  flowRate = 0;
  heatStatus = 0;
  for (byte i = 0; i < VOLUME_READ_COUNT; i++)
    volumeReadings[i] = 0;
  lastFlowrateVolume = 0;
  lastVolumeRead = 0;
  lastFlowrateRead = 0;
  volumeReadCursor = 0;
}

Vessel::~Vessel(void) {
  if (pid)
    delete pid;
  #ifdef PID_AUTOTUNE
    if (aTune)
      delete aTune;
  #endif
}

void Vessel::update(void) {
  updateVolume();
  updateFlowRate();
  updateHeat();
}

PID* Vessel::getPID(void) {
  return pid;
}

analogOutput* Vessel::getPWMOutput(void) {
  return pwmOutput;
}

void Vessel::setPWMOutput(analogOutput *aout) {
  if (pwmOutput)
    delete pwmOutput;
  pwmOutput = aout;
}

byte Vessel::getVolumeInput(void) {
  return vSensor;
}

void Vessel::setVolumeInput(byte pin) {
  vSensor = pin;
}

unsigned int Vessel::getSetpoint(void) {
  return setpoint;
}

void Vessel::setSetpoint(unsigned int value) {
  setpoint = value;
  PIDSetpoint = tToPercent(value);
}

double Vessel::tToPercent(double tValue) {
  return (tValue - WORKING_TEMPERATURE_MINIMUM) / (WORKING_TEMPERATURE_MAXIMUM - WORKING_TEMPERATURE_MINIMUM) * 100.0;
}

byte Vessel::getHysteresis(void) {
  return hysteresis;
}

void Vessel::setHysteresis(byte value) {
  hysteresis = value;
}

unsigned long Vessel::getTemperature(void) {
  return *temperature;
}

unsigned long Vessel::getVolume(void) {
  return volume;
}

unsigned long Vessel::getTargetVolume(void) {
  return targetVolume;
}

void Vessel::setTargetVolume(unsigned long target) {
  targetVolume = target;
}

long Vessel::getFlowRate(void) {
  return flowRate;
}

double Vessel::getHeatPower (void) {
  return (pwmOutput ? pwmOutput->getValue() : (heatStatus ? 100.0 : 0.0));
}

void Vessel::updateHeat(void) {
  //Call On/Off Update first to set heatstatus
  if (!setpoint || *temperature == BAD_TEMP)
    setHeatStatus(HEATSTATE_DISABLE);
  else if (heatStatus && (*temperature >= setpoint))
    setHeatStatus(HEATSTATE_IDLE);
  else if (!heatStatus && (*temperature <= (setpoint - (hysteresis * 10))))
    setHeatStatus(HEATSTATE_HEAT);
  else if (!heatStatus)
    setHeatStatus(HEATSTATE_IDLE); //Required when setpoint is set after temperature is already above setpoint
  
  //Only updates heatstatus if PID value is non-zero
  updatePIDHeat();
}

void Vessel::setHeatStatus(enum HeatState heatState) {
  heatStatus = heatState & 1;
  outputs->setProfileState(heatProfile, heatStatus);
  outputs->setProfileState(idleProfile, heatState>>1);
}

void Vessel::updatePIDHeat(void) {
  //This code should only be applied for vessels with a pwmOutput
  if (!pwmOutput)
    return;

  if (!setpoint)
    pwmOutput->setValue(0);
  else {
    if (pid->GetMode() == AUTOMATIC
        #ifdef PID_AUTOTUNE
          || tuning
        #endif
    ) {
      PIDInput = tToPercent(*temperature);
      #ifdef PID_AUTOTUNE
        if(!tuning)
      #endif
        pid->Compute();
      #ifdef PID_AUTOTUNE
      else if (aTune->Runtime() != 0)
        stopAutoTune();
      #endif
      pwmOutput->setValue(PIDOutput);
    }
  }
    
  pwmOutput->update();
  
  if (pwmOutput->getValue()) {
    outputs->setProfileState(pwmActiveProfile, 1);
    heatStatus = 1;
  } else {
    //Do not modify heatStatus; initial value is set in On/Off logic and only updated if PID is active
    outputs->setProfileState(pwmActiveProfile, 0);
  }
}

#ifdef PID_AUTOTUNE
void Vessel::startAutoTune(byte controlMode, double aTuneStartValue, double aTuneStep, double aTuneNoise, int aTuneLookBack)
{
  PIDOutput = aTuneStartValue;
  aTune->SetNoiseBand(tToPercent(aTuneNoise + WORKING_TEMPERATURE_MINIMUM));
  aTune->SetOutputStep(aTuneStep);
  aTune->SetLookbackSec(aTuneLookBack);
  aTune->SetControlType(controlMode);
  ATuneModeRemember = pid->GetMode();
  pid->SetMode(MANUAL);
  tuning = true;
}

void Vessel::stopAutoTune()
{
  tuning = false;
  aTune->Cancel();
  pid->SetMode(ATuneModeRemember);
  PIDOutput = 0;
}

boolean Vessel::isTuning()
{
  return tuning;
}

PID_ATune* Vessel::getPIDAutoTune() {
  return aTune;
}
#endif

void Vessel::updateVolume(void) {
  //Process bubbler logic and prevent reads if bubbler is active or in delay
  boolean readEnabled = 1;
  if (BrewTrollerApplication::getInstance()->getBubbler())
    readEnabled = BrewTrollerApplication::getInstance()->getBubbler()->compute();
  
  //Check volume on VOLUME_READ_INTERVAL and update vol with average of VOLUME_READ_COUNT readings
  if (millis() - lastVolumeRead > VOLUME_READ_INTERVAL) {
    if (vSensor != INDEX_NONE && readEnabled) {
      volumeReadings[volumeReadCursor++] = analogRead(vSensor);
      unsigned long rawVolume = 0;
      for (byte i = 0; i < VOLUME_READ_COUNT; i++)
        rawVolume += volumeReadings[i];
      rawVolume = rawVolume / VOLUME_READ_COUNT; 
      volume = calibrateVolume(rawVolume);
    }

    if (volumeReadCursor >= VOLUME_READ_COUNT)
      volumeReadCursor = 0;
    lastVolumeRead = millis();
  }
}

void Vessel::updateFlowRate(void) {
  unsigned long timestamp = millis();
  unsigned long ellapsed = timestamp - lastFlowrateRead;
  if (ellapsed > FLOWRATE_READ_INTERVAL) {
    long difference = volume - lastFlowrateVolume;
    flowRate = difference * 60000 / ellapsed;
    lastFlowrateVolume = volume;
    lastFlowrateRead = timestamp;
  }
}

unsigned long Vessel::calibrateVolume(unsigned int aValue) {
  unsigned long retValue;
  
  byte upperCal = 0;
  byte lowerCal = 0;
  byte lowerCal2 = 0;
  for (byte i = 0; i < 10; i++) {
    if (aValue == volumeCalibration[i].inputValue) { 
      upperCal = i;
      lowerCal = i;
      lowerCal2 = i;
      break;
    } else if (aValue > volumeCalibration[i].inputValue) {
        if (aValue < volumeCalibration[lowerCal].inputValue)
          lowerCal = i;
        else if (volumeCalibration[i].inputValue > volumeCalibration[lowerCal].inputValue) { 
          if (aValue < volumeCalibration[lowerCal2].inputValue || volumeCalibration[lowerCal].inputValue > volumeCalibration[lowerCal2].inputValue)
            lowerCal2 = lowerCal;
          lowerCal = i; 
        } else if (aValue < volumeCalibration[lowerCal2].inputValue || volumeCalibration[i].inputValue > volumeCalibration[lowerCal2].inputValue)
          lowerCal2 = i;
    } else if (aValue < volumeCalibration[i].inputValue) {
      if (aValue > volumeCalibration[upperCal].inputValue)
        upperCal = i;
      else if (volumeCalibration[i].inputValue < volumeCalibration[upperCal].inputValue)
        upperCal = i;
    }
  }
  
  //If no calibrations exist return zero
  if (volumeCalibration[upperCal].inputValue == 0 && volumeCalibration[lowerCal].inputValue == 0)
    retValue = 0;

  //If the value matches a calibration point return that value
  else if (aValue == volumeCalibration[lowerCal].inputValue)
    retValue = volumeCalibration[lowerCal].outputValue;
  else if (aValue == volumeCalibration[upperCal].inputValue)
    retValue = volumeCalibration[upperCal].outputValue;
  
  //If read value is greater than all calibrations plot value based on two closest lesser values
  else if (aValue > volumeCalibration[upperCal].inputValue && volumeCalibration[lowerCal].inputValue > volumeCalibration[lowerCal2].inputValue)
    retValue = round((float) ((float)aValue - (float)volumeCalibration[lowerCal].inputValue) / (float) ((float)volumeCalibration[lowerCal].inputValue - (float)volumeCalibration[lowerCal2].inputValue) * ((float)volumeCalibration[lowerCal].outputValue - (float)volumeCalibration[lowerCal2].outputValue)) + volumeCalibration[lowerCal].outputValue;
  
  //If read value exceeds all calibrations and only one lower calibration point is available plot value based on zero and closest lesser value
  else if (aValue > volumeCalibration[upperCal].inputValue)
    retValue = round((float) ((float)aValue - (float)volumeCalibration[lowerCal].inputValue) / (float) ((float)volumeCalibration[lowerCal].inputValue) * (float)((float)volumeCalibration[lowerCal].outputValue)) + volumeCalibration[lowerCal].outputValue;
  
  //If read value is less than all calibrations plot value between zero and closest greater value
  else if (aValue < volumeCalibration[lowerCal].inputValue)
    retValue = round((float) aValue / (float) volumeCalibration[upperCal].inputValue * (float)volumeCalibration[upperCal].outputValue);
  
  //Otherwise plot value between lower and greater calibrations
  else
    retValue = round((float) ((float)aValue - (float)volumeCalibration[lowerCal].inputValue) / (float) ((float)volumeCalibration[upperCal].inputValue - (float)volumeCalibration[lowerCal].inputValue) * ((float)volumeCalibration[upperCal].outputValue - (float)volumeCalibration[lowerCal].outputValue)) + volumeCalibration[lowerCal].outputValue;

  return retValue;
}

unsigned int Vessel::getRawVolumeValue(void) {
  if (vSensor == INDEX_NONE)
    return 0;
  unsigned int newSensorValueAverage = 0;
  
  for (byte i = 0; i < VOLUME_READ_COUNT; i++) {
    newSensorValueAverage += analogRead(vSensor);
    unsigned long intervalEnd = millis() + VOLUME_READ_INTERVAL;
    while(millis() < intervalEnd)
        BrewTrollerApplication::getInstance()->update(PRIORITYLEVEL_CRITICAL);
  }
  return (newSensorValueAverage / VOLUME_READ_COUNT);
}

struct Calibration Vessel::getVolumeCalibration(byte index) {
  return volumeCalibration[index];
}

void Vessel::setVolumeCalibration(byte index, struct Calibration calibration) {
  volumeCalibration[index] = calibration;
}

