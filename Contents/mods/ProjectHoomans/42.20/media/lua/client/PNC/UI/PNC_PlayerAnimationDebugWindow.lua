-- Stable player animation debug window entry point.
require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_PlayerAnimationDebug"
require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

PNC = PNC or {}
PNC.PlayerAnimationDebugUI = PNC.PlayerAnimationDebugUI or {}

require "PNC/UI/PNC_PlayerAnimationDebugWindow_Core"
require "PNC/UI/PNC_PlayerAnimationDebugWindow_Setup"
require "PNC/UI/PNC_PlayerAnimationDebugWindow_Detail"
require "PNC/UI/PNC_PlayerAnimationDebugWindow_Lifecycle"

return PNC.PlayerAnimationDebugUI
