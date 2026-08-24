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
        local level = facility and Definitions.GetLevel(
            facility.definitionId, facility.level) or nil
        -- Definitions are authoritative. Remove saved components belonging to
        -- retired roles (research.room, workshop.room, and future migrations)
        -- instead of allowing obsolete UI requirements to survive forever.
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
    local products = {}
    for _, cost in ipairs(costs) do
        local fullType = cost.fullType
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

return Service
