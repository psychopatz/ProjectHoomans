-- Stable ambient director entry point.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Core"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Targets"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Objective"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Refresh"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Runtime"

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal

function Director.RefreshFactionObjective(factionID, at)
    return H.RefreshFactionObjective(factionID, at)
end

function Director.PumpAmbient(at, budget)
    return H.PumpAmbient(at, budget)
end

return Director
