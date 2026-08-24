-- Guarded faction debug service entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

require "PNC/Factions/FactionDebug/PNC_FactionDebug_Core"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_Summaries"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_NPCDiagnostics"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_Snapshots"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_ActionCreation"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_ActionMembership"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_ActionDiplomacy"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_ActionDiagnostics"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_ActionIncidents"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_Router"
require "PNC/Factions/FactionDebug/PNC_FactionDebug_Formatting"

return PNC.FactionDebug
