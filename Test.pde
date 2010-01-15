void menuTest() {
//Program memory used: <1KB (as of Build 205)
#ifdef MODULE_SYSTEST
  byte lastOption = 0;
  
  while(1) {
    strcpy_P(menuopts[0], PSTR("HLT Volume"));
    strcpy_P(menuopts[1], PSTR("Mash Volume"));
    strcpy_P(menuopts[2], PSTR("Kettle Volume"));
    strcpy_P(menuopts[3], PSTR("Exit Test"));
    
    lastOption = scrollMenu("Test Menu", 4, lastOption);
    if (lastOption == 0) volumeTest(TS_HLT);
    else if (encCount == 1) volumeTest(TS_MASH);
    else if (encCount == 2) volumeTest(TS_KETTLE);
    else return;
  }
#endif
}

void volumeTest(byte vessel) {
#ifdef MODULE_SYSTEST
  setZeroVol(vessel, analogRead(vSensor[vessel]));
  unsigned int calibVals[10];
  unsigned long calibVols[10];
  unsigned int zero;
  unsigned long vol;
  unsigned long lastUpdate = 0;

  zero = getZeroVol(vessel);
  getVolCalibs(vessel, calibVols, calibVals);
  clearLCD();
  printLCD_P(0, 0, PSTR("Zero: "));
  printLCD(0, 11, itoa(zero, buf, 10));
  printLCD_P(1, 0, PSTR("Raw: "));
  printLCD_P(2, 0, PSTR("Corrected: "));
  printLCD_P(3, 0, PSTR("Volume: "));
      
  while (1) {
    if (millis() - lastUpdate > 750) {
      vol = readVolume(vSensor[vessel], calibVols, calibVals, zero);
      printLCDRPad(1, 11, itoa(analogRead(vSensor[vessel]), buf, 10), 8, ' ');
      printLCDRPad(2, 11, itoa(analogRead(vSensor[vessel]) - zero, buf, 10), 8, ' ');
      ftoa(vol/1000.0, buf, 2);
      printLCDRPad(3, 11, buf, 8, ' ');
      lastUpdate = millis();
    }
    if (enterStatus == 2) { enterStatus = 0; return; }
  }
#endif
}
