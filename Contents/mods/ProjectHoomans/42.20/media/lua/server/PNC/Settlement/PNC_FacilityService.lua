if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}

local Service = PNC.FacilityService
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Service.ByType = Service.ByType or {}
Service.ByCapability = Service.ByCapability or {}
Service.ComponentsByRole = Service.ComponentsByRole or {}

local function calculatedState(base, facility)
    local state = tostring(facility.constructionState or "BUILT")
    if state == "PLANNED" or state == "UNDER_CONSTRUCTION"
        or state == "RECONSTRUCTING" or state == "DECONSTRUCTING"
    then return state end
    return Validation.CalculateOperationalState(base, facility)
end

local function emit(eventType, payload)
    if EventsBus and EventsBus.emit then EventsBus.emit(eventType, payload) end
end

local function addIndex(index, key, id)
    local bucket = index[key]
    if not bucket then bucket = {}; index[key] = bucket end
    bucket[id] = true
end

function Service.RebuildIndexes()
    Service.ByType, Service.ByCapability, Service.ComponentsByRole = {}, {}, {}
    local obsoleteComponents = {}
    for id, facility in pairs(Repository.State.facilities) do
        local base = PNC.BaseService.Get(facility.baseId)
        if base then
            facility.cachedState = calculatedState(base, facility)
        else
            facility.cachedState = "INVALID_COMPONENT"
        end
        addIndex(Service.ByType, facility.definitionId, id)
        local level = Definitions.GetLevel(facility.definitionId, facility.level)
        for _, capability in ipairs(level and level.capabilities or {}) do
            addIndex(Service.ByCapability, capability, id)
        end
    end
    for id, component in pairs(Repository.State.components) do
        local facility = Repository.GetFacility(component.facilityId)
        if facility and facility.definitionId == "research_facility"
            and component.role == "research.room"
        then
            obsoleteComponents[#obsoleteComponents + 1] = id
        else
            addIndex(Service.ComponentsByRole, component.role, id)
        end
    end
    for _, componentId in ipairs(obsoleteComponents) do
        local component = Repository.State.components[componentId]
        local facility = component
            and Repository.GetFacility(component.facilityId) or nil
        if facility and facility.componentIds then
            facility.componentIds[componentId] = nil
        end
        Repository.State.components[componentId] = nil
    end
    if #obsoleteComponents > 0 then
        Repository.MarkDirty()
    end
end

local function touch(base, facility)
    facility.revision = (tonumber(facility.revision) or 0) + 1
    base.revision = (tonumber(base.revision) or 0) + 1
    Repository.MarkDirty()
end

local function updateState(base, facility)
    local previous = facility.cachedState
    facility.cachedState = calculatedState(base, facility)
    if previous ~= facility.cachedState then
        emit(PNC.EventTypes.FACILITY_STATE_CHANGED, { facilityId = facility.id,
            state = facility.cachedState, revision = facility.revision })
    end
end

function Service.RefreshState(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    touch(base, facility)
    updateState(base, facility)
    Service.RebuildIndexes()
    return true, facility.cachedState
end

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
    for _, other in pairs(Repository.State.facilities or {}) do
        if other.constructionRegion and GridRegion.intersects(
            constructionRegion, other.constructionRegion)
        then return { ok = false, reason = "OVERLAP_NOT_ALLOWED" } end
    end
    facility.constructionRegion = constructionRegion
    Repository.State.facilities[id] = facility
    base.facilityIds[id] = true
    local workOrder, workReason
    if PNC.ConstructionService then
        workOrder, workReason = PNC.ConstructionService.QueueBuild(
            player, facility, definition)
    else
        workReason = "CONSTRUCTION_SERVICE_UNAVAILABLE"
    end
    if not workOrder then
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

local function pointFromRegion(region)
    local zKeys = {}
    for z, _ in pairs(region and region.levels or {}) do zKeys[#zKeys + 1] = z end
    table.sort(zKeys)
    for _, z in ipairs(zKeys) do
        local level = region.levels[z]
        local yKeys = {}
        for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
        table.sort(yKeys)
        for _, y in ipairs(yKeys) do
            local spans = level.rows[y]
            if spans and spans[1] ~= nil then
                return { x = spans[1], y = y, z = z }
            end
        end
    end
end

function Service.ResolveWorkTarget(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    if not facility then return nil, "FACILITY_NOT_FOUND" end
    local componentIds = {}
    for componentId, _ in pairs(facility.componentIds or {}) do
        componentIds[#componentIds + 1] = componentId
    end
    table.sort(componentIds)
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        if component and component.kind == "anchor" then
            return { x = component.x, y = component.y, z = component.z,
                componentId = component.id, role = component.role }
        end
    end
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        if component and component.kind == "region" and component.region then
            local point = pointFromRegion(component.region)
            if point then
                point.componentId, point.role = component.id, component.role
                return point
            end
        end
    end
    local point = pointFromRegion(facility.constructionRegion)
    if point then
        point.componentId, point.role = "footprint:" .. facility.id,
            "facility.footprint"
        return point
    end
    return nil, "FACILITY_HAS_NO_WORK_TARGET"
end

function Service.Upgrade(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if facility.constructionState ~= nil
        and facility.constructionState ~= "BUILT"
    then return { ok = false, reason = "FACILITY_NOT_BUILT" } end
    local check = Validation.CanUpgrade(base, facility, args.expectedRevision)
    if not check.ok then return check end
    facility.level = facility.level + 1
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_UPGRADED, { facilityId = facility.id,
        level = facility.level, revision = facility.revision })
    return { ok = true, facility = facility, event = "FacilityUpgraded" }
end

local function isBuilt(facility)
    return facility.constructionState == nil
        or facility.constructionState == "BUILT"
end

local function applyComponent(base, facility, input)
    input = type(input) == "table" and PNC.Core.DeepCopy(input) or {}
    local existing = input.id and Repository.GetComponent(input.id) or nil
    if existing and existing.facilityId ~= facility.id then
        return { ok = false, reason = "INVALID_COMPONENT" }
    end
    input.id = tostring(input.id or PNC.Core.GenerateID("component"))
    local check = Validation.NormalizeComponent(base, facility, input)
    if not check.ok then return check end
    local component = check.details.component
    component.revision = existing and ((tonumber(existing.revision) or 0) + 1) or 0
    Repository.State.components[component.id] = component
    facility.componentIds[component.id] = true
    if PNC.FacilityInteractionTargets then
        PNC.FacilityInteractionTargets.Invalidate(component.id)
    end
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, { facilityId = facility.id,
        componentId = component.id, operation = existing and "EDIT" or "ADD",
        revision = facility.revision })
    return { ok = true, facility = facility, component = component,
        event = existing and "FacilityComponentChanged" or "FacilityComponentAdded" }
end

local function removeComponent(base, facility, component)
    Repository.State.components[component.id] = nil
    facility.componentIds[component.id] = nil
    if PNC.FacilityInteractionTargets then
        PNC.FacilityInteractionTargets.Invalidate(component.id)
    end
    if PNC.FacilityReservations then
        PNC.FacilityReservations.ReleaseComponent(component.id)
    end
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, { facilityId = facility.id,
        componentId = component.id, operation = "REMOVE",
        revision = facility.revision })
    return { ok = true, facility = facility,
        event = "FacilityComponentRemoved" }
end

function Service.FinalizeSetComponent(facilityId, input)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    local result = applyComponent(base, facility, input)
    if result.ok ~= true then return false, result.reason end
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, result.event
end

function Service.FinalizeRemoveComponent(facilityId, componentId)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    local component = Repository.GetComponent(componentId)
    if not base or not component or component.facilityId ~= facility.id then
        return false, "COMPONENT_NOT_FOUND"
    end
    local result = removeComponent(base, facility, component)
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, result.event
end

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
    if existing and existing.kind == "region" then
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
    return applyComponent(base, facility, check.details.component)
end

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
    if component.kind == "region" then
        if not PNC.ConstructionService
            or not PNC.ConstructionService.QueueReconstruct
        then return { ok = false,
            reason = "CONSTRUCTION_SERVICE_UNAVAILABLE" } end
        local order, reason = PNC.ConstructionService.QueueReconstruct(
            player, facility, { action = "remove",
                componentId = component.id })
        if not order then return { ok = false, reason = reason } end
        return { ok = true, facility = facility, workOrder = order,
            event = "FacilityReconstructionQueued" }
    end
    return removeComponent(base, facility, component)
end

function Service.Destroy(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
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

function Service.ListByCapability(baseId, capability)
    local output = {}
    for id, _ in pairs(Service.ByCapability[tostring(capability or "")] or {}) do
        local facility = Repository.GetFacility(id)
        if facility and facility.baseId == baseId and facility.cachedState == "OPERATIONAL" then
            output[#output + 1] = facility
        end
    end
    return output
end

function Service.RevalidateTargets(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    for componentId, _ in pairs(facility.componentIds or {}) do
        local component = Repository.GetComponent(componentId)
        local validator = component and PNC.FacilityWorldValidation
            and (component.kind == "anchor"
                and PNC.FacilityWorldValidation.ValidateAnchor
                or PNC.FacilityWorldValidation.ValidateRegion) or nil
        if validator then
            local valid, reason = validator(component)
            if valid ~= true then
                local previous = facility.cachedState
                facility.cachedState = "INVALID_COMPONENT"
                if previous ~= facility.cachedState then
                    emit(PNC.EventTypes.FACILITY_STATE_CHANGED, {
                        facilityId = facility.id, state = facility.cachedState,
                        revision = facility.revision,
                    })
                end
                return false, reason or "INVALID_TARGET", componentId
            end
        end
    end
    updateState(base, facility)
    return true, facility.cachedState
end

function Service.BuildSnapshot(facility)
    if type(facility) ~= "table" then facility = Repository.GetFacility(facility) end
    if not facility then return nil end
    local output = PNC.Core.DeepCopy(facility)
    output.components = {}
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    output.capabilities = PNC.Core.DeepCopy(level and level.capabilities or {})
    output.workstations = PNC.Core.DeepCopy(level and level.workstations or {})
    for id, _ in pairs(facility.componentIds) do
        local component = Repository.GetComponent(id)
        if component then output.components[#output.components + 1] = PNC.Core.DeepCopy(component) end
    end
    for _, station in pairs(output.workstations or {}) do
        local componentId
        for index = 1, #output.components do
            if output.components[index].role == station.role then
                componentId = output.components[index].id; break
            end
        end
        station.componentId = componentId
        station.workOrderId = componentId and PNC.WorkService
            and PNC.WorkService.ClaimsByStation[componentId] or nil
    end
    return output
end

Repository.Load()
Service.RebuildIndexes()
return Service
