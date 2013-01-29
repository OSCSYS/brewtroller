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


#ifdef ENCODER_CUI
#define ENTER_BOUNCE_DELAY 50
#endif

#ifdef ENCODER_ALPS
#define ENTER_BOUNCE_DELAY 30
#endif

volatile unsigned long lastEncUpd = millis();
unsigned long enterStart;

void doEncoderALPS() {
  if (digitalRead(2) != digitalRead(4)) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 
void doEncoderCUI() {
  if (millis() - lastEncUpd < 50) return;
  //Read EncB
  if (digitalRead(4) == LOW) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEnter() {
  if (digitalRead(11) == HIGH) {
    enterStart = millis();
  } else {
    if (millis() - enterStart > 1000) {
      enterStatus = 2;
    } else if (millis() - enterStart > ENTER_BOUNCE_DELAY) {
      enterStatus = 1;
    }
  }
}

