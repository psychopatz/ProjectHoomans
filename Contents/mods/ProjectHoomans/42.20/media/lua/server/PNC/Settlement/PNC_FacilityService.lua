if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}

local Service = PNC.FacilityService
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events

Service.ByType = Service.ByType or {}
Service.ByCapability = Service.ByCapability or {}
Service.ComponentsByRole = Service.ComponentsByRole or {}

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
    for id, facility in pairs(Repository.State.facilities) do
        local base = PNC.BaseService.Get(facility.baseId)
        if base then
            facility.cachedState = Validation.CalculateOperationalState(base, facility)
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
        addIndex(Service.ComponentsByRole, component.role, id)
    end
end

local function touch(base, facility)
    facility.revision = (tonumber(facility.revision) or 0) + 1
    base.revision = (tonumber(base.revision) or 0) + 1
    Repository.MarkDirty()
end

local function updateState(base, facility)
    local previous = facility.cachedState
    facility.cachedState = Validation.CalculateOperationalState(base, facility)
    if previous ~= facility.cachedState then
        emit(PNC.EventTypes.FACILITY_STATE_CHANGED, { facilityId = facility.id,
            state = facility.cachedState, revision = facility.revision })
    end
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
    local affordable, cost = Costs.CanAfford(player, definition)
    if not affordable then
        return { ok = false, reason = "INSUFFICIENT_BUILD_MATERIALS",
            details = { cost = cost } }
    end
    local id = tostring(args.facilityId or PNC.Core.GenerateID("facility"))
    local facility = { schemaVersion = 1, id = id, baseId = base.id,
        definitionId = tostring(args.definitionId), level = 1,
        componentIds = {}, revision = 0, cachedState = "PLANNED" }
    local consumed, charged = Costs.Consume(player, definition)
    if not consumed then
        return { ok = false, reason = "INSUFFICIENT_BUILD_MATERIALS",
            details = { cost = charged } }
    end
    updateState(base, facility)
    Repository.State.facilities[id] = facility
    base.facilityIds[id] = true
    touch(base, facility)
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_CREATED, { baseId = base.id,
        facilityId = id, revision = facility.revision })
    return { ok = true, facility = facility, cost = charged,
        event = "FacilityCreated" }
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
            local zKeys = {}
            for z, _ in pairs(component.region.levels or {}) do
                zKeys[#zKeys + 1] = z
            end
            table.sort(zKeys)
            for _, z in ipairs(zKeys) do
                local level = component.region.levels[z]
                local yKeys = {}
                for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
                table.sort(yKeys)
                for _, y in ipairs(yKeys) do
                    local spans = level.rows[y]
                    if spans[1] ~= nil then
                        return { x = spans[1], y = y, z = z,
                            componentId = component.id, role = component.role }
                    end
                end
            end
        end
    end
    return nil, "FACILITY_HAS_NO_WORK_TARGET"
end

function Service.Upgrade(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    local check = Validation.CanUpgrade(base, facility, args.expectedRevision)
    if not check.ok then return check end
    facility.level = facility.level + 1
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_UPGRADED, { facilityId = facility.id,
        level = facility.level, revision = facility.revision })
    return { ok = true, facility = facility, event = "FacilityUpgraded" }
end

function Service.SetComponent(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= facility.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision }
    end
    local input = type(args.component) == "table" and PNC.Core.DeepCopy(args.component) or {}
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

function Service.RemoveComponent(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return { ok = false, reason = "FACILITY_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= facility.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = facility.revision }
    end
    local component = Repository.GetComponent(args.componentId)
    if not component or component.facilityId ~= facility.id then
        return { ok = false, reason = "COMPONENT_NOT_FOUND" }
    end
    Repository.State.components[component.id] = nil
    facility.componentIds[component.id] = nil
    if PNC.FacilityInteractionTargets then
        PNC.FacilityInteractionTargets.Invalidate(component.id)
    end
    if PNC.FacilityReservations then PNC.FacilityReservations.ReleaseComponent(component.id) end
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, { facilityId = facility.id,
        componentId = component.id, operation = "REMOVE", revision = facility.revision })
    return { ok = true, facility = facility, event = "FacilityComponentRemoved" }
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
    for componentId, _ in pairs(facility.componentIds) do
        Repository.State.components[componentId] = nil
        if PNC.FacilityReservations then PNC.FacilityReservations.ReleaseComponent(componentId) end
    end
    Repository.State.facilities[facility.id] = nil
    base.facilityIds[facility.id] = nil
    base.revision = base.revision + 1
    Repository.MarkDirty(); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_DESTROYED, { facilityId = facility.id, baseId = base.id })
    return { ok = true, event = "FacilityDestroyed" }
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
    for id, _ in pairs(facility.componentIds) do
        local component = Repository.GetComponent(id)
        if component then output.components[#output.components + 1] = PNC.Core.DeepCopy(component) end
    end
    return output
end

Repository.Load()
Service.RebuildIndexes()
return Service
