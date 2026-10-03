require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}
PNC.PerceptionDebug.UI = PNC.PerceptionDebug.UI or {}

local DebugUI = PNC.PerceptionDebug.UI
local Internal = DebugUI.Internal or {}
DebugUI.Internal = Internal
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
local SLEEP_COLOR = Internal.SleepColor
local OPTION_LABELS = Internal.OptionLabels

function ISPNCPerceptionDebugWindow:onAction(button)
    local id = button and button.internal or ""
    if id == "refresh" then
        self:refreshSnapshot(true)
    elseif id == "overlay" then
        Overlay.Toggle()
        self:syncControls()
    elseif id == "close" then
        self:close()
    end
end


return DebugUI
