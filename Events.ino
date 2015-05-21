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


void eventHandler(enum EventIndex eventID, int eventParam) {
  //Global Event handler
  //EVENT_STEPINIT: Nothing to do here (Pass to UI handler below)
  //EVENT_STEPEXIT: Nothing to do here (Pass to UI handler below)
  if (eventID == EVENT_SETPOINT && !setpoint[eventParam])
    resetVesselHeat(eventParam);
  
  #ifndef NOUI
    //Pass Event Info to UI Event Handler
    uiEvent(eventID, eventParam);
  #endif

  //Pass Event Info to Com Event Handler
  comEvent(eventID, eventParam);

}

#ifdef DIGITAL_INPUTS
  void triggerInit() {
    byte inputPins[] = DIGITAL_INPUTS_PINS;
    for (byte i = 0; i < DIGITAL_INPUTS_COUNT; i++)
      digInPin[i].setup(inputPins[i], INPUT);
  
    //If EEPROM is not initialized skip trigger init
    if (checkConfig()) return;
    //For each logical trigger type see what the assigned trigger pin is (if any)
    for (byte i = 0; i < NUM_TRIGGERS; i++) {
      if (TriggerPin[i] != NULL) TriggerPin[i]->detachPCInt();
      if (getTriggerPin(i)) {
        TriggerPin[i] = &digInPin[getTriggerPin(i) - 1];
        if (i == TRIGGER_ESTOP) TriggerPin[i]->attachPCInt(CHANGE, eStopISR);
        else if (i == TRIGGER_SPARGEMAX) TriggerPin[i]->attachPCInt(RISING, spargeMaxISR);
        else if (i == TRIGGER_HLTMIN) TriggerPin[i]->attachPCInt(FALLING, hltMinISR);
        else if (i == TRIGGER_MASHMIN) TriggerPin[i]->attachPCInt(FALLING, mashMinISR);
        else if (i == TRIGGER_KETTLEMIN) TriggerPin[i]->attachPCInt(FALLING, kettleMinISR);
      }
    }
  }

  void eStopISR() {
    //Either clear E-Stop condition if e-Stop trigger goes high
    //or perform E-Stop actions on trigger low
    if (TriggerPin[TRIGGER_ESTOP]->get())
      outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, 0xFFFFFFFFul); //Enable all pins in estop enable mask
    else {
      setAlarm(1);
      //Disable all pins except alarm pin(s)
      outputs->setOutputEnableMask(OUTPUTENABLE_ESTOP, outputs->getProfileMask(OUTPUTPROFILE_ALARM));
      outputs->update();
      updateTimers();
    }
  }
  
  void spargeMaxISR() {
    outputs->setProfileState(OUTPUTPROFILE_SPARGEIN, 0);
  }
  
  void hltMinISR() {
    resetVesselHeat(VS_HLT);
  }
  
  void mashMinISR() {
    resetVesselHeat(VS_MASH);
  }
  
  void kettleMinISR() {
    resetVesselHeat(VS_KETTLE);
  }
#endif
