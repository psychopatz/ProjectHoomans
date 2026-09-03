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
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"

local function nativeWorkstationInfo(facility, placement, definition)
    local objectInfoName = placement and placement.objectInfoName
        or definition and (definition.buildRecipeObjectInfoName
            or definition.entityScript)
    local catalog = PNC.BuildRecipeCatalog
    if catalog and catalog.Get and objectInfoName then
        local descriptor = catalog.Get(objectInfoName)
        if descriptor and descriptor.nativeObjectInfo then
            return descriptor.nativeObjectInfo
        end
    end
    if catalog and catalog.Queries and catalog.Queries.FindForAliases
        and objectInfoName
    then
        local descriptor = catalog.Queries.FindForAliases({ objectInfoName })
        if descriptor and descriptor.nativeObjectInfo then
            return descriptor.nativeObjectInfo
        end
    end
    if catalog and catalog.Queries and catalog.Queries.FindNativeObjectInfo
        and objectInfoName
    then
        local info = catalog.Queries.FindNativeObjectInfo(objectInfoName)
        if info then return info end
    end
    if SpriteConfigManager and SpriteConfigManager.GetObjectInfo
        and objectInfoName
    then
        local ok, info = pcall(SpriteConfigManager.GetObjectInfo,
            objectInfoName)
        if ok and info then return info end
    end
    return nil
end

local function snapshotOccupiedRegion(facility, component)
    if component.occupiedRegion then
        return PNC.Core.DeepCopy(component.occupiedRegion)
    end
    if component.managedByFacility ~= true or component.kind ~= "anchor" then
        return nil
    end
    local definition = Definitions.Get(facility.definitionId)
    local placement = facility.workstationPlacement
    if not definition or not placement then return nil end
    local info = nativeWorkstationInfo(facility, placement, definition)
    local x = placement.x or component.x
    local y = placement.y or component.y
    local z = placement.z or component.z
    return Footprint.FromObjectInfo(info, placement.nSprite or 1,
        x, y, z)
end


function Service.BuildSnapshot(facility)
    if type(facility) ~= "table" then facility = Repository.GetFacility(facility) end
    if not facility then return nil end
    local output = PNC.Core.DeepCopy(facility)
    output.components = {}
    output.pendingComponents = {}
    output.discoveredComponents = {}
    output.roomProfile = nil
    output.farming = PNC.FarmingService and PNC.FarmingService.BuildFacilitySnapshot
        and PNC.FarmingService.BuildFacilitySnapshot(facility) or nil
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    output.capabilities = PNC.Core.DeepCopy(level and level.capabilities or {})
    output.workstations = PNC.Core.DeepCopy(level and level.workstations or {})
    output.workZoneEnabled = Definitions.RequiresWorkZone
        and Definitions.RequiresWorkZone(
            facility.definitionId, facility.level) == true or false
    for id, _ in pairs(facility.componentIds) do
        local component = Repository.GetComponent(id)
        if component then
            local snapshot = PNC.Core.DeepCopy(component)
            local occupied = snapshotOccupiedRegion(facility, component)
            if occupied then snapshot.occupiedRegion = occupied end
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
    if PNC.FacilityResources and PNC.FacilityResources.BuildSnapshot then
        local resources = PNC.FacilityResources.BuildSnapshot(facility)
        output.discoveredComponents = resources.components or {}
        output.roomProfile = resources.profile
        output.roomLabelKey = resources.profile
            and resources.profile.roomLabelKey or nil
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


return Service
