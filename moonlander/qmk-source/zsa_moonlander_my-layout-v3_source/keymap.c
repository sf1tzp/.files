#include QMK_KEYBOARD_H
#include "version.h"
#define MOON_LED_LEVEL LED_LEVEL
#ifndef ZSA_SAFE_RANGE
#define ZSA_SAFE_RANGE SAFE_RANGE
#endif

enum custom_keycodes {
  RGB_SLD = ZSA_SAFE_RANGE,
  ST_MACRO_0,
};



enum tap_dance_codes {
  DANCE_0,
  DANCE_1,
};

#define DUAL_FUNC_0 LT(7, KC_F19)
#define DUAL_FUNC_1 LT(2, KC_F19)
#define DUAL_FUNC_2 LT(2, KC_R)
#define DUAL_FUNC_3 LT(5, KC_F3)
#define DUAL_FUNC_4 LT(8, KC_U)
#define DUAL_FUNC_5 LT(4, KC_C)
#define DUAL_FUNC_6 LT(8, KC_F21)
#define DUAL_FUNC_7 LT(1, KC_F17)
#define DUAL_FUNC_8 LT(7, KC_F6)

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
  [0] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_1,           KC_2,           KC_3,           KC_4,           KC_5,           KC_TRANSPARENT,                                 ST_MACRO_0,     KC_6,           KC_7,           KC_8,           KC_9,           KC_0,           KC_TRANSPARENT, 
    KC_TAB,         KC_Q,           KC_W,           KC_E,           KC_R,           KC_T,           LCTL(KC_LEFT),                                  LCTL(KC_RIGHT), KC_Y,           KC_U,           KC_I,           KC_O,           KC_P,           KC_MINUS,       
    MT(MOD_LCTL, KC_ESCAPE),KC_A,           KC_S,           KC_D,           KC_F,           KC_G,           KC_MEH,                                                                         KC_MEH,         KC_H,           KC_J,           KC_K,           KC_L,           KC_SCLN,        KC_QUOTE,       
    KC_LEFT_SHIFT,  KC_Z,           KC_X,           KC_C,           KC_V,           KC_B,                                           KC_N,           KC_M,           KC_COMMA,       KC_DOT,         KC_SLASH,       KC_EQUAL,       
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_LEFT_GUI,                                                                                                    KC_LEFT_GUI,    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, TD(DANCE_1),    
    KC_SPACE,       TD(DANCE_0),    KC_LEFT_ALT,                    KC_LEFT_ALT,    OSL(1),         MT(MOD_LSFT, KC_ENTER)
  ),
  [1] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TILD,        KC_EXLM,        KC_AT,          KC_HASH,        KC_PLUS,        KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_NO,          KC_LPRN,        KC_RPRN,        KC_GRAVE,       KC_NO,          KC_NO,          
    KC_TRANSPARENT, KC_NO,          KC_DLR,         KC_AMPR,        KC_ASTR,        KC_MINUS,       KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_NO,          KC_LCBR,        KC_RCBR,        KC_DQUO,        KC_NO,          KC_NO,          
    KC_TRANSPARENT, KC_BSLS,        KC_CIRC,        KC_PERC,        KC_PIPE,        KC_EQUAL,                                       KC_NO,          KC_LBRC,        KC_RBRC,        KC_QUOTE,       KC_SLASH,       KC_NO,          
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_NO,          
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                 KC_TRANSPARENT, TO(2),          KC_TRANSPARENT
  ),
  [2] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_NO,          KC_NO,          KC_MS_UP,       KC_NO,          KC_MS_WH_UP,    KC_NO,          KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_NO,          KC_NO,          KC_NO,          KC_NO,          KC_NO,          KC_NO,          
    DUAL_FUNC_0,    KC_MS_LEFT,     KC_MS_DOWN,     KC_MS_RIGHT,    KC_MS_WH_DOWN,  KC_NO,          KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_LEFT,        KC_DOWN,        KC_UP,          KC_RIGHT,       KC_NO,          KC_NO,          
    KC_LEFT_SHIFT,  KC_NO,          KC_NO,          KC_C,           KC_V,           KC_NO,                                          KC_NO,          KC_NO,          KC_NO,          KC_NO,          KC_NO,          KC_NO,          
    KC_TRANSPARENT, KC_TRANSPARENT, KC_MS_BTN3,     KC_MS_BTN2,     KC_MS_BTN1,     KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_BSPC,        KC_TRANSPARENT,                 KC_TRANSPARENT, TO(0),          KC_TRANSPARENT
  ),
  [3] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, EE_CLR,         QK_BOOT,        
    RGB_MODE_FORWARD,TOGGLE_LAYER_COLOR,KC_NO,          RGB_HUD,        RGB_HUI,        RGB_VAI,        KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_NO,          TO(4),          TO(5),          KC_NO,          KC_NO,          KC_NO,          
    DUAL_FUNC_0,    KC_NO,          KC_NO,          KC_NO,          KC_NO,          RGB_VAD,        KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_NO,          KC_NO,          KC_NO,          KC_NO,          KC_NO,          QK_DYNAMIC_TAPPING_TERM_PRINT,
    RGB_TOG,        KC_NO,          KC_NO,          RGB_SPD,        RGB_SPI,        KC_NO,                                          KC_NO,          KC_MEDIA_PREV_TRACK,KC_MEDIA_PLAY_PAUSE,KC_MEDIA_NEXT_TRACK,KC_NO,          QK_DYNAMIC_TAPPING_TERM_UP,
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_NO,                                                                                                          KC_NO,          KC_AUDIO_VOL_DOWN,KC_AUDIO_VOL_UP,KC_AUDIO_MUTE,  KC_TRANSPARENT, QK_DYNAMIC_TAPPING_TERM_DOWN,
    TO(0),          KC_NO,          KC_NO,                          KC_NO,          KC_NO,          KC_NO
  ),
  [4] = LAYOUT_moonlander(
    KC_TILD,        DUAL_FUNC_1,    DUAL_FUNC_2,    DUAL_FUNC_3,    DUAL_FUNC_4,    DUAL_FUNC_5,    DUAL_FUNC_6,                                    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_MINUS,       
    KC_TAB,         KC_Q,           KC_W,           KC_E,           KC_R,           KC_T,           DUAL_FUNC_7,                                    KC_F2,          KC_Y,           KC_U,           KC_I,           KC_O,           KC_P,           KC_BSLS,        
    KC_ESCAPE,      KC_A,           KC_S,           KC_D,           KC_F,           KC_G,           DUAL_FUNC_8,                                                                    KC_TRANSPARENT, KC_H,           KC_J,           KC_K,           KC_L,           KC_SCLN,        KC_QUOTE,       
    KC_LEFT_SHIFT,  KC_Z,           KC_X,           KC_C,           KC_V,           KC_B,                                           KC_N,           KC_M,           KC_COMMA,       KC_DOT,         KC_SLASH,       KC_EQUAL,       
    KC_LEFT_CTRL,   KC_LEFT_ALT,    KC_I,           KC_N,           KC_M,           KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_LEFT,        KC_DOWN,        KC_UP,          KC_RIGHT,       KC_TRANSPARENT, 
    KC_SPACE,       KC_BSPC,        KC_ENTER,                       TO(0),          KC_TRANSPARENT, KC_TRANSPARENT
  ),
  [5] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_F,           KC_P,           KC_B,           KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_J,           KC_L,           KC_U,           KC_Y,           KC_SCLN,        KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_R,           KC_S,           KC_T,           KC_TRANSPARENT, KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_M,           KC_N,           KC_E,           KC_I,           KC_O,           KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_D,           KC_V,                                           KC_K,           KC_H,           KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
  [6] = LAYOUT_moonlander(
    KC_TRANSPARENT, KC_F1,          KC_F2,          KC_F3,          KC_F4,          KC_F5,          KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_F6,          KC_F7,          KC_F8,          KC_F9,          KC_F10,         KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_1,           KC_2,           KC_3,           KC_4,           KC_5,           KC_TRANSPARENT,                                                                 KC_TRANSPARENT, KC_6,           KC_7,           KC_8,           KC_9,           KC_0,           KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                                                                                                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT, 
    KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT,                 KC_TRANSPARENT, KC_TRANSPARENT, KC_TRANSPARENT
  ),
};



uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case MT(MOD_LCTL, KC_ESCAPE):
            return g_tapping_term -20;
        default:
            return g_tapping_term;
    }
}


extern rgb_config_t rgb_matrix_config;

RGB hsv_to_rgb_with_value(HSV hsv) {
  RGB rgb = hsv_to_rgb( hsv );
  float f = (float)rgb_matrix_config.hsv.v / UINT8_MAX;
  return (RGB){ f * rgb.r, f * rgb.g, f * rgb.b };
}

void keyboard_post_init_user(void) {
  rgb_matrix_enable();
}

const uint8_t PROGMEM ledmap[][RGB_MATRIX_LED_COUNT][3] = {
    [0] = { {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {218,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {218,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {218,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {90,255,255}, {90,255,255}, {152,255,255}, {152,255,255}, {152,255,255}, {33,162,255}, {90,255,255}, {218,255,255}, {152,255,255}, {44,255,255}, {152,255,255}, {152,255,255} },

    [1] = { {0,0,117}, {0,0,117}, {152,255,255}, {152,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {0,0,117}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {152,255,255}, {41,255,255}, {41,255,255}, {41,255,255}, {152,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {41,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {152,255,255}, {41,255,255}, {188,255,255}, {152,255,255}, {152,255,255} },

    [2] = { {0,0,117}, {0,0,117}, {152,255,255}, {152,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {188,255,255}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {188,255,255}, {0,0,117}, {188,255,255}, {188,255,255}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {41,255,255}, {41,255,255}, {152,255,255}, {152,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {188,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {41,255,255}, {0,0,255}, {152,255,255}, {152,255,255} },

    [3] = { {0,0,117}, {20,255,255}, {0,0,117}, {0,0,255}, {0,0,117}, {0,0,117}, {43,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {74,255,206}, {0,0,117}, {20,255,255}, {0,0,117}, {0,0,117}, {229,255,255}, {0,0,117}, {97,229,188}, {0,0,117}, {0,0,117}, {41,216,246}, {41,214,172}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,245,245}, {0,0,117}, {36,255,255}, {36,255,255}, {36,255,255}, {0,255,255}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {74,255,206}, {187,255,255}, {0,0,117}, {0,255,255}, {0,0,117}, {152,255,255}, {131,255,255}, {0,0,117}, {44,255,255}, {0,0,117}, {20,255,255}, {131,255,146}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117}, {0,0,117} },

    [5] = { {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {41,216,246}, {41,216,246}, {41,216,246}, {0,0,0}, {0,0,0}, {41,216,246}, {0,255,255}, {41,216,246}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {41,216,246}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {0,255,255}, {0,0,0}, {0,0,0}, {0,255,255}, {41,216,246}, {0,255,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {41,216,246}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {41,216,246}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {41,216,246}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {0,255,255}, {0,0,0}, {0,0,0}, {0,255,255}, {0,255,255}, {0,255,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0} },

    [6] = { {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {188,255,255}, {0,0,0}, {74,255,255}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0} },

};

void set_layer_color(int layer) {
  for (int i = 0; i < RGB_MATRIX_LED_COUNT; i++) {
    HSV hsv = {
      .h = pgm_read_byte(&ledmap[layer][i][0]),
      .s = pgm_read_byte(&ledmap[layer][i][1]),
      .v = pgm_read_byte(&ledmap[layer][i][2]),
    };
    if (!hsv.h && !hsv.s && !hsv.v) {
        rgb_matrix_set_color( i, 0, 0, 0 );
    } else {
        RGB rgb = hsv_to_rgb_with_value(hsv);
        rgb_matrix_set_color(i, rgb.r, rgb.g, rgb.b);
    }
  }
}

bool rgb_matrix_indicators_user(void) {
  if (!keyboard_config.disable_layer_led) { 
    switch (biton32(layer_state)) {
      case 0:
        set_layer_color(0);
        break;
      case 1:
        set_layer_color(1);
        break;
      case 2:
        set_layer_color(2);
        break;
      case 3:
        set_layer_color(3);
        break;
      case 5:
        set_layer_color(5);
        break;
      case 6:
        set_layer_color(6);
        break;
     default:
        if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
          rgb_matrix_set_color_all(0, 0, 0);
        }
    }
  } else {
    if (rgb_matrix_get_flags() == LED_FLAG_NONE) {
      rgb_matrix_set_color_all(0, 0, 0);
    }
  }

  return true;
}


typedef struct {
    bool is_press_action;
    uint8_t step;
} tap;

enum {
    SINGLE_TAP = 1,      
    SINGLE_HOLD,         
    DOUBLE_TAP,          
    DOUBLE_HOLD,         
    DOUBLE_SINGLE_TAP,   
    MORE_TAPS            
};

static tap dance_state[2];

uint8_t dance_step(tap_dance_state_t *state);

uint8_t dance_step(tap_dance_state_t *state) {
    if (state->count == 1) {
        if (state->interrupted || !state->pressed) return SINGLE_TAP;
        else return SINGLE_HOLD;
    } else if (state->count == 2) {
        if (state->interrupted) return DOUBLE_SINGLE_TAP;
        else if (state->pressed) return DOUBLE_HOLD;
        else return DOUBLE_TAP;
    }
    return MORE_TAPS;
}


void on_dance_0(tap_dance_state_t *state, void *user_data);
void dance_0_finished(tap_dance_state_t *state, void *user_data);
void dance_0_reset(tap_dance_state_t *state, void *user_data);

void on_dance_0(tap_dance_state_t *state, void *user_data) {
    if(state->count == 3) {
        tap_code16(KC_BSPC);
        tap_code16(KC_BSPC);
        tap_code16(KC_BSPC);
    }
    if(state->count > 3) {
        tap_code16(KC_BSPC);
    }
}

void dance_0_finished(tap_dance_state_t *state, void *user_data) {
    dance_state[0].step = dance_step(state);
    switch (dance_state[0].step) {
        case SINGLE_TAP: register_code16(KC_BSPC); break;
        case SINGLE_HOLD: layer_on(6); break;
        case DOUBLE_TAP: register_code16(KC_BSPC); register_code16(KC_BSPC); break;
        case DOUBLE_HOLD: register_code16(KC_BSPC); break;
        case DOUBLE_SINGLE_TAP: tap_code16(KC_BSPC); register_code16(KC_BSPC);
    }
}

void dance_0_reset(tap_dance_state_t *state, void *user_data) {
    wait_ms(10);
    switch (dance_state[0].step) {
        case SINGLE_TAP: unregister_code16(KC_BSPC); break;
        case SINGLE_HOLD:
          layer_off(6);
        break;
        case DOUBLE_TAP: unregister_code16(KC_BSPC); break;
        case DOUBLE_HOLD: unregister_code16(KC_BSPC); break;
        case DOUBLE_SINGLE_TAP: unregister_code16(KC_BSPC); break;
    }
    dance_state[0].step = 0;
}
void dance_1_finished(tap_dance_state_t *state, void *user_data);
void dance_1_reset(tap_dance_state_t *state, void *user_data);

void dance_1_finished(tap_dance_state_t *state, void *user_data) {
    dance_state[1].step = dance_step(state);
    switch (dance_state[1].step) {
        case DOUBLE_TAP: layer_move(3); break;
    }
}

void dance_1_reset(tap_dance_state_t *state, void *user_data) {
    wait_ms(10);
    switch (dance_state[1].step) {
    }
    dance_state[1].step = 0;
}

tap_dance_action_t tap_dance_actions[] = {
        [DANCE_0] = ACTION_TAP_DANCE_FN_ADVANCED(on_dance_0, dance_0_finished, dance_0_reset),
        [DANCE_1] = ACTION_TAP_DANCE_FN_ADVANCED(NULL, dance_1_finished, dance_1_reset),
};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  switch (keycode) {
  case QK_MODS ... QK_MODS_MAX:
    // Mouse and consumer keys (volume, media) with modifiers work inconsistently across operating systems,
    // this makes sure that modifiers are always applied to the key that was pressed.
    if (IS_MOUSE_KEYCODE(QK_MODS_GET_BASIC_KEYCODE(keycode)) || IS_CONSUMER_KEYCODE(QK_MODS_GET_BASIC_KEYCODE(keycode))) {
      if (record->event.pressed) {
        add_mods(QK_MODS_GET_MODS(keycode));
        send_keyboard_report();
        wait_ms(2);
        register_code(QK_MODS_GET_BASIC_KEYCODE(keycode));
        return false;
      } else {
        wait_ms(2);
        del_mods(QK_MODS_GET_MODS(keycode));
      }
    }
    break;
    case ST_MACRO_0:
    if (record->event.pressed) {
      SEND_STRING(SS_LSFT(SS_TAP(X_H))SS_DELAY(100)  SS_TAP(X_M)SS_DELAY(100)  SS_TAP(X_M)SS_DELAY(100)  SS_TAP(X_SPACE));
    }
    break;

    case DUAL_FUNC_0:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          layer_move(0);
        } else {
          layer_move(0);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_LEFT_CTRL);
        } else {
          unregister_code16(KC_LEFT_CTRL);
        }  
      }  
      return false;
    case DUAL_FUNC_1:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_1);
        } else {
          unregister_code16(KC_1);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F1);
        } else {
          unregister_code16(KC_F1);
        }  
      }  
      return false;
    case DUAL_FUNC_2:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_2);
        } else {
          unregister_code16(KC_2);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F2);
        } else {
          unregister_code16(KC_F2);
        }  
      }  
      return false;
    case DUAL_FUNC_3:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_3);
        } else {
          unregister_code16(KC_3);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F3);
        } else {
          unregister_code16(KC_F3);
        }  
      }  
      return false;
    case DUAL_FUNC_4:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_4);
        } else {
          unregister_code16(KC_4);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F4);
        } else {
          unregister_code16(KC_F4);
        }  
      }  
      return false;
    case DUAL_FUNC_5:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_5);
        } else {
          unregister_code16(KC_5);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F5);
        } else {
          unregister_code16(KC_F5);
        }  
      }  
      return false;
    case DUAL_FUNC_6:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_6);
        } else {
          unregister_code16(KC_6);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F6);
        } else {
          unregister_code16(KC_F6);
        }  
      }  
      return false;
    case DUAL_FUNC_7:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_7);
        } else {
          unregister_code16(KC_7);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F7);
        } else {
          unregister_code16(KC_F7);
        }  
      }  
      return false;
    case DUAL_FUNC_8:
      if (record->tap.count > 0) {
        if (record->event.pressed) {
          register_code16(KC_8);
        } else {
          unregister_code16(KC_8);
        }
      } else {
        if (record->event.pressed) {
          register_code16(KC_F8);
        } else {
          unregister_code16(KC_F8);
        }  
      }  
      return false;
    case RGB_SLD:
        if (record->event.pressed) {
            rgblight_mode(1);
        }
        return false;
  }
  return true;
}

