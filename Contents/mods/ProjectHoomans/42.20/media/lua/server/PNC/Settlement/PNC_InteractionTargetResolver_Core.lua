if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityInteractionTargets = PNC.FacilityInteractionTargets or {}

local Targets = PNC.FacilityInteractionTargets
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"
local Resources = PNC.FacilityResources
Targets.Resolvers = Targets.Resolvers or {}
Targets.ResourceResolvers = Targets.ResourceResolvers or {}
Targets.Cache = Targets.Cache or {}

function Targets.Register(id, resolver)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "INVALID_RESOLVER"
    end
    Targets.Resolvers[id] = resolver
    return true
end

function Targets.RegisterResource(id, resolver)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "INVALID_RESOURCE_RESOLVER"
    end
    Targets.ResourceResolvers[id] = resolver
    return true
end

function Targets.Invalidate(componentId)
    Targets.Cache[tostring(componentId or "")] = nil
end

function Targets.Resolve(component, context)
    if type(component) ~= "table" or component.kind ~= "anchor" then return {} end
    local dynamicSleep = component.role == "sleep.bed"
        or component.targetResolver == "sleepSpot"
        or component.targetResolver == "bed"
    local contextResolver = type(context) == "table"
        and context.targetResolver or nil
    local resolverId = component.role == "sleep.bed"
        and "sleepSpot" or component.targetResolver or contextResolver
    local dynamic = dynamicSleep or resolverId == "workstationEdge"
    local cached = not dynamic and Targets.Cache[component.id] or nil
    if cached and cached.revision == component.revision then return cached.targets end
    local resolver = Targets.Resolvers[resolverId]
    local targets = resolver and resolver(component, context or {}) or nil
    if type(targets) ~= "table" or #targets == 0 then
        targets = (resolverId == "workstationEdge" or dynamicSleep) and {}
            or { { x = component.x, y = component.y, z = component.z } }
    end
    if not dynamic then
        Targets.Cache[component.id] = { revision = component.revision, targets = targets }
    end
    return targets
end

function Targets.ResolveResource(resource, context)
    if type(resource) ~= "table" then return {} end
    local resolverId = tostring(resource.targetResolver
        or resource.detectorId or "")
    local resolver = Targets.ResourceResolvers[resolverId]
    local targets = resolver and resolver(resource, context or {}) or nil
    return type(targets) == "table" and targets or {}
end

function Targets.ReportPathFailure(componentId)
    Targets.Invalidate(componentId)
end

Targets.Register("worldObject", function(component, context)
    if component.objectTag == "bed" and Targets.Resolvers.sleepSpot then
        return Targets.Resolvers.sleepSpot(component, context)
    end
    if PNC.WorldObjectTargetResolvers
        and type(PNC.WorldObjectTargetResolvers[component.objectTag]) == "function"
    then
        return PNC.WorldObjectTargetResolvers[component.objectTag](component,
            context)
    end
    return { { x = component.x, y = component.y, z = component.z } }
end)

local function isApproachSquare(square)
    if not square then return false end
    if square.isFree then
        return square:isFree(false) == true
    end
    return true
end

local function nativeWorkstationInfo(component, context)
    local facility = context and context.facility
    local placement = facility and facility.workstationPlacement or nil
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility and facility.definitionId)
        or nil
    local objectInfoName = component.objectInfoName
        or placement and placement.objectInfoName
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

local function workstationOccupiedRegion(component, context)
    if component.occupiedRegion then
        return GridRegion.normalize(component.occupiedRegion)
    end
    local facility = context and context.facility
    local placement = facility and facility.workstationPlacement or nil
    local info = nativeWorkstationInfo(component, context)
    local x = placement and placement.x or component.x
    local y = placement and placement.y or component.y
    local z = placement and placement.z or component.z
    return Footprint.FromObjectInfo(info,
        component.nSprite or placement and placement.nSprite or 1,
        x, y, z) or Footprint.Anchor(x, y, z)
end

local function facingToward(fromX, fromY, toX, toY)
    local dx, dy = (toX or 0) - (fromX or 0), (toY or 0) - (fromY or 0)
    if math.abs(dx) > math.abs(dy) then return dx > 0 and "E" or "W" end
    return dy >= 0 and "S" or "N"
end

local function workstationEdgeTargets(component, context)
    context = type(context) == "table" and context or {}
    local occupied = workstationOccupiedRegion(component, context)
    if not occupied then return {} end
    local offsets = {
        { x = 0, y = 1, order = 1 }, { x = 1, y = 0, order = 2 },
        { x = 0, y = -1, order = 3 }, { x = -1, y = 0, order = 4 },
    }
    local candidates, seen = {}, {}
    local allowDeferred = context.abstract == true or not context.character
    local character = context.character
    local anchorX = (tonumber(component.x) or 0) + 0.5
    local anchorY = (tonumber(component.y) or 0) + 0.5
    Footprint.ForEachTile(occupied, function(sourceX, sourceY, sourceZ)
        for _, offset in ipairs(offsets) do
            local x, y, z = sourceX + offset.x, sourceY + offset.y, sourceZ
            local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
            if not GridRegion.containsPoint(occupied, x, y, z)
                and not seen[key]
            then
                local square = allowDeferred
                    and true or SquareRules.GetSquare(x, y, z)
                if allowDeferred or isApproachSquare(square) then
                    local targetX, targetY = x + 0.5, y + 0.5
                    local distance = (targetX - anchorX) * (targetX - anchorX)
                        + (targetY - anchorY) * (targetY - anchorY)
                    if character and character.getX and character.getY then
                        local dx = targetX - character:getX()
                        local dy = targetY - character:getY()
                        distance = dx * dx + dy * dy
                    end
                    seen[key] = true
                    candidates[#candidates + 1] = {
                        x = targetX, y = targetY, z = z,
                        interactionX = sourceX + 0.5,
                        interactionY = sourceY + 0.5,
                        interactionZ = sourceZ,
                        interactionFacing = facingToward(targetX, targetY,
                            sourceX + 0.5, sourceY + 0.5),
                        interactionTarget = true,
                        approachKey = key,
                        distance = distance, order = offset.order,
                    }
                end
            end
        end
        return true
    end)
    table.sort(candidates, function(left, right)
        if left.distance ~= right.distance then
            return left.distance < right.distance
        end
        if left.order ~= right.order then return left.order < right.order end
        return left.approachKey < right.approachKey
    end)
    for _, target in ipairs(candidates) do
        target.distance, target.order = nil, nil
    end
    return candidates
end

Targets.Register("workstationEdge", workstationEdgeTargets)


Targets.Internal = Targets.Internal or {}
local Internal = Targets.Internal
Internal.isApproachSquare = isApproachSquare
Internal.nativeWorkstationInfo = nativeWorkstationInfo
Internal.workstationOccupiedRegion = workstationOccupiedRegion
Internal.workstationEdgeTargets = workstationEdgeTargets

return Targets
