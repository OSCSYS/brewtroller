#ifndef _MENU_H
#define _MENU_H

#include <Arduino.h>

class menu
{
public:
  menu(byte);
  
	/* Set selected by specifying index */
	void setSelected(byte);

	/* Select by menu item value */
	void setSelectedByValue(byte);

	/* Get selected menu item index */
	byte getSelected(void);

	/* Update _topItem based on selection and pageSize */
	boolean refreshDisp(void);

	/* Get specified row's menu item text based on _topItem and _pageSize */
	void getVisibleRow(byte, char[]);

	/* Get menu item text for currently selected item */
	char* getSelectedRow(char[]);

	/* Get the value for the currently selected menu item */
	byte getValue(void);

	/* Get the cursor position based on current selection, _topItem and _pageSize */
	byte getCursor(void);

	/* Get total number of defined menu items */
	virtual byte getItemCount(void) = 0;

  /* Get the item text at the specified index */
  virtual char* getItem(byte, char *) = 0;
  
  /* Get the item value at the specified index */
  virtual byte getItemValue(byte);

	/* Get menu item index based on specified menu item value */
	byte getIndexByValue(byte);
private:
	byte 	_pageSize,
		_selected,
		_topItem;
};

//Pure PROGMEM Implementation
class menuPROGMEM : public menu
{
  private:
    const void *PROGMEMData;
    byte menuSize;
        
  public:
    menuPROGMEM(byte pSize, const void *d, byte s);
    virtual byte getItemCount(void);
    virtual char* getItem(byte index, char *retString);
};

//Pure PROGMEM with *selected item
class menuPROGMEMSelection : public menu
{
  private:
    const void *PROGMEMData;
    byte menuSize, currentSelection;
        
  public:
    menuPROGMEMSelection(byte pSize, const void *d, byte s, byte sel);
    virtual byte getItemCount(void);
    virtual char* getItem(byte index, char *retString);
};

class menuNumberedItemList : public menu {
  private:
    byte currentSelection, itemCount;
    const char *itemText;
    
  public:
    menuNumberedItemList(byte, byte, byte, const char *);
    byte getItemCount(void);
    char* getItem(byte, char *);
};

#endif
