/* constants */
/* how tall the keyboard should be by default (can be overriden) */
#define KBD_PIXEL_HEIGHT 240

/* how tall the keyboard should be by default (can be overriden) */
#define KBD_PIXEL_LANDSCAPE_HEIGHT 360

/* spacing around each key */
#define KBD_KEY_BORDER 1

/* layout declarations */
enum layout_id {
	Full = 0,
	Special,
	NumLayouts,
	Index = 0,
};

static struct key keys_full[], keys_special[];

static struct layout layouts[NumLayouts] = {
  [Full] = {keys_full, "latin", "full"}, // second parameter is the keymap name
                                         // third parameter is the layout name
  [Special] = {keys_special, "latin", "special"},
};

/* key layouts
 *
 * define keys like:
 *
 *  `{
 *     "label",
 *     "SHIFT_LABEL",
 *     1,
 *     [Code, Mod, Layout, EndRow, Last],
 *     [KEY_CODE, Modifier],
 *     [&layout]
 *  },`
 *
 * - label: normal label for key
 *
 * - shift_label: label for key in shifted (uppercase) layout
 *
 * - width: column width of key
 *
 * - type: what kind of action this key peforms (emit keycode, toggle modifier,
 *   switch layout, or end the layout)
 *
 * - code: key scancode or modifier name (see
 *   `/usr/include/linux/input-event-codes.h` for scancode names, and
 *   `keyboard.h` for modifiers)
 *
 * - layout: layout to switch to when key is pressed
 */
static struct key keys_full[] = {
  {"`", "~", 1.0, Code, KEY_GRAVE},
  {"1", "!", 1.0, Code, KEY_1},
  {"2", "@", 1.0, Code, KEY_2},
  {"3", "#", 1.0, Code, KEY_3},
  {"4", "$", 1.0, Code, KEY_4},
  {"5", "%", 1.0, Code, KEY_5},
  {"6", "^", 1.0, Code, KEY_6},
  {"7", "&", 1.0, Code, KEY_7},
  {"8", "*", 1.0, Code, KEY_8},
  {"9", "(", 1.0, Code, KEY_9},
  {"0", ")", 1.0, Code, KEY_0},
  {"-", "_", 1.0, Code, KEY_MINUS},
  {"=", "+", 1.0, Code, KEY_EQUAL},
  {"←|", "←|", 1.5, Code, KEY_BACKSPACE},
  {"", "", 0.0, EndRow},

  {"Tab", "Tab", 1.0, Code, KEY_TAB},
  {"q", "Q", 1.0, Code, KEY_Q},
  {"w", "W", 1.0, Code, KEY_W},
  {"e", "E", 1.0, Code, KEY_E},
  {"r", "R", 1.0, Code, KEY_R},
  {"t", "T", 1.0, Code, KEY_T},
  {"y", "Y", 1.0, Code, KEY_Y},
  {"u", "U", 1.0, Code, KEY_U},
  {"i", "I", 1.0, Code, KEY_I},
  {"o", "O", 1.0, Code, KEY_O},
  {"p", "P", 1.0, Code, KEY_P},
  {"[", "{", 1.0, Code, KEY_LEFTBRACE},
  {"]", "}", 1.0, Code, KEY_RIGHTBRACE},
  {"\\", "|", 1.0, Code, KEY_BACKSLASH},
  {"", "", 0.0, EndRow},

  {"Caps", "Caps", 1.0, Mod, CapsLock},
  {"a", "A", 1.0, Code, KEY_A},
  {"s", "S", 1.0, Code, KEY_S},
  {"d", "D", 1.0, Code, KEY_D},
  {"f", "F", 1.0, Code, KEY_F},
  {"g", "G", 1.0, Code, KEY_G},
  {"h", "H", 1.0, Code, KEY_H},
  {"j", "J", 1.0, Code, KEY_J},
  {"k", "K", 1.0, Code, KEY_K},
  {"l", "L", 1.0, Code, KEY_L},
  {";", ":", 1.0, Code, KEY_SEMICOLON},
  {"'", "\"", 1.0, Code, KEY_APOSTROPHE},
  {"Enter", "Enter", 1.7, Code, KEY_ENTER},
  {"", "", 0.0, EndRow},

  {"⇧", "⇧", 2.0, Mod, Shift},
  {"z", "Z", 1.0, Code, KEY_Z},
  {"x", "X", 1.0, Code, KEY_X},
  {"c", "C", 1.0, Code, KEY_C},
  {"v", "V", 1.0, Code, KEY_V},
  {"b", "B", 1.0, Code, KEY_B},
  {"n", "N", 1.0, Code, KEY_N},
  {"m", "M", 1.0, Code, KEY_M},
  {",", "<", 1.0, Code, KEY_COMMA},
  {".", ">", 1.0, Code, KEY_DOT},
  {"/", "?", 1.0, Code, KEY_SLASH},
  {"⇧", "⇧", 2.0, Mod, Shift},
  {"", "", 0.0, EndRow},

  {"Sym", "Sym", 1.0, NextLayer, .scheme = 1},
  {"Ctr", "Ctr", 1.2, Mod, Ctrl},
  {"Sup", "Sup", 1.0, Mod, Super},
  {"Alt", "Alt", 1.0, Mod, Alt},
  {"", "", 4.0, Code, KEY_SPACE},
  {"AGr", "AGr", 1.0, Mod, AltGr},
  {"PrtSc", "PrtSc", 1.0, Code, KEY_PRINT},
  {"Ctr", "Ctr", 1.0, Mod, Ctrl},
  {"PgUp", "PgUp", 1.0, Code, KEY_PAGEUP},
  {"PgDn", "PgDn", 1.0, Code, KEY_PAGEDOWN},

  {"", "", 0.0, Last},
};

static struct key keys_special[] = {
  {"Esc", "Esc", 2.0, Code, KEY_ESC},
  {"F1", "F1", 1.0, Code, KEY_F1},
  {"F2", "F2", 1.0, Code, KEY_F2},
  {"F3", "F3", 1.0, Code, KEY_F3},
  {"F4", "F4", 1.0, Code, KEY_F4},
  {"", "", 0.2, Pad},
  {"F5", "F5", 1.0, Code, KEY_F5},
  {"F6", "F6", 1.0, Code, KEY_F6},
  {"F7", "F7", 1.0, Code, KEY_F7},
  {"F8", "F8", 1.0, Code, KEY_F8},
  {"", "", 0.2, Pad},
  {"F9", "F9", 1.0, Code, KEY_F9},
  {"F10", "F10", 1.0, Code, KEY_F10},
  {"F11", "F11", 1.0, Code, KEY_F11},
  {"F12", "F12", 1.0, Code, KEY_F12},
  {"", "", 0.0, EndRow},

  {"", "", 1.0, Code, KEY_MUTE},
  {"-", "-", 1.0, Code, KEY_VOLUMEDOWN},
  {"+", "+", 1.0, Code, KEY_VOLUMEUP},
  {"", "", 1.0, Code, KEY_MICMUTE},
  {"-", "-", 1.0, Code, KEY_BRIGHTNESSDOWN},
  {"+", "+", 1.0, Code, KEY_BRIGHTNESSUP},
  {"", "", 0.0, EndRow},

  {"", "", 0.0, EndRow},

  {"⇧", "⇧", 1.0, Mod, Shift},
  {"", "", 9.0, Pad},
  {"", "", 0.0, EndRow},

  {"Sym", "Sym", 1.0, NextLayer, .scheme = 1},
  {"Ctr", "Ctr", 1.2, Mod, Ctrl},
  {"Sup", "Sup", 1.0, Mod, Super},
  {"Alt", "Alt", 1.0, Mod, Alt},
  {"", "", 4.0, Code, KEY_SPACE},
  {"AGr", "AGr", 1.0, Mod, AltGr},
  {"↑", "↑", 1.0, Code, KEY_UP},
  {"↓", "↓", 1.0, Code, KEY_DOWN},
  {"←", "←", 1.0, Code, KEY_LEFT},
  {"→", "→", 1.0, Code, KEY_RIGHT},

  {"", "", 0.0, Last},
};
