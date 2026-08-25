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

function H.AwardBuildXP(order, descriptor)
    local payload = order.payload or {}
    local awards = descriptor and descriptor.xpAwards or {}
    local awarded = payload.xpAwarded or {}
    local record

    if payload.xpGranted == true then return true end
    if #awards == 0 then
        payload.xpAwarded = awarded
        payload.xpGranted = true
        Repository.MarkDirty()
        return true
    end

    record = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if not record or not PNC.Skills
        or type(PNC.Skills.AddXP) ~= "function"
    then
        return false, "BUILD_XP_WORKER_UNAVAILABLE"
    end

    for index, award in ipairs(awards) do
        local key = tostring(index)
        if awarded[key] ~= true then
            local ok = PNC.Skills.AddXP(record, award.skillId,
                tonumber(award.amount) or 0)
            if ok ~= true then
                return false, "BUILD_XP_NOT_APPLIED"
            end
            -- Persist each entry separately so a retry after a partial
            -- failure cannot award an earlier recipe entry twice.
            awarded[key] = true
            payload.xpAwarded = awarded
            Repository.MarkDirty()
        end
    end

    payload.xpGranted = true
    Repository.MarkDirty()
    return true
end

function H.Complete(order)
    local placed, reason = H.Place(order)
    if not placed then return false, reason end
    local committed
    committed, reason = PNC.WorkInputService.Commit(order,
        "building_material_consumption")
    if not committed then return false, reason end
    local blueprint = H.BlueprintFor(order)
    local descriptor = Catalog.Get(blueprint and blueprint.objectInfoName)
    local payload = order.payload or {}
    if payload.facilityId and PNC.FacilityService
        and PNC.FacilityService.FinalizeNativeWorkstationBuild
    then
        local finalized, finalizeReason =
            PNC.FacilityService.FinalizeNativeWorkstationBuild(
                payload.facilityId, order.id, blueprint)
        if not finalized then return false, finalizeReason end
    end
    return H.AwardBuildXP(order, descriptor)
end

function H.Refund(order)
    local payload = order.payload or {}
    local input = payload.input or {}
    if input.consume == true and input.committed ~= true then
        return true
    end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local remaining = math.max(0, (required - math.min(required,
        tonumber(order.progress) or 0)) / required)
    local products = {}
    for _, requirement in ipairs(payload.materialRequirements or {}) do
        if requirement.consumed ~= false then
            local fullType = requirement.fullType
                or requirement.itemTypes and requirement.itemTypes[1]
            local quantity = math.floor((tonumber(requirement.amount) or 0)
                * remaining + 0.000001)
            if fullType and quantity > 0 then
                products[#products + 1] = { fullType = fullType,
                    quantity = quantity }
            end
        end
    end
    if #products == 0 then return true end
    local storageId = payload.storageId or input.storageId
    local ok, reason = PNC.ColonyStorageService.DepositProductionItems(
        storageId, products, nil, order.id, "building_cancellation_refund")
    return ok, reason
end

function H.Cancel(order)
    local ok, reason = H.Refund(order)
    if not ok then return false, reason end
    local payload = order.payload or {}
    if payload.facilityId and PNC.FacilityService
        and PNC.FacilityService.RemoveNativeWorkstation
    then
        local removed, removeReason =
            PNC.FacilityService.RemoveNativeWorkstation(
                payload.facilityId, order.id)
        if not removed then return false, removeReason end
    end
    return PNC.WorkInputService.Cancel(order)
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.BUILD_OBJECT = H.Cancel
PNC.WorkService.RegisterTargetProvider("BUILD_OBJECT", H.ResolveTarget)
PNC.WorkService.RegisterPreparation("BUILD_OBJECT", H.Prepare)
PNC.WorkService.RegisterCompletion("BUILD_OBJECT", H.Complete)

return Service
