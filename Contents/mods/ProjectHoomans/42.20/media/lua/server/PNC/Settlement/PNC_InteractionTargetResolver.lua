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
        targets = resolverId == "workstationEdge" and {}
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

local function sleepSpotTargets(component)
    local square = SquareRules.GetSquare(component.x, component.y, component.z)
    local bed = SquareRules.DescribeBed(square)
    if not bed then
        return { {
            x = component.x + 0.5,
            y = component.y + 0.5,
            z = component.z,
            sceneId = "facility.sleep.floor",
            sleepSurface = "floor",
        } }
    end
    local offsets = {
        { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 },
    }
    local index
    for index = 1, #offsets do
        local x = component.x + offsets[index][1]
        local y = component.y + offsets[index][2]
        local square = SquareRules.GetSquare(x, y, component.z)
        if isApproachSquare(square) then
            return { {
                x = x + 0.5, y = y + 0.5, z = component.z,
                interactionX = bed.x,
                interactionY = bed.y,
                interactionZ = bed.z,
                interactionAxis = bed.axis,
                interactionFacing = bed.facing,
                sceneId = "facility.sleep.bed",
                sleepSurface = "bed",
                object = bed.object,
            } }
        end
    end
    return { {
        x = component.x + 0.5, y = component.y + 0.5, z = component.z,
        interactionX = bed.x,
        interactionY = bed.y,
        interactionZ = bed.z,
        interactionAxis = bed.axis,
        interactionFacing = bed.facing,
        sceneId = "facility.sleep.bed",
        sleepSurface = "bed",
        object = bed.object,
    } }
end

local function resourceBedTargets(resource, context)
    local originX = math.floor(tonumber(resource.originX)
        or tonumber(resource.x) or 0)
    local originY = math.floor(tonumber(resource.originY)
        or tonumber(resource.y) or 0)
    local originZ = math.floor(tonumber(resource.originZ)
        or tonumber(resource.z) or 0)
    local square = SquareRules.GetSquare(originX, originY, originZ)
    local bed = square and SquareRules.DescribeBed(square) or nil
    local loaded = square ~= nil
    if loaded and not bed then return {} end
    bed = bed or {
        object = resource.object,
        x = tonumber(resource.x) or originX + 0.5,
        y = tonumber(resource.y) or originY + 0.5,
        z = tonumber(resource.z) or originZ,
        axis = resource.axis,
        facing = resource.facing,
        surfaceOffset = resource.surfaceOffset,
    }
    local interactionZ = tonumber(bed.z) or originZ
    local surfaceOffset = tonumber(bed.surfaceOffset)
    if surfaceOffset and surfaceOffset > 0 then
        -- Project Zomboid stores furniture surface height in pixels. Match
        -- Offline Survivor's supported-bed placement conversion so the live
        -- NPC and its abstract position use the mattress height.
        interactionZ = interactionZ + (surfaceOffset + 1) / 96
    end
    local offsets = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } }
    for index = 1, #offsets do
        local x = originX + offsets[index][1]
        local y = originY + offsets[index][2]
        local approach = SquareRules.GetSquare(x, y, originZ)
        if isApproachSquare(approach) then
            return { {
                x = x + 0.5, y = y + 0.5, z = originZ,
                interactionX = bed.x, interactionY = bed.y,
                interactionZ = interactionZ, interactionAxis = bed.axis,
                interactionFacing = bed.facing,
                interactionSurfaceOffset = bed.surfaceOffset,
                sceneId = "facility.sleep.bed", sleepSurface = "bed",
                object = bed.object, resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
            } }
        end
    end
    return { {
        x = originX + 0.5, y = originY + 0.5, z = originZ,
        interactionX = bed.x, interactionY = bed.y, interactionZ = interactionZ,
        interactionAxis = bed.axis, interactionFacing = bed.facing,
        interactionSurfaceOffset = bed.surfaceOffset,
        sceneId = "facility.sleep.bed", sleepSurface = "bed",
        object = bed.object, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind,
    } }
end

local function fallbackSeatSpots(resource)
    local originX = math.floor(tonumber(resource.originX)
        or tonumber(resource.x) or 0)
    local originY = math.floor(tonumber(resource.originY)
        or tonumber(resource.y) or 0)
    local originZ = math.floor(tonumber(resource.originZ)
        or tonumber(resource.z) or 0)
    local offsets = {
        { 0, 1, "N" }, { 1, 0, "E" },
        { 0, -1, "S" }, { -1, 0, "W" },
    }
    local spots = {}
    -- Without an IsoGameCharacter, SeatingManager cannot validate the full
    -- animation-side approach. Keep these as rematerialization hints only;
    -- live resolution must use BuildSeatSpots instead.
    for index = 1, #offsets do
        local offset = offsets[index]
        local x = originX + offset[1]
        local y = originY + offset[2]
        local square = SquareRules.GetSquare(x, y, originZ)
        if isApproachSquare(square) then
            spots[#spots + 1] = {
                x = x + 0.5, y = y + 0.5, z = originZ,
                seatAnchorX = x + 0.5, seatAnchorY = y + 0.5,
                seatAnchorZ = originZ,
                direction = offset[3], side = "Front",
                approachKey = offset[3] .. ":Front", valid = false,
                approachValid = false, validationState = "DEFERRED",
                routeStatus = "DEFERRED",
            }
        end
    end
    if #spots == 0 then
        spots[1] = {
            x = originX + 0.5, y = originY + 0.5, z = originZ,
            seatAnchorX = originX + 0.5, seatAnchorY = originY + 0.5,
            seatAnchorZ = originZ,
            direction = "S", side = "Front",
            approachKey = "S:Front", valid = false,
            approachValid = false, validationState = "DEFERRED",
            routeStatus = "DEFERRED",
        }
    end
    return spots
end

local function resourceSeatTargets(resource, context)
    context = type(context) == "table" and context or {}
    local object = resource.object
    if not object and Resources and Resources.ResolveLiveObject
        and context.abstract ~= true
    then
        object = Resources.ResolveLiveObject(resource)
    end
    local spots = resource.seatSpots
    if object and context.character and Resources
        and Resources.BuildSeatSpots
    then
        local liveSpots = Resources.BuildSeatSpots(context.character, object)
        -- A live object with no SeatingManager approach position is not a
        -- usable live target. Abstract records may still use their captured
        -- primitive spot list or a conservative fallback for rematerializing.
        if #liveSpots > 0 then
            spots = liveSpots
        elseif context.abstract ~= true then
            return {}
        end
    elseif context.character and not object then
        -- A live body must never use an abstract or stale seat coordinate
        -- without resolving the current world object first.
        return {}
    end
    if type(spots) ~= "table" or #spots == 0 then
        if object and context.abstract ~= true then return {} end
        spots = fallbackSeatSpots(resource)
    end
    local character = context.character
    local requestedApproachKey = tostring(context.approachKey or "")
    local includeInvalid = context.includeInvalid == true
    local allowDeferred = context.abstract == true
    if character and character.getX and character.getY then
        table.sort(spots, function(left, right)
            local leftRequested = requestedApproachKey ~= ""
                and tostring(left.approachKey or "") == requestedApproachKey
            local rightRequested = requestedApproachKey ~= ""
                and tostring(right.approachKey or "") == requestedApproachKey
            if leftRequested ~= rightRequested then
                return leftRequested
            end
            local leftDistance = (left.x - character:getX())
                * (left.x - character:getX())
                + (left.y - character:getY())
                * (left.y - character:getY())
            local rightDistance = (right.x - character:getX())
                * (right.x - character:getX())
                + (right.y - character:getY())
                * (right.y - character:getY())
            return leftDistance < rightDistance
        end)
    elseif requestedApproachKey ~= "" then
        table.sort(spots, function(left, right)
            local leftRequested = tostring(left.approachKey or "")
                == requestedApproachKey
            local rightRequested = tostring(right.approachKey or "")
                == requestedApproachKey
            if leftRequested ~= rightRequested then
                return leftRequested
            end
            return tostring(left.approachKey or "")
                < tostring(right.approachKey or "")
        end)
    end
    local targets = {}
    for index = 1, #spots do
        local spot = spots[index]
        local validSpot = type(spot) == "table"
            and spot.valid ~= false and spot.approachValid ~= false
        if type(spot) == "table" and tonumber(spot.x)
            and tonumber(spot.y) and tonumber(spot.z)
            and (validSpot or includeInvalid or allowDeferred)
        then
            targets[#targets + 1] = {
                x = tonumber(spot.x), y = tonumber(spot.y),
                z = tonumber(spot.z), sceneId = "facility.living.sitFurniture",
                seatAnchorX = tonumber(spot.seatAnchorX or spot.x),
                seatAnchorY = tonumber(spot.seatAnchorY or spot.y),
                seatAnchorZ = tonumber(spot.seatAnchorZ or spot.z),
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                seating = true, seatDirection = spot.direction,
                seatSide = spot.side, approachKey = spot.approachKey,
                validSpot = validSpot,
                validationState = spot.validationState
                    or (validSpot and "VALID" or allowDeferred
                        and "DEFERRED" or "BLOCKED"),
                rejectionReason = spot.rejectionReason,
                routeStatus = spot.routeStatus
                    or (allowDeferred and "DEFERRED" or "UNTESTED"),
                -- SeatingManager returns the exact furniture animation anchor.
                -- Movement uses the corrected approach point above; the
                -- behavior performs a final authoritative snap to the
                -- separate animation anchor.
                stopDistance = 0.10,
                arrivalDistance = 0.14,
                object = object,
            }
        end
    end
    return targets
end

Targets.Register("sleepSpot", sleepSpotTargets)
-- Compatibility for components saved before sleep spots became furniture-optional.
Targets.Register("bed", sleepSpotTargets)
Targets.RegisterResource("bed", resourceBedTargets)
Targets.RegisterResource("seat", resourceSeatTargets)

return Targets
