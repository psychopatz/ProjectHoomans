-- Canonical server Settlement entry. Dependency order is contractual.
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

return PNC
