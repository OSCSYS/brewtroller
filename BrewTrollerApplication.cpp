#include "BrewTrollerApplication.h"

//Eventually we'll move the logic into new classes owned by the application
//In the near-term we'll poke some holes to access globals
extern int temp[NUM_TS];
extern struct ProgramThread programThread[PROGRAMTHREAD_MAX];
extern Trigger *trigger[USERTRIGGER_COUNT];
extern OutputSystem *outputs;
#if defined UI_LCD_4BIT
  extern LCD4Bit LCD;
#elif defined UI_LCD_I2C
  extern LCDI2C LCD;
#endif
extern ControlState boilControlState;
extern byte boilPwr;
extern boolean autoValve[NUM_AV];
extern struct BrewStepConfiguration brewStepConfiguration;
extern unsigned long prevSpargeVol[2];

void initializeBrewStepConfiguration();
void tempInit();
void comInit();
boolean checkConfig();
void loadSetup();
void uiInit();
void triggerUpdate();
void updateTimers();
void updateTemps();
void updateBuzzer();
void programThreadsUpdate();
#ifdef RGBIO8_ENABLE
  void RGBIO8_Update();
#endif
void updateCom();
void updateAutoValve();

#ifndef NOUI
  void uiUpdate();
#endif

void setSetpoint(byte, int);
byte getBoilTemp();
void setBoilOutput(byte);
void setBoilControlState(ControlState);

BrewTrollerApplication* BrewTrollerApplication::INSTANCE = new BrewTrollerApplication();

enum schedulerTasks {
  SCHEDULETASK_TIMERS,
#ifndef NOUI
  SCHEDULETASK_LCD,
#endif
  SCHEDULETASK_TEMPS,
  SCHEDULETASK_BUZZER,
  SCHEDULETASK_PROGRAMS,
#ifdef RGBIO8_ENABLE
  SCHEDULETASK_RGBIO,
#endif
  SCHEDULETASK_COMS,
  SCHEDULETASK_AUTOVALVE,
  SCHEDULETASK_COUNT
};

BrewTrollerApplication::BrewTrollerApplication(void) {
  for (byte index = 0; index < VESSEL_COUNT; index++)
    vessel[index] = new Vessel(temp + index, OUTPUTPROFILE_VESSEL1PWMACTIVE + index, OUTPUTPROFILE_VESSEL1HEAT + index, OUTPUTPROFILE_VESSEL1IDLE + index);
  bubbler = NULL;

  lastKettleOutSave = 0;
  scheduler = SCHEDULETASK_TIMERS;
  #ifdef HEARTBEAT
    hbStart = 0;
  #endif
}

BrewTrollerApplication::~BrewTrollerApplication(void) {
  for (byte index = 0; index < VESSEL_COUNT; index++)
    delete vessel[index];
}


BrewTrollerApplication* BrewTrollerApplication::getInstance(void) {
  return INSTANCE;
}

Vessel* BrewTrollerApplication::getVessel(byte index) {
  return vessel[index];
}

void BrewTrollerApplication::init(void) {
  #ifdef ADC_REF
  analogReference(ADC_REF);
  #endif
  
  #ifdef USE_I2C
    Wire.begin(BT_I2C_ADDR);
  #endif
  
  #ifdef HEARTBEAT
    hbPin.setup(HEARTBEAT_PIN, OUTPUT);
  #endif

  for (byte i = 0; i < PROGRAMTHREAD_MAX; i++) {
    programThread[i].activeStep = INDEX_NONE;
    programThread[i].recipe = INDEX_NONE;
  }
  
  for (byte i = 0; i < USERTRIGGER_COUNT; i++)
    trigger[i] = NULL;
  
  initializeBrewStepConfiguration();

  //We need some object for UI in case setup is not loaded due to missing config
  //This will get thrown away after setup is loaded
  outputs = new OutputSystem();
  outputs->init();

  tempInit();  
  comInit();
  
  //Check for cfgVersion variable and update EEPROM if necessary (EEPROM.ino)
  if (!checkConfig())
    loadSetup();
  
  //User Interface Initialization (UI.ino)
  //Moving this to last of setup() to allow time for I2CLCD to initialize
  #ifndef NOUI
    uiInit();
  #endif
}

void BrewTrollerApplication::update(enum ApplicationUpdatePriorityLevel priorityLevel) {
  //START CRITICAL PRIORITY (Avoid ESTOP)
  #ifdef HEARTBEAT
    heartbeat();
  #endif
  //END CRITICAL PRIORITY

  if (priorityLevel < PRIORITYLEVEL_HIGH)
    return;

  //START HIGH PRIORITY: Time-sensitive updates performed on each iteration
  if (bubbler)
    bubbler->compute();

  triggerUpdate();

  updateBoilController();
  for (byte i = 0; i < VESSEL_COUNT; i++)
    vessel[i]->update();

  outputs->update();
  //END HIGH PRIORITY

  if (priorityLevel < PRIORITYLEVEL_NORMAL)
    return;
  
  //START NORMAL PRIORITY: Updated in turn
  switch (scheduler) {
#ifndef NOUI
    case SCHEDULETASK_LCD:
      LCD.update();
      break;
#endif  

    case SCHEDULETASK_TIMERS:
      //Timers: Timer.ino
      updateTimers();
      break;
      
    case SCHEDULETASK_TEMPS:
     //temps: Temp.ino
     updateTemps();
     break;

    case SCHEDULETASK_BUZZER:
      //Alarm update allows to have a beeping alarm
      updateBuzzer();
      break;
      
    case SCHEDULETASK_PROGRAMS:
      //Step Logic: StepLogic.ino
      programThreadsUpdate();
      break;
      
#ifdef RGBIO8_ENABLE
    case SCHEDULETASK_RGBIO:
      RGBIO8_Update();
#endif
      
    case SCHEDULETASK_COMS:
      //Communications: Com.ino
      updateCom();
      break;
      
    case SCHEDULETASK_AUTOVALVE:
      //Auto Valve Logic: Outputs.ino
      updateAutoValve();
      break;
  }
  
  if(++scheduler >= SCHEDULETASK_COUNT)
    scheduler = 0;

  if (priorityLevel < PRIORITYLEVEL_NORMALUI)
    return;

  #ifndef NOUI
    uiUpdate();
  #endif
}

#ifdef HEARTBEAT
  void BrewTrollerApplication::heartbeat(void) {
    if (millis() - hbStart > 750) {
      hbPin.toggle();
      hbStart = millis();
    }
  }
#endif

void BrewTrollerApplication::updateBoilController () {
  if (!vessel[VS_KETTLE]->getPWMOutput())
    return;

  if (boilControlState == CONTROLSTATE_AUTO)
    vessel[VS_KETTLE]->getPWMOutput()->setValue((vessel[VS_KETTLE]->getTemperature() < getBoilTemp() * SETPOINT_MULT) ? vessel[VS_KETTLE]->getPWMOutput()->getLimit() : (unsigned int)(vessel[VS_KETTLE]->getPWMOutput()->getLimit()) * boilPwr / 100);
  else if (boilControlState == CONTROLSTATE_OFF)
    vessel[VS_KETTLE]->getPWMOutput()->setValue(0);

  //Save Kettle output to EEPROM if different, check every minuite (to avoid excessive EEPROM writes)
  if ((millis() - lastKettleOutSave > 60000) && boilControlState == CONTROLSTATE_MANUAL) {
      lastKettleOutSave = millis();
      setBoilOutput(vessel[VS_KETTLE]->getPWMOutput()->getValue());
    }
}

void BrewTrollerApplication::reset(void) {
  setBoilControlState(CONTROLSTATE_OFF);
  for (byte i = 0; i < VESSEL_COUNT; i++)
    setSetpoint(i, 0);
  outputs->setProfileStateMask(0x00000000ul, 0);
}

void BrewTrollerApplication::updateAutoValve() {
    //Do Valves
    if (autoValve[AV_FILL]) {
      outputs->setProfileState(OUTPUTPROFILE_FILLHLT, (vessel[VS_HLT]->getVolume() < vessel[VS_HLT]->getTargetVolume()) ? 1 : 0);
      outputs->setProfileState(OUTPUTPROFILE_FILLMASH, (vessel[VS_MASH]->getVolume() < vessel[VS_MASH]->getTargetVolume()) ? 1 : 0);
    }
    
    if (autoValve[AV_SPARGEIN])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, (vessel[VS_HLT]->getVolume() > vessel[VS_HLT]->getTargetVolume()) ? 1 : 0);

    if (autoValve[AV_SPARGEOUT])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, (vessel[VS_KETTLE]->getVolume() < vessel[VS_KETTLE]->getTargetVolume()) ? 1 : 0);

    if (autoValve[AV_FLYSPARGE]) {
      if (vessel[VS_KETTLE]->getVolume() < vessel[VS_KETTLE]->getTargetVolume()) {
        if (brewStepConfiguration.flySpargeHysteresis) {
          if((long)(vessel[VS_KETTLE]->getVolume()) - (long)prevSpargeVol[0] >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1);
             prevSpargeVol[0] = vessel[VS_KETTLE]->getVolume();
          } else if((long)prevSpargeVol[1] - (long)(vessel[VS_HLT]->getVolume()) >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
             prevSpargeVol[1] = vessel[VS_HLT]->getVolume();
          }
        } else {
          outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1);
        }
        outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 1);
      } else {
        outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
        outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, 0);
      }
    }
    if (autoValve[AV_CHILL]) {
      //Needs work
      /*
      //If Pumping beer
      if (vlvConfigIsActive(OUTPUTPROFILE_WORTOUT)) {
        //Cut beer if exceeds pitch + 1
        if (temp[TS_BEEROUT] > pitchTemp + 1.0) bitClear(actProfiles, OUTPUTPROFILE_WORTOUT);
      } else {
        //Enable beer if chiller H2O output is below pitch
        //ADD MIN DELAY!
        if (temp[TS_H2OOUT] < pitchTemp - 1.0) bitSet(actProfiles, OUTPUTPROFILE_WORTOUT);
      }
      
      //If chiller water is running
      if (vlvConfigIsActive(OUTPUTPROFILE_CHILL)) {
        //Cut H2O if beer below pitch - 1
        if (temp[TS_BEEROUT] < pitchTemp - 1.0) bitClear(actProfiles, OUTPUTPROFILE_CHILL);
      } else {
        //Enable H2O if chiller H2O output is at pitch
        //ADD MIN DELAY!
        if (temp[TS_H2OOUT] >= pitchTemp) bitSet(actProfiles, OUTPUTPROFILE_CHILL);
      }
      */
    }
  }
  
byte BrewTrollerApplication::autoValveBitmask(void) {
  byte modeMask = 0;
  for (byte i = AV_FILL; i < NUM_AV; i++)
    if (autoValve[i]) modeMask |= 1<<i;
  return modeMask;
}


boolean BrewTrollerApplication::isEStop(void) {
  #ifdef ESTOP_PIN
    return (outputs->getOutputEnableMask(OUTPUTENABLE_ESTOP) == outputs->getProfileMask(OUTPUTPROFILE_ALARM));
  #else
    return 0;
  #endif
}

Bubbler* BrewTrollerApplication::getBubbler(void) {
  return bubbler;
}

void BrewTrollerApplication::addBubbler(Bubbler *b) {
  if (bubbler)
    delete bubbler;
  bubbler = b;
}

