/*  
   Copyright (C) 2009, 2010 Matt Reba, Jeremiah Dillingham

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

  Update 9/22/2010 to support enhanced functions and mutiple schemas.
  
*/

#if COMTYPE == 1

  // Using Values 65-90 & 97-122 for command codes to make terminal input easier 
  // but any value between 0-255 can be used with the following exceptions
  // Command Field Char		9	(Tab)
  // Command Term Char		10	(Line Feed)
  // Command Term Char		13	(Carriage Return)

  //Command codes for special responses
  #define CMD_REJECT        33	//!
  #define CMD_REJECT_PARAM  35	//#
  #define CMD_REJECT_CRC     42	//*

  #define CMD_GET_BOIL		    65 	//A
  #define CMD_GET_CAL		      66 	//B
  #define CMD_GET_EVAP		    67 	//C
  #define CMD_GET_OSET		    68 	//D
  #define CMD_GET_PROG		    69 	//E
  #define CMD_GET_TS		      70 	//F
  #define CMD_GET_VER		      71 	//G
  #define CMD_GET_VSET		    72 	//H
  #define CMD_INIT_EEPROM	    73 	//I
  #define CMD_SCAN_TS		      74 	//J
  #define CMD_SET_BOIL		    75 	//K
  #define CMD_SET_CAL		      76 	//L
  #define CMD_SET_EVAP		    77 	//M
  #define CMD_SET_OSET		    78 	//N
  #define CMD_SET_PROG		    79 	//O
  #define CMD_SET_TS		      80 	//P
  #define CMD_SET_VLVCFG	    81 	//Q
  #define CMD_SET_VSET		    82 	//R
  #define CMD_ADV_STEP		    83 	//S
  #define CMD_EXIT_STEP		    84 	//T
  #define CMD_INIT_STEP		    85 	//U
  #define CMD_SET_ALARM		    86 	//V
  #define CMD_SET_AUTOVLV	    87 	//W
  #define CMD_SET_SETPOINT	  88 	//X
  #define CMD_SET_TIMRERSTATUS	89 	//Y
  #define CMD_SET_TIMERVALUE	90 	//Z
  #define CMD_SET_VLV		      97 	//a
  #define CMD_SET_VLVPRF	    98 	//b
  #define CMD_RESET		        99 	//c
  #define CMD_GET_VLVCFG	    100 //d
  #define CMD_GET_ALARM		    101 	//e
  #define CMD_GET_BOILPWR	    102 	//f
  #define CMD_GET_DELAYTIME	  103 	//g
  #define CMD_GET_GRAINTEMP	  104 	//h
  #define CMD_SET_BOILPWR	    105 	//i
  #define CMD_SET_DELAYTIME	  106 	//j
  #define CMD_SET_GRAINTEMP	  107 	//k
  #define CMD_GET_CALCTEMPS	  108 	//l
  #define CMD_GET_CALCVOLS	  109 	//m
  #define CMD_STEPPRG		      110 	//n
  #define CMD_TIMER		        111 	//o
  #define CMD_VOL		          112 	//p
  #define CMD_TEMP		        113 	//q
  #define CMD_STEAM		        114 	//r
  #define CMD_HEATPWR		      115 	//s
  #define CMD_SETPOINT		    116 	//t
  #define CMD_AUTOVLV		      117 	//u
  #define CMD_VLVBITS		      118 	//v
  #define CMD_VLVPRF		      119 	//w
  
  #include "Config.h"
  #include "Enum.h"

  char cmdBuffer[255];
  byte cmdBufLen = 0;
  
  void updateLog() {
  #if defined USESERIAL
    while (Serial.available()) {
      byte byteIn = Serial.read();
      if (byteIn == 0x0D) {
        //End Byte: Carriage Return (\r)
        byte retValue = chkCmd();
        if (retValue) rejectCmd(retValue);
      } else cmdBuffer[cmdBufLen++] = byteIn;
    }
  #endif
  }
  
  void logStart_P (const char *sType) {
  #if defined USESERIAL
  cmdBufLen = 0;
  logField_P(sType);
  #endif
  }

  //Sends Response queued in cmdBuffer
  void logEnd() {
  #if defined USESERIAL
   Serial.print(millis(),DEC);
   Serial.write(0x09);
   for (byte pos = 0; pos < cmdBufLen; pos++) Serial.write(cmdBuffer[pos]);
   Serial.write(0x0D); //Carriage Return
   Serial.write(0x0A); //New Line
  #endif
   cmdBufLen = 0;
  }
  
  void rejectCmd(byte rejectCode) {
    //Unknown Command: Set First param to received command code, set response command code to CMD_REJECT and set message length to 3;
    byte cmdCode = cmdBuffer[0];
    cmdBufLen = 0;
    cmdBuffer[cmdBufLen++] = rejectCode;
    logFieldI(cmdCode);
    logEnd();  
  }
  
  void sendOK() {
    //Simple ACK by returning received command code
    cmdBufLen = 1;
    logEnd();
  }
  
  void logFieldI(unsigned long param) {
    ultoa(param, buf, 10);
    if (cmdBufLen) cmdBuffer[cmdBufLen++] = 0x09;  //Tab Char
    for (byte pos = 0; pos < strlen(buf); pos++) cmdBuffer[cmdBufLen++] = buf[pos];
  }
  
  void logField(char string[]) {
    if (cmdBufLen) cmdBuffer[cmdBufLen++] = 0x09;  //Tab Char
    for (byte pos = 0; pos < strlen(string); pos++) cmdBuffer[cmdBufLen++] = string[pos];
  }
  
  void logField_P(const char *string) {
    if (cmdBufLen) cmdBuffer[cmdBufLen++] = 0x09;  //Tab Char
    while (pgm_read_byte(string) != 0) cmdBuffer[cmdBufLen++] = pgm_read_byte(string++);
  }
  
  #if COMSCHEMA == 21
  boolean chkCRC() {
    //Trunc CRC Field
    return 0;
  }
  #endif
  
  byte getCmdParamCount() {
    byte paramCount = 0;
    for (byte pos = 0; pos < cmdBufLen; pos++) if (cmdBuffer[pos] == 0x09) paramCount++;
    return paramCount;
  }
  
  char* getCmdParam(byte paramNum, char retStr[], byte limit) {
    byte pos = 0;
    byte param = 0;
    while (pos < cmdBufLen && param < paramNum) { if (cmdBuffer[pos++] == 0x09) param++; }
    byte retPos = 0;
    while (pos < cmdBufLen && cmdBuffer[pos] != 0x09 && retPos < limit) { retStr[retPos++] = cmdBuffer[pos++]; }
    retStr[retPos] = '\0';
    return retStr;
  }
  
  unsigned long getCmdParamNum(byte paramNum) {
    getCmdParam(paramNum, buf, 10);
    return strtoul(buf, NULL, 10);
  }
  
  //Check and process command. Return error code (0 if OK)
  byte chkCmd() {
    #if COMSCHEMA == 21
      if(chkCRC()) return CMD_REJECT_CRC;
    #endif
    
    //No Param Commands with built responses
    if(cmdBuffer[0] == CMD_GET_BOIL
      || cmdBuffer[0] == CMD_GET_EVAP
      || cmdBuffer[0] == CMD_INIT_EEPROM
      || cmdBuffer[0] == CMD_SCAN_TS
      || cmdBuffer[0] == CMD_GET_ALARM
      || cmdBuffer[0] == CMD_GET_BOILPWR
      || cmdBuffer[0] == CMD_GET_DELAYTIME
      || cmdBuffer[0] == CMD_GET_GRAINTEMP
      || cmdBuffer[0] == CMD_STEPPRG
      || cmdBuffer[0] == CMD_STEAM
      || cmdBuffer[0] == CMD_VLVBITS
      || cmdBuffer[0] == CMD_AUTOVLV
      || cmdBuffer[0] == CMD_VLVPRF
    ) {
      if (getCmdParamCount() != 0) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      if(cmdBuffer[0] == CMD_GET_BOIL) logFieldI(getBoilTemp());
      else if (cmdBuffer[0] == CMD_GET_EVAP) logFieldI(getEvapRate());
      else if (cmdBuffer[0] == CMD_INIT_EEPROM) initEEPROM();
      else if (cmdBuffer[0] == CMD_SCAN_TS) {
        byte tsAddr[8];
        getDSAddr(tsAddr);
        for (byte i=0; i<8; i++) logFieldI(tsAddr[i]);
      }
      else if (cmdBuffer[0] == CMD_GET_ALARM) logFieldI(alarmStatus);
      else if (cmdBuffer[0] == CMD_GET_BOILPWR) logFieldI(boilPwr);
      else if (cmdBuffer[0] == CMD_GET_DELAYTIME) logFieldI(getDelayMins());
      else if (cmdBuffer[0] == CMD_GET_GRAINTEMP) logFieldI(getGrainTemp());
      else if (cmdBuffer[0] == CMD_STEPPRG) { for (byte i = 0; i < NUM_BREW_STEPS; i++) logFieldI(stepProgram[i]); }
	  #ifdef PID_FLOW_CONTROL
	  else if (cmdBuffer[0] == CMD_STEAM) logFieldI(flowRate[VS_MASH]);
	  #else
      else if (cmdBuffer[0] == CMD_STEAM) logFieldI(steamPressure);
	  #endif
      else if (cmdBuffer[0] == CMD_VLVBITS) logFieldI(computeValveBits());
      else if (cmdBuffer[0] == CMD_AUTOVLV) {
        byte modeMask = 0;
        for (byte i = AV_FILL; i <= AV_HLT; i++)
          if (autoValve[i]) modeMask |= 1<<i;
        logFieldI(modeMask);
      } 
      else if (cmdBuffer[0] == CMD_VLVPRF) {
        logFieldI(actProfiles);
      }
      logEnd();
    }
    
    //1 Param, No check, SendOK
    else if (cmdBuffer[0] == CMD_SET_BOIL
      || cmdBuffer[0] == CMD_SET_BOILPWR
      || cmdBuffer[0] == CMD_SET_ALARM
      || cmdBuffer[0] == CMD_SET_AUTOVLV
      || cmdBuffer[0] == CMD_SET_EVAP
      || cmdBuffer[0] == CMD_RESET
      || cmdBuffer[0] == CMD_SET_DELAYTIME
      || cmdBuffer[0] == CMD_SET_GRAINTEMP
    ) {
      if (getCmdParamCount() != 1) return CMD_REJECT_PARAM;
      if (cmdBuffer[0] == CMD_SET_BOIL) setBoilTemp(getCmdParamNum(1));
      else if (cmdBuffer[0] == CMD_SET_BOILPWR) setBoilPwr(getCmdParamNum(1));
      else if (cmdBuffer[0] == CMD_SET_ALARM) setAlarm(getCmdParamNum(1));
      else if (cmdBuffer[0] == CMD_SET_AUTOVLV) {
        byte actModes = getCmdParamNum(1);
        for (byte i = AV_FILL; i <= AV_HLT; i++) 
          autoValve[i] = (actModes & (1<<i));
      }
      else if (cmdBuffer[0] == CMD_SET_EVAP) setEvapRate(min(getCmdParamNum(1), 100));
      else if (cmdBuffer[0] == CMD_SET_DELAYTIME) setDelayMins(getCmdParamNum(1));
      else if (cmdBuffer[0] == CMD_SET_GRAINTEMP) setGrainTemp(getCmdParamNum(1));
      sendOK();
      //Do Reset Logic after SendOK due to softReset() aborting further procesing
      if (cmdBuffer[0] == CMD_RESET) {
        //Reboot (1) or just Reset Outputs?
        if (getCmdParamNum(1) == 1) softReset();
        else {
          resetOutputs();
          clearTimer(TIMER_MASH);
          clearTimer(TIMER_BOIL);
        }
      }
    } 
  
    //1 Param, HLT-Kettle
    else if (cmdBuffer[0] == CMD_GET_CAL
      || cmdBuffer[0] == CMD_GET_VSET
      || cmdBuffer[0] == CMD_VOL
      || cmdBuffer[0] == CMD_TEMP
    ) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || vessel > VS_KETTLE) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      logFieldI(vessel);
      if (cmdBuffer[0] == CMD_GET_CAL) {
        for (byte i = 0; i < 10; i++) {
            logFieldI(calibVols[vessel][i]);
            logFieldI(calibVals[vessel][i]);
        }
      } 
      else if (cmdBuffer[0] == CMD_GET_VSET) {
        logFieldI(getCapacity(vessel));
        logFieldI(getVolLoss(vessel));  
      } 
      else if (cmdBuffer[0] == CMD_VOL) {
        logFieldI(volAvg[vessel]);
        #ifdef FLOWRATE_CALCS
          logFieldI(flowRate[vessel]);
        #else
          logFieldI(0);
        #endif
      } 
      else if (cmdBuffer[0] == CMD_TEMP) logFieldI(temp[vessel]);
      logEnd();
    } 
  
    //1 Param, HLT-Steam
    else if (cmdBuffer[0] == CMD_GET_OSET
      || cmdBuffer[0] == CMD_HEATPWR
      || cmdBuffer[0] == CMD_SETPOINT
    ) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || vessel > VS_STEAM) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      logFieldI(vessel);
      if (cmdBuffer[0] == CMD_GET_OSET) {
        logFieldI(PIDEnabled[vessel]);
        logFieldI(PIDCycle[vessel]);
        logFieldI(getPIDp(vessel));
        logFieldI(getPIDi(vessel));
        logFieldI(getPIDd(vessel));
        if (vessel == VS_STEAM) {
          logFieldI(getSteamTgt());
          #ifndef PID_FLOW_CONTROL
          logFieldI(steamZero);
          logFieldI(steamPSens);
          #endif
        } 
        else {
          logFieldI(hysteresis[vessel]);
          logFieldI(0);
          logFieldI(0);
        }
      } 
      else if (cmdBuffer[0] == CMD_HEATPWR) {
        byte pct;
        if (PIDEnabled[vessel]) pct = PIDOutput[vessel] / PIDCycle[vessel];
        else if (heatStatus[vessel]) pct = 100;
        else pct = 0;
        logFieldI(pct);
      } 
      else if (cmdBuffer[0] == CMD_SETPOINT) logFieldI(setpoint[vessel] / SETPOINT_MULT);
      logEnd();
    } 
  
    //1 Param, Step
    else if (cmdBuffer[0] == CMD_ADV_STEP || cmdBuffer[0] == CMD_EXIT_STEP) {
      byte stepNum = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || stepNum >= NUM_BREW_STEPS) return CMD_REJECT_PARAM;
      if (cmdBuffer[0] == CMD_ADV_STEP) stepAdvance(stepNum); else stepExit(stepNum);
      sendOK();
    } 
      
    //Unique Commands
    else if (cmdBuffer[0] == CMD_SET_OSET) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 9 || vessel > VS_STEAM) return CMD_REJECT_PARAM;
      setPIDEnabled(vessel, getCmdParamNum(2));
      setPIDCycle(vessel, getCmdParamNum(3));
      setPIDp(vessel, getCmdParamNum(4));
      setPIDi(vessel, getCmdParamNum(5));
      setPIDd(vessel, getCmdParamNum(6));
      if (vessel == VS_STEAM) {
        setSteamZero(getCmdParamNum(7));
        setSteamTgt(getCmdParamNum(8));
        setSteamPSens(getCmdParamNum(9));
      } 
      else {
        setHysteresis(vessel, getCmdParamNum(7));
      }
      sendOK();
    } 
    
    //One Param, Program Number
    else if (cmdBuffer[0] == CMD_GET_PROG
      || cmdBuffer[0] == CMD_GET_CALCTEMPS
      || cmdBuffer[0] == CMD_GET_CALCVOLS
    ) {
      byte program = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || program > 20) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      if (cmdBuffer[0] == CMD_GET_PROG) {
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
        logFieldI(getProgMLHeatSrc(program));
      } 
      else if (cmdBuffer[0] == CMD_GET_CALCTEMPS) {
        logFieldI(program);
        logFieldI(calcStrikeTemp(program));
        logFieldI(getFirstStepTemp(program));
      } 
      else if (cmdBuffer[0] == CMD_GET_CALCVOLS) {
        logFieldI(program);
        logFieldI(calcGrainVolume(program));
        logFieldI(calcGrainLoss(program));
        logFieldI(calcPreboilVol(program));
        logFieldI(calcStrikeVol(program));
        logFieldI(calcSpargeVol(program));
      }
      logEnd();
    } 
    
    else if (cmdBuffer[0] == CMD_SET_PROG) {
      byte program = getCmdParamNum(1);
      if (getCmdParamCount() != 23 || program > 20) return CMD_REJECT_PARAM;
        char pName[20];
        getCmdParam(2, pName, 19);
        setProgName(program, pName);
        for (byte i = MASH_DOUGHIN; i <= MASH_MASHOUT; i++) {
          setProgMashTemp(program, i, getCmdParamNum(i * 2 + 3));
          setProgMashMins(program, i, getCmdParamNum(i * 2 + 4));
        }
        setProgSparge(program, getCmdParamNum(15));
        setProgHLT(program, getCmdParamNum(16));
        setProgBatchVol(program, getCmdParamNum(17));
        setProgGrain(program, getCmdParamNum(18));
        setProgBoil(program, getCmdParamNum(19));
        setProgRatio(program, getCmdParamNum(20));
        setProgPitch(program, getCmdParamNum(21));
        setProgAdds(program, getCmdParamNum(22));
        setProgMLHeatSrc(program, getCmdParamNum(23));
        sendOK();
    } 
    else if (cmdBuffer[0] == CMD_GET_TS) {
      byte sensor = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || sensor > TS_AUX3) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      logFieldI(sensor);
      for (byte i=0; i<8; i++) logFieldI(tSensor[sensor][i]);
      logEnd();
    } 
    else if (cmdBuffer[0] == CMD_SET_TS) {
      byte sensor = getCmdParamNum(1);
      if (getCmdParamCount() != 9 || sensor > TS_AUX3) return CMD_REJECT_PARAM;
      byte addr[8];
      for (byte i=0; i<8; i++) addr[i] = (byte)getCmdParamNum(i+2);
      setTSAddr(sensor, addr);
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_GET_VLVCFG) {
      byte profile = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || profile > VLV_HLTHEAT) return CMD_REJECT_PARAM;
      cmdBufLen = 1; //Reuse CMD code
      logFieldI(profile);
      logFieldI(vlvConfig[profile]);  
      logEnd();
    } 
    else if (cmdBuffer[0] == CMD_SET_VLVCFG) {
      byte profile = getCmdParamNum(1);
      if (getCmdParamCount() != 2 || profile > VLV_HLTHEAT) return CMD_REJECT_PARAM;
      setValveCfg(profile, getCmdParamNum(2));
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_SET_CAL) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 21 || vessel > VS_KETTLE) return CMD_REJECT_PARAM;
      for (byte i = 0; i < 10; i++) setVolCalib(vessel, i, getCmdParamNum(i * 2 + 3), getCmdParamNum(i * 2 + 2));
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_SET_VSET) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 3 || vessel > VS_KETTLE) return CMD_REJECT_PARAM;
      setCapacity(vessel, getCmdParamNum(2));
      setVolLoss(vessel, getCmdParamNum(3));
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_INIT_STEP) {
      byte progNum = getCmdParamNum(1);
      byte stepNum = getCmdParamNum(2);
      if (getCmdParamCount() != 2 || stepNum >= NUM_BREW_STEPS || progNum >= 20) return CMD_REJECT_PARAM;
      stepInit(progNum, stepNum);
      sendOK();    
    } 
    else if (cmdBuffer[0] == CMD_SET_SETPOINT) {
      byte vessel = getCmdParamNum(1);
      if (getCmdParamCount() != 2 || vessel > VS_STEAM) return CMD_REJECT_PARAM;
      setSetpoint(vessel, getCmdParamNum(2));
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_SET_TIMRERSTATUS || cmdBuffer[0] == CMD_SET_TIMERVALUE) {
      byte timer = getCmdParamNum(1);
      if (getCmdParamCount() != 2 || timer > TIMER_BOIL) return CMD_REJECT_PARAM;
      if (cmdBuffer[0] == CMD_SET_TIMRERSTATUS) setTimerStatus(timer, getCmdParamNum(2)); 
      else {
        timerValue[timer] = getCmdParamNum(2);
        lastTime[timer] = millis();
      }
      sendOK();
    } 
    else if (cmdBuffer[0] == CMD_TIMER) {
      byte timer = getCmdParamNum(1);
      if (getCmdParamCount() != 1 || timer > TIMER_BOIL) return CMD_REJECT_PARAM;
      logFieldI(timer);
      logFieldI(timerValue[timer]);
      logFieldI(timerStatus[timer]);
      logEnd();
    } 
    else if (cmdBuffer[0] == CMD_SET_VLV) {
      return CMD_REJECT_PARAM; //Command no longer supported
    } 
    else if (cmdBuffer[0] == CMD_SET_VLVPRF) {
      if (getCmdParamCount() != 2) return CMD_REJECT_PARAM;
      //Check param 2 (value) and set/unset specified active profiles
      if (getCmdParamNum(2)) actProfiles |= getCmdParamNum(1);
      else actProfiles &= ~getCmdParamNum(1);
      sendOK();
    } 

    // log ASCII version "GET_VER"
    else if (strcasecmp(getCmdParam(0, buf, 20), "GET_VER") == 0) {
      logASCIIVersion();
      cmdBufLen = 0;
    }

    // log BTNic Version "G"
    else if (cmdBuffer[0] == CMD_GET_VER) {
      cmdBufLen = 1; //Reuse CMD code
      logField_P(BTVER);
      logFieldI(BUILD);
      logFieldI(COMTYPE);  // Protocol Type
      logFieldI(COMSCHEMA);// Protocol Schema
      #ifdef USEMETRIC
        logFieldI(0);
      #else
        logFieldI(1);
      #endif
      logEnd();
    }
    
   else
      return CMD_REJECT; //Reject Command Code (CMD_REJECT);

    return 0;
  }
#endif
