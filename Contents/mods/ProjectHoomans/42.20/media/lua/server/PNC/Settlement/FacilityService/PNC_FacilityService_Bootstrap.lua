if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Internal = Service.Internal
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events


Repository.Load()
Service.RebuildIndexes()

return Service
