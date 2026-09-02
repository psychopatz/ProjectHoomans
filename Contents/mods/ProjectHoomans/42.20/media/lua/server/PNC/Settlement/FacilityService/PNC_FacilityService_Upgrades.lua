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
local emit = Internal.emit
local touch = Internal.touch
local updateState = Internal.updateState
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

function Service.Upgrade(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if not FacilityState.IsBuilt(facility) then
        return { ok = false, reason = "FACILITY_NOT_BUILT" }
    end
    local check = Validation.CanUpgrade(base, facility, args.expectedRevision)
    if not check.ok then return check end
    if not PNC.ConstructionService
        or not PNC.ConstructionService.QueueReconstruct
    then return { ok = false, reason = "CONSTRUCTION_SERVICE_UNAVAILABLE" } end
    local targetLevel = facility.level + 1
    local order, reason = PNC.ConstructionService.QueueReconstruct(
        player, facility, { action = "upgrade", targetLevel = targetLevel })
    if not order then return { ok = false, reason = reason } end
    return { ok = true, facility = facility, workOrder = order,
        event = "FacilityUpgradeQueued" }
end

function Service.FinalizeUpgrade(facilityId, targetLevel)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    local level = math.floor(tonumber(targetLevel) or 0)
    if level ~= facility.level + 1
        or not Definitions.GetLevel(facility.definitionId, level)
    then return false, "INVALID_FACILITY_LEVEL" end
    facility.level = level
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_UPGRADED, { facilityId = facility.id,
        level = facility.level, revision = facility.revision })
    if facility.definitionId == "stockpile"
        and PNC.StockpileVisualService
        and PNC.StockpileVisualService.Apply
    then
        PNC.StockpileVisualService.Apply(facility)
    end
    return true, "FacilityUpgraded"
end


return Service
