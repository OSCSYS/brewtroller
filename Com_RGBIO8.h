#ifndef COM_RGBIO8_H
#define COM_RGBIO8_H
#include "Config.h"
#include <Arduino.h>
#include "Outputs.h"
#include <Wire.h>


// The first address of your RGB Boards. Other boards should follow using the next
// address. So, for instance, if this value is 0x30, board 2 should be 0x31, board
// 3 should be 0x32, etc.
//
#define RGBIO8_START_ADDR 0x30
#define RGBIO8_INIT_ADDR 0x7F

//
// The maximum number of RGB boards you can have connnected.
//
#define RGBIO8_MAX_BOARDS 4

#define RGBIO8_MAX_OUTPUT_RECIPES 4
#define RGBIO8_INTERVAL 100

#define RGBIO8_UNASSIGNED 255

struct RGBIO8_assignment {
  byte index;
  byte recipe_id;
};

class RGBIO8 {
  public:
    /**
     * Initializes the RGBIO8 board at the given i2c_address. Once initialized the board is reset and
     * ready for use but it will not actually do anything until assign* functions are called.
     */
    RGBIO8(byte i2c_address);
    
    /**
     * Sets up the RGBIO8 class with pointer to output system object.
     */    
    static void setup(OutputSystem* o);
    
    /**
     * Creates an output recipe that can be assigned to an output. A recipe determines
     * which colors will be shown for a given output state. The returned recipe id can
     * then be used for multiple outputs.
     * Red, green and blue values should be 4 bits each, i.e. values from 0-15. A good way
     * to specify the color is using three characters of hex, where the characters are
     * r, g, b.
     * Examples:
     *   Red: 0xf00
     *   Purple: 0xf0f
     *   Yellow: 0x0ff
     *   White: 0xfff
     */
    static void setOutputRecipe(
      byte recipe_id, 
      uint16_t off_rgb,
      uint16_t auto_off_rgb,
      uint16_t auto_on_rgb,
      uint16_t on_rgb);
    
    /**
     * Attaches the specified output or profile to an RGBIO8 channel using the specified recipe.
     */
    void assign(byte assignment, byte outputIndex, byte recipe_id);
    
    
    /**
     * Called regularly by the main program loop. Updates the local state of the inputs, checks
     * the values of the outputs and sends any new output state that needs to be updated.
     */
    void update(void);

    void restart();
    void setIdMode(byte id_mode);
    void setAddress(byte a);
    int getInputs(void);
    
  private:
    static OutputSystem* outputs;
    static uint16_t output_recipes[RGBIO8_MAX_OUTPUT_RECIPES][4];
    byte i2c_address;
    struct RGBIO8_assignment assignments[8];
    byte inputs_auto, inputs_manual;
    
    void setOutput(byte output, uint16_t rgb);
    uint8_t crc8(uint8_t inCrc, uint8_t inData );
};

#endif

