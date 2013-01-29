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

Compiled on Arduino-0017 (http://arduino.cc/en/Main/Software)
With Sanguino Software v1.4 (http://code.google.com/p/sanguino/downloads/list)
using PID Library v0.6 (Beta 6) (http://www.arduino.cc/playground/Code/PIDLibrary)
using OneWire Library (http://www.arduino.cc/playground/Learning/OneWire)
*/


void logPLR() {
  logStart_P(LOGGLB);
  logField_P(PSTR("PLR"));
  logFieldI(pwrRecovery);
  logEnd();
}

void logPgm() {
  logStart_P(LOGDATA);
  logField_P(PSTR("PGM"));
  logFieldI(pwrRecovery);
  logEnd();
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
        //Check for Global Commands
        if       (strcasecmp(msg[0], "GET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= TS_HLT && val <= TS_AUX2) {
            logTSensor(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_TS") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 9 && val >= TS_HLT && val <= TS_AUX2) {
            for (byte i=0; i<8; i++) tSensor[val][i] = (byte)atoi(msg[i+2]);
            saveSetup();
            clearMsg();
            logTSensor(val);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SCAN_TS") == 0) {
          byte tsAddr[8] = {0, 0, 0, 0, 0, 0, 0, 0};
          getDSAddr(tsAddr);
          logStart_P(LOGGLB);
          logField_P(PSTR("TS_SCAN"));
          for (byte i=0; i<8; i++) logFieldI(tsAddr[i]);
          logEnd();
        } else if(strcasecmp(msg[0], "GET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_STEAM) {
            logOSet(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_OSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 7 && val >= VS_HLT && val <= VS_STEAM) {
            PIDEnabled[val] = (byte)atoi(msg[2]);
            PIDCycle[val] = (byte)atoi(msg[3]);
            PIDp[val] = (byte)atoi(msg[4]);
            PIDi[val] = (byte)atoi(msg[5]);
            PIDd[val] = (byte)atoi(msg[6]);
            hysteresis[val] = (byte)atoi(msg[7]);
            saveSetup();
            clearMsg();
            logOSet(val);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_BOIL") == 0) {
          logBoil();
          clearMsg();
        } else if(strcasecmp(msg[0], "SET_BOIL") == 0) {
          if (msgField == 1) {
            byte val = atoi(msg[1]);
            setBoilTemp(val);
            clearMsg();
            logBoil();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_VSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_KETTLE) {
            logVSet(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_VSET") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 3 && val >= VS_HLT && val <= VS_STEAM) {
            capacity[val] = strtoul(msg[2], NULL, 10);
            volLoss[val] = atol(msg[3]);
            saveSetup();
            clearMsg();
            logVSet(val);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_CAL") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= VS_HLT && val <= VS_KETTLE) {
            logVolCalib(val);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_CAL") == 0) {
          byte vessel = atoi(msg[1]);
          if (msgField == 21 && vessel >= VS_HLT && vessel <= VS_KETTLE) {
            for (byte i = 0; i < 10; i++) {
              calibVols[vessel][i] = strtoul(msg[i * 2 + 2], NULL, 10);
              calibVals[vessel][i] = atol(msg[i * 2 + 3]);
              saveSetup();
            }
            clearMsg();
            logVolCalib(vessel);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_EVAP") == 0) {
          logEvap();
          clearMsg();
        } else if(strcasecmp(msg[0], "SET_EVAP") == 0) {
          byte val = atoi(msg[1]);
          if (msgField == 1 && val >= 0 && val <= 100) {
            evapRate = val;
            saveSetup();
            clearMsg();
            logEvap();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_VLVP") == 0) {
          byte profile = atoi(msg[1]);
          if (msgField == 1 && profile >= VLV_FILLHLT && profile <= VLV_DRAIN) {
            logVlvProfile(profile);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_VLVP") == 0) {
          byte profile = atoi(msg[1]);
          if (msgField == 2 && profile >= VLV_FILLHLT && profile <= VLV_DRAIN) {
            vlvConfig[profile] = strtoul(msg[2], NULL, 10);
            saveSetup();
            clearMsg();
            logVlvProfile(profile);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_ABSET") == 0) {
          clearMsg();
          logABSettings();
        } else if(strcasecmp(msg[0], "SET_ABSET") == 0) {
          if (msgField == 18) {
            byte stepTemp[4], stepMins[4];
            for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) {
              stepTemp[i] = atoi(msg[i * 2 + 1]);
              stepMins[i] = atoi(msg[i * 2 + 2]);
            }
            saveABSteps(stepTemp, stepMins);
            setABSparge(atoi(msg[9]));
            setABDelay(atol(msg[10]));
            setABHLTTemp(atoi(msg[11]));
            setABBatchVol(strtoul(msg[12], NULL, 10));
            setABGrain(strtoul(msg[13], NULL, 10));
            setABBoil(atol(msg[14]));
            setABRatio(atol(msg[15]));
            setABPitch(atoi(msg[16]));
            setABAdds(atol(msg[17]));
            setABGrainTemp(atoi(msg[18]));
            clearMsg();
            logABSettings();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_PROG") == 0) {
          byte program = atoi(msg[1]);
          if (msgField == 1 && program >= 0 && program < 30) {
            logProgram(program);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_PROG") == 0) {
          byte program = atoi(msg[1]);
          if (msgField == 20 && program >= 0 && program < 30) {
            setProgName(program, msg[2]);
            byte stepTemp[4], stepMins[4];
            for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) {
              stepTemp[i] = atoi(msg[i * 2 + 3]);
              stepMins[i] = atoi(msg[i * 2 + 4]);
            }
            setProgSchedule(program, stepTemp, stepMins);
            setProgSparge(program, atoi(msg[11]));
            setProgDelay(program, atol(msg[12]));
            setProgHLT(program, atoi(msg[13]));
            setProgBatchVol(program, strtoul(msg[14], NULL, 10));
            setProgGrain(program, strtoul(msg[15], NULL, 10));
            setProgBoil(program, atol(msg[16]));
            setProgRatio(program, atol(msg[17]));
            setProgPitch(program, atoi(msg[18]));
            setProgAdds(program, atol(msg[19]));
            setProgGrainT(program, atoi(msg[20]));
            clearMsg();
            logProgram(program);
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_UNIT") == 0) {
          clearMsg();
          logStart_P(LOGGLB);
          logField_P(PSTR("UNIT"));
          #ifdef USEMETRIC
            logFieldI(0);
          #else
            logFieldI(1);
          #endif
          logEnd();
        } else if(strcasecmp(msg[0], "RESET") == 0) {
          if (msgField == 1 && strcasecmp(msg[1], "SURE") == 0) {
            clearMsg();
            logStart_P(LOGSYS);
            logField_P(PSTR("SOFT_RESET"));
            logEnd();
            softReset();
          }
        } else if(strcasecmp(msg[0], "GET_ABSTEP") == 0) {
          clearMsg();
          logABStep();
        } else if(strcasecmp(msg[0], "SET_ABSTEP") == 0) {
          byte ABStep = atoi(msg[1]);
          if (msgField == 1 && ABStep >= 0 && ABStep <= 12) {
            setABRecovery(ABStep);
            clearMsg();
            logABStep();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "GET_PLR") == 0) {
          clearMsg();
          logPLR();
        } else if(strcasecmp(msg[0], "SET_PLR") == 0) {
          byte PLR = atoi(msg[1]);
          if (msgField == 1 && PLR >= 0 && PLR <= 2) {
            setPwrRecovery(PLR);
            clearMsg();
            logPLR();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "PING") == 0) {
          clearMsg();
          logStart_P(LOGGLB);
          logField_P(PSTR("PONG"));
          logEnd();
        } else if(strcasecmp(msg[0], "SET_SETPOINT") == 0) {
          byte vessel = atoi(msg[1]);
          if (msgField == 2 && vessel <= VS_KETTLE) {
            setpoint[vessel] = (byte)atoi(msg[2]);
            saveSetpoints();
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_TIMERVALUE") == 0) {
          if (msgField == 1) {
            timerValue = strtoul(msg[1], NULL, 10);
            lastTime = millis();
            timerLastWrite = 0;
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_TIMERSTATUS") == 0) {
          if (msgField == 1) {
            timerStatus = (boolean)atoi(msg[1]);
            lastTime = millis();
            timerLastWrite = 0;
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_AUTOVLV") == 0) {
          byte avSet = atoi(msg[1]);
          if (msgField == 1 && avSet >= AV_OFF && avSet <= AV_CHILL) {
            autoValve = avSet;
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "ACT_VLV") == 0) {
          if (msgField == 1) {
            setValves(strtoul(msg[1], NULL, 10));
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "ACT_VLVPRF") == 0) {
          if (msgField == 1) {
            unsigned long newBits = 0;
            unsigned long actProfiles = strtoul(msg[1], NULL, 10);
            for (byte i = VLV_FILLHLT; i <= VLV_DRAIN; i++) 
              if ((actProfiles & 1<<i)) newBits |= vlvConfig[i];
            setValves(newBits);
            clearMsg();
          } else rejectParam(LOGGLB);
        } else if(strcasecmp(msg[0], "SET_ALARM") == 0) {
          if (msgField == 1) {
            setAlarm((boolean)atoi(msg[1]));
            clearMsg();
          } else rejectParam(LOGGLB);
        }
        break;
      } else if (byteIn == '\t') {
        if (msgField < 25) {
          msgField++;
        } else {
          logString_P(LOGCMD, PSTR("MSG_OVERFLOW"));
          clearMsg();
        }
      } else {
        byte charCount = strlen(msg[msgField]);
        if (charCount < 20) { 
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
  for (byte i = 0; i < 20; i++) msg[i][0] = '\0';
}

void rejectMsg(const char *handler) {
  logStart_P(LOGCMD);
  logField_P(PSTR("UNKNOWN_CMD"));
  logField_P(handler);
  for (byte i = 0; i < msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
}

void rejectParam(const char *handler) {
  logStart_P(LOGCMD);
  logField_P(PSTR("BAD_PARAM"));
  logField_P(handler);
  for (byte i = 0; i <= msgField; i++) logField(msg[i]);
  logEnd();
  clearMsg();
}

#if defined USESERIAL
void logTSensor(byte sensor) {
  logStart_P(LOGGLB);
  logField_P(PSTR("TS_ADDR"));
  logFieldI(sensor);
  for (byte i=0; i<8; i++) logFieldI(tSensor[sensor][i]);
  logEnd();
}

void logOSet(byte vessel) {
  logStart_P(LOGGLB);
  logField_P(PSTR("OUTPUT_SET"));
  logFieldI(vessel);
  logFieldI(PIDEnabled[vessel]);
  logFieldI(PIDCycle[vessel]);
  logFieldI(PIDp[vessel]);
  logFieldI(PIDi[vessel]);
  logFieldI(PIDd[vessel]);
  logFieldI(hysteresis[vessel]);
  logEnd();
}

void logBoil() {
  logStart_P(LOGGLB);
  logField_P(PSTR("BOIL_TEMP"));
  logFieldI(getBoilTemp());
  logEnd();
}

void logVolCalib(byte vessel) {
  logStart_P(LOGGLB);
  logField_P(PSTR("VOL_CALIB"));
  logFieldI(vessel);

  for (byte i = 0; i < 10; i++) {
      logFieldI(calibVols[vessel][i]);
      logFieldI(calibVals[vessel][i]);
  }
  logEnd();
}

void logVSet(byte vessel) {
  logStart_P(LOGGLB);
  logField_P(PSTR("VOL_SET"));
  logFieldI(vessel);
  logFieldI(capacity[vessel]);
  logFieldI(volLoss[vessel]);
  logEnd();
}

void logEvap() {
  logStart_P(LOGGLB);
  logField_P(PSTR("EVAP_RATE"));
  logFieldI(evapRate);
  logEnd();
}

void logVlvProfile (byte profile) {
  logStart_P(LOGGLB);
  logField_P(PSTR("VLV_PROFILE"));
  logFieldI(profile);
  logFieldI(vlvConfig[profile]);  
  logEnd();
}

void logABSettings() {
  byte stepTemp[4], stepMins[4];
  loadABSteps(stepTemp, stepMins);
  
  logStart_P(LOGGLB);
  logField_P(PSTR("AB_SET"));
  for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) {
    logFieldI(stepTemp[i]);
    logFieldI(stepMins[i]);
  }
  logFieldI(getABSparge());
  logFieldI(getABDelay());
  logFieldI(getABHLTTemp());
  logFieldI(getABBatchVol());
  logFieldI(getABGrain());
  logFieldI(getABBoil());
  logFieldI(getABRatio());
  logFieldI(getABPitch());
  logFieldI(getABAdds());
  logFieldI(getABGrainTemp());
  logEnd();
}

void logProgram(byte program) {
  byte stepTemp[4], stepMins[4];
  getProgSchedule(program, stepTemp, stepMins);
  
  logStart_P(LOGGLB);
  logField_P(PSTR("PROG_SET"));
  logFieldI(program);
  getProgName(program, buf);
  logField(buf);
  
  for (byte i = STEP_DOUGHIN; i <= STEP_MASHOUT; i++) {
    logFieldI(stepTemp[i]);
    logFieldI(stepMins[i]);
  }
  logFieldI(getProgSparge(program));
  logFieldI(getProgDelay(program));
  logFieldI(getProgHLT(program));
  logFieldI(getProgBatchVol(program));
  logFieldI(getProgGrain(program));
  logFieldI(getProgBoil(program));
  logFieldI(getProgRatio(program));
  logFieldI(getProgPitch(program));
  logFieldI(getProgAdds(program));
  logFieldI(getProgGrainT(program));
  logEnd();
}

void logABStep() {
  logStart_P(LOGGLB);
  logField_P(PSTR("AB_STEP"));
  logFieldI(recoveryStep);
  logEnd();
}
#endif
