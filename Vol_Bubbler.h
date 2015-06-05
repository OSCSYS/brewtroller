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

#ifndef Vol_Bubbler_h
#define Vol_Bubbler_h

#include "Outputs.h"

class Bubbler
{
  private:
    byte _outputIndex;
    unsigned int _duration, _readDelay;
    unsigned long _intervalStart, _interval;
    OutputSystem *_outputs;
   
  public:
    Bubbler(OutputSystem *outputs, byte outputIndex, byte interval, byte duration, byte readDelay) {
      _outputs = outputs;
      _outputIndex = outputIndex;
      _interval = interval * 1000ul;
      _duration = duration * 100u;
      _readDelay = readDelay * 100u;
      _intervalStart = 0;
    }
    boolean compute(void) {
      unsigned long timestamp = millis();
      
      //Check for first interval
      if (_interval == 0)
        _intervalStart = timestamp;
      
      //Check for new interval
      if (timestamp > _intervalStart + _interval)
        _intervalStart = timestamp;
      
      //Update output status      
      _outputs->setDiscreetState(_outputIndex, (timestamp > _intervalStart + _duration) ? 0 : 1);

      //Check if volume reads are enabled
      if (timestamp > _intervalStart + _duration + _readDelay)
        return 1;
      
      return 0;
    }
};


#endif
