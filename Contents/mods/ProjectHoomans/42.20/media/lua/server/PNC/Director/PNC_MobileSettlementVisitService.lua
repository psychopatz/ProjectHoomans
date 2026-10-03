-- Stable server mobile settlement visit service entry point.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileSettlementVisitService = PNC.MobileSettlementVisitService or {}

require "PNC/Director/PNC_MobileSettlementVisitService_Core"
require "PNC/Director/PNC_MobileSettlementVisitService_Pending"
require "PNC/Director/PNC_MobileSettlementVisitService_Admission"
require "PNC/Director/PNC_MobileSettlementVisitService_Arrival"

return PNC.MobileSettlementVisitService
