-- Stable settlement-generation coordinator entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementGenerator = PNC.SettlementGenerator or {}
PNC.SettlementGenerator.Metrics = PNC.SettlementGenerator.Metrics or {
    attempts = 0, successes = 0, failures = 0,
    npcRecordsCreated = 0, candidateEvaluations = 0,
}

require "PNC/Director/Population/SettlementGenerator/PNC_SettlementGenerator_Factions"
require "PNC/Director/Population/SettlementGenerator/PNC_SettlementGenerator_Planning"
require "PNC/Director/Population/SettlementGenerator/PNC_SettlementGenerator_Validation"
require "PNC/Director/Population/SettlementGenerator/PNC_SettlementGenerator_Commit"

return PNC.SettlementGenerator
