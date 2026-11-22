-- Foreign target discovery. This is intentionally separate from the ordinary
-- Hoomans spatial index, which must continue to exclude managed actors.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Targeting = PNC.Compatibility.Targeting or {}

local Targeting = PNC.Compatibility.Targeting
local API = PNC.Compatibility.API
local Core = PNC.Core

local function distanceSq(source, target)
    local dx = (tonumber(target.x) or 0) - (tonumber(source.x) or 0)
    local dy = (tonumber(target.y) or 0) - (tonumber(source.y) or 0)
    return (dx * dx) + (dy * dy)
end

local function isVisible(source, target, options)
    local perception = PNC.Perception
    local visible
    local visibilityKind
    if options and type(options.canSee) == "function" then
        return options.canSee(source, target.worldObject, target) == true
    end
    if perception and type(perception.CanSeeWorldObject) == "function"
        and target.worldObject
    then
        visible, visibilityKind = perception.CanSeeWorldObject(
            source,
            target.worldObject
        )
        if visible ~= true or visibilityKind == "clearthroughwindow" then
            return false
        end
        target.visibilityKind = visibilityKind
        return true
    end
    return target.visible ~= false
end

local function passesVisionCone(source, candidate, radius)
    local svc = PNC.PerceptionService
    if not svc or type(svc.PassesBodyVisionCone) ~= "function" then
        return true
    end
    local perception = PNC.Perception
    local aid = tostring(candidate.actorId or candidate.id or "")
    local prov = tostring(candidate.provider or "")
    local runtime = type(source) == "table" and source.runtime or nil
    local recent = runtime and runtime.recentThreat or nil
    local active = runtime and runtime.target or nil
    local isEngaged = (recent and recent.kind == "foreign_npc"
            and tostring(recent.provider or "") == prov
            and tostring(recent.id or "") == aid)
        or (active and active.kind == "foreign_npc"
            and tostring(active.provider or "") == prov
            and tostring(active.actorId or active.id or "") == aid)
        or (perception and perception.IsWarnedThreat ~= nil
            and perception.IsWarnedThreat(source, "foreign_npc", aid, prov) == true)
    local observer = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(source.id) or nil
    local profile = type(svc.GetProfile) == "function" and svc.GetProfile(source) or nil
    return svc.PassesBodyVisionCone(source, candidate.worldObject, profile, observer, {
        radius = radius,
        bypassCone = isEngaged == true,
    })
end

function Targeting.FindNearestEnemy(source, radius, options)
    local best
    local candidates
    local limit
    local limitSq
    local i
    local candidate
    local allowed
    local distSq
    local context
    if not source or not API then return nil end
    options = type(options) == "table" and options or {}
    limit = tonumber(radius) or 12
    limit = math.max(1, limit)
    limitSq = limit * limit
    context = {
        source = source,
        radius = limit,
        options = options,
    }
    candidates = API.EnumerateTargets(context)
    for i = 1, #candidates do
        candidate = candidates[i]
        if candidate and candidate.kind == "foreign_npc"
            and candidate.actorId ~= nil
            and candidate.worldObject
            and candidate.worldObject.isAlive
            and candidate.worldObject:isAlive()
            and math.abs(
                (tonumber(candidate.z) or 0) - (tonumber(source.z) or 0)
            ) < 1
        then
            allowed = API.CanAttack(source, candidate, context)
            if allowed and passesVisionCone(source, candidate, limit)
                and isVisible(source, candidate, options)
            then
                candidate.threatening = true
                distSq = distanceSq(source, candidate)
                if distSq <= limitSq then
                    candidate.distSq = distSq
                    candidate.lastSeenAt = Core and Core.Now
                        and Core.Now() or 0
                    if not best or distSq < (best.distSq or math.huge) then
                        best = candidate
                    end
                end
            end
        end
    end
    return best
end

return Targeting
