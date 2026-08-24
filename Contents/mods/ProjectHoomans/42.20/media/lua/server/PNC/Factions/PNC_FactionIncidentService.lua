-- Server-authoritative faction incident ingestion and escalation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}
PNC.FactionIncidentService.RuntimeEpisodes =
    PNC.FactionIncidentService.RuntimeEpisodes or {}
PNC.FactionIncidentService.RuntimeCallbackIDs =
    PNC.FactionIncidentService.RuntimeCallbackIDs or {}
PNC.FactionIncidentService.RuntimeCallbackOrder =
    PNC.FactionIncidentService.RuntimeCallbackOrder or {}
PNC.FactionIncidentService.LastRuntimePumpAtMS =
    tonumber(PNC.FactionIncidentService.LastRuntimePumpAtMS) or 0

require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_Context"
require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_Escalation"
require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_IncidentMutation"
require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_AttackPreflight"
require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_AttackAggregation"
require "PNC/Factions/FactionIncidentService/PNC_FactionIncidentService_Runtime"

return PNC.FactionIncidentService
