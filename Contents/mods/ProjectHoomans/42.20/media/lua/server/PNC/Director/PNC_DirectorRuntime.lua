-- Domain registration: Director. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Director/PNC_Director"
require "PNC/Director/PNC_MobileSettlementVisitService"
require "PNC/Director/PNC_CommercialMobilityService"
