#ifndef NOUI

//*****************************************************************************************************************************
//Generic UI Functions
//*****************************************************************************************************************************
void uiLabelFPoint(byte row, byte col, byte width, unsigned long value, unsigned int divisor) {
  char numText[12];
  vftoa(value, numText, divisor, 1);
  truncFloat(numText, width);
  LCD.lPad(row, col, numText, width, ' ');
}

void uiLabelTemperature (byte row, byte col, byte width, unsigned long value) {
  if (value == BAD_TEMP)
    LCD.lPad(row, col, "", width, '-');
  else {
    uiLabelFPoint(row, col, width - 1, value, 100);
    LCD.print_P(row, col + width - 1, TUNIT);
  }
}

void uiLabelPercentOnOff (byte row, byte col, byte pct) {
  char numText[5];
  if (pct == 0)
    strcpy_P(numText, LABEL_BUTTONOFF);
  else if (pct == 100)
    strcpy_P(numText, LABEL_BUTTONON);
  else {
    itoa(pct, numText, 10);
    strcat(numText, "%"); 
  }
  LCD.lPad(row, col, numText, 3, ' ');
}

void uiCursorNone(byte row, byte col, byte width) {
  LCD.print_P(row, col, PSTR(" "));
  LCD.print_P(row, col + width - 1, PSTR(" "));
}

void uiCursorFocus(byte row, byte col, byte width) {
  LCD.print_P(row, col, PSTR(">"));
  LCD.print_P(row, col + width - 1, PSTR("<"));
}

void uiCursorUnfocus(byte row, byte col, byte width) {
  LCD.print_P(row, col, PSTR("["));
  LCD.print_P(row, col + width - 1, PSTR("]"));
}

void uiCursorHasFocus(byte row, byte col, byte width, boolean hasFocus) {
  if (hasFocus)
    uiCursorFocus(row, col, width);
  else
    uiCursorUnfocus(row, col, width);
}

/*
  scrollMenu() & drawMenu():
  Glues together menu, Encoder and LCD objects
*/

byte scrollMenu(char sTitle[], menu *objMenu) {
  Encoder.setMin(0);
  Encoder.setMax(objMenu->getItemCount() - 1);
  //Force refresh in case selected value was set
  Encoder.setCount(objMenu->getSelected());
  boolean redraw = 1;
  
  while(1) {
    int encValue = redraw ? Encoder.getCount() : Encoder.change();
    if (encValue >= 0) {
      objMenu->setSelected(encValue);
      if (objMenu->refreshDisp() || redraw)
        drawMenu(sTitle, objMenu);
      for (byte i = 0; i < 3; i++)
        LCD.writeCustChar(i + 1, 0, ((i == objMenu->getCursor()) ? '>' : ' '));
    }
    redraw = 0;
    //If Enter
    if (Encoder.ok())
      return objMenu->getValue();
    if (Encoder.cancel())
      return 255;
    brewCore();
  }
}

void drawMenu(char sTitle[], menu *objMenu) {
  LCD.clear();
  LCD.print(0, 0, sTitle);

  for (byte i = 0; i < 3; i++) {
    char optionText[20];
    objMenu->getVisibleRow(i, optionText);
    LCD.print(i + 1, 1, optionText);
  }
  LCD.print(objMenu->getCursor() + 1, 0, ">");
}

void infoBox(char line1[], char line2[], char line3[], const char* prompt) {
  LCD.clear();
  LCD.center(0, 0, line1, 20);
  LCD.center(1, 0, line2, 20);
  LCD.center(2, 0, line3, 20);
  uiCursorFocus(3, 0, 20);
  
  char optionText[21];
  LCD.center(3, 1, strcpy_P(optionText, prompt), 18);
  while (!Encoder.ok())
    brewCore();
}

byte getChoice(menu *objMenu, byte iRow) {
  uiCursorFocus(iRow, 0, 20);
  Encoder.setMin(0);
  Encoder.setMax(objMenu->getItemCount() - 1);
  Encoder.setCount(0);
  boolean redraw = 1;
  
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      objMenu->setSelected(encValue);
      char item[21];
      LCD.center(iRow, 1, objMenu->getSelectedRow(item), 18);
    }
    
    //If Enter
    if (Encoder.ok()) {
      LCD.print_P(iRow, 0, SPACE);
      LCD.print_P(iRow, 19, SPACE);
      return Encoder.getCount();
    } else if (Encoder.cancel()) {
      return 255;
    }
    brewCore();
  }
}

class menuChoice : public menu {
  private:
    const char *itemText;
    
  public:
    menuChoice(byte pSize, const char *choice) : menu (pSize) {
      itemText = choice;
    }

    byte getItemCount(void) {
      return 2;
    }

    char *getItem(byte index, char *retString) {
      return strcpy_P(retString, index ? itemText : CANCEL);
    }
};

boolean confirmChoice(char line1[], char line2[], char line3[], const char *choice) {
  LCD.clear();
  LCD.print(0, 0, line1);
  LCD.print(1, 0, line2);
  LCD.print(2, 0, line3);
  menuChoice choiceMenu(1, choice);
  if(getChoice(&choiceMenu, 3) == 1) return 1; else return 0;
}

boolean confirmAbort() {
  return confirmChoice("Abort operation and", "reset setpoints,", "timers and outputs?", PSTR("Reset"));
}

boolean confirmDel() {
  return confirmChoice("Delete Item?", "", "", DELETE);
}

boolean confirmSave() {
  return confirmChoice("Save Changes?", "", "", PSTR("Save"));
}

boolean confirmAdvance() {
  return confirmChoice("Advance program?", "", "", PSTR("Advance"));
}

unsigned long getValue_P(const char *sTitle, unsigned long defValue, unsigned int divisor, unsigned long maxValue, const char *dispUnit) {
  char title[20];
  strcpy_P(title, sTitle);
  return getValue(title, defValue, divisor, maxValue, dispUnit);
}

unsigned long getValue(char sTitle[], unsigned long defValue, unsigned int divisor, unsigned long maxValue, const char *dispUnit) {
  unsigned long retValue = defValue;
  char strValue[11];
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  byte increment;
  
  itoa(divisor - 1, strValue, 10);
  byte precision = strlen(strValue);
  if (divisor == 1) precision = 0;
  unsigned int mult = pow10(precision);
  ultoa(maxValue/divisor, strValue, 10);
  byte digits = strlen(strValue) + precision;

  Encoder.setMin(0);
  Encoder.setMax(digits);
  Encoder.setCount(0);

  LCD.setCustChar_P(0, CHARFIELD);
  LCD.setCustChar_P(1, CHARCURSOR);
  LCD.setCustChar_P(2, CHARSEL);
  
  byte valuePos = (20 - digits + 1) / 2;
  LCD.clear();
  LCD.print(0, 0, sTitle);
  LCD.print_P(1, valuePos + digits + 1, dispUnit);
  LCD.print_P(3, 9, OK);
  boolean redraw = 1;
  
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        vftoa(retValue, strValue, divisor, 0);
        strLPad(strValue, digits, '0');
        strValue[cursorPos] = '0' + encValue * increment;
        unsigned long newValue = strtoul(strValue, NULL, 10) / (mult / divisor);
        if (newValue <= maxValue)
          retValue = newValue;
        vftoa(retValue, strValue, divisor, 0);
        strLPad(strValue, digits, '0');
        Encoder.setCount((strValue[cursorPos] - '0') / increment);
      } else {
        cursorPos = encValue;
        for (byte i = valuePos - 1; i < valuePos - 1 + digits - precision; i++) LCD.writeCustChar(2, i, 0);
        if (precision) for (byte i = valuePos + digits - precision; i < valuePos + digits; i++) LCD.writeCustChar(2, i, 0);
        
        if (cursorPos == digits)
         uiCursorFocus(3, 8, 4);
        else {
          uiCursorNone(3, 8, 4);
          if (cursorPos < digits - precision)
            LCD.writeCustChar(2, valuePos + cursorPos - 1, 1);
          else
            LCD.writeCustChar(2, valuePos + cursorPos, 1);
        }
      }
      vftoa(retValue, strValue, divisor, 1);
      strLPad(strValue, digits + (precision ? 1 : 0), ' ');
      LCD.print(1, valuePos - 1, strValue);
    }
    
    if (Encoder.ok()) {
      if (cursorPos == digits) break;
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          if (cursorPos < digits - precision) LCD.writeCustChar(2, valuePos + cursorPos - 1, 2);
          else LCD.writeCustChar(2, valuePos + cursorPos, 2);
          unsigned long cursorPow = pow10(digits - cursorPos - 1);
          if(divisor == 1) increment = 1;
          else increment = max(10 / (cursorPow * divisor), 1);
          Encoder.setMin(0);
          Encoder.setMax(10 / increment - 1);
          vftoa(retValue, strValue, divisor, 0);
          strLPad(strValue, digits, '0');
          Encoder.setCount((strValue[cursorPos] - '0') / increment);
        } else {
          if (cursorPos < digits - precision) LCD.writeCustChar(2, valuePos + cursorPos - 1, 1);
          else LCD.writeCustChar(2, valuePos + cursorPos, 1);
          Encoder.setMin(0);
          Encoder.setMax(digits);
          Encoder.setCount(cursorPos);
        }
      }
    } else if (Encoder.cancel()) {
      retValue = defValue;
      break;
    }
    brewCore();
  }
  return retValue;
}

unsigned long ulpow(unsigned long base, unsigned long exponent) {
  unsigned long ret = 1;
  for (int i = 0; i < exponent; i++) {
    ret *= base;
  }
  return ret;
}

/**
 * Prompt the user for a value in hex. The value is shown with 0x prepended
 * and the user may only select 0-f for each digit.
 */
unsigned long getHexValue(char sTitle[], unsigned long defValue, byte digits) {
  unsigned long retValue = defValue;
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected

  Encoder.setMin(0);
  Encoder.setMax(digits);
  Encoder.setCount(0);

  LCD.setCustChar_P(0, CHARFIELD);
  LCD.setCustChar_P(1, CHARCURSOR);
  LCD.setCustChar_P(2, CHARSEL);
  
  byte valuePos = (20 - digits + 1) / 2;
  LCD.clear();
  LCD.print(0, 0, sTitle);
  LCD.print_P(3, 9, OK);
  boolean redraw = 1;
  
  unsigned long multiplier = ulpow(16, (digits - cursorPos - 1));
  
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else {
      encValue = Encoder.change();
    }
    if (encValue >= 0) {
      if (cursorState) {
        retValue -= (retValue / multiplier % 16 * multiplier);
        retValue += (encValue * multiplier);
      } 
      else {
        cursorPos = encValue;
        multiplier = ulpow(16, (digits - cursorPos - 1));
        for (byte i = valuePos - 1; i < valuePos - 1 + digits; i++) {
          LCD.writeCustChar(2, i, 0);
        }
        if (cursorPos == digits)
          uiCursorFocus(3, 8, 4);
        else {
          uiCursorNone(3, 8, 4);
          if (cursorPos < digits) {
            LCD.writeCustChar(2, valuePos + cursorPos - 1, 1);
          }
          else {
            LCD.writeCustChar(2, valuePos + cursorPos, 1);
          }
        }
      }
      char format[6] = "%0";
      char optionText[21];
      strcat(format, itoa(digits, optionText, 10));
      strcat(format, "X");
      
      sprintf(optionText, format, retValue);
      LCD.print(1, valuePos - 1, optionText);
      LCD.print(1, valuePos - 3, "0x");
    }
    
    if (Encoder.ok()) {
      if (cursorPos == digits) {
        break;
      }
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          if (cursorPos < digits) {
            LCD.writeCustChar(2, valuePos + cursorPos - 1, 2);
          }
          else {
            LCD.writeCustChar(2, valuePos + cursorPos, 2);
          }
          Encoder.setMin(0);
          Encoder.setMax(0x0f);
          Encoder.setCount(retValue / multiplier % 16);
        } 
        else {
          if (cursorPos < digits) {
            LCD.writeCustChar(2, valuePos + cursorPos - 1, 1);
          }
          else LCD.writeCustChar(2, valuePos + cursorPos, 1);
          Encoder.setMin(0);
          Encoder.setMax(digits);
          Encoder.setCount(cursorPos);
        }
      }
    } 
    else if (Encoder.cancel()) {
      retValue = defValue;
      break;
    }
    brewCore();
  }
  return retValue;
}

void printTimer(byte timer, byte iRow, byte iCol) {
  if (timerValue[timer] > 0 && !timerStatus[timer]) LCD.print(iRow, iCol, "PAUSED");
  else if (alarmStatus || timerStatus[timer]) {
    byte hours = timerValue[timer] / 3600000;
    byte mins = (timerValue[timer] - hours * 3600000) / 60000;
    byte secs = (timerValue[timer] - hours * 3600000 - mins * 60000) / 1000;

    //Update LCD once per second
    if (millis() - timerLastPrint >= 1000) {
      timerLastPrint = millis();
      LCD.rPad(iRow, iCol, "", 6, ' ');
      LCD.print_P(iRow, iCol+2, PSTR(":  :"));
      char numText[4];
      LCD.lPad(iRow, iCol, itoa(hours, numText, 10), 2, '0');
      LCD.lPad(iRow, iCol + 3, itoa(mins, numText, 10), 2, '0');
      LCD.lPad(iRow, iCol + 6, itoa(secs, numText, 10), 2, '0');
      if (alarmStatus) LCD.writeCustChar(iRow, iCol + 8, 5);
    }
  } else LCD.rPad(iRow, iCol, "", 9, ' ');
}

int getTimerValue(const char *sTitle, int defMins, byte maxHours) {
  byte hours = defMins / 60;
  byte mins = defMins - hours * 60;
  byte cursorPos = 0; //0 = Hours, 1 = Mins, 2 = OK
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  Encoder.setMin(0);
  Encoder.setMax(2);
  Encoder.setCount(0);
  
  LCD.clear();
  LCD.print_P(0,0,sTitle);
  LCD.print(1, 7, "(hh:mm)");
  LCD.print(2, 10, ":");
  LCD.print_P(3, 9, OK);
  boolean redraw = 1;
  int encValue;
 
  while(1) {
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    } else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        if (cursorPos) mins = encValue; else hours = encValue;
      } else {
        cursorPos = encValue;
        switch (cursorPos) {
          case 0: //hours
            LCD.print(2, 7, ">");
            LCD.print(2, 13, " ");
            uiCursorNone(3, 8, 4);
            break;
          case 1: //mins
            LCD.print(2, 7, " ");
            LCD.print(2, 13, "<");
            uiCursorNone(3, 8, 4);
            break;
          case 2: //OK
            uiCursorNone(2, 7, 7);
            uiCursorFocus(3, 8, 4);
            break;
        }
      }
      char numText[4];
      LCD.lPad(2, 8, itoa(hours, numText, 10), 2, '0');
      LCD.lPad(2, 11, itoa(mins, numText, 10), 2, '0');
    }
    
    if (Encoder.ok()) {
      if (cursorPos == 2) return hours * 60 + mins;
      cursorState = cursorState ^ 1; //Toggles between value editing mode and cursor navigation.
      if (cursorState) {
        //Edition mode
        Encoder.setMin(0);
        if (cursorPos) {
          //Editing minutes
          Encoder.setMax(59);
          Encoder.setCount(mins); 
        } else {
          //Editing hours
          Encoder.setMax(maxHours);
          Encoder.setCount(hours);
        }
      } else {
        Encoder.setMin(0);
        Encoder.setMax(2);
        Encoder.setCount(cursorPos);
      }
    } else if (Encoder.cancel()) return -1; //This value will be validated in SetTimerValue. SetTimerValue will reject the storage of the timer value. 
    brewCore();
  }
}

void getString(const char *sTitle, char defValue[], byte chars) {
  char retValue[20];
  strcpy(retValue, defValue);
  
  //Right-Pad with spaces
  boolean doWipe = 0;
  for (byte i = 0; i < chars; i++) {
    if (retValue[i] < 32 || retValue[i] > 126) doWipe = 1;
    if (doWipe) retValue[i] = 32;
  }
  retValue[chars] = '\0';
  
  byte cursorPos = 0; 
  boolean cursorState = 0; //0 = Unselected, 1 = Selected
  Encoder.setMin(0);
  Encoder.setMax(chars);
  Encoder.setCount(0);


  LCD.setCustChar_P(0, CHARFIELD);
  LCD.setCustChar_P(1, CHARCURSOR);
  LCD.setCustChar_P(2, CHARSEL);
  
  LCD.clear();
  LCD.print_P(0,0,sTitle);
  LCD.print_P(3, 9, OK);
  boolean redraw = 1;
  while(1) {
    int encValue;
    if (redraw) {
      redraw = 0;
      encValue = Encoder.getCount();
    }
    else encValue = Encoder.change();
    if (encValue >= 0) {
      if (cursorState) {
        retValue[cursorPos] = enc2ASCII(encValue);
      } else {
        cursorPos = encValue;
        for (byte i = (20 - chars + 1) / 2 - 1; i < (20 - chars + 1) / 2 - 1 + chars; i++)
          LCD.writeCustChar(2, i, 0);
        if (cursorPos == chars)
          uiCursorFocus(3, 8, 4);
        else {
          uiCursorNone(3, 8, 4);
          LCD.writeCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 1);
        }
      }
      LCD.print(1, (20 - chars + 1) / 2 - 1, retValue);
    }
    
    if (Encoder.ok()) {
      if (cursorPos == chars) {
        strcpy(defValue, retValue);
        return;
      }
      else {
        cursorState = cursorState ^ 1;
        if (cursorState) {
          Encoder.setMin(0);
          Encoder.setMax(94);
          Encoder.setCount(ASCII2enc(retValue[cursorPos]));
          LCD.writeCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 2);
        } else {
          Encoder.setMin(0);
          Encoder.setMax(chars);
          Encoder.setCount(cursorPos);
          LCD.writeCustChar(2, (20 - chars + 1) / 2 + cursorPos - 1, 1);
        }
      }
    } else if (Encoder.cancel()) return;
    brewCore();
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
  else if (charin >= 1 && charin <= 26) return charin + 64;  //Scan uper case alphabet
  else if (charin >= 27 && charin <= 52) return charin + 70; //Scan lower case alphabet
  else if (charin >= 53 && charin <= 62) return charin - 5;  //Scan number
  else if (charin >= 63 && charin <= 77) return charin - 30; //Scan special character from space
  else if (charin >= 78 && charin <= 84) return charin - 20; //Scan special character :
  else if (charin >= 85 && charin <= 90) return charin + 6;  //Scan special character from [
  else if (charin >= 91 && charin <= 94) return charin + 32; //Scan special character from {
}
#endif
