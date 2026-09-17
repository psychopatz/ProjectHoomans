-- Composition root for the Hoomans perception debug hub.  Provider modules,
-- presentation, and rendering remain separate so new perception domains can
-- register beside semantic objects without reopening this UI class.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Window"

local Namespace = PNC.PerceptionDebug
local DebugUI = Namespace.UI

function Namespace.Open()
    return DebugUI and DebugUI.Open and DebugUI.Open() or nil
end

function Namespace.Toggle()
    return DebugUI and DebugUI.Toggle and DebugUI.Toggle() or false
end

function Namespace.IsOpen()
    return DebugUI and DebugUI.instance
        and DebugUI.instance:getIsVisible() == true or false
end

return Namespace
