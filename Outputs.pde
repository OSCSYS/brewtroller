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
  pinMode(ENCA_PIN, INPUT);
  pinMode(ENCB_PIN, INPUT);
  pinMode(ENTER_PIN, INPUT);
  pinMode(ALARM_PIN, OUTPUT);
  #if MUXBOARDS > 0
    pinMode(MUX_LATCH_PIN, OUTPUT);
    pinMode(MUX_CLOCK_PIN, OUTPUT);
    pinMode(MUX_DATA_PIN, OUTPUT);
    pinMode(MUX_OE_PIN, OUTPUT);
  #endif
  #ifdef ONBOARDPV
    pinMode(VALVE1_PIN, OUTPUT);
    pinMode(VALVE2_PIN, OUTPUT);
    pinMode(VALVE3_PIN, OUTPUT);
    pinMode(VALVE4_PIN, OUTPUT);
    pinMode(VALVE5_PIN, OUTPUT);
    pinMode(VALVE6_PIN, OUTPUT);
    pinMode(VALVE7_PIN, OUTPUT);
    pinMode(VALVE8_PIN, OUTPUT);
    pinMode(VALVE9_PIN, OUTPUT);
    pinMode(VALVEA_PIN, OUTPUT);
    pinMode(VALVEB_PIN, OUTPUT);
  #endif
  pinMode(HLTHEAT_PIN, OUTPUT);
  pinMode(MASHHEAT_PIN, OUTPUT);
  pinMode(KETTLEHEAT_PIN, OUTPUT);
  #ifdef USESTEAM
    pinMode(STEAMHEAT_PIN, OUTPUT);
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
  for (byte i = VS_HLT; i <= VS_STEAM; i++) {
    setpoint[i] = 0;
    pid[i].SetMode(MANUAL);
    PIDOutput[i] = 0;
  }
  digitalWrite(HLTHEAT_PIN, LOW);
  digitalWrite(MASHHEAT_PIN, LOW);
  digitalWrite(KETTLEHEAT_PIN, LOW);

#ifdef USESTEAM
  digitalWrite(STEAMHEAT_PIN, LOW);
#endif

  autoValve = 0;
  setValves(0);
}

void setValves (unsigned long vlvBitMask) {
  vlvBits = vlvBitMask;
  setValveRecovery(vlvBitMask);

#if MUXBOARDS > 0
//New MUX Valve Code
  //Disable outputs
  digitalWrite(MUX_OE_PIN, HIGH);
  //ground latchPin and hold low for as long as you are transmitting
  digitalWrite(MUX_LATCH_PIN, LOW);
  //clear everything out just in case to prepare shift register for bit shifting
  digitalWrite(MUX_DATA_PIN, LOW);
  digitalWrite(MUX_CLOCK_PIN, LOW);

  //for each bit in the long myDataOut
  for (byte i = 0; i < 32; i++)  {
    digitalWrite(MUX_CLOCK_PIN, LOW);
    //create bitmask to grab the bit associated with our counter i and set data pin accordingly (NOTE: 32 - i causes bits to be sent most significant to least significant)
    if ( vlvBitMask & ((unsigned long)1<<(31 - i)) ) digitalWrite(MUX_DATA_PIN, HIGH); else  digitalWrite(MUX_DATA_PIN, LOW);
    //register shifts bits on upstroke of clock pin  
    digitalWrite(MUX_CLOCK_PIN, HIGH);
    //zero the data pin after shift to prevent bleed through
    digitalWrite(MUX_DATA_PIN, LOW);
  }

  //stop shifting
  digitalWrite(MUX_CLOCK_PIN, LOW);
  digitalWrite(MUX_LATCH_PIN, HIGH);
  //Enable outputs
  digitalWrite(MUX_OE_PIN, LOW);
#endif
#ifdef ONBOARDPV
//Original 11 Valve Code
  if (vlvBitMask & 1) digitalWrite(VALVE1_PIN, HIGH); else digitalWrite(VALVE1_PIN, LOW);
  if (vlvBitMask & 2) digitalWrite(VALVE2_PIN, HIGH); else digitalWrite(VALVE2_PIN, LOW);
  if (vlvBitMask & 4) digitalWrite(VALVE3_PIN, HIGH); else digitalWrite(VALVE3_PIN, LOW);
  if (vlvBitMask & 8) digitalWrite(VALVE4_PIN, HIGH); else digitalWrite(VALVE4_PIN, LOW);
  if (vlvBitMask & 16) digitalWrite(VALVE5_PIN, HIGH); else digitalWrite(VALVE5_PIN, LOW);
  if (vlvBitMask & 32) digitalWrite(VALVE6_PIN, HIGH); else digitalWrite(VALVE6_PIN, LOW);
  if (vlvBitMask & 64) digitalWrite(VALVE7_PIN, HIGH); else digitalWrite(VALVE7_PIN, LOW);
  if (vlvBitMask & 128) digitalWrite(VALVE8_PIN, HIGH); else digitalWrite(VALVE8_PIN, LOW);
  if (vlvBitMask & 256) digitalWrite(VALVE9_PIN, HIGH); else digitalWrite(VALVE9_PIN, LOW);
  if (vlvBitMask & 512) digitalWrite(VALVEA_PIN, HIGH); else digitalWrite(VALVEA_PIN, LOW);
  if (vlvBitMask & 1024) digitalWrite(VALVEB_PIN, HIGH); else digitalWrite(VALVEB_PIN, LOW);
#endif
}

void processHeatOutputs() {
//Process Heat Outputs
#ifdef USESTEAM
  for (byte i = VS_HLT; i <= VS_STEAM; i++) {
#else
  for (byte i = VS_HLT; i <= VS_KETTLE; i++) {
#endif
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
      if (PIDOutput[i] > millis() - cycleStart[i]) digitalWrite(heatPin[i], HIGH); else digitalWrite(heatPin[i], LOW);
      if (PIDOutput[i] == 0)  heatStatus[i] = 0; else heatStatus[i] = 1; 
    } else {
      if (heatStatus[i]) {
        if (
          (i != VS_STEAM && (temp[i] <= 0 || temp[i] >= setpoint[i]))  
            || (i == VS_STEAM && steamPressure >= setpoint[i])
        ) {
          digitalWrite(heatPin[i], LOW);
          heatStatus[i] = 0;
        } else {
          digitalWrite(heatPin[i], HIGH);
        }
      } else {
        if (
          (i != VS_STEAM && temp[i] > 0 && (float)(setpoint[i] - temp[i]) >= (float) hysteresis[i] / 10.0) 
            || (i == VS_STEAM && (float)(setpoint[i] - steamPressure) >= (float) hysteresis[i] / 10.0)
        ) {
          digitalWrite(heatPin[i], HIGH);
          heatStatus[i] = 1;
        } else {
          digitalWrite(heatPin[i], LOW);
        }
      }
    }    
  }
}

void processAutoValve() {
  //Do Valves
  if (autoValve == AV_FILL) {
    if (volAvg[VS_HLT] < tgtVol[VS_HLT] && volAvg[VS_MASH] < tgtVol[VS_MASH]) {
      if (vlvBits != (vlvConfig[VLV_FILLHLT] | vlvConfig[VLV_FILLMASH])) setValves(vlvConfig[VLV_FILLHLT] | vlvConfig[VLV_FILLMASH]);
    } else if (volAvg[VS_HLT] < tgtVol[VS_HLT]) {
      if (vlvBits != vlvConfig[VLV_FILLHLT]) setValves(vlvConfig[VLV_FILLHLT]);
    } else if (volAvg[VS_MASH] < tgtVol[VS_MASH]) {
      if (vlvBits != vlvConfig[VLV_FILLMASH]) setValves(vlvConfig[VLV_FILLMASH]);
    } else if (vlvBits != 0) setValves(0);
  } else if (autoValve == AV_MASH) {
    if (heatStatus[TS_MASH]) {
      if (vlvBits != vlvConfig[VLV_MASHHEAT]) setValves(vlvConfig[VLV_MASHHEAT]);
    } else if (vlvBits != vlvConfig[VLV_MASHIDLE]) setValves(vlvConfig[VLV_MASHIDLE]); 
  } else if (autoValve == AV_CHILL) {
    if (temp[TS_BEEROUT] > pitchTemp + 1.0) {
     if (vlvBits != vlvConfig[VLV_CHILLH2O]) setValves(vlvConfig[VLV_CHILLH2O]);
    } else if (temp[TS_BEEROUT] < pitchTemp - 1.0) {
      if (vlvBits != vlvConfig[VLV_CHILLBEER]) setValves(vlvConfig[VLV_CHILLBEER]);
    } else if (vlvBits != (vlvConfig[VLV_CHILLBEER] | vlvConfig[VLV_CHILLH2O])) setValves(vlvConfig[VLV_CHILLBEER] | vlvConfig[VLV_CHILLH2O]);
  }
}
