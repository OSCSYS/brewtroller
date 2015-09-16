# brewtroller
BrewTroller Open Source Brewing Control System

## develop Branch
This branch represents the latest development release of BrewTroller. This branch has had minimal testing and may include bugs. Your help testing develop releases is appreciated. After a development release has been tested by the user community it will be promoted to the master (stable) branch.

## Uploading Code
As of Arduino 1.6 and BrewTroller v2.7 Build 11 a customized Arduino is no longer required.

* Download Arduino official package.
* Add third-party Board Manager URL in Arduino Preferences:
  *  https://github.com/OSCSYS/boards/raw/master/package_OSCSYS_Boards_index.json
* Select BrewTroller/OpenTroller from Boards menu.

## More Information
See [BrewTroller User Manual (develop)](https://github.com/OSCSYS/brewtroller/wiki/BrewTroller-v2.7-Manual-%28develop%29)

## Contributors
BrewTroller is the collective work of a handful of developers and a much larger group of users. I'd like to specifically thank the following users who have contributed directly to BrewTroller. If I've missed someone it is entirely my error. Please open an issue and remind me.

 * Jeremiah Dillingham
 * Jason Vreeland
 * Jason von Nieda
 * Keith Mycek
 * Martin Leblanc
 * Tom Harkaway
 * Devon Dallmann
 * Timothy Reaves
 * Adam Shake
 * Eric Yanush
 * Allan Marshall


Some key formulas used in BrewTroller calculations came from the following books: 

 * _How to Brew_ by John Palmer
 * _Designing Great Beers_ by Ray Daniels

A slew of libraries developed by members of the Arduino community are used in this project. Some of the more prominent examples include:

  * PID - Brett Beauregard
  * PID Autotune - Brett Beauregard, Tom Price (fork)
  * DS2482 - Paeae Technologies
  * ModbusMaster - Doc Walker
  * OneWire - Jim Studt, Paul Stoffregen