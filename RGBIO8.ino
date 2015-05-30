#ifdef RGBIO8_ENABLE
  unsigned long lastRGBIO8 = 0;
  
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
