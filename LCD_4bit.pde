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

#include <LiquidCrystal.h>

const byte LCD_DELAY_CURSOR = 60;
const byte LCD_DELAY_CHAR = 60;

// LiquidCrystal display with:
// rs on pin 17	  (LCD pin 4 ) aka DI
// rw on pin 18	  (LCD pin 5)
// enable on pin 19 (LCD pin 6)
// d4, d5, d6, d7 on pins 20, 21, 22, 23  (LCD pins 11-14)

LiquidCrystal lcd(17, -1, 19, 20, 21, 22, 23);

void initLCD(){
  //Attempt to avoid blank screen on boot by reinit of LCD after delay
  delay(1000);
  lcd = LiquidCrystal(17, -1, 19, 20, 21, 22, 23);
}

void printLCD(byte iRow, byte iCol, char sText[]){
 lcd.setCursor(iCol, iRow);
 delayMicroseconds(LCD_DELAY_CURSOR);
 int i = 0;
 while (sText[i] != '\0')
 {
   lcd.print(sText[i++]);
   delayMicroseconds(LCD_DELAY_CHAR);
 }
} 

//Version of PrintLCD reading from PROGMEM
void printLCD_P(byte iRow, byte iCol, const char *sText){
 lcd.setCursor(iCol, iRow);
 delayMicroseconds(LCD_DELAY_CURSOR);
 int i = 0;
 while (pgm_read_byte(sText) != 0)
 {
   lcd.print(pgm_read_byte(sText++)); 
   delayMicroseconds(LCD_DELAY_CHAR);
 }
} 

void clearLCD(){ lcd.clear(); }

char printLCDPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
 lcd.setCursor(iCol, iRow);
 delayMicroseconds(LCD_DELAY_CURSOR);
 if (strlen(sText) < length) {
   for (int i=0; i < length-strlen(sText) ; i++) {
     lcd.print(pad);
     delayMicroseconds(LCD_DELAY_CHAR);
   }
 }
 
 int i = 0;
 while (sText[i] != 0)
 {
   lcd.print(sText[i++]);
   delayMicroseconds(LCD_DELAY_CHAR);
 }
}  

void lcdSetCustChar(byte slot, const byte charDef[]) {
  lcd.command(64 | (slot << 3));
  for (int i = 0; i < 8; i++) {
    lcd.write(charDef[i]);
    delayMicroseconds(LCD_DELAY_CHAR);
  }
  lcd.command(B10000000);
}

void lcdWriteCustChar(byte iRow, byte iCol, byte slot) {
  lcd.setCursor(iCol, iRow);
  delayMicroseconds(LCD_DELAY_CURSOR);
  lcd.write(slot);
  delayMicroseconds(LCD_DELAY_CHAR);
}
