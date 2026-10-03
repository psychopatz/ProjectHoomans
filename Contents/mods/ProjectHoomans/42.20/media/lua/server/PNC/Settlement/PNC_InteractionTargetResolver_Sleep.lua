if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Furniture sleep surfaces and bounded approach target resolution.
local Targets = PNC.FacilityInteractionTargets
local Internal = Targets.Internal
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local isApproachSquare = Internal.isApproachSquare
local sleepCapacity = nil
local sleepFootprint = nil
local sleepApproachCandidates = nil
local sleepSurfaceTargets = nil

local function sleepCapacity(surface, resource)
    local explicit = tonumber(resource and resource.sleepCapacity)
        or tonumber(surface and surface.sleepCapacity)
    if explicit and explicit >= 1 then
        return math.min(2, math.floor(explicit))
    end
    if tostring(resource and resource.sleepSurface
        or surface and surface.sleepSurface or "") == "sofa"
    then
        return 1
    end
    local width = tonumber(resource and (resource.gridWidth
        or resource.sleepGridWidth))
        or tonumber(surface and surface.gridWidth) or 1
    local height = tonumber(resource and (resource.gridHeight
        or resource.sleepGridHeight))
        or tonumber(surface and surface.gridHeight) or 1
    return math.max(width, height) >= 2 and 2 or 1
end

local function sleepFootprint(surface, originX, originY)
    local width = math.max(1, math.floor(tonumber(surface.gridWidth) or 1))
    local height = math.max(1, math.floor(tonumber(surface.gridHeight) or 1))
    local gridX = tonumber(surface.gridX)
    local gridY = tonumber(surface.gridY)
    local baseX = gridX and originX - math.floor(gridX) or originX
    local baseY = gridY and originY - math.floor(gridY) or originY
    return baseX, baseY, width, height
end

local function sleepApproachCandidates(surface, originX, originY, originZ,
    context)
    context = type(context) == "table" and context or {}
    local baseX, baseY, width, height = sleepFootprint(
        surface, originX, originY)
    local allowDeferred = context.abstract == true or not context.character
    local offsets = {
        { x = 0, y = 1, order = 1 }, { x = 1, y = 0, order = 2 },
        { x = 0, y = -1, order = 3 }, { x = -1, y = 0, order = 4 },
    }
    local candidates, seen = {}, {}
    local fx
    local fy
    local offsetIndex
    for fy = 0, height - 1 do
        for fx = 0, width - 1 do
            local sourceX = baseX + fx
            local sourceY = baseY + fy
            for offsetIndex = 1, #offsets do
                local offset = offsets[offsetIndex]
                local x, y = sourceX + offset.x, sourceY + offset.y
                local key = tostring(x) .. ":" .. tostring(y) .. ":"
                    .. tostring(originZ)
                local inside = x >= baseX and x < baseX + width
                    and y >= baseY and y < baseY + height
                if not inside and not seen[key] then
                    local square = allowDeferred and true
                        or SquareRules.GetSquare(x, y, originZ)
                    if allowDeferred or isApproachSquare(square) then
                        seen[key] = true
                        candidates[#candidates + 1] = {
                            x = x + 0.5, y = y + 0.5, z = originZ,
                            approachKey = key, approachOrder = offset.order,
                        }
                    end
                end
            end
        end
    end
    return candidates, width, height
end

local function sleepSurfaceTargets(surface, originX, originY, originZ,
    sleepSurface, context, resourceKey, resourceKind)
    local approaches, width, height = sleepApproachCandidates(
        surface, originX, originY, originZ, context)
    local capacity = sleepCapacity(surface, {
        sleepSurface = sleepSurface,
        sleepCapacity = surface.sleepCapacity,
        gridWidth = width,
        gridHeight = height,
    })
    local axis = tostring(surface.axis or "")
    if axis ~= "x" and axis ~= "y" then
        axis = width >= height and "x" or "y"
    end
    local targets = {}
    local index
    for index = 1, capacity do
        local approach = approaches[index] or approaches[1]
        if approach then
            local interactionX = tonumber(surface.x) or originX + 0.5
            local interactionY = tonumber(surface.y) or originY + 0.5
            if capacity > 1 then
                local offset = index == 1 and -0.5 or 0.5
                if axis == "y" then interactionY = interactionY + offset
                else interactionX = interactionX + offset end
            end
            targets[#targets + 1] = {
                x = approach.x, y = approach.y, z = approach.z,
                interactionX = interactionX, interactionY = interactionY,
                interactionZ = tonumber(surface.z) or originZ,
                interactionAxis = axis,
                interactionFacing = surface.facing,
                interactionSurfaceOffset = surface.surfaceOffset,
                sleepAnchorX = surface.x, sleepAnchorY = surface.y,
                sleepAnchorZ = tonumber(surface.z) or originZ,
                sleepAxis = axis, sleepFacing = surface.facing,
                sleepSprite = surface.spriteName,
                sleepGridX = surface.gridX, sleepGridY = surface.gridY,
                sleepGridWidth = surface.gridWidth or width,
                sleepGridHeight = surface.gridHeight or height,
                sleepSlotId = "slot:" .. tostring(index),
                sleepSlotIndex = index, sleepCapacity = capacity,
                bedCapacity = capacity,
                approachKey = approach.approachKey,
                sceneId = "facility.sleep." .. sleepSurface,
                sleepSurface = sleepSurface, object = surface.object,
                resourceKey = resourceKey, resourceKind = resourceKind,
            }
        end
    end
    return targets
end

local function sleepSpotTargets(component, context)
    context = type(context) == "table" and context or {}
    local square = SquareRules.GetSquare(component.x, component.y, component.z)
    local surface = SquareRules.DescribeSleepSurface(square)
    if not surface then
        return { {
            x = component.x + 0.5,
            y = component.y + 0.5,
            z = component.z,
            sceneId = "facility.sleep.floor",
            sleepSurface = "floor",
        } }
    end
    local sleepSurface = SquareRules.ClassifySleepSurface(surface.object)
    local surfaceZ = tonumber(surface.z) or tonumber(component.z) or 0
    local surfaceOffset = tonumber(surface.surfaceOffset)
    if surfaceOffset and surfaceOffset > 0 then
        surfaceZ = surfaceZ + (surfaceOffset + 1) / 96
    end
    surface.sleepCapacity = component.sleepCapacity
        or component.bedCapacity or surface.sleepCapacity
    surface.z = surfaceZ
    return sleepSurfaceTargets(surface, math.floor(component.x),
        math.floor(component.y), math.floor(component.z), sleepSurface,
        context, component.id, component.resourceKind)
end

local function resourceSleepTargets(resource, context)
    local sleepSurface = tostring(resource.sleepSurface
        or resource.detectorId or "")
    if sleepSurface ~= "bed" and sleepSurface ~= "sofa" then return {} end
    local originX = math.floor(tonumber(resource.originX)
        or tonumber(resource.x) or 0)
    local originY = math.floor(tonumber(resource.originY)
        or tonumber(resource.y) or 0)
    local originZ = math.floor(tonumber(resource.originZ)
        or tonumber(resource.z) or 0)
    local square = SquareRules.GetSquare(originX, originY, originZ)
    local object = square and (sleepSurface == "sofa"
        and SquareRules.FindSofa(square) or SquareRules.FindBed(square)) or nil
    local surface = square and object
        and SquareRules.DescribeSleepSurface(square, object) or nil
    local loaded = square ~= nil
    if loaded and (not surface
        or SquareRules.ClassifySleepSurface(surface.object) ~= sleepSurface)
    then
        return {}
    end
    surface = surface or {
        object = resource.object,
        x = tonumber(resource.x) or originX + 0.5,
        y = tonumber(resource.y) or originY + 0.5,
        z = tonumber(resource.z) or originZ,
        axis = resource.axis,
        facing = resource.facing,
        surfaceOffset = resource.surfaceOffset,
        spriteName = resource.spriteName or resource.sprite,
        gridX = resource.gridX, gridY = resource.gridY,
        gridWidth = resource.gridWidth,
        gridHeight = resource.gridHeight,
    }
    local interactionZ = tonumber(surface.z) or originZ
    local surfaceOffset = tonumber(surface.surfaceOffset)
    if surfaceOffset and surfaceOffset > 0 then
        -- Project Zomboid stores furniture surface height in pixels. Match
        -- Offline Survivor's supported-bed placement conversion so the live
        -- NPC and its abstract position use the furniture surface height.
        interactionZ = interactionZ + (surfaceOffset + 1) / 96
    end
    surface.sleepCapacity = resource.sleepCapacity
        or resource.bedCapacity or surface.sleepCapacity
    surface.z = interactionZ
    return sleepSurfaceTargets(surface, originX, originY, originZ,
        sleepSurface, context, resource.resourceKey, resource.resourceKind)
end


Internal.sleepCapacity = sleepCapacity
Internal.sleepFootprint = sleepFootprint
Internal.sleepApproachCandidates = sleepApproachCandidates
Internal.sleepSurfaceTargets = sleepSurfaceTargets
Internal.sleepSpotTargets = sleepSpotTargets
Internal.resourceSleepTargets = resourceSleepTargets

Targets.Register("sleepSpot", sleepSpotTargets)
Targets.Register("bed", sleepSpotTargets)
Targets.RegisterResource("bed", resourceSleepTargets)
Targets.RegisterResource("sofa", resourceSleepTargets)

return Targets
