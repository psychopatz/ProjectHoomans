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
local BuildCatalog = PNC.BuildRecipeCatalog
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

local function tileRegion(x, y, z)
    return GridRegion.normalize({ levels = {
        [z] = { rows = {
            [y] = { x, x },
        } },
    } })
end

local function candidateWorkZones(region)
    local normalized = GridRegion.normalize(region)
    local candidates, seen = {}, {}
    local function add(x, y, z)
        local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
        if not seen[key] then
            seen[key] = true
            candidates[#candidates + 1] = tileRegion(x, y, z)
        end
    end
    local function addAdjacent(x, y, z)
        if not GridRegion.containsPoint(normalized, x, y, z) then
            add(x, y, z)
        end
    end
    for z, level in pairs(normalized.levels) do
        for y, spans in pairs(level.rows) do
            for index = 1, #spans, 2 do
                local first, last = spans[index], spans[index + 1]
                -- Prefer a cardinally adjacent standing tile. The endpoint
                -- candidates cover both rectangular and irregular footprints
                -- without expanding every tile in a large room.
                addAdjacent(first - 1, y, z)
                addAdjacent(last + 1, y, z)
                addAdjacent(first, y - 1, z)
                addAdjacent(last, y - 1, z)
                addAdjacent(first, y + 1, z)
                addAdjacent(last, y + 1, z)
                -- Keep an inside-footprint fallback for enclosed facilities.
                add(first, y, z)
            end
        end
    end
    return candidates
end

local function buildDefaultWorkZone(base, facility, region, componentId)
    if not base or not facility or not region
        or not Validation.NormalizeComponent
    then
        return nil, "FACILITY_WORK_ZONE_REQUIRED"
    end
    local candidates = candidateWorkZones(region)
    for index = 1, #candidates do
        local check = Validation.NormalizeComponent(base, facility, {
            id = componentId or PNC.Core.GenerateID("workzone"), kind = "region",
            role = "work.zone", region = candidates[index],
        })
        if check.ok then return check.details.component end
    end
    return nil, "FACILITY_WORK_ZONE_REQUIRED"
end

local function ensureWorkZone(facility, base)
    if not facility or not base then return false end
    local existing
    for componentId, present in pairs(facility.componentIds or {}) do
        if present == true then
            local component = Repository.GetComponent(componentId)
            if component and component.role == "work.zone" then
                existing = component
                break
            end
        end
    end
    if existing and existing.kind == "region"
        and existing.region and facility.constructionRegion
        and Validation.Internal.WorkZoneTouchesFacility
        and Validation.Internal.WorkZoneTouchesFacility(facility, existing.region)
    then
        return false
    end
    local component = buildDefaultWorkZone(
        base, facility, facility.constructionRegion,
        existing and existing.id or nil)
    if not component then return false end
    facility.componentIds = facility.componentIds or {}
    component.revision = existing
        and (tonumber(existing.revision) or 0) + 1 or component.revision
    Repository.State.components[component.id] = component
    facility.componentIds[component.id] = true
    return true
end

function Service.RebuildIndexes()
    Service.ByType, Service.ByCapability, Service.ComponentsByRole = {}, {}, {}
    local obsoleteComponents = {}
    for id, facility in pairs(Repository.State.facilities) do
        local base = PNC.BaseService.Get(facility.baseId)
        if base then
            if ensureWorkZone(facility, base) then
                Repository.MarkDirty()
            end
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
        local level = facility and Definitions.GetLevel(
            facility.definitionId, facility.level) or nil
        -- Definitions are authoritative. Remove saved components belonging to
        -- retired roles (research.room, research virtual benches/labs,
        -- workshop.room, and future migrations) instead of allowing obsolete
        -- UI requirements to survive forever.
        if facility and level and level.componentLimits
            and level.componentLimits[component.role] == nil
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

function Service.DebugGrantMaterials(player, args)
    args = type(args) == "table" and args or {}
    local storageService = PNC.ColonyStorageService
    if not storageService or not storageService.ResolveForPlayer
        or not storageService.DebugAction
    then
        return nil, "STORAGE_DEBUG_UNAVAILABLE"
    end
    local storage, reason = storageService.ResolveForPlayer(player)
    if not storage then return nil, reason end
    local definition = Definitions.Get(args.definitionId)
    if not definition then return nil, "FACILITY_DEFINITION_NOT_FOUND" end
    local costs = definition.buildCosts or definition.buildCost or {}
    local catalog = PNC.BuildRecipeCatalog or BuildCatalog
    if definition.directWorkstation == true and catalog then
        local objectInfoName = definition.buildRecipeObjectInfoName
            or definition.entityScript
        local descriptor = catalog.Get and catalog.Get(objectInfoName)
            or catalog.Queries and catalog.Queries.FindForObjectInfo
            and catalog.Queries.FindForObjectInfo(objectInfoName)
        if descriptor and type(descriptor.requirements) == "table" then
            costs = descriptor.requirements
        end
    end
    local products = {}
    for _, cost in ipairs(costs) do
        local fullType = cost.fullType or cost.itemType
            or cost.itemTypes and cost.itemTypes[1]
        local quantity = math.max(1, math.floor(
            tonumber(cost.amount or cost.quantity) or 1))
        if fullType then
            products[#products + 1] = {
                fullType = tostring(fullType), quantity = quantity,
            }
        end
    end
    if #products == 0 then return nil, "FACILITY_HAS_NO_BUILD_MATERIALS" end
    local granted, grantReason, _, grantDetails = storageService.DebugAction(
        player, {
            debugAction = "add_many",
            storageId = storage.id,
            products = products,
            requestId = args.requestId,
            transactionLogging = args.transactionLogging,
        })
    if not granted then return nil, grantReason end
    return {
        definitionId = tostring(args.definitionId),
        storageId = storage.id,
        products = products,
        storageDetails = grantDetails,
    }, "FACILITY_MATERIALS_GRANTED"
end


Internal.calculatedState = calculatedState
Internal.emit = emit
Internal.addIndex = addIndex
Internal.touch = touch
Internal.updateState = updateState
Internal.GridRegion = GridRegion
Internal.buildDefaultWorkZone = buildDefaultWorkZone
Internal.ensureWorkZone = ensureWorkZone

return Service
