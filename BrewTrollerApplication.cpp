#include "BrewTrollerApplication.h"

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

  //START HIGH PRIORITY: Time-sensitive updates perfromed on each iteration
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
    vessel[VS_KETTLE]->getPWMOutput()->setValue((temp[TS_KETTLE] < getBoilTemp() * SETPOINT_MULT) ? vessel[VS_KETTLE]->getPWMOutput()->getLimit() : (unsigned int)(vessel[VS_KETTLE]->getPWMOutput()->getLimit()) * boilPwr / 100);
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
    vessel[i]->setSetpoint(0);
  outputs->setProfileStateMask(0x00000000ul, 0);
}

void BrewTrollerApplication::updateAutoValve() {
    //Do Valves
    if (autoValve[AV_FILL]) {
      outputs->setProfileState(OUTPUTPROFILE_FILLHLT, (volAvg[VS_HLT] < tgtVol[VS_HLT]) ? 1 : 0);
      outputs->setProfileState(OUTPUTPROFILE_FILLMASH, (volAvg[VS_MASH] < tgtVol[VS_MASH]) ? 1 : 0);
    }
    
    if (autoValve[AV_SPARGEIN])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, (volAvg[VS_HLT] > tgtVol[VS_HLT]) ? 1 : 0);

    if (autoValve[AV_SPARGEOUT])
      outputs->setProfileState(OUTPUTPROFILE_SPARGEOUT, (volAvg[VS_KETTLE] < tgtVol[VS_KETTLE]) ? 1 : 0);

    if (autoValve[AV_FLYSPARGE]) {
      if (volAvg[VS_KETTLE] < tgtVol[VS_KETTLE]) {
        if (brewStepConfiguration.flySpargeHysteresis) {
          if((long)volAvg[VS_KETTLE] - (long)prevSpargeVol[0] >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 1);
             prevSpargeVol[0] = volAvg[VS_KETTLE];
          } else if((long)prevSpargeVol[1] - (long)volAvg[VS_HLT] >= brewStepConfiguration.flySpargeHysteresis * 100ul) {
             outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
             prevSpargeVol[1] = volAvg[VS_HLT];
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

#ifdef ESTOP_PIN
boolean BrewTrollerApplication::isEStop() {
  return (outputs->getOutputEnableMask(OUTPUTENABLE_ESTOP) == outputs->getProfileMask(OUTPUTPROFILE_ALARM));
}
#endif

