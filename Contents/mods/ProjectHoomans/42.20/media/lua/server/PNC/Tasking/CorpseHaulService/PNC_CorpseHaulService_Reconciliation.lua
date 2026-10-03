-- Corpse haul reconciliation composition root.
--
-- Candidate discovery loads before active-order recovery so every durable
-- reconciliation handoff crosses an explicit Service.Internal boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService

require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Reconciliation_Candidates"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Reconciliation_Active"

return Service
