/*  
   Copyright (C) 2009, 2010 Matt Reba, Jeremiah Dillingham

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


BrewTroller - Open Source Brewing Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com
*/

void triggerInit() {
  //If EEPROM is not initialized skip trigger init
  if (checkConfig()) return;
  
  #ifdef ESTOP_PIN
    estopInit();
  #endif
  
  for (byte i = 0; i < USERTRIGGER_COUNT; i++)
    triggerInitInstance(i);
}

void triggerInitInstance(byte i) {
  if (trigger[i])
    delete trigger[i];
  trigger[i] = NULL;
  
  byte triggerPinMap[] = DIGITAL_INPUTS_PINS;
  
  struct TriggerConfiguration trigConfig;
  loadTriggerConfiguration(i, &trigConfig);
  
  if (trigConfig.type == TRIGGERTYPE_GPIO) {
    trigger[i] = new TriggerGPIO(triggerPinMap[trigConfig.index], trigConfig.activeLow, trigConfig.profileFilter, trigConfig.disableMask, trigConfig.releaseHysteresis);
  } else if (trigConfig.type == TRIGGERTYPE_VOLUME) {
    trigger[i] = new TriggerValue(&volAvg[trigConfig.index], trigConfig.threshold, trigConfig.activeLow, trigConfig.profileFilter, trigConfig.disableMask, trigConfig.releaseHysteresis);
  }
}

void triggerUpdate() {
  #ifdef ESTOP_PIN
    estopUpdate();
  #endif
  
  unsigned long triggerEnable = 0xFFFFFFFFul;
  for (byte i = 0; i < USERTRIGGER_COUNT; i++) {
    if (trigger[i])
      triggerEnable &= ~(trigger[i]->compute(outputs->getProfileStateMask()));
  }
  outputs->setOutputEnableMask(OUTPUTENABLE_TRIGGER, triggerEnable);
}

#ifdef ESTOP_PIN
void estopInit() {
  outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, 0xFFFFFFFFul); //Enable all pins in estop enable mask
  if (estopPin)
    delete estopPin;
  estopPin = NULL;
  if (getEStopEnabled()) {
    estopPin = new pin;
    estopPin->setup(ESTOP_PIN, INPUT);
  }
}

void estopUpdate() {
  if (estopPin) {
    if (estopPin->get())
      outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, 0xFFFFFFFFul); //Enable all pins in estop enable mask
    else {
      setAlarm(1);
      //Disable all pins except alarm pin(s)
      outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, outputs->getProfileMask(OUTPUTPROFILE_ALARM));
      outputs->update();
      updateTimers();
    }
  }
}
#endif
