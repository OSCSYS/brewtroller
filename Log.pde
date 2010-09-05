/*  
   Copyright (C) 2009, 2010 Matt Reba, Jermeiah Dillingham

    This file is part of BrewTroller.

    BrewTroller is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    BrewTroller is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with BrewTroller.  If not, see <http://www.gnu.org/licenses/>.


BrewTroller - Open Source Brewing Computer
Software Lead: Matt Reba (matt_AT_brewtroller_DOT_com)
Hardware Lead: Jeremiah Dillingham (jeremiah_AT_brewtroller_DOT_com)

Documentation, Forums and more information available at http://www.brewtroller.com
*/

#include "Config.h"
#include "Enum.h"

#define CMD_MSG_FIELDS 25
#define CMD_FIELD_CHARS 21

boolean msgQueued;
unsigned long lastLog;
byte logCount, msgField;
char msg[CMD_MSG_FIELDS][CMD_FIELD_CHARS];

void logInit() {
  #if defined USESERIAL
    Serial.begin(BAUD_RATE);
    Serial.println();
  #endif
  logVersion();
}

void logString_P (const char *sType, const char *sText) {
 logStart_P(sType);
 logField_P(sText);
 logEnd();
}

void logStart_P (const char *sType) {
#if defined USESERIAL
 Serial.print(millis(),DEC);
 Serial.print("\t");
 while (pgm_read_byte(sType) != 0) Serial.print(pgm_read_byte(sType++)); 
 Serial.print("\t");
#endif
}

void logEnd () {
#if defined USESERIAL
 Serial.println();
#endif
}

void logField (char sText[]) {
#if defined USESERIAL
  Serial.print(sText);
  Serial.print("\t");
#endif
}

void logFieldI (unsigned long value) {
#if defined USESERIAL
  Serial.print(value, DEC);
  Serial.print("\t");
#endif
}

void logField_P (const char *sText) {
#if defined USESERIAL
  while (pgm_read_byte(sText) != 0) Serial.print(pgm_read_byte(sText++));
  Serial.print("\t");
#endif
}

boolean chkMsg() {
#if defined USESERIAL
  if (!msgQueued) {
    while (Serial.available()) {
      byte byteIn = Serial.read();
      if (byteIn == '\r') { 
        msgQueued = 1;
        //Configuration Class (CFG) Commands
        if(strcasecmp(msg[0], "GET_BOIL") == 0) {
          logBoil();
          clearMsg();
        } else if(strcasecmp(msg[0], "GET_CAL") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_KETTLE) {
            logVolCalib(val);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_EVAP") == 0) {
          logEvap();
          clearMsg();
        } else if(strcasecmp(msg[0], "GET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_STEAM) {
            logOSet(val);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_PROG") == 0) {
          byte program = atoi(msg[1]);
          if (msgField == 1 && program >= 0 && program < 20) {
            logProgram(program);
            clearMsg();
          } else rejectParam();
        } else if (strcasecmp(msg[0], "GET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= TS_HLT && val <= TS_AUX3) {
            logTSensor(val);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_VLVCFG") == 0) {
          byte profile = atoi(msg[1]);
          if (msgField == 1 && profile >= VLV_FILLHLT && profile <= VLV_DRAIN) {
            logVlvConfig(profile);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_VSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_KETTLE) {
            logVSet(val);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "INIT_EEPROM") == 0) {
          clearMsg();
          initEEPROM();
        } else if(strcasecmp(msg[0], "SCAN_TS") == 0) {
          clearMsg();
          byte tsAddr[8];
          getDSAddr(tsAddr);
          logStart_P(LOGCFG);
          logField_P(PSTR("TS_SCAN")); 
          for (byte i=0; i<8; i++) logFieldI(tsAddr[i]);
          logEnd();
        } else if(strcasecmp(msg[0], "SET_BOIL") == 0) {
          if (msgField == 1) {
            byte val = atoi(msg[1]);
            setBoilTemp(val);
            clearMsg();
            logBoil();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_CAL") == 0) {
          byte vessel = atoi(msg[1]);
          if (msgField == 21 && vessel >= VS_HLT && vessel <= VS_KETTLE) {
            for (byte i = 0; i < 10; i++) setVolCalib(vessel, i, atol(msg[i * 2 + 3]), strtoul(msg[i * 2 + 2], NULL, 10));
            clearMsg();
            logVolCalib(vessel);
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_EVAP") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= 0 && val <= 100) {
            setEvapRate(val);
            clearMsg();
            logEvap();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 7 && val >= VS_HLT && val <= VS_STEAM) {
            setPIDEnabled(val, (byte)atoi(msg[2]));
            setPIDCycle(val, (byte)atoi(msg[3]));
            setPIDp(val, (byte)atoi(msg[4]));
            setPIDi(val, (byte)atoi(msg[5]));
            setPIDd(val, (byte)atoi(msg[6]));
            setHysteresis(val, (byte)atoi(msg[7]));
            clearMsg();
            logOSet(val);
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_PROG") == 0) {          
          byte program = atoi(msg[1]);
          if (msgField == 22 && program >= 0 && program < 20) {
            char pName[20];
            strncpy(pName,msg[2],19); // Trunc the Program Name to 19 chars
            pName[19] = '\0';
            setProgName(program, pName);
            for (byte i = MASH_DOUGHIN; i <= MASH_MASHOUT; i++) {
              setProgMashTemp(program, i, atoi(msg[i * 2 + 3]));
              setProgMashMins(program, i, atoi(msg[i * 2 + 4]));
            }
            setProgSparge(program, atoi(msg[15]));
            setProgHLT(program, atoi(msg[16]));
            setProgBatchVol(program, strtoul(msg[17], NULL, 10));
            setProgGrain(program, strtoul(msg[18], NULL, 10));
            setProgBoil(program, atol(msg[19]));
            setProgRatio(program, atol(msg[20]));
            setProgPitch(program, atoi(msg[21]));
            setProgAdds(program, atol(msg[22]));
            clearMsg();
            logProgram(program);
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 9 && val >= TS_HLT && val <= TS_AUX3) {
            byte addr[8];
            for (byte i=0; i<8; i++) addr[i] = (byte)atoi(msg[i+2]);
            setTSAddr(val, addr);
            clearMsg();
            logTSensor(val);
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_VLVCFG") == 0) {
          byte profile = atoi(msg[1]);
          if (msgField == 2 && profile >= VLV_FILLHLT && profile <= VLV_DRAIN) {
            setValveCfg(profile, strtoul(msg[2], NULL, 10));
            clearMsg();
            logVlvConfig(profile);
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_VSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 3 && val >= VS_HLT && val <= VS_STEAM) {
            setCapacity(val, strtoul(msg[2], NULL, 10));
            setVolLoss(val, atol(msg[3]));
            clearMsg();
            logVSet(val);
          } else rejectParam();

        //Data Class (DATA) Commands
        } else if(strcasecmp(msg[0], "ADV_STEP") == 0) {
          if (msgField == 1) {
            stepAdvance((byte)atoi(msg[1]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "EXIT_STEP") == 0) {
          if (msgField == 1) {
            stepExit((byte)atoi(msg[1]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "INIT_STEP") == 0) {
          if (msgField == 2) {
            stepInit((byte)atoi(msg[1]), (byte)atoi(msg[2]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_ALARM") == 0) {
          if (msgField == 1) {
            setAlarm((boolean)atoi(msg[1]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_AUTOVLV") == 0) {
          byte avSet = atoi(msg[1]);
          if (msgField == 1) {
            byte actModes = atoi(msg[1]);
            for (byte i = AV_FILL; i <= AV_CHILL; i++) 
              autoValve[i] = (actModes & (1<<i));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_SETPOINT") == 0) {
          byte vessel = atoi(msg[1]);
          if (msgField == 2 && vessel <= VS_KETTLE) {
            setSetpoint(vessel, (byte)atoi(msg[2]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_TIMERSTATUS") == 0) {
          byte timer = atoi(msg[1]);
          if (msgField == 2 && timer >= TIMER_MASH && timer <= TIMER_BOIL) {
            setTimerStatus(timer, (boolean)atoi(msg[2]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_TIMERVALUE") == 0) {
          byte timer = atoi(msg[1]);
          if (msgField == 2 && timer >= TIMER_MASH && timer <= TIMER_BOIL) {
            timerValue[timer] = strtoul(msg[2], NULL, 10);
            lastTime[timer] = millis();
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_VLV") == 0) {
          if (msgField == 2) {
            setValves(strtoul(msg[1], NULL, 10), atoi(msg[2]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_VLVPRF") == 0) {
          if (msgField == 2) {
            setValves(VLV_ALL, 0);
            unsigned long actProfiles = strtoul(msg[1], NULL, 10);
            for (byte i = VLV_FILLHLT; i <= VLV_DRAIN; i++) 
              if ((actProfiles & (1<<i))) setValves(vlvConfig[i], atoi(msg[2]));
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_LOG") == 0) {
          getLog();
          clearMsg();

        //System Class (SYS) Commands
        } else if(strcasecmp(msg[0], "RESET") == 0) {
          byte level = atoi(msg[1]);
          if (msgField == 1 && level >= 0 && level <= 1) {
            clearMsg();
            if (level == 0) {
              resetOutputs();
              clearTimer(TIMER_MASH);
              clearTimer(TIMER_BOIL);
            } else if (level == 1) {
              logStart_P(LOGSYS);
              logField_P(PSTR("SOFT_RESET"));
              logEnd();
              softReset();
            }
          } else rejectParam();
        } else if(strcasecmp(msg[0], "SET_LOGSTATUS") == 0) {
          if (msgField == 1) {
            logData = (boolean)atoi(msg[1]);
            clearMsg();
          } else rejectParam();
        } else if(strcasecmp(msg[0], "GET_VER") == 0) {
          logVersion();
          clearMsg();        

        //End of Commands
        }
        break;

      } else if (byteIn == '\t') {
        if (msgField < CMD_MSG_FIELDS) {
          msgField++;
        } else {
          logString_P(LOGCMD, PSTR("MSG_OVERFLOW"));
          clearMsg();
        }
      } else {
        byte charCount = strlen(msg[msgField]);
        if (charCount < CMD_FIELD_CHARS - 1) { 
          msg[msgField][charCount] = byteIn; 
          msg[msgField][charCount + 1] = '\0';
        } else {
          logString_P(LOGCMD, PSTR("FIELD_OVERFLOW"));
          clearMsg();
        }
      }
    }
  }
  if (msgQueued) return 1; else return 0;
#endif
}

void clearMsg() {
  msgQueued = 0;
  msgField = 0;
  for (byte i = 0; i < CMD_MSG_FIELDS; i++) msg[i][0] = '\0';
}

void rejectMsg() {
  logStart_P(LOGCMD);
  logField_P(PSTR("UNKNOWN_CMD"));
  for (byte i = 0; i < msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
}

void rejectParam() {
  logStart_P(LOGCMD);
  logField_P(PSTR("BAD_PARAM"));
  for (byte i = 0; i <= msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
}

void updateLog() {
  //Log data every 2s
  //Log 1 of 6 chunks per cycle to improve responsiveness to calling function
  if (logData) {
    if (millis() - lastLog > LOG_INTERVAL) {
      getLog();
    }
  }
  // if logData is false && chkMsg() is false - should we pass the LOGCFG constant into rejectMsg?
  if (chkMsg()) rejectMsg();   // old value: LOGGLB
}

void getLog() {
  if (logCount == 0) {
    logStart_P(LOGDATA);
    logField_P(PSTR("STEPPRG"));
    for (byte i = 0; i < NUM_BREW_STEPS; i++)
      logFieldI(stepProgram[i]);
    logEnd();
  } else if (logCount == 1) {
    for (byte timer = TIMER_MASH; timer <= TIMER_BOIL; timer++) {
      logStart_P(LOGDATA);
      logField_P(PSTR("TIMER"));
      logFieldI(timer);
      logFieldI(timerValue[timer]);
      logFieldI(timerStatus[timer]);
      logEnd();
    }
    logStart_P(LOGDATA);
    logField_P(PSTR("ALARM"));
    logFieldI(alarmStatus);
    logEnd();
  } else if (logCount >= 2 && logCount <= 4) {
    byte i = logCount - 2;
    logStart_P(LOGDATA);
    logField_P(PSTR("VOL"));
    logFieldI(i);
    logFieldI(volAvg[i]);
    #ifdef FLOWRATE_CALCS
      logFieldI(flowRate[i]);
    #else
      logFieldI(0);
    #endif
    #ifdef USEMETRIC
      logFieldI(0);
    #else
      logFieldI(1);
    #endif
    logEnd();
  } else if (logCount >= 5 && logCount <= 13) {
    byte i = logCount - 5;
    logStart_P(LOGDATA);
    logField_P(PSTR("TEMP"));
    logFieldI(i);
    logFieldI(temp[i]);
    #ifdef USEMETRIC
      logFieldI(0);
    #else
      logFieldI(1);
    #endif
    logEnd();
  } else if (logCount == 14) {
    logStart_P(LOGDATA);
    logField_P(PSTR("STEAM"));
    logFieldI(steamPressure);
    #ifdef USEMETRIC
      logFieldI(0);
    #else
      logFieldI(1);
    #endif
    logEnd();
  } else if (logCount >= 15 && logCount <= 18) {
    byte pct;
    byte i = logCount - 15;
    if (PIDEnabled[i]) pct = PIDOutput[i] / PIDCycle[i];
    else if (heatStatus[i]) pct = 100;
    else pct = 0;
    logStart_P(LOGDATA);
    logField_P(PSTR("HEATPWR"));
    logFieldI(i);
    logFieldI(pct);
    logEnd();
  } else if (logCount >= 19 && logCount <= 22) {
    byte i = logCount - 19;
    logStart_P(LOGDATA);
    logField_P(PSTR("SETPOINT"));
    logFieldI(i);
    logFieldI(setpoint[i] / 100);
    #ifdef USEMETRIC
      logFieldI(0);
    #else
      logFieldI(1);
    #endif
    logEnd();
  } else if (logCount == 23) {
    logStart_P(LOGDATA);
    logField_P(PSTR("AUTOVLV"));
    byte modeMask = 0;
    for (byte i = AV_FILL; i <= AV_CHILL; i++)
      if (autoValve[i]) modeMask |= 1<<i;
    logFieldI(modeMask);
    logEnd();
    logStart_P(LOGDATA);
    logField_P(PSTR("VLVBITS"));
    logFieldI(vlvBits);
    logEnd();
  } else if (logCount == 24) {
    logStart_P(LOGDATA);
    logField_P(PSTR("VLVPRF"));
    unsigned int profileMask = 0;
    for (byte i = VLV_FILLHLT; i <= VLV_DRAIN; i++) 
      if (vlvConfig[i] != 0 && (vlvBits & vlvConfig[i]) == vlvConfig[i]) profileMask |= 1<<i;
    logFieldI(profileMask);
    logEnd();
    //Logic below times start of log to start of log. Interval is reset if exceeds two intervals.
    if (millis() - lastLog > LOG_INTERVAL * 2) lastLog = millis(); else lastLog += LOG_INTERVAL;
  }
  logCount++;
  if (logCount > 24) logCount = 0;  
}

#if defined USESERIAL
void logTSensor(byte sensor) {
  logStart_P(LOGCFG);
  logField_P(PSTR("TS_ADDR"));
  logFieldI(sensor);
  for (byte i=0; i<8; i++) logFieldI(tSensor[sensor][i]);
  logEnd();
}

void logOSet(byte vessel) {
  logStart_P(LOGCFG);
  logField_P(PSTR("OUTPUT_SET"));
  logFieldI(vessel);
  logFieldI(PIDEnabled[vessel]);
  logFieldI(PIDCycle[vessel]);
  logFieldI(getPIDp(vessel));
  logFieldI(getPIDi(vessel));
  logFieldI(getPIDd(vessel));
  logFieldI(hysteresis[vessel]);
  logEnd();
}

void logBoil() {
  logStart_P(LOGCFG);
  logField_P(PSTR("BOIL_TEMP"));
  logFieldI(getBoilTemp());
  #ifdef USEMETRIC
    logFieldI(0);
  #else
    logFieldI(1);
  #endif 
  logEnd();
}

void logVersion() {
  logStart_P(LOGSYS);
  logField_P(PSTR("VER"));
  logField_P(BTVER);
  logField(itoa(BUILD, buf, 10));
  logEnd();
}

void logVolCalib(byte vessel) {
  logStart_P(LOGCFG);
  logField_P(PSTR("VOL_CALIB"));
  logFieldI(vessel);

  for (byte i = 0; i < 10; i++) {
      logFieldI(calibVols[vessel][i]);
      logFieldI(calibVals[vessel][i]);
  }
  logEnd();
}

void logVSet(byte vessel) {
  logStart_P(LOGCFG);
  logField_P(PSTR("VOL_SET"));
  logFieldI(vessel);
  logFieldI(getCapacity(vessel));
  logFieldI(getVolLoss(vessel));  
  #ifdef USEMETRIC
    logFieldI(0);
  #else
    logFieldI(1);
  #endif
  logEnd();
}

void logEvap() {
  logStart_P(LOGCFG);
  logField_P(PSTR("EVAP_RATE"));
  logFieldI(getEvapRate());
  logEnd();
}

void logVlvConfig (byte profile) {
  logStart_P(LOGCFG);
  logField_P(PSTR("VLV_CONFIG"));
  logFieldI(profile);
  logFieldI(vlvConfig[profile]);  
  logEnd();
}

void logProgram(byte program) {
  logStart_P(LOGCFG);
  logField_P(PSTR("PROG_SET"));
  logFieldI(program);
  getProgName(program, buf);
  logField(buf);
  
  for (byte i = MASH_DOUGHIN; i <= MASH_MASHOUT; i++) {
    logFieldI(getProgMashTemp(program, i));
    logFieldI(getProgMashMins(program, i));
  }
  logFieldI(getProgSparge(program));
  logFieldI(getProgHLT(program));
  logFieldI(getProgBatchVol(program));
  logFieldI(getProgGrain(program));
  logFieldI(getProgBoil(program));
  logFieldI(getProgRatio(program));
  logFieldI(getProgPitch(program));
  logFieldI(getProgAdds(program));
  #ifdef USEMETRIC
    logFieldI(0);
  #else
    logFieldI(1);
  #endif
  logEnd();
}

#ifdef DEBUG_PID_GAIN
void logDebugPIDGain(byte vessel) {
  logStart_P(LOGDEBUG);
  logField_P(PSTR("PID_GAIN"));
  logFieldI(vessel);
  logFieldI(pid[vessel].GetP_Param());
  logFieldI(pid[vessel].GetI_Param());
  logFieldI(pid[vessel].GetD_Param());
  logEnd();
}
#endif

#ifdef DEBUG_VOLCALIB
void logVolCalib(char* logText, int value) {
  logStart_P(LOGDEBUG);
  logField(logText);
  logFieldI(value);  
  logEnd();
}
#endif

#endif
