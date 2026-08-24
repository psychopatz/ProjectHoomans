if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}
PNC.BuildingServiceInternal = PNC.BuildingServiceInternal or {}

local Service = PNC.BuildingService
local H = PNC.BuildingServiceInternal
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions

function H.ResolveTarget(order)
    local blueprint = H.BlueprintFor(order)
    local base = PNC.BaseService.Get(order.baseId)
    if not blueprint or not H.TargetValid(base, blueprint) then
        return { ok = false, reason = "BUILD_TARGET_INVALID" }
    end
    return { ok = true, componentId = "build:" .. tostring(order.id),
        facilityId = "build:" .. tostring(order.id),
        target = { x = blueprint.x, y = blueprint.y, z = blueprint.z } }
end

function H.Prepare(order)
    local blueprint = H.BlueprintFor(order)
    if not blueprint or not Catalog.Get(blueprint.objectInfoName) then
        return false, "BUILD_RECIPE_NOT_FOUND"
    end
    local base = PNC.BaseService.Get(order.baseId)
    if not H.TargetValid(base, blueprint) then
        return false, "BUILD_TARGET_INVALID"
    end
    local input = order.payload and order.payload.input or nil
    if input and tonumber(order.progress) and tonumber(order.progress) > 0
        and not order.funded and input.funded ~= true
        and input.committed ~= true and (input.storageId == nil
            or input.storageId == "") and (input.reservationId == nil
            or input.reservationId == "")
    then
        order.funded = true
        input.funded, input.committed, input.legacyRecovered = true, true, true
        Repository.MarkDirty()
        return true
    end
    if order.funded == true or input and (input.funded == true
        or input.committed == true)
    then order.funded = true; return true end
    if input and PNC.WorkInputService.IsReady(order) then return true end
    return false, input and "BUILDING_INPUTS_UNAVAILABLE"
        or "BUILDING_INPUTS_MISSING"
end

