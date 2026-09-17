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
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CoreProvider"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Overlay"

local Namespace = PNC.PerceptionDebug
local Provider = Namespace.CoreProvider

local function previewHub()
    local loaded, hub = pcall(require, "PsychopatzCore/Preview/PC_PreviewHub")
    if loaded and hub then return hub end
    return nil
end

function Namespace.Open()
    local hub = previewHub()
    if hub and hub.Open and Provider then
        return hub.Open(Provider.ID)
    end
    return nil
end

function Namespace.Toggle()
    local hub = previewHub()
    if hub and hub.Toggle and Provider then
        return hub.Toggle(Provider.ID)
    end
    return false
end

function Namespace.IsOpen()
    local window = rawget(_G, "ISPsychopatzPreviewHubWindow")
        and ISPsychopatzPreviewHubWindow.instance or nil
    return window and window.getIsVisible
        and window:getIsVisible() == true or false
end

return Namespace
