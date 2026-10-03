-- Dashboard for the client-local perception snapshot.  It deliberately has
-- no request/response path: refresh means re-scan the loaded cell locally.
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}
PNC.PerceptionDebug.UI = PNC.PerceptionDebug.UI or {}

local DebugUI = PNC.PerceptionDebug.UI
local Settings = PNC.PerceptionDebug.Settings
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
local Model = PNC.PerceptionDebug.Model
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
local Overlay = PNC.PerceptionDebug.Overlay
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local SLEEP_COLOR = { r = 0.78, g = 0.42, b = 1.0, a = 1 }

local OPTION_LABELS = {
    showObjectNames = "UI_PNC_PerceptionDebug_ShowObjectNames",
    showSemanticNames = "UI_PNC_PerceptionDebug_ShowSemanticNames",
    showUsage = "UI_PNC_PerceptionDebug_ShowUsage",
    showSitting = "UI_PNC_PerceptionDebug_ShowSitting",
    showSleeping = "UI_PNC_PerceptionDebug_ShowSleeping",
    showWater = "UI_PNC_PerceptionDebug_ShowWater",
    showCampZones = "UI_PNC_PerceptionDebug_ShowCampZones",
    showJobs = "UI_PNC_PerceptionDebug_ShowJobs",
    showUnknownObjects = "UI_PNC_PerceptionDebug_ShowUnknown",
    showTooltip = "UI_PNC_PerceptionDebug_ShowTooltip",
    showCampPreview = "UI_PNC_PerceptionDebug_ShowCampPreview",
}


local Internal = DebugUI.Internal or {}
DebugUI.Internal = Internal
Internal.OptionLabels = OPTION_LABELS
Internal.SleepColor = SLEEP_COLOR

require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Window_Core"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Window_Actions"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Window_Lifecycle"

return DebugUI
