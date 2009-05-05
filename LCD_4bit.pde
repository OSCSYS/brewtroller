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
