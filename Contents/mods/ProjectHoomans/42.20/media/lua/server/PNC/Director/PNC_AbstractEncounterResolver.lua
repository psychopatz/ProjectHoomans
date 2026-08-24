-- Stable abstract-encounter resolver entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounterResolver = PNC.AbstractEncounterResolver or {}

require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_Core"
require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_State"
require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_Hostile"
require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_Displacement"
require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_Resolution"
require "PNC/Director/AbstractEncounterResolver/PNC_AbstractEncounterResolver_QueueProcessing"

return PNC.AbstractEncounterResolver
