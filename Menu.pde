byte scrollMenu(char sTitle[], char menuItems[][20], byte numOpts, byte defOption) {
  encMin = 0;
  encMax = numOpts-1;
  
  encCount = defOption;
  byte lastCount = encCount + 1;
  byte topItem = numOpts;

  while(1) {
    if (encCount != lastCount) {

      if (encCount < topItem) {
        clearLCD();
        if (sTitle != NULL) printLCD(0, 0, sTitle);
        topItem = encCount;
        drawItems(menuItems, numOpts, topItem);
      } else if (encCount > topItem + 2) {
        clearLCD();
        if (sTitle != NULL) printLCD(0, 0, sTitle);
        topItem = encCount - 2;
        drawItems(menuItems, numOpts, topItem);
      }
      for (int i = 1; i <= 3; i++) if (i == encCount - topItem + 1) printLCD(i, 0, ">"); else printLCD(i, 0, " ");
      lastCount = encCount;
    }
    
    //If Enter
    if (enterStatus == 1) {
      enterStatus = 0;
      return encCount;
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return numOpts;
    }
  }
}

void drawItems(char menuItems[][20], int numOpts, int topItem) {
  int maxOpt = topItem + 2;
  if (maxOpt > numOpts - 1) maxOpt = numOpts - 1;
  for (int i = topItem; i <= maxOpt; i++) printLCD(i-topItem+1, 1, menuItems[i]);
}

int getChoice(char choices[][19], int numChoices, int iRow) {
  printLCD(iRow, 0, ">                  <");

  encMin = 0;
  encMax = numChoices-1;
 
  encCount = 0;
  int lastCount = encCount+1;

  while(1) {
    if (encCount != lastCount) {
      printLCD(iRow, 1, choices[encCount]);
      lastCount = encCount;
    }
    
    //If Enter
    if (enterStatus == 1) {
      enterStatus = 0;
      printLCD(iRow, 0, " ");
      printLCD(iRow, 19, " ");
      return encCount;
    } else if (enterStatus == 2) {
      enterStatus = 0;
      printLCD(iRow, 0, " ");
      printLCD(iRow, 19, " ");
      return numChoices;
    }
  }
}

boolean confirmExit() {
  clearLCD();
  printLCD_P(0, 0, PSTR("Exiting will reset"));
  printLCD_P(1, 0, PSTR("outputs, setpoints"));
  printLCD_P(2, 0, PSTR("and timers."));
  
  char choices[2][19] = {
    "      Return      ",
    "   Exit Program   "};
  if(getChoice(choices, 2, 3) == 1) return 1; else return 0;
}

boolean confirmDel() {
  clearLCD();
  printLCD_P(1, 0, PSTR("Delete Item?"));
  
  char choices[2][19] = {
    "      Cancel      ",
    "      Delete      "};
  if(getChoice(choices, 2, 3) == 1) return 1; else return 0;
}

long getValue(char sTitle[], unsigned long defValue, byte digits, byte precision, long maxValue, char dispUnit[]) {
  unsigned long retValue = defValue;
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected

  encMin = 0;
  encMax = digits;
  encCount = 0;
  int lastCount = 1;
  char buf[11];

  {
    const byte charByte[] = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
    lcdSetCustChar(0, charByte);
  }
  {
    const byte charByte[] = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
    lcdSetCustChar(1, charByte);
  }
      
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD(1, (20 - digits + 1) / 2 + digits + 1, dispUnit);
  printLCD(3, 9, "OK");
  unsigned long whole, frac;
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        unsigned long factor = 1;
        for (int i = 0; i < digits - cursorPos - 1; i++) factor *= 10;
        if (encCount > lastCount) retValue += (encCount-lastCount) * factor; else retValue -= (lastCount-encCount) * factor;
        if (retValue > maxValue) retValue = maxValue;
      } else {
        cursorPos = encCount;
        for (int i = (20 - digits + 1) / 2 - 1; i < (20 - digits + 1) / 2 - 1 + digits - precision; i++) lcdWriteCustChar(2, i, 0);
        if (precision) for (int i = (20 - digits + 1) / 2 + digits - precision; i < (20 - digits + 1) / 2 + digits; i++) lcdWriteCustChar(2, i, 0);
        printLCD(3, 8, " ");
        printLCD(3, 11, " ");
        if (cursorPos == digits) {
          printLCD(3, 8, ">");
          printLCD(3, 11, "<");
        } else {
          if (cursorPos < digits - precision) lcdWriteCustChar(2, (20 - digits + 1) / 2 + encCount - 1, 1);
          else lcdWriteCustChar(2, (20 - digits + 1) / 2 + encCount, 1);
        }
      }
      lastCount = encCount;
      whole = retValue / pow(10, precision);
      frac = retValue - (whole * pow(10, precision)) ;
      printLCDPad(1, (20 - digits + 1) / 2 - 1, ltoa(whole, buf, 10), digits - precision, ' ');
      if (precision) {
        printLCD(1, (20 - digits + 1) / 2 + digits - precision - 1, ".");
        printLCDPad(1, (20 - digits + 1) / 2 + digits - precision, ltoa(frac, buf, 10), precision, '0');
      }
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == digits) return retValue;
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          encMin = 0;
          encMax = 9;
          if (cursorPos < digits - precision) {
            ltoa(whole, buf, 10);
            if (cursorPos < digits - precision - strlen(buf)) encCount = 0; else  encCount = buf[cursorPos - (digits - precision - strlen(buf))] - '0';
          } else {
            ltoa(frac, buf, 10);
            if (cursorPos < digits - strlen(buf)) encCount = 0; else  encCount = buf[cursorPos - (digits - strlen(buf))] - '0';
          }
        } else {
          encMin = 0;
          encMax = digits;
          encCount = cursorPos;
        }
        lastCount = encCount;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return defValue;
    }
  }
}

unsigned int getTimerValue(char sTitle[], unsigned int defMins) {
  unsigned int hours = defMins / 60;
  unsigned int mins = defMins - hours * 60;
  byte cursorPos = 0; //0 = Hours, 1 = Mins, 2 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  encMin = 0;
  encMax = 2;
  encCount = 0;
  int lastCount = 1;
  char buf[3];
  
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD(1, 9, ":");
  printLCD(1, 13, "(hh:mm)");
  printLCD(3, 8, "OK");
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        if (cursorPos) mins = encCount; else hours = encCount;
      } else {
        cursorPos = encCount;
        switch (cursorPos) {
          case 0:
            printLCD(1, 6, ">");
            printLCD(1, 12, " ");
            printLCD(3, 7, " ");
            printLCD(3, 10, " ");
            break;
          case 1:
            printLCD(1, 6, " ");
            printLCD(1, 12, "<");
            printLCD(3, 7, " ");
            printLCD(3, 10, " ");
            break;
          case 2:
            printLCD(1, 6, " ");
            printLCD(1, 12, " ");
            printLCD(3, 7, ">");
            printLCD(3, 10, "<");
            break;
        }
      }
      printLCDPad(1, 7, itoa(hours, buf, 10), 2, '0');
      printLCDPad(1, 10, itoa(mins, buf, 10), 2, '0');
      lastCount = encCount;
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == 2) return hours * 60 + mins;
      cursorState = cursorState ^ 1;
      if (cursorState) {
        encMin = 0;
        encMax = 99;
        if (cursorPos)encCount = mins; else encCount = hours;
      } else {
        encMin = 0;
        encMax = 2;
        encCount = cursorPos;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return NULL;
    }
  }
}

void getString(char sTitle[], char defValue[], byte chars) {
  char retValue[20];
  strcpy(retValue, defValue);
  
  //Right-Pad with spaces
  boolean doWipe = 0;
  for (int i = 0; i < chars; i++) {
    if (retValue[i] < 32 || retValue[i] > 126) doWipe = 1;
    if (doWipe) retValue[i] = 32;
  }
  retValue[chars] = '\0';
  
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected

  encMin = 0;
  encMax = chars;
  encCount = 0;
  int lastCount = 1;

  {
    const byte charByte[] = {B11111, B00000, B00000, B00000, B00000, B00000, B00000, B00000};
    lcdSetCustChar(0, charByte);
  }
  {
    const byte charByte[] = {B11111, B11111, B00000, B00000, B00000, B00000, B00000, B00000};
    lcdSetCustChar(1, charByte);
  }
      
  clearLCD();
  printLCD(0,0,sTitle);
  printLCD(3, 9, "OK");
  
  while(1) {
    if (encCount != lastCount) {
      if (cursorState) {
        retValue[cursorPos] = enc2ASCII(encCount);
      } else {
        cursorPos = encCount;
        for (int i = (20 - chars + 1) / 2 - 1; i < (20 - chars + 1) / 2 - 1 + chars; i++) lcdWriteCustChar(2, i, 0);
        printLCD(3, 8, " ");
        printLCD(3, 11, " ");
        if (cursorPos == chars) {
          printLCD(3, 8, ">");
          printLCD(3, 11, "<");
        } else {
          lcdWriteCustChar(2, (20 - chars + 1) / 2 + encCount - 1, 1);
        }
      }
      lastCount = encCount;
      printLCD(1, (20 - chars + 1) / 2 - 1, retValue);
    }
    if (enterStatus == 1) {
      enterStatus = 0;
      if (cursorPos == chars) {
        strcpy(defValue, retValue);
        return;
      }
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          encMin = 0;
          encMax = 94;
          encCount = ASCII2enc(retValue[cursorPos]);
        } else {
          encMin = 0;
          encMax = chars;
          encCount = cursorPos;
        }
        lastCount = encCount;
      }
    } else if (enterStatus == 2) {
      enterStatus = 0;
      return;
    }
  }
}


//Next two functions used to change order of charactor scroll to (space), A-Z, a-z, 0-9, symbols
byte ASCII2enc(byte charin) {
  if (charin == 32) return 0;
  else if (charin >= 65 && charin <= 90) return charin - 64;
  else if (charin >= 97 && charin <= 122) return charin - 70;
  else if (charin >= 48 && charin <= 57) return charin + 5;
  else if (charin >= 33 && charin <= 47) return charin + 30;
  else if (charin >= 58 && charin <= 64) return charin + 20;
  else if (charin >= 91 && charin <= 96) return charin - 6;
  else if (charin >= 123 && charin <= 126) return charin - 32;
}

byte enc2ASCII(byte charin) {
  if (charin == 0) return 32;
  else if (charin >= 1 && charin <= 26) return charin + 64;
  else if (charin >= 27 && charin <= 52) return charin + 70;
  else if (charin >= 53 && charin <= 62) return charin - 5;
  else if (charin >= 63 && charin <= 77) return charin - 30;
  else if (charin >= 78 && charin <= 84) return charin - 20;
  else if (charin >= 85 && charin <= 90) return charin + 6;
  else if (charin >= 91 && charin <= 94) return charin + 32;
}
