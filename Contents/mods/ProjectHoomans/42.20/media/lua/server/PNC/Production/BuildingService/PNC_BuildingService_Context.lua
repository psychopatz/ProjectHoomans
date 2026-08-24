if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}
PNC.BuildingServiceInternal = PNC.BuildingServiceInternal or {}

local Service = PNC.BuildingService
local H = PNC.BuildingServiceInternal
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

function H.Copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

function H.Active(order)
    return order and order.status ~= "COMPLETED"
        and order.status ~= "CANCELLED" and order.status ~= "FAILED"
end

function H.ContextFor(player)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    if not PNC.BaseValidationService.CanUse(player, context.base) then
        return nil, "NO_PERMISSION"
    end
    if not context.storage then return nil, "STORAGE_REQUIRED" end
    return context
end

function H.BlueprintFor(order)
    local payload = order and order.payload or {}
    return payload and payload.blueprint or nil
end

function H.TargetValid(base, blueprint)
    if not base or not blueprint then return false end
    local zone = Zones.get(base.baseZoneId)
    return zone and zone.geometry
        and GridRegion.containsXY(zone.geometry,
            math.floor(tonumber(blueprint.x) or 0),
            math.floor(tonumber(blueprint.y) or 0)) == true
end

function H.DuplicateAt(colonyId, blueprint)
    for _, order in pairs(Repository.State.byId or {}) do
        local other = H.BlueprintFor(order)
        if H.Active(order) and order.operation == "BUILD_OBJECT"
            and tostring(order.colonyId) == tostring(colonyId)
            and other and tonumber(other.x) == tonumber(blueprint.x)
            and tonumber(other.y) == tonumber(blueprint.y)
            and tonumber(other.z) == tonumber(blueprint.z)
        then return true end
    end
    return false
end

function H.RequirementSnapshot(storageId, requirements)
    local output = {}
    for _, requirement in ipairs(requirements or {}) do
        local available = PNC.ColonyStorageService.CountProductionAvailable(
            storageId, requirement.itemTypes)
        local names = {}
        for _, fullType in ipairs(requirement.itemTypes or {}) do
            names[#names + 1] = tostring(fullType)
        end
        output[#output + 1] = {
            itemTypes = H.Copy(requirement.itemTypes or {}),
            names = names,
            amount = tonumber(requirement.amount) or 1,
            consumed = requirement.consumed ~= false,
            available = available,
            ready = available >= (tonumber(requirement.amount) or 1),
        }
    end
    return output
end

function H.PublicDescriptor(descriptor, storageId)
    descriptor = descriptor or {}
    return {
        id = descriptor.id,
        recipeKey = descriptor.recipeKey,
        objectInfoName = descriptor.objectInfoName,
        displayName = descriptor.displayName,
        recipeName = descriptor.recipeName,
        category = descriptor.category,
        iconName = descriptor.iconName,
        buildWork = descriptor.buildWork,
        requiredSkills = H.Copy(descriptor.requiredSkills or {}),
        requirements = H.Copy(descriptor.requirements or {}),
        materials = H.RequirementSnapshot(storageId, descriptor.requirements),
    }
end

