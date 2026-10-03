-- Stable client audio debug window entry point.
require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_AudioDebugModel"

PNC = PNC or {}
PNC.AudioDebugUI = PNC.AudioDebugUI or {}

require "PNC/UI/PNC_AudioDebugWindow_Core"
require "PNC/UI/PNC_AudioDebugWindow_Dialogue"
require "PNC/UI/PNC_AudioDebugWindow_SFX"
require "PNC/UI/PNC_AudioDebugWindow_Window"

return PNC.AudioDebugUI
