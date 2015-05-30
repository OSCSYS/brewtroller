#ifdef RGBIO8_ENABLE
  unsigned long lastRGBIO8 = 0;
  
  // Initializes the RGBIO8 system. If you want to provide custom IO mappings
  // this is the place to do it. See the CUSTOM CONFIGURATION section below for
  // further instructions.
  void RGBIO8_Init() {
    RGBIO8::setup(outputs);
  }
  
  void RGBIO8_Update() {
    if (millis() > (lastRGBIO8 + RGBIO8_INTERVAL)) {
      for (int i = 0; i < RGBIO8_MAX_BOARDS; i++) {
        if (rgbio[i])
          rgbio[i]->update();
      }
      outputs->setProfileState(OUTPUTPROFILE_RGBIO, outputs->getProfileMask(OUTPUTPROFILE_RGBIO) ? 1 : 0);
      lastRGBIO8 = millis();
    }
  }
#endif
