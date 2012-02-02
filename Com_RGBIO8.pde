#ifdef RGBIO8_ENABLE

#include "Config.h"
#include "Com_RGBIO8.h"

// TODO: Still need to implement softSwitchHeat honoring in Heat outputs


#define SOFTSWITCH_OFF 0
#define SOFTSWITCH_ON 1
#define SOFTSWITCH_AUTO 2

byte softSwitchPv[PVOUT_COUNT];
byte softSwitchHeat[4];

RGBIO8 rgbio8s[RGBIO8_NUM_BOARDS];
unsigned long lastRGBIO8 = 0;

void RGBIO8_Init() {
  // Initialize and address each RGB board that is attached
  for (int i = 0; i < RGBIO8_NUM_BOARDS; i++) {
    rgbio8s[i].begin(0, RGBIO8_START_ADDR + i);
  }
  
  // Create the recipes that we'll use
  // Off  Auto Off  Auto On  On
  // =============================
  // Red  Yellow    Blue     Green
  RGBIO8::setOutputRecipe(0, 0xf00, 0xff0, 0x00f, 0x0f0);
  
  // Create input and output assignments to wire everything together
  
  // Inputs
  // Assign board 0, input 0 to PV 0
  rgbio8s[0].assignPvInput(0, 0);
  // Assign board 0, input 1 to PV 1
  rgbio8s[0].assignPvInput(1, 1);
  // Assign board 0, input 2 to PV 2
  rgbio8s[0].assignPvInput(2, 2);
  
  // Assign board 0, input 3 to HLT heat
  rgbio8s[0].assignHeatInput(VS_HLT, 3);

  // Outputs
  // Assign board 0, output 0 to PV 0 using recipe 0.
  rgbio8s[0].assignPvOutputRecipe(0, 0, 0);
  // Assign board 0, output 1 to PV 1 using recipe 0.
  rgbio8s[0].assignPvOutputRecipe(1, 1, 0);
  // Assign board 0, output 2 to PV 2 using recipe 0.
  rgbio8s[0].assignPvOutputRecipe(2, 2, 0);
  
  // Assign board 0, output 3 to HLT heat using recipe 0.
  rgbio8s[0].assignHeatOutputRecipe(VS_HLT, 3, 0);
}

void RGBIO8_Update() {
  if (millis() > (lastRGBIO8 + RGBIO8_INTERVAL)) {
    for (int i = 0; i < RGBIO8_NUM_BOARDS; i++) {
      rgbio8s[i].update();
    }
    lastRGBIO8 = millis();
  }
}

uint16_t RGBIO8::output_recipes[RGBIO8_MAX_OUTPUT_RECIPES][4];

RGBIO8::RGBIO8() {
  this->rs485_address = 0;
  this->i2c_address = 0;
  for (int i = 0; i < 8; i++) {
    output_assignments[i].type = 0;
    input_assignments[i].type = 0;
  }
}

void RGBIO8::begin(int rs485_address, int i2c_address) {
  this->rs485_address = rs485_address;
  this->i2c_address = i2c_address;
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
    
void RGBIO8::assignHeatOutputRecipe(byte vessel, byte output, byte recipe_id) {
  output_assignments[output].type = 1;
  output_assignments[output].index = vessel;
  output_assignments[output].recipe_id = recipe_id;
}
    
void RGBIO8::assignPvOutputRecipe(byte pv, byte output, byte recipe_id) {
  output_assignments[output].type = 2;
  output_assignments[output].index = pv;
  output_assignments[output].recipe_id = recipe_id;
}
    
void RGBIO8::assignHeatInput(byte vessel, byte input) {
  input_assignments[input].type = 1;
  input_assignments[input].index = vessel;
}
    
void RGBIO8::assignPvInput(byte pv, byte input) {
  input_assignments[input].type = 2;
  input_assignments[input].index = pv;
}
    
void RGBIO8::update(void) {
  // Get the state of the 8 inputs first
  getInputs(&inputs_manual, &inputs_auto);
  
  // Update any assigned inputs
  for (int i = 0; i < 8; i++) {
    RGBIO8_input_assignment *a = &input_assignments[i];
    if (a->type) {
      if (a->type == 1) {
        // this is a heat input
        if (inputs_manual & (1 << i)) {
          softSwitchHeat[a->index] = SOFTSWITCH_ON;
        }
        else if (inputs_auto & (1 << i)) {
          softSwitchHeat[a->index] = SOFTSWITCH_AUTO;
        }
        else {
          softSwitchHeat[a->index] = SOFTSWITCH_OFF;
        }
      }
      else if (a->type == 2) {
        // this is a PV input
        if (inputs_manual & (1 << i)) {
          softSwitchPv[a->index] = SOFTSWITCH_ON;
        }
        else if (inputs_auto & (1 << i)) {
          softSwitchPv[a->index] = SOFTSWITCH_AUTO;
        }
        else {
          softSwitchPv[a->index] = SOFTSWITCH_OFF;
        }
      }
    }
  }
  
  // Update any assigned outputs
  #ifdef PVOUT
  unsigned long vlvBits = Valves.get();
  #endif
  for (int i = 0; i < 8; i++) {
    RGBIO8_output_assignment *a = &output_assignments[i];
    if (a->type) {
      if (a->type == 1) {
        // this is a heat output
        if (heatStatus[a->index]) {
          if (softSwitchHeat[a->index] == SOFTSWITCH_AUTO) {
            setOutput(i, output_recipes[a->recipe_id][2]);
          }
          else {
            setOutput(i, output_recipes[a->recipe_id][3]);
          }
        }
        else {
          if (softSwitchHeat[a->index] == SOFTSWITCH_AUTO) {
            setOutput(i, output_recipes[a->recipe_id][1]);
          }
          else {
            setOutput(i, output_recipes[a->recipe_id][0]);
          }
        }
      }
      else if (a->type == 2) {
        // this is a PV output
        #ifdef PVOUT
        if (vlvBits & (1 << a->index)) {
          if (softSwitchPv[a->index] == SOFTSWITCH_AUTO) {
            setOutput(i, output_recipes[a->recipe_id][2]);
          }
          else {
            setOutput(i, output_recipes[a->recipe_id][3]);
          }
        }
        else {
          if (softSwitchPv[a->index] == SOFTSWITCH_AUTO) {
            setOutput(i, output_recipes[a->recipe_id][1]);
          }
          else {
            setOutput(i, output_recipes[a->recipe_id][0]);
          }
        }
        #endif
      }
    }
  }
}

void RGBIO8::restart() {
  Wire.beginTransmission(i2c_address);
  Wire.send(0xfd);
  Wire.endTransmission();
}

void RGBIO8::setIdMode(byte id_mode) {
  Wire.beginTransmission(i2c_address);
  Wire.send(0xfe);
  Wire.send(id_mode);
  Wire.endTransmission();
}

void RGBIO8::setAddress(byte a) {
  Wire.beginTransmission(i2c_address);
  Wire.send(0xff);
  Wire.send(a);
  Wire.endTransmission();
}

int RGBIO8::getInputs(uint8_t *m, uint8_t *a) {
  Wire.requestFrom(i2c_address, 3);
  uint8_t inputs_m = Wire.receive();
  uint8_t inputs_a = Wire.receive();
  uint8_t crc = Wire.receive();
  
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
  Wire.send(0x01);
  Wire.send(output);
  Wire.send((uint8_t*) &rgb, 2);
  Wire.endTransmission();
  delay(1);
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


#endif

