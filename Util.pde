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

//Converts a "Virtual Float" (fixed deciaml value represented in tenths, hundredths, thousandths, etc.) to a string
void vftoa(unsigned long val, char retStr[], byte precision) {
  char lbuf[11];
  unsigned int mult = 1;
  for(byte i = 0; i< precision; i++) mult *=10;
  unsigned long whole = val / mult;
  itoa(whole, retStr, 10);
  strcat(retStr, ".");
  itoa(val - whole * mult, lbuf, 10);
  strcat(retStr, lbuf);
  for (byte i = 0; i < precision - strlen(lbuf); i++) strcat(retStr, "0");
}

//Truncate a string representation of a float to (length) chars but do not end string with a decimal point
void truncFloat(char string[], byte length) {
  if (strlen(string) > length) {
    if (string[length - 1] == '.') string[length - 1] = '\0';
    else string[length] = '\0';
  }
}


