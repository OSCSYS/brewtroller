#include "LOCAL_Menu.h"
#include <avr/pgmspace.h>

menu::menu(byte pageSize) {
	_pageSize = pageSize;
	_selected = 0;
	_topItem = 0;
}


/* Set selected by specifying index */
void menu::setSelected(byte index) {
	_selected = index;
}

/* Select by menu item value */
void menu::setSelectedByValue(byte value) {
	_selected = this->getIndexByValue(value);
}

/* Get selected menu item index */
byte menu::getSelected(void) {
	return _selected;
}

/* Update _topItem based on selection and pageSize */
boolean menu::refreshDisp(void) {
	if (_selected < _topItem) {
		_topItem = _selected;
		return 1;
	}
	if (_selected >= _topItem + _pageSize) {
		_topItem = _selected - _pageSize + 1;
		return 1;
	}
	return 0;
}

/* Get specified row's menu item text based on _topItem and _pageSize */
void menu::getVisibleRow(byte row, char retString[]) {
	this->refreshDisp();
	if (_topItem + row < getItemCount())
	  getItem(_topItem + row, retString);
	else
	  strcpy(retString, "");
}

/* Get menu item text for currently selected item */
char* menu::getSelectedRow(char retString[]) {
  return getItem(_selected, retString);
}

/* Get the value for the currently selected menu item */
byte menu::getValue() {
	return getItemValue(_selected);
}

/* Get the cursor position based on current selection, _topItem and _pageSize */
byte menu::getCursor(void) {
	this->refreshDisp();
	return _selected - _topItem;
}

/* Get menu item index based on specified menu item value */
byte menu::getIndexByValue(byte val) {
  for (byte i = 0; i < getItemCount(); i++)
  	if (getItemValue(i) == val)
		  return i;
}

//Default implementation uses index as value
//Override for custom values
byte menu::getItemValue(byte index) {
  return index;
}

menuPROGMEM::menuPROGMEM(byte pSize, const void *d, byte s) : menu(pSize) {
  PROGMEMData = d;
  menuSize = s;
}

byte menuPROGMEM::getItemCount(void) {
  return menuSize;
}

char* menuPROGMEM::getItem(byte index, char *retString) {
  byte option = getItemValue(index);
  strcpy_P(retString, (char*)pgm_read_word((((const char **)PROGMEMData) + option)));
}

menuPROGMEMSelection::menuPROGMEMSelection(byte pSize, const void *d, byte s, byte sel) : menu(pSize) {
  PROGMEMData = d;
  menuSize = s;
  currentSelection = sel;
}
byte menuPROGMEMSelection::getItemCount(void) {
  return menuSize;
}
char* menuPROGMEMSelection::getItem(byte index, char *retString) {
  byte option = getItemValue(index);
  strcpy(retString, index == currentSelection ? "*" : " ");
  strcat_P(retString, (char*)pgm_read_word((((const char **)PROGMEMData) + option)));
  return retString;
}

menuNumberedItemList::menuNumberedItemList(byte pSize, byte cSelection, byte c, const char *t) : menu(pSize) {
  currentSelection = cSelection;
  itemCount = c;
  itemText = t;
}

byte menuNumberedItemList::getItemCount(void) {
  return itemCount;
}

char* menuNumberedItemList::getItem(byte index, char *retString) {
  strcpy(retString, index == currentSelection ? "*" : " ");
  strcat_P(retString, itemText);
  char numText[4];
  strcat(retString, itoa(index + 1, numText, 10));
  return retString;
}

