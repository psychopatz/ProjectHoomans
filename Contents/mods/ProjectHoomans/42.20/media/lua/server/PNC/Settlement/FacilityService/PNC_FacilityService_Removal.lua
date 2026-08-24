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
local isBuilt = Internal.isBuilt
local removeComponent = Internal.removeComponent

function Service.RemoveComponent(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if not isBuilt(facility) then
        return { ok = false, reason = "FACILITY_NOT_BUILT" }
    end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= facility.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision }
    end
    local component = Repository.GetComponent(args.componentId)
    if not component or component.facilityId ~= facility.id then
        return { ok = false, reason = "COMPONENT_NOT_FOUND" }
    end
    if facility.definitionId == "stockpile"
        or component.role == "storage.stockpile"
    then
        return { ok = false, reason = "STOCKPILE_CANNOT_DECONSTRUCT" }
    end
    if not PNC.ConstructionService
        or not PNC.ConstructionService.QueueReconstruct
    then return { ok = false,
        reason = "CONSTRUCTION_SERVICE_UNAVAILABLE" } end
    local costs = Definitions.GetComponentCosts(
        facility.definitionId, facility.level, component.role)
    if not Definitions.RequiresComponentConstruction(
        facility.definitionId, facility.level, component.role, component.kind)
    then
        return removeComponent(base, facility, component)
    end
    local refundPercent = PNC.Sandbox
        and PNC.Sandbox.ComponentDeconstructionRefundPercent
        and PNC.Sandbox.ComponentDeconstructionRefundPercent() or 50
    local order, reason = PNC.ConstructionService.QueueReconstruct(
        player, facility, { action = "remove",
            componentId = component.id,
            refundRequirements = costs,
            refundPercent = refundPercent })
    if not order then return { ok = false, reason = reason } end
    return { ok = true, facility = facility, workOrder = order,
        event = "FacilityReconstructionQueued" }
end

function Service.Destroy(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if facility.definitionId == "stockpile" then
        return { ok = false, reason = "STOCKPILE_CANNOT_DECONSTRUCT" }
    end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= facility.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision }
    end
    local order, reason
    if PNC.ConstructionService then
        order, reason = PNC.ConstructionService.QueueDeconstruct(player, facility)
    else
        reason = "CONSTRUCTION_SERVICE_UNAVAILABLE"
    end
    if not order then return { ok = false, reason = reason } end
    return { ok = true, facility = facility, workOrder = order,
        event = "FacilityDeconstructionQueued" }
end

function Service.FinalizeDestroy(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    if facility.definitionId == "stockpile" then
        return false, "STOCKPILE_CANNOT_DECONSTRUCT"
    end
    for componentId, _ in pairs(facility.componentIds) do
        Repository.State.components[componentId] = nil
        if PNC.FacilityReservations then PNC.FacilityReservations.ReleaseComponent(componentId) end
    end
    Repository.State.facilities[facility.id] = nil
    base.facilityIds[facility.id] = nil
    base.revision = base.revision + 1
    Repository.MarkDirty(); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_DESTROYED, { facilityId = facility.id, baseId = base.id })
    return true, "FacilityDestroyed"
end


return Service
