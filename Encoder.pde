byte encBounceDelay;
byte enterBounceDelay;
volatile unsigned long lastEncUpd = millis();
unsigned long enterStart;

void initEncoder() {
  switch(encMode) {
    case ENC_CUI:
      enterBounceDelay = 50;
      encBounceDelay = 50;
      attachInterrupt(2, doEncoderCUI, RISING);
      break;
    case ENC_ALPS:
      enterBounceDelay = 30;
      encBounceDelay = 60;
      attachInterrupt(2, doEncoderALPS, CHANGE);
      break;
  }
  attachInterrupt(1, doEnter, CHANGE);
}

void doEncoderCUI() {
  if (millis() - lastEncUpd < encBounceDelay) return;
  //Read EncB
  if (digitalRead(4) == LOW) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEncoderALPS() {
  //if (millis() - lastEncUpd < encBounceDelay) return;
  //Compare EncA and EncB
  if (digitalRead(2) != digitalRead(4)) encCount++; else encCount--;
  if (encCount == -1) encCount = 0; else if (encCount < encMin) { encCount = encMin; } else if (encCount > encMax) { encCount = encMax; }
  lastEncUpd = millis();
} 

void doEnter() {
  if (digitalRead(11) == HIGH) {
    enterStart = millis();
  } else {
    if (millis() - enterStart > 1000) {
      enterStatus = 2;
    } else if (millis() - enterStart > enterBounceDelay) {
      enterStatus = 1;
    }
  }
}

