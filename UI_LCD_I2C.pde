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

#include "Config.h"
#include "Enum.h"
#include "HWProfile.h"

#if !defined NOUI && defined UI_LCD_I2C
#include <Wire.h>

//*****************************************************************************************************************************
// UI COMPILE OPTIONS
//*****************************************************************************************************************************

byte screen[80];

void initLCD(){
  delay(1000);
  Wire.begin();
  i2cLcdBegin(20, 4);
}

void printLCD(byte iRow, byte iCol, char sText[]){
  byte pos = iRow * 20 + iCol;
  memcpy((byte*)&screen[pos], sText, min(strlen(sText), 80-pos));
}  

//Version of PrintLCD reading from PROGMEM
void printLCD_P(byte iRow, byte iCol, const char *sText){
  byte pos = iRow * 20 + iCol;
  memcpy_P((byte*)&screen[pos], sText, min(strlen_P(sText), 80-pos));
} 

void clearLCD() {
  memset(screen, ' ', 80);
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
  screen[iRow * 20 + iCol] = slot;
}

void updateLCD() {
  for (byte row = 0; row < 4; row++) {
    i2cLcdWrite(0, row, 20, (char*)&screen[row * 20]);
  }
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

void i2cLcdWrite(byte iCol, byte iRow, byte len, char s[]) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x14);
  Wire.send(iCol);
  Wire.send(iRow);
  Wire.send(len);
  for (byte i = 0; i < len; i++) Wire.send(s[i]);
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
  delay(5);
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

void i2cSetBright(byte val) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x07);
  Wire.send(val);
  Wire.endTransmission();
  delay(3);
}

void i2cSetContrast(byte val) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x08);
  Wire.send(val);
  Wire.endTransmission();
  delay(3);
}

byte i2cGetBright(void) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x09);
  Wire.endTransmission();
  Wire.requestFrom((int)i2cLcdAddr, (int)1);
  while(Wire.available())
  {
    return Wire.receive();
  }
}

byte i2cGetContrast(void) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x0A);
  Wire.endTransmission();
  Wire.requestFrom((int)i2cLcdAddr, (int)1);
  while(Wire.available())
  {
    return Wire.receive();
  }
}

byte i2cSaveConfig(void) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x0B);
  Wire.endTransmission();
  delay(10);
}

byte i2cLoadConfig(void) {
  Wire.beginTransmission(i2cLcdAddr);
  Wire.send(0x0C);
  Wire.endTransmission();
  delay(10);
}

#endif
