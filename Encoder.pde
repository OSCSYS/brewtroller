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

Compiled on Arduino-0015 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/

byte encBounceDelay;
byte enterBounceDelay;
volatile unsigned long lastEncUpd = millis();
unsigned long enterStart;

void initEncoder() {
  switch(encMode) {
    case ENC_CUI:
      enterBounceDelay = 50;
      encBounceDelay = 50;
      attachInterrupt(2, doEncoderCUI, RISING);
      break;
    case ENC_ALPS:
      enterBounceDelay = 30;
      encBounceDelay = 60;
      attachInterrupt(2, doEncoderALPS, CHANGE);
      break;
  }
  attachInterrupt(1, doEnter, CHANGE);
}

void doEncoderCUI() {
  if (millis() - lastEncUpd < encBounceDelay) return;
  //Read EncB
  if (digitalRead(4) == LOW) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEncoderALPS() {
  //if (millis() - lastEncUpd < encBounceDelay) return;
  //Compare EncA and EncB
  if (digitalRead(2) != digitalRead(4)) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEnter() {
  if (digitalRead(11) == HIGH) {
    enterStart = millis();
  } else {
    if (millis() - enterStart > 1000) {
      enterStatus = 2;
    } else if (millis() - enterStart > enterBounceDelay) {
      enterStatus = 1;
    }
  }
}

