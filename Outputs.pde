/*  
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

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

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

void pinInit() {
  alarmPin.setup(ALARM_PIN, OUTPUT);

  #if MUXBOARDS > 0
    muxLatchPin.setup(MUX_LATCH_PIN, OUTPUT);
    muxDataPin.setup(MUX_CLOCK_PIN, OUTPUT);
    muxClockPin.setup(MUX_DATA_PIN, OUTPUT);
    muxOEPin.setup(MUX_OE_PIN, OUTPUT);
  #endif
  #ifdef ONBOARDPV
    valvePin[0].setup(VALVE1_PIN, OUTPUT);
    valvePin[1].setup(VALVE2_PIN, OUTPUT);
    valvePin[2].setup(VALVE3_PIN, OUTPUT);
    valvePin[3].setup(VALVE4_PIN, OUTPUT);
    valvePin[4].setup(VALVE5_PIN, OUTPUT);
    valvePin[5].setup(VALVE6_PIN, OUTPUT);
    valvePin[6].setup(VALVE7_PIN, OUTPUT);
    valvePin[7].setup(VALVE8_PIN, OUTPUT);
    valvePin[8].setup(VALVE9_PIN, OUTPUT);
    valvePin[9].setup(VALVEA_PIN, OUTPUT);
    valvePin[10].setup(VALVEB_PIN, OUTPUT);
  #endif
  
  heatPin[VS_HLT].setup(HLTHEAT_PIN, OUTPUT);
  heatPin[VS_MASH].setup(MASHHEAT_PIN, OUTPUT);
  heatPin[VS_KETTLE].setup(KETTLEHEAT_PIN, OUTPUT);
#ifdef USESTEAM
  heatPin[VS_STEAM].setup(STEAMHEAT_PIN, OUTPUT);
#endif
  resetOutputs();  
}

void pidInit() {
  pid[VS_HLT].SetInputLimits(0, 255);
  pid[VS_HLT].SetOutputLimits(0, PIDCycle[VS_HLT] * 10 * PIDLIMIT_HLT);
  pid[VS_HLT].SetTunings(getPIDp(VS_HLT), getPIDi(VS_HLT), getPIDd(VS_HLT));

  pid[VS_MASH].SetInputLimits(0, 255);
  pid[VS_MASH].SetOutputLimits(0, PIDCycle[VS_MASH] * 10 * PIDLIMIT_MASH);
  pid[VS_MASH].SetTunings(getPIDp(VS_MASH), getPIDi(VS_MASH), getPIDd(VS_MASH));
  
  pid[VS_KETTLE].SetInputLimits(0, 255);
  pid[VS_KETTLE].SetOutputLimits(0, PIDCycle[VS_KETTLE] * 10 * PIDLIMIT_KETTLE);
  pid[VS_KETTLE].SetTunings(getPIDp(VS_KETTLE), getPIDi(VS_KETTLE), getPIDd(VS_KETTLE));
  
  #ifdef USEMETRIC
    pid[VS_STEAM].SetInputLimits(0, 50000 / steamPSens);
  #else
    pid[VS_STEAM].SetInputLimits(0, 7250 / steamPSens);
  #endif
  pid[VS_STEAM].SetOutputLimits(0, PIDCycle[VS_STEAM] * 10 * PIDLIMIT_STEAM);
  pid[VS_STEAM].SetTunings(getPIDp(VS_STEAM), getPIDi(VS_STEAM), getPIDd(VS_STEAM));
}

void resetOutputs() {
  #ifdef USESTEAM
    #define LAST_HEAT_OUTPUT VS_STEAM
  #else
    #define LAST_HEAT_OUTPUT VS_KETTLE
  #endif
  for (byte i = VS_HLT; i <= LAST_HEAT_OUTPUT; i++) resetHeatOutput(i);
  for (byte i = AV_FILL; i <= AV_CHILL; i++) autoValve[i] = 0;
  setValves(VLV_ALL, 0);
}

void resetHeatOutput(byte vessel) {
  setpoint[vessel] = 0;
  pid[vessel].SetMode(MANUAL);
  PIDOutput[vessel] = 0;
  heatPin[vessel].set(LOW);
}  

//Sets the specified valves On or Off
void setValves (unsigned long vlvBitMask, boolean value) {

  if (value) vlvBits |= vlvBitMask;
  else vlvBits ^ (vlvBits & vlvBitMask);
  setValveRecovery(vlvBits);
  
  #if MUXBOARDS > 0
  //MUX Valve Code
    //Disable outputs (I'm not sure this is necessary; Removing for now) 
    //muxOEPin.set();
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
    //Enable outputs
    muxOEPin.clear();
  #endif
  #ifdef ONBOARDPV
  //Original 11 Valve Code
  for (byte i = 0; i < 11; i++) { if (vlvBits & 1<<i) valvePin[i].set(); else valvePin[i].clear(); }
  #endif
}

void processHeatOutputs() {
  //Process Heat Outputs
  #ifdef USESTEAM
    #define LAST_HEAT_OUTPUT VS_STEAM
  #else
    #define LAST_HEAT_OUTPUT VS_KETTLE
  #endif
  for (byte i = VS_HLT; i <= LAST_HEAT_OUTPUT; i++) {
    if (PIDEnabled[i]) {
      if (i != VS_STEAM && i != VS_KETTLE && temp[i] <= 0) {
        PIDOutput[i] = 0;
      } else {
        if (pid[i].GetMode() == AUTO) {
          if (i == VS_STEAM) PIDInput[i] = steamPressure; else PIDInput[i] = temp[i];
          pid[i].Compute();
        }
      }
      if (cycleStart[i] == 0) cycleStart[i] = millis();
      if (millis() - cycleStart[i] > PIDCycle[i] * 1000) cycleStart[i] += PIDCycle[i] * 1000;
      if (PIDOutput[i] > millis() - cycleStart[i]) heatPin[i].set(HIGH); else heatPin[i].set(LOW);
      if (PIDOutput[i] == 0)  heatStatus[i] = 0; else heatStatus[i] = 1;
    } else {
      if (heatStatus[i]) {
        if (
          (i != VS_STEAM && (temp[i] <= 0 || temp[i] >= setpoint[i]))  
            || (i == VS_STEAM && steamPressure >= setpoint[i])
        ) {
          heatPin[i].set(LOW);
          heatStatus[i] = 0;
        } else {
          heatPin[i].set(HIGH);
        }
      } else {
        if ((i != VS_STEAM && temp[i] > 0 && (float)(setpoint[i] - temp[i]) >= (float) hysteresis[i] / 10.0) 
        || (i == VS_STEAM && (float)(setpoint[i] - steamPressure) >= (float) hysteresis[i] / 10.0)) {
          heatPin[i].set(HIGH);
          heatStatus[i] = 1;
        } else {
          heatPin[i].set(LOW);
        }
      }
    }    
  }
}

boolean vlvConfigIsActive(byte profile) {
  if (vlvBits & vlvConfig[profile] == vlvConfig[profile]) return 1; else return 0;
}

void processAutoValve() {
  //Do Valves
  if (autoValve[AV_FILL]) {
    if (volAvg[VS_HLT] < tgtVol[VS_HLT]) setValves(vlvConfig[VLV_FILLHLT], 1);
      else setValves(vlvConfig[VLV_FILLHLT], 0);
      
    if (volAvg[VS_MASH] < tgtVol[VS_MASH]) setValves(vlvConfig[VLV_FILLMASH], 1);
      else setValves(vlvConfig[VLV_FILLMASH], 0);
  } 
  if (autoValve[AV_MASH]) {
    if (heatStatus[TS_MASH] && (!vlvConfigIsActive(VLV_MASHHEAT))) {
      setValves(vlvConfig[VLV_MASHIDLE], 0);
      setValves(vlvConfig[VLV_MASHHEAT], 1);
    } else if (!heatStatus[TS_MASH] && (!vlvConfigIsActive(VLV_MASHIDLE))) {
      setValves(vlvConfig[VLV_MASHHEAT], 0);
      setValves(vlvConfig[VLV_MASHIDLE], 1); 
    }
  } 
  if (autoValve[AV_CHILL]) {
    //Needs work
    /*
    //If Pumping beer
    if (vlvConfigIsActive(VLV_CHILLBEER)) {
      //Cut beer if exceeds pitch + 1
      if (temp[TS_BEEROUT] > pitchTemp + 1.0) setValves(vlvConfig[VLV_CHILLBEER], 0);
    } else {
      //Enable beer if chiller H2O output is below pitch
      //ADD MIN DELAY!
      if (temp[TS_H2OOUT] < pitchTemp - 1.0) setValves(vlvConfig[VLV_CHILLBEER], 1);
    }
    
    //If chiller water is running
    if (vlvConfigIsActive(VLV_CHILLH2O)) {
      //Cut H2O if beer below pitch - 1
      if (temp[TS_BEEROUT] < pitchTemp - 1.0) setValves(vlvConfig[VLV_CHILLH2O], 0);
    } else {
      //Enable H2O if chiller H2O output is at pitch
      //ADD MIN DELAY!
      if (temp[TS_H2OOUT] >= pitchTemp) setValves(vlvConfig[VLV_CHILLH2O], 1);
    }
    */
  }
}
