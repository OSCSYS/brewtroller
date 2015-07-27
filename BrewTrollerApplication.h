#ifndef BrewTroller_h
#define BrewTroller_h

#include "Vessel.h"
#include "Enum.h"
#include "Trigger.h"
#include "Outputs.h"
#include "Vol_Bubbler.h"
#include "UI_LCD.h"

enum ApplicationUpdatePriorityLevel {
  PRIORITYLEVEL_CRITICAL, //Updates to prevent ESTOP
  PRIORITYLEVEL_HIGH,     //Critical + Updates needed on each iteration
  PRIORITYLEVEL_NORMAL,   //High + Updates performed using round-robin scheduler
  PRIORITYLEVEL_NORMALUI  //Normal + UI Update
};

class Vessel;

class BrewTrollerApplication {
  private:
    Vessel *vessel[VESSEL_COUNT];
    static BrewTrollerApplication* INSTANCE;
    BrewTrollerApplication(void);
    ~BrewTrollerApplication(void);
    unsigned long lastKettleOutSave = 0;
    byte scheduler;
    #ifdef HEARTBEAT
      unsigned long hbStart = 0;
      pin hbPin;
    #endif
    Bubbler *bubbler;

    void updateBoilController(void);
    void updateAutoValve();
    void heartbeat(void);
    
  public:
    Vessel* getVessel(byte index);
    static BrewTrollerApplication* getInstance(void);
    void init(void);
    void update(enum ApplicationUpdatePriorityLevel);
    void reset(void);
    byte autoValveBitmask(void);
    boolean isEStop(void);
    Bubbler* getBubbler(void);
    void addBubbler(Bubbler *b);
};

#endif
