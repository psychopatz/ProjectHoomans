-- Canonical server Settlement entry. Dependency order is contractual.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/Settlement/PNC_SettlementRepository"
require "PNC/Settlement/PNC_BaseValidationService"
require "PNC/Settlement/PNC_BaseService"
require "PNC/Settlement/PNC_FacilityWorldValidation"
require "PNC/Settlement/PNC_FacilityValidationService"
require "PNC/Settlement/PNC_FacilityCostService"
require "PNC/Settlement/PNC_FacilityService"
require "PNC/Settlement/PNC_InteractionTargetResolver"
require "PNC/Settlement/PNC_FacilityReservations"
require "PNC/Settlement/PNC_StockpileAccessService"
require "PNC/Settlement/PNC_SettlementDebug"
require "PNC/Settlement/PNC_WaterUtilityService"

return PNC
