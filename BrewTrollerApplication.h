#ifndef BrewTroller_h
#define BrewTroller_h

#include "Vessel.h"
#include "enum.h"

enum ApplicationUpdatePriorityLevel {
  PRIORITYLEVEL_CRITICAL, //Updates to prevent ESTOP
  PRIORITYLEVEL_HIGH,     //Critical + Updates needed on each iteration
  PRIORITYLEVEL_NORMAL,   //High + Updates performed using round-robin scheduler
  PRIORITYLEVEL_NORMALUI  //Normal + UI Update
};

class BrewTrollerApplication {
  private:
    Vessel *vessel[VESSEL_COUNT];
    static BrewTrollerApplication* INSTANCE;
    BrewTrollerApplication(void);
    unsigned long lastKettleOutSave = 0;
    byte scheduler;
    #ifdef HEARTBEAT
      unsigned long hbStart = 0;
    #endif

    void updateBoilController(void);
    void heartbeat(void);
    
  public:
    Vessel* getVessel(byte index);
    static BrewTrollerApplication* getInstance(void);
    void init(void);
    void update(enum ApplicationUpdatePriorityLevel);
    void reset(void);
    byte autoValveBitmask(void);
};

#endif
