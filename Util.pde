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


void ftoa(float val, char retStr[], byte precision) {
  char lbuf[11];
  itoa(val, retStr, 10);  
  if(val < 0) val = -val;
  if( precision > 0) {
    strcat(retStr, ".");
    unsigned int mult = 1;
    for(byte i = 0; i< precision; i++) mult *=10;
    unsigned int frac = (val - int(val)) * mult;
    itoa(frac, lbuf, 10);
    for(byte i = 0; i < precision - (int)strlen(lbuf); i++) strcat(retStr, "0");
    strcat(retStr, lbuf);
  }
}

//Truncate a string representation of a float to (length) chars but do not end string with a decimal point
void truncFloat(char string[], byte length) {
  if (strlen(string) > length) {
    if (string[length - 1] == '.') string[length - 1] = '\0';
    else string[length] = '\0';
  }
}

byte sysInfo(byte address) {
  byte retValue = 0;
  if (address == SYSINFO_BTBOARD) {
    #if defined BTBOARD_1
      retValue =  1;
    #elif defined BTBOARD_22
      retValue =  2;
    #elif defined BTBOARD_3
      retValue =  3;
    #endif
    
    #ifdef USEMETRIC
      retValue &=  1<<4;
    #endif

    #ifdef USESTEAM
      retValue &=  1<<5;
    #endif

    #ifdef DEBUG
      retValue &=  1<<6;
    #endif

    #ifdef SMART_HERMS_HLT
      retValue &=  1<<7;
    #endif
  }
  else if (address == SYSINFO_AUTOSTEP) {
    #ifdef AUTO_FILL
      retValue =  1;
    #endif
    #ifdef AUTO_MASH_HOLD_EXIT
      retValue &= 1<<1;
    #endif
  }
  else if (address == SYSINFO_BOILRECIRC) {
    #ifdef AUTO_BOIL_RECIRC
      retValue = byte(AUTO_BOIL_RECIRC);
    #else
      retValue = byte(255);
    #endif
  }
  else if (address == SYSINFO_MUXBOARDS) {
    #ifdef MUXBOARDS
      retValue = byte(MUXBOARDS);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_PIDLIMIT_HLT) {
    #ifdef PIDLIMIT_HLT
      retValue = byte(PIDLIMIT_HLT);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_PIDLIMIT_MASH) {
    #ifdef PIDLIMIT_MASH
      retValue = byte(PIDLIMIT_MASH);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_PIDLIMIT_KETTLE) {
    #ifdef PIDLIMIT_KETTLE
      retValue = byte(PIDLIMIT_KETTLE);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_PIDLIMIT_STEAM) {
    #ifdef PIDLIMIT_STEAM
      retValue = byte(PIDLIMIT_STEAM);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_KETTLELID) {
    #ifdef KETTLELID_THRESH
      retValue = byte(KETTLELID_THRESH);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_PREBOILALARM) {
    #ifdef PREBOIL_ALARM
      retValue = byte(PREBOIL_ALARM);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_HLTMAX) {
    #ifdef HLT_MAX_TEMP
      retValue = byte(HLT_MAX_TEMP);
    #endif
  }

  else if (address == SYSINFO_MASH_HEATLOSS_1) {
    #ifdef MASH_HEAT_LOSS
      retValue = float2byte(MASH_HEAT_LOSS, 0);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_MASH_HEATLOSS_2) {
    #ifdef MASH_HEAT_LOSS
      retValue = float2byte(MASH_HEAT_LOSS, 1);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_MASH_HEATLOSS_3) {
    #ifdef MASH_HEAT_LOSS
      retValue = float2byte(MASH_HEAT_LOSS, 2);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_MASH_HEATLOSS_4) {
    #ifdef MASH_HEAT_LOSS
      retValue = float2byte(MASH_HEAT_LOSS, 3);
    #else
      retValue = 255;
    #endif
  }

  else if (address == SYSINFO_HOPADD_DELAY_1) {
    #ifdef HOPADD_DELAY
      retValue = int2byte(HOPADD_DELAY, 0);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_HOPADD_DELAY_2) {
    #ifdef HOPADD_DELAY
      retValue = int2byte(HOPADD_DELAY, 1);
    #else
      retValue = 255;
    #endif
  }
  
  else if (address == SYSINFO_STRIKEOFFSET_1) {
    #ifdef STRIKE_TEMP_OFFSET
      retValue = float2byte(STRIKE_TEMP_OFFSET, 0);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_STRIKEOFFSET_2) {
    #ifdef STRIKE_TEMP_OFFSET
      retValue = float2byte(STRIKE_TEMP_OFFSET, 1);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_STRIKEOFFSET_3) {
    #ifdef STRIKE_TEMP_OFFSET
      retValue = float2byte(STRIKE_TEMP_OFFSET, 2);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_STRIKEOFFSET_4) {
    #ifdef STRIKE_TEMP_OFFSET
      retValue = float2byte(STRIKE_TEMP_OFFSET, 3);
    #else
      retValue = 255;
    #endif
  }

  else if (address == SYSINFO_LOGINTERVAL_1) {
    #ifdef LOG_INTERVAL
      retValue = int2byte(LOG_INTERVAL, 0);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_LOGINTERVAL_2) {
    #ifdef LOG_INTERVAL
      retValue = int2byte(LOG_INTERVAL, 1);
    #else
      retValue = 255;
    #endif
  }

  else if (address == SYSINFO_UILEVEL) {
    #ifdef NOUI
      //No UI
      retValue = 0;
    #elif defined UI_NO_SETUP
      //'Light' UI
      retValue = 1;
    //Space reserved for alternate UI
    #else
      //'Stock' UI
      retValue = 255;
    #endif
  }
  
  else if (address == SYSINFO_VOLINT_1) {
    #ifdef VOLUME_READ_INTERVAL
      retValue = int2byte(VOLUME_READ_INTERVAL, 0);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_VOLINT_2) {
    #ifdef VOLUME_READ_INTERVAL
      retValue = int2byte(VOLUME_READ_INTERVAL, 1);
    #else
      retValue = 255;
    #endif
  }
  else if (address == SYSINFO_VOLCOUNT) {
    #ifdef VOLUME_READ_COUNT
      retValue = byte(VOLUME_READ_COUNT);
    #else
      retValue = 255;
    #endif
  }
  return retValue;
}

byte int2byte(int varInt, byte pos) {
  union u_ib {
    int i_var;
    byte b_var[4];
  };
  u_ib convert;
  convert.i_var = varInt;
  return convert.b_var[pos];
}

byte float2byte(float varFlt, byte pos) {
  union u_fb {
    int f_var;
    byte b_var[4];
  };
  u_fb convert;
  convert.f_var = varFlt;
  return convert.b_var[pos];
}

