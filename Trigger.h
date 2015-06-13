/*  
   Copyright (C) 2009 - 2012 Open Source Control Systems, Inc.

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


BrewTroller - Open Source Brewing Controller
Documentation, Forums and more information available at http://www.brewtroller.com
*/

#ifndef OT_Trigger_h
#define OT_Trigger_h

#include <Arduino.h>
#include <pin.h>

class Trigger
{
  protected:
    boolean activeLow;
    unsigned long filterBits;
    unsigned long disableMask;
    byte releaseHysteresis;
    unsigned long releaseMillis;
   
  public:
    virtual unsigned long compute(unsigned long filterValue);
    virtual boolean getRawValue(void) = 0;
};

class TriggerGPIO : public Trigger
{
  private:
  pin inputPin;
  
  public:
  TriggerGPIO(byte p, boolean aLow, unsigned long filter, unsigned long dMask, byte rHysteresis);
  ~TriggerGPIO();
  boolean getRawValue(void);
    
};

class TriggerValue : public Trigger
{
  private:
  unsigned long *value;
  unsigned long threshold;
  
  public:
  TriggerValue(unsigned long *v, unsigned long t, boolean aLow, unsigned long filter, unsigned long dMask, byte rHysteresis);
  ~TriggerValue();
  boolean getRawValue(void);
};

class TriggerSetpointDelay : public Trigger
{
  private:
  double *value;
  boolean tripped;
  
  public:
  TriggerSetpointDelay(double *v, boolean aLow, unsigned long filter, unsigned long dMask, byte rHysteresis);
  ~TriggerSetpointDelay();
  boolean getRawValue(void);
};
#endif
