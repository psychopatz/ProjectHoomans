-- Stable settlement-candidate manager entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementCandidates = PNC.SettlementCandidates or {}

require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_Core"
require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_Discovery"
require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_MetaDiscovery"
require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_Evaluation"
require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_Selection"
require "PNC/Director/Population/SettlementCandidateManager/PNC_SettlementCandidateManager_Reservations"

return PNC.SettlementCandidates
