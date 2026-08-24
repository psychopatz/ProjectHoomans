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
local isBuilt = Internal.isBuilt
local validationFacilityWithoutRole = Internal.validationFacilityWithoutRole
local applyComponent = Internal.applyComponent

function Service.SetComponent(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if not isBuilt(facility) then
        return { ok = false, reason = "FACILITY_NOT_BUILT" }
    end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= facility.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision }
    end
    local input = type(args.component) == "table"
        and PNC.Core.DeepCopy(args.component) or {}
    local existing = input.id and Repository.GetComponent(input.id) or nil
    if existing and existing.facilityId ~= facility.id then
        return { ok = false, reason = "INVALID_COMPONENT" }
    end
    input.id = tostring(input.id or PNC.Core.GenerateID("component"))
    local check = Validation.NormalizeComponent(base, facility, input)
    if not check.ok then return check end
    if not Definitions.RequiresComponentConstruction(
        facility.definitionId, facility.level, check.details.component.role,
        check.details.component.kind)
    then
        return applyComponent(base, facility, check.details.component)
    end
    if not PNC.ConstructionService
        or not PNC.ConstructionService.QueueReconstruct
    then return { ok = false,
        reason = "CONSTRUCTION_SERVICE_UNAVAILABLE" } end
    local order, reason = PNC.ConstructionService.QueueReconstruct(
        player, facility, { action = "set",
            component = check.details.component })
    if not order then return { ok = false, reason = reason } end
    return { ok = true, facility = facility, workOrder = order,
        pendingComponent = check.details.component,
        event = "FacilityReconstructionQueued" }
end

function Service.ReplaceAnchorRole(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then
        return { ok = false, reason = "NO_PERMISSION" }
    end
    if not isBuilt(facility) then
        return { ok = false, reason = "FACILITY_NOT_BUILT" }
    end
    if args.expectedRevision ~= nil
        and tonumber(args.expectedRevision) ~= facility.revision
    then return { ok = false, reason = "REVISION_CONFLICT",
        revision = facility.revision } end
    local role = tostring(args.role or "")
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    local limit = level and level.componentLimits and level.componentLimits[role]
    local anchors = type(args.anchors) == "table" and args.anchors or {}
    if not limit or limit.kind ~= "anchor" then
        return { ok = false, reason = "INVALID_COMPONENT_ROLE" }
    end
    if #anchors < (tonumber(limit.minCount) or 0)
        or limit.maxCount and #anchors > limit.maxCount
    then return { ok = false, reason = "FACILITY_COMPONENT_LIMIT" } end
    local old = {}
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true and Repository.GetComponent(componentId)
        if component and component.role == role then
            old[#old + 1] = component
        end
    end
    local validationFacility = validationFacilityWithoutRole(facility, role)
    local normalized = {}
    local failure
    for index, anchor in ipairs(anchors) do
        local input = {
            id = PNC.Core.GenerateID("component"), kind = "anchor", role = role,
            x = anchor.x, y = anchor.y, z = anchor.z,
            targetResolver = role == "sleep.bed" and "sleepSpot" or nil,
        }
        local check = Validation.NormalizeComponent(
            base, validationFacility, input)
        if check.ok ~= true then failure = check; break end
        normalized[index] = check.details.component
    end
    if failure then
        return failure
    end
    local requiresConstruction = Definitions.RequiresComponentConstruction(
        facility.definitionId, facility.level, role, "anchor")
    if requiresConstruction and PNC.ConstructionService
        and PNC.ConstructionService.QueueReconstruct
    then
        local order, reason = PNC.ConstructionService.QueueReconstruct(
            player, facility, { action = "replace_role", role = role,
                anchors = PNC.Core.DeepCopy(anchors) })
        if not order then return { ok = false, reason = reason } end
        return { ok = true, facility = facility, workOrder = order,
            pendingAnchors = anchors, event = "FacilityReconstructionQueued" }
    end
    for _, component in ipairs(old) do
        facility.componentIds[component.id] = nil
        Repository.State.components[component.id] = nil
        if PNC.FacilityInteractionTargets then
            PNC.FacilityInteractionTargets.Invalidate(component.id)
        end
        if PNC.FacilityReservations then
            PNC.FacilityReservations.ReleaseComponent(component.id)
        end
    end
    for _, component in ipairs(normalized) do
        Repository.State.components[component.id] = component
        facility.componentIds[component.id] = true
    end
    touch(base, facility)
    updateState(base, facility)
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, {
        facilityId = facility.id, role = role, operation = "REPLACE_ROLE",
        revision = facility.revision,
    })
    return { ok = true, facility = facility, components = normalized,
        event = "FacilityAnchorRoleReplaced" }
end


return Service
