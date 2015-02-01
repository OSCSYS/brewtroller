#include "Com_RGBIO8.h"

OutputSystem* RGBIO8::outputs;
uint16_t RGBIO8::output_recipes[RGBIO8_MAX_OUTPUT_RECIPES][4];

RGBIO8::RGBIO8() {
  this->rs485_address = 0;
  this->i2c_address = 0;
  for (int i = 0; i < 8; i++)
    assignments[i].index = RGBIO8_UNASSIGNED;
}

void RGBIO8::begin(int rs485_address, int i2c_address) {
  this->rs485_address = rs485_address;
  this->i2c_address = i2c_address;
}

void RGBIO8::setup(OutputSystem* o) {
    outputs = o;
}

void RGBIO8::setOutputRecipe(
  byte recipe_id, 
  uint16_t off_rgb,
  uint16_t auto_off_rgb,
  uint16_t auto_on_rgb,
  uint16_t on_rgb) {
    output_recipes[recipe_id][0] = off_rgb;
    output_recipes[recipe_id][1] = auto_off_rgb;
    output_recipes[recipe_id][2] = auto_on_rgb;
    output_recipes[recipe_id][3] = on_rgb;
}
    
void RGBIO8::assign(byte assignment, byte outputIndex, byte recipe_id) {
  assignments[assignment].index = outputIndex;
  assignments[assignment].recipe_id = recipe_id;
}
    
void RGBIO8::update(void) {
  // Get the state of the 8 inputs first
  getInputs(&inputs_manual, &inputs_auto);
  
  // Update any assigned inputs
  for (int i = 0; i < 8; i++) {
    unsigned long mask = 1;
    mask = mask << i;
    
    RGBIO8_assignment *a = &assignments[i];
    if (a->index != RGBIO8_UNASSIGNED) {
      //Update input
      if (inputs_manual & mask) {
        outputs->setProfileMaskBit(OUTPUTPROFILE_RGBIO, a->index, 1);
        outputs->setOutputEnable(OUTPUTENABLE_RGBIO, a->index, 1);
      } else if (inputs_auto & mask) {
        outputs->setProfileMaskBit(OUTPUTPROFILE_RGBIO, a->index, 0);
        outputs->setOutputEnable(OUTPUTENABLE_RGBIO, a->index, 1);
      } else {
        outputs->setProfileMaskBit(OUTPUTPROFILE_RGBIO, a->index, 0);
        outputs->setOutputEnable(OUTPUTENABLE_RGBIO, a->index, 0);
      }
      
      //Update output
      if (outputs->getProfileMaskBit(OUTPUTPROFILE_RGBIO, a->index))
        setOutput(i, output_recipes[a->recipe_id][3]);                                                       //On: Enabled via RGB
      else if (!(outputs->getOutputEnable(OUTPUTPROFILE_RGBIO, a->index)))
        setOutput(i, output_recipes[a->recipe_id][0]);                                                       //Off: Disabled via enable flag (maybe RGB or other enable)
      else if (outputs->getOutputState(a->index))
        setOutput(i, output_recipes[a->recipe_id][2]);                                                       //Auto On
      else
        setOutput(i, output_recipes[a->recipe_id][1]);                                                       //Auto Off
    }
  }
}

void RGBIO8::restart() {
  Wire.beginTransmission(i2c_address);
  Wire.write(0xfd);
  Wire.endTransmission();
}

void RGBIO8::setIdMode(byte id_mode) {
  Wire.beginTransmission(i2c_address);
  Wire.write(0xfe);
  Wire.write(id_mode);
  Wire.endTransmission();
}

void RGBIO8::setAddress(byte a) {
  Wire.beginTransmission(i2c_address);
  Wire.write(0xff);
  Wire.write(a);
  Wire.endTransmission();
}

int RGBIO8::getInputs(uint8_t *m, uint8_t *a) {
  Wire.requestFrom(i2c_address, 3);
  uint8_t inputs_m = Wire.read();
  uint8_t inputs_a = Wire.read();
  uint8_t crc = Wire.read();
  
  uint8_t crc_comp = '*';
  crc_comp = crc8(crc_comp, inputs_m);
  crc_comp = crc8(crc_comp, inputs_a);
  
  if (crc == crc_comp) {
    *m = inputs_m;
    *a = inputs_a;
    return 1;
  }
  else {
    return 0;
  }
}

void RGBIO8::setOutput(byte output, uint16_t rgb) {
  Wire.beginTransmission(i2c_address);
  Wire.write(0x01);
  Wire.write(output);
  Wire.write((uint8_t*) &rgb, 2);
  Wire.endTransmission();
}

uint8_t RGBIO8::crc8(uint8_t inCrc, uint8_t inData ) {
  uint8_t i;
  uint8_t data;

  data = inCrc ^ inData;
  
  for (i = 0; i < 8; i++) {
    if ((data & 0x80) != 0) {
      data <<= 1;
      data ^= 0x07;
    }
    else {
      data <<= 1;
    }
  }

  return data;
}
