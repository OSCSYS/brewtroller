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
*/

#ifndef NOUI
#ifdef UI_LCD_I2C
#include "Config.h"
#include "Enum.h"
#include <LiquidCrystalFP.h>
#include <Wire.h>

//*****************************************************************************************************************************
// UI COMPILE OPTIONS
//*****************************************************************************************************************************

void initLCD(){
  Wire.begin();
  i2cLcdBegin(20, 4);
}

void printLCD(byte iRow, byte iCol, char sText[]){
  i2cLcdPrint(iCol, iRow, sText);
}  

//Version of PrintLCD reading from PROGMEM
void printLCD_P(byte iRow, byte iCol, const char *sText){
  char s[20];
  byte i = 0;
  byte ch = 0;
  while (ch = pgm_read_byte(sText++)) {
    s[i++] = ch;
  }
  s[i] = 0;
  printLCD(iRow, iCol, s);
} 

void clearLCD() { 
  i2cLcdClear();
}

void printLCDCenter(byte iRow, byte iCol, char sText[], byte fieldWidth){
  byte sLen = strlen(sText);
  byte textStart = (fieldWidth - sLen) / 2;
  char s[20];
  memset(s, ' ', fieldWidth);
  memcpy(s + textStart, sText, sLen);
  s[fieldWidth] = NULL;
  printLCD(iRow, iCol, s);
}
  
char printLCDLPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
  char s[20];
  byte sLen = strlen(sText);
  byte textStart = length - sLen;
  memset(s, pad, textStart);
  memcpy(s + textStart, sText, sLen);
  s[length] = 0;
  printLCD(iRow, iCol, s);
}  

char printLCDRPad(byte iRow, byte iCol, char sText[], byte length, char pad) {
  char s[20];
  byte sLen = strlen(sText);
  memcpy(s, sText, sLen);
  memset(s + sLen, pad, length - sLen);
  s[length] = 0;
  printLCD(iRow, iCol, s);
}  

void lcdSetCustChar_P(byte slot, const byte *charDef) {
  i2cLcdSetCustChar_P(slot, charDef);
}

void lcdWriteCustChar(byte iRow, byte iCol, byte slot) {
  i2cLcdWriteCustChar(iCol, iRow, slot);
}

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////// //////////

byte i2cLcdAddr = 0x01;

void i2cLcdBegin(byte iCols, byte iRows) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x01);
  Wire.send(iCols);
  Wire.send(iRows);
  Wire.endTransmission();
  delay(5);
}

void i2cLcdClear() {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x02);
  Wire.endTransmission();
  delay(3);
}

/*
void i2cLcdSetCursor(byte iCol, byte iRow) {
  Wire.beginTransmission(I2CLCD_ADDR);
  Wire.send(0x03);
  Wire.send(iCol);
  Wire.send(iRow);
  Wire.endTransmission();
}
*/

void i2cLcdPrint(byte iCol, byte iRow, char s[]) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x04);
  Wire.send(iCol);
  Wire.send(iRow);
  char *p = s;
  while (*p) {
    Wire.send(*p++);
  }
  Wire.endTransmission();
  delay(3);
}

void i2cLcdSetCustChar_P(byte slot, const byte *charDef) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x05);
  Wire.send(slot);
  for (byte i = 0; i < 8; i++) {
    Wire.send(pgm_read_byte(charDef++));
  }
  Wire.endTransmission();
  delay(3);
}

void i2cLcdWriteCustChar(byte iCol, byte iRow, byte c) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x06);
  Wire.send(iCol);
  Wire.send(iRow);
  Wire.send(c);
  Wire.endTransmission();
  delay(3);
}

#endif
#endif
