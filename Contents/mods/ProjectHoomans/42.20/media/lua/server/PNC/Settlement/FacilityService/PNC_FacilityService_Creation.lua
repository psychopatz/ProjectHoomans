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
local buildDefaultWorkZone = Internal.buildDefaultWorkZone

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
    local nativeBuild = args.nativeBuild == true
        and definition and definition.directWorkstation == true
    local capacity
    if args.capacity ~= nil and PNC.FacilityResources
        and PNC.FacilityResources.NormalizeCapacity
    then
        local capacityReason
        capacity, capacityReason = PNC.FacilityResources.NormalizeCapacity(
            args.capacity)
        if capacityReason then
            return { ok = false, reason = capacityReason }
        end
    end
    local id = tostring(args.facilityId or PNC.Core.GenerateID("facility"))
    local facility = { schemaVersion = 1, id = id, baseId = base.id,
        definitionId = tostring(args.definitionId), level = 1,
        componentIds = {}, revision = 0, cachedState = "PLANNED",
        constructionState = "PLANNED", capacity = capacity }
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
    if definition.directWorkstation == true
        and GridRegion.countTiles(constructionRegion) ~= 1
    then
        return { ok = false, reason = "WORKSTATION_SINGLE_TILE_REQUIRED" }
    end
    local initialComponent = definition.providesStockpileAccess == true
        and footprintCheck.details.component or nil
    for _, other in pairs(Repository.State.facilities or {}) do
        if other.constructionRegion and GridRegion.intersects(
            constructionRegion, other.constructionRegion)
        then return { ok = false, reason = "OVERLAP_NOT_ALLOWED" } end
    end
    facility.constructionRegion = constructionRegion
    local workZone
    if Definitions.RequiresWorkZone(args.definitionId, facility.level) then
        local workZoneReason
        workZone, workZoneReason = buildDefaultWorkZone(
            base, facility, constructionRegion)
        if not workZone then
            return { ok = false, reason = workZoneReason
                or "FACILITY_WORK_ZONE_REQUIRED" }
        end
    end
    local managedWorkstation
    if definition.directWorkstation == true then
        local bounds = GridRegion.bounds(constructionRegion)
        if not bounds then
            return { ok = false, reason = "WORKSTATION_LOCATION_REQUIRED" }
        end
        local role = definition.workstationRole or "work.craft"
        local check = Validation.NormalizeComponent(base, facility, {
            id = PNC.Core.GenerateID("workstation"), kind = "anchor",
            role = role, x = bounds.minX, y = bounds.minY, z = bounds.minZ,
        })
        if not check.ok then return check end
        managedWorkstation = check.details.component
        managedWorkstation.managedByFacility = true
        managedWorkstation.workstationId = definition.stationId
        managedWorkstation.entityScript = definition.entityScript
        facility.workstationPlacement = {
            kind = "workstation", stationId = definition.stationId,
            entityScript = definition.entityScript,
            x = bounds.minX, y = bounds.minY, z = bounds.minZ,
            placed = false,
        }
    end
    Repository.State.facilities[id] = facility
    base.facilityIds[id] = true
    if initialComponent then
        Repository.State.components[initialComponent.id] = initialComponent
        facility.componentIds[initialComponent.id] = true
    end
    if managedWorkstation then
        Repository.State.components[managedWorkstation.id] = managedWorkstation
        facility.componentIds[managedWorkstation.id] = true
    end
    if workZone then
        Repository.State.components[workZone.id] = workZone
        facility.componentIds[workZone.id] = true
    end
    local workOrder, workReason
    if nativeBuild then
        -- The native Build 42 object order owns material reservation and
        -- world placement. This facility record is prepared here so the
        -- workstation can participate in colony work as soon as that order
        -- completes.
        facility.nativeBuildPending = true
        workOrder = { nativeBuildPending = true }
    elseif PNC.ConstructionService then
        workOrder, workReason = PNC.ConstructionService.QueueBuild(
            player, facility, definition)
    else
        workReason = "CONSTRUCTION_SERVICE_UNAVAILABLE"
    end
    if not workOrder then
        if initialComponent then
            Repository.State.components[initialComponent.id] = nil
        end
        if managedWorkstation then
            Repository.State.components[managedWorkstation.id] = nil
        end
        if workZone then
            Repository.State.components[workZone.id] = nil
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
        workOrder = nativeBuild and nil or workOrder,
        event = nativeBuild and "FacilityNativeBuildPrepared"
            or "FacilityConstructionQueued" }
end

function Service.FinalizeNativeWorkstationBuild(facilityId, orderId, blueprint)
    local facility = Repository.GetFacility(facilityId)
    if not facility or facility.nativeBuildPending ~= true then
        return false, "FACILITY_NOT_FOUND"
    end
    if facility.constructionWorkOrderId
        and tostring(facility.constructionWorkOrderId)
            ~= tostring(orderId or "")
    then
        return false, "FACILITY_BUILD_ORDER_MISMATCH"
    end
    local placement = facility.workstationPlacement
    if placement and blueprint then
        placement.x = tonumber(blueprint.x) or placement.x
        placement.y = tonumber(blueprint.y) or placement.y
        placement.z = tonumber(blueprint.z) or placement.z
        placement.sprite = blueprint.sprite or placement.sprite
        placement.placed = true
    end
    facility.nativeBuildPending = nil
    facility.constructionState = "BUILT"
    facility.constructionWorkOrderId = nil
    local base = PNC.BaseService.Get(facility.baseId)
    if not base then return false, "BASE_NOT_FOUND" end
    touch(base, facility)
    updateState(base, facility)
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_STATE_CHANGED, {
        facilityId = facility.id, revision = facility.revision,
        state = facility.cachedState,
    })
    return true, facility
end

function Service.RemoveNativeWorkstation(facilityId, orderId)
    local facility = Repository.GetFacility(facilityId)
    if not facility or facility.nativeBuildPending ~= true then return true end
    if facility.constructionWorkOrderId
        and tostring(facility.constructionWorkOrderId)
            ~= tostring(orderId or "")
    then
        return false, "FACILITY_BUILD_ORDER_MISMATCH"
    end
    local base = PNC.BaseService.Get(facility.baseId)
    if not base then return false, "BASE_NOT_FOUND" end
    for componentId, present in pairs(facility.componentIds or {}) do
        if present == true then
            Repository.State.components[componentId] = nil
        end
    end
    touch(base, facility)
    Repository.State.facilities[facility.id] = nil
    base.facilityIds[facility.id] = nil
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_DESTROYED, {
        facilityId = facility.id, baseId = base.id,
    })
    return true
end


return Service
