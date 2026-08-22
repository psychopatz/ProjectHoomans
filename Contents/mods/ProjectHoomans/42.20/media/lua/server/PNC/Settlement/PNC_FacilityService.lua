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
    return true, "FacilityUpgraded"
end

local function isBuilt(facility)
    return facility.constructionState == nil
        or facility.constructionState == "BUILT"
end

local function validationFacilityWithoutRole(facility, role)
    local output = PNC.Core.DeepCopy(facility)
    output.componentIds = {}
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true
            and Repository.GetComponent(componentId) or nil
        if not component or component.role ~= role then
            output.componentIds[componentId] = present
        end
    end
    return output
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
    if facility.definitionId == "stockpile" and result.component
        and result.component.role == "storage.stockpile"
        and result.component.region
    then
        facility.constructionRegion = PNC.Core.DeepCopy(result.component.region)
    end
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
    if facility.definitionId == "stockpile"
        or component.role == "storage.stockpile"
    then
        return false, "STOCKPILE_CANNOT_DECONSTRUCT"
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

function Service.FinalizeReplaceAnchorRole(facilityId, role, anchors)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    local limit = level and level.componentLimits and level.componentLimits[role]
    if not limit or limit.kind ~= "anchor" then
        return false, "INVALID_COMPONENT_ROLE"
    end
    anchors = type(anchors) == "table" and anchors or {}
    if #anchors < (tonumber(limit.minCount) or 0)
        or limit.maxCount and #anchors > limit.maxCount
    then return false, "FACILITY_COMPONENT_LIMIT" end
    local validationFacility = validationFacilityWithoutRole(facility, role)
    local normalized = {}
    for index, anchor in ipairs(anchors) do
        local check = Validation.NormalizeComponent(base, validationFacility, {
            id = PNC.Core.GenerateID("component"), kind = "anchor", role = role,
            x = anchor.x, y = anchor.y, z = anchor.z,
            targetResolver = role == "sleep.bed" and "sleepSpot" or nil,
        })
        if check.ok ~= true then return false, check.reason end
        normalized[index] = check.details.component
    end
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true and Repository.GetComponent(componentId)
        if component and component.role == role then
            facility.componentIds[componentId] = nil
            Repository.State.components[componentId] = nil
            if PNC.FacilityInteractionTargets then
                PNC.FacilityInteractionTargets.Invalidate(componentId)
            end
            if PNC.FacilityReservations then
                PNC.FacilityReservations.ReleaseComponent(componentId)
            end
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
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, "FacilityAnchorRoleReplaced"
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

function Service.ListByCapability(baseId, capability)
    local output = {}
    local requestedBaseId = tostring(baseId or "")
    for id, _ in pairs(Service.ByCapability[tostring(capability or "")] or {}) do
        local facility = Repository.GetFacility(id)
        if facility and tostring(facility.baseId or "") == requestedBaseId then
            -- Saved facilities may still carry the cached state calculated by
            -- an older component definition (notably the retired
            -- research.room requirement). Capability discovery is the last
            -- gate before assigning a worker, so refresh the inexpensive
            -- logical state here instead of leaving valid work in limbo.
            local base = PNC.BaseService.Get(facility.baseId)
            local currentState = base and calculatedState(base, facility)
                or "INVALID_COMPONENT"
            if facility.cachedState ~= currentState then
                facility.cachedState = currentState
                Repository.MarkDirty()
            end
            local hasRequestedWorkstation = false
            if string.sub(tostring(capability or ""), 1, 5) == "work."
                and facility.constructionState == "BUILT"
            then
                for componentId, _ in pairs(facility.componentIds or {}) do
                    local component = Repository.GetComponent(componentId)
                    if component and component.role == capability then
                        hasRequestedWorkstation = true
                        break
                    end
                end
            end
            -- Workstation lanes become usable independently. A workshop with
            -- a craft station may craft while its disassembly station remains
            -- unassigned, and research benches behave the same way.
            if currentState == "OPERATIONAL" or hasRequestedWorkstation then
                output[#output + 1] = facility
            end
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
    output.pendingComponents = {}
    output.farming = PNC.FarmingService and PNC.FarmingService.BuildFacilitySnapshot
        and PNC.FarmingService.BuildFacilitySnapshot(facility) or nil
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    output.capabilities = PNC.Core.DeepCopy(level and level.capabilities or {})
    output.workstations = PNC.Core.DeepCopy(level and level.workstations or {})
    for id, _ in pairs(facility.componentIds) do
        local component = Repository.GetComponent(id)
        if component then
            local snapshot = PNC.Core.DeepCopy(component)
            if output.farming and component.role == "growing.plot" then
                for _, plot in ipairs(output.farming.plots or {}) do
                    if tostring(plot.id) == tostring(component.id) then
                        snapshot.width, snapshot.height = plot.width, plot.height
                        snapshot.status = plot.status
                        snapshot.diagnostics = plot.diagnostics
                        break
                    end
                end
            end
            output.components[#output.components + 1] = snapshot
        end
    end
    for _, order in pairs(PNC.WorkRepository
        and PNC.WorkRepository.State and PNC.WorkRepository.State.byId or {}) do
        local payload = order.payload or {}
        local change = payload.change or {}
        if order.operation == "RECONSTRUCT"
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
            and tostring(payload.facilityId or "") == tostring(facility.id)
            and (change.action == "set" and change.component
                or change.action == "replace_role"
                    and type(change.anchors) == "table")
        then
            if change.action == "set" then
                local pending = PNC.Core.DeepCopy(change.component)
                pending.pending = true
                output.pendingComponents[#output.pendingComponents + 1] = pending
            else
                for pendingIndex, anchor in ipairs(change.anchors) do
                    output.pendingComponents[#output.pendingComponents + 1] = {
                        schemaVersion = 1,
                        id = "pending:" .. tostring(order.id) .. ":"
                            .. tostring(pendingIndex),
                        facilityId = facility.id,
                        kind = "anchor",
                        role = change.role,
                        x = anchor.x, y = anchor.y, z = anchor.z,
                        pending = true,
                    }
                end
            end
        end
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
