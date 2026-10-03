require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.NeedsDebugUI = PNC.NeedsDebugUI or {}

require "PNC/UI/Needs/PNC_NeedsDebugWindow_Core"
require "PNC/UI/Needs/PNC_NeedsDebugWindow_Actions"
require "PNC/UI/Needs/PNC_NeedsDebugWindow_Lifecycle"

return PNC.NeedsDebugUI
