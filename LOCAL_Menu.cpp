#include "LOCAL_Menu.h"
#include <avr/pgmspace.h>

menu::menu(byte pageSize, byte maxOpts) {
	_pageSize = pageSize;
	_itemCount = 0;
	_selected = 0;
	_topItem = 0;
	_maxOpts = maxOpts;
	_menuItems = (menuItem *) malloc(_maxOpts * sizeof(menuItem));
}

menu::~menu() {
	free(_menuItems);
}

/* Adds or updates a menu item (based on unique value) */
void menu::setItem(char disp[], byte value) {
	byte index = this->getIndexByValue(value);
	if (index >= _maxOpts) return;
	strcpy(_menuItems[index].name, disp);
	_menuItems[index].value = value;
	if (index == _itemCount) _itemCount++;
}

void menu::setItem_P(const char *disp, byte value) {
	byte index = this->getIndexByValue(value);
	if (index >= _maxOpts) return;
	strcpy_P(_menuItems[index].name, disp);
	_menuItems[index].value = value;
	if (index == _itemCount) _itemCount++;
}

/* Appends text to an existing menu item */
void menu::appendItem(char disp[], byte value) {
	byte index = this->getIndexByValue(value);
	if (index == _itemCount) return;
	strcat(_menuItems[index].name, disp);
}

void menu::appendItem_P(const char *disp, byte value) {
	byte index = this->getIndexByValue(value);
	if (index == _itemCount) return;
	strcat_P(_menuItems[index].name, disp);
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
	if (_topItem + row < _itemCount) strcpy(retString, _menuItems[_topItem + row].name);
	else strcpy(retString, "");
}

/* Get menu item text for currently selected item */
char* menu::getSelectedRow(char retString[]) {
	strcpy(retString, _menuItems[_selected].name);
	return (char*)_menuItems[_selected].name;
}

/* Get the value for the currently selected menu item */
byte menu::getValue() {
	return _menuItems[_selected].value;
}

/* Get the cursor position based on current selection, _topItem and _pageSize */
byte menu::getCursor(void) {
	this->refreshDisp();
	return _selected - _topItem;
}

/* Get total number of defined menu items */
byte menu::getItemCount(void) {
	return _itemCount;
}

/* Get menu item index based on specified menu item value */
byte menu::getIndexByValue(byte val) {
	if (_itemCount) {
		for (byte i = 0; i < _itemCount; i++) {
			if (_menuItems[i].value == val) return i;
		}
	}
	return _itemCount;
}
