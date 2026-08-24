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
local GridRegion = Internal.GridRegion

function Service.Create(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService.Get(args.baseId)
    if not base then return { ok = false, reason = "BASE_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then
        return { ok = false, reason = "NO_PERMISSION" }
    end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= base.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = base.revision }
    end
    local check = Validation.CanCreate(base, args.definitionId, 1)
    if not check.ok then return check end
    local definition = Definitions.Get(args.definitionId)
    local id = tostring(args.facilityId or PNC.Core.GenerateID("facility"))
    local facility = { schemaVersion = 1, id = id, baseId = base.id,
        definitionId = tostring(args.definitionId), level = 1,
        componentIds = {}, revision = 0, cachedState = "PLANNED",
        constructionState = "PLANNED" }
    if type(args.component) ~= "table" or args.component.kind ~= "region" then
        return { ok = false, reason = "FACILITY_FOOTPRINT_REQUIRED" }
    end
    local footprintInput = PNC.Core.DeepCopy(args.component)
    footprintInput.id = tostring(PNC.Core.GenerateID("footprint"))
    local footprintCheck
    if footprintInput.role == "facility.footprint"
        and Validation.NormalizeFootprint
    then
        footprintCheck = Validation.NormalizeFootprint(
            base, facility, footprintInput)
    else
        footprintCheck = Validation.NormalizeComponent(
            base, facility, footprintInput)
    end
    if not footprintCheck.ok then return footprintCheck end
    local constructionRegion = footprintCheck.details.component.region
    local initialComponent = definition.providesStockpileAccess == true
        and footprintCheck.details.component or nil
    for _, other in pairs(Repository.State.facilities or {}) do
        if other.constructionRegion and GridRegion.intersects(
            constructionRegion, other.constructionRegion)
        then return { ok = false, reason = "OVERLAP_NOT_ALLOWED" } end
    end
    facility.constructionRegion = constructionRegion
    Repository.State.facilities[id] = facility
    base.facilityIds[id] = true
    if initialComponent then
        Repository.State.components[initialComponent.id] = initialComponent
        facility.componentIds[initialComponent.id] = true
    end
    local workOrder, workReason
    if PNC.ConstructionService then
        workOrder, workReason = PNC.ConstructionService.QueueBuild(
            player, facility, definition)
    else
        workReason = "CONSTRUCTION_SERVICE_UNAVAILABLE"
    end
    if not workOrder then
        if initialComponent then
            Repository.State.components[initialComponent.id] = nil
        end
        Repository.State.facilities[id] = nil
        base.facilityIds[id] = nil
        Service.RebuildIndexes()
        return { ok = false, reason = workReason }
    end
    updateState(base, facility)
    touch(base, facility)
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_CREATED, { baseId = base.id,
        facilityId = id, revision = facility.revision })
    return { ok = true, facility = facility, constructionRegion = constructionRegion,
        workOrder = workOrder, event = "FacilityConstructionQueued" }
end


return Service
