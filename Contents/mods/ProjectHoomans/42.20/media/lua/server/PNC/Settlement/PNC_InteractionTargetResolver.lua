if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityInteractionTargets = PNC.FacilityInteractionTargets or {}

local Targets = PNC.FacilityInteractionTargets
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
Targets.Resolvers = Targets.Resolvers or {}
Targets.Cache = Targets.Cache or {}

function Targets.Register(id, resolver)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "INVALID_RESOLVER"
    end
    Targets.Resolvers[id] = resolver
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
    local cached = not dynamicSleep and Targets.Cache[component.id] or nil
    if cached and cached.revision == component.revision then return cached.targets end
    local resolverId = component.role == "sleep.bed"
        and "sleepSpot" or component.targetResolver
    local resolver = Targets.Resolvers[resolverId]
    local targets = resolver and resolver(component, context) or nil
    if type(targets) ~= "table" or #targets == 0 then
        targets = { { x = component.x, y = component.y, z = component.z } }
    end
    if not dynamicSleep then
        Targets.Cache[component.id] = { revision = component.revision, targets = targets }
    end
    return targets
end

function Targets.ReportPathFailure(componentId)
    Targets.Invalidate(componentId)
end

Targets.Register("worldObject", function(component)
    if component.objectTag == "bed" and Targets.Resolvers.sleepSpot then
        return Targets.Resolvers.sleepSpot(component)
    end
    if PNC.WorldObjectTargetResolvers
        and type(PNC.WorldObjectTargetResolvers[component.objectTag]) == "function"
    then
        return PNC.WorldObjectTargetResolvers[component.objectTag](component)
    end
    return { { x = component.x, y = component.y, z = component.z } }
end)

local function isApproachSquare(square)
    if not square then return false end
    if square.isFree then
        local ok, free = pcall(square.isFree, square, false)
        if ok then return free == true end
    end
    return true
end

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

Targets.Register("sleepSpot", sleepSpotTargets)
-- Compatibility for components saved before sleep spots became furniture-optional.
Targets.Register("bed", sleepSpotTargets)

return Targets
