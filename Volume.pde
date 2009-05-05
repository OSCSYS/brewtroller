unsigned long readVolume( byte pin, unsigned long calibrationVols[10], unsigned int calibrationValues[10], unsigned int zeroValue ) {
  unsigned int aValue = analogRead(pin);
  #ifdef DEBUG
    Serial.print("readVolume (Pin ");
    Serial.print(pin, DEC);
    Serial.print(") analogRead: ");
    Serial.print(aValue, DEC);
    Serial.print(" zeroValue: ");
    Serial.println(zeroValue, DEC);
  #endif
  if (aValue <= zeroValue) return 0; else aValue -= zeroValue;
  
  byte upperCal = 0;
  byte lowerCal = 0;
  byte lowerCal2 = 0;
  for (byte i = 0; i < 10; i++) {
    if (aValue == calibrationValues[i]) return calibrationVols[i];
    if (aValue > calibrationValues[i] && calibrationValues[i] > calibrationValues[lowerCal]) { lowerCal2 = lowerCal; lowerCal = i; }
    else if (aValue > calibrationValues[i] && calibrationValues[i] > calibrationValues[lowerCal2]) lowerCal2 = i;
    else if (aValue < calibrationValues[i] && calibrationValues[i] < calibrationValues[upperCal]) upperCal = i;
  }
  
  #ifdef DEBUG
    Serial.print("readVolume Corrected: ");
    Serial.print(aValue, DEC);
    Serial.print(" upperCal Value: ");
    Serial.print(calibrationValues[upperCal], DEC);
    Serial.print(" lowerCal Value: ");
    Serial.print(calibrationValues[lowerCal], DEC);
    Serial.print(" lowerCal2 Value: ");
    Serial.println(calibrationValues[lowerCal2], DEC);
  #endif
  
  //If no calibrations exist return zero
  if (calibrationValues[upperCal] == 0 && calibrationValues[lowerCal] == 0) return 0;
  
  //If read value is greater than all calibrations plot value based on two closest lesser values
  if (aValue > calibrationValues[upperCal] && calibrationValues[lowerCal] > calibrationValues[lowerCal2]) return round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[lowerCal] - calibrationValues[lowerCal2]) * (calibrationVols[lowerCal] - calibrationVols[lowerCal2])) + calibrationVols[lowerCal];
  
  //If read value exceeds all calibrations and only one lower calibration point is available plot value based on zero and closest lesser value
  if (aValue > calibrationValues[upperCal] && calibrationValues[lowerCal] == calibrationValues[lowerCal2]) return round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[lowerCal]) * (calibrationVols[lowerCal])) + calibrationVols[lowerCal];
  
  //If read value is less than all calibrations plot value between zero and closest greater value
  if (aValue < calibrationValues[lowerCal]) return round((float) aValue / (float) calibrationValues[upperCal] * calibrationVols[upperCal]);
  
  //Otherwise plot value between lower and greater calibrations
  else return round((float) (aValue - calibrationValues[lowerCal]) / (float) (calibrationValues[upperCal] - calibrationValues[lowerCal]) * (calibrationVols[upperCal] - calibrationVols[lowerCal])) + calibrationVols[lowerCal];
}
