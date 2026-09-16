-- Adapters from authoritative evidence to NPC-cognition facts.
--
-- This module does not search for actors and does not decide whether an NPC
-- can see something. Callers must supply an observation already established
-- by an authoritative subsystem such as Perception. The adapter only shapes
-- the evidence into the shared cognition contract and applies a cheap
-- per-observer/target throttle.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Evidence = PNC.Semantics.CognitionEvidence or {}
PNC.Semantics.CognitionEvidence = Evidence

Evidence.VERSION = 1
Evidence.OBSERVATION_INTERVAL_HOURS = 0.05
Evidence.SEEN_EXPIRY_HOURS = 72

local function authority()
    local Core = PNC.Core
    return not Core or not Core.IsAuthority
        or Core.IsAuthority() == true
end

local function service()
    local semantics = PNC.Semantics
    local current = semantics and semantics.CognitionService or nil
    return current and type(current.Remember) == "function"
        and current or nil
end

local function identifier(value)
    if type(value) == "table" then
        value = value.id or value.entityID or value.npcID
    end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function worldAge(options)
    local value = finite(options and options.observedAt)
    local gameTime
    if value ~= nil then return math.max(0, value) end
    gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return math.max(0, finite(gameTime:getWorldAgeHours()) or 0)
    end
    return 0
end

local function position(target, options)
    local x = finite(options and options.x)
        or finite(target and target.x)
    local y = finite(options and options.y)
        or finite(target and target.y)
    local z = finite(options and options.z)
        or finite(target and target.z)
    return x, y, z
end

local function distanceBand(observer, target, options)
    local ox = finite(observer and observer.x)
    local oy = finite(observer and observer.y)
    local tx
    local ty
    local dx
    local dy
    local distanceSq
    local supplied = finite(options and options.distanceSq)
    if supplied ~= nil then
        distanceSq = math.max(0, supplied)
    else
        tx = finite(target and target.x)
        ty = finite(target and target.y)
        if ox == nil or oy == nil or tx == nil or ty == nil then
            return nil
        end
        dx = tx - ox
        dy = ty - oy
        distanceSq = dx * dx + dy * dy
    end
    if distanceSq <= 8 * 8 then return "nearby" end
    if distanceSq <= 32 * 32 then return "not_far" end
    return "far"
end

local function observationKey(targetID)
    return "SEEN|" .. tostring(targetID)
end

local function throttle(observer, key, at)
    local runtime = observer.runtime
    local previous
    if not runtime then
        runtime = {}
        observer.runtime = runtime
    end
    runtime.semanticCognitionObservationAt =
        runtime.semanticCognitionObservationAt or {}
    previous = finite(runtime.semanticCognitionObservationAt[key])
    if previous ~= nil
        and at - previous < Evidence.OBSERVATION_INTERVAL_HOURS
    then
        return false
    end
    runtime.semanticCognitionObservationAt[key] = at
    return true
end

function Evidence.RecordVisibleNPC(observer, target, options)
    local observerID
    local targetID
    local at
    local key
    local remembered
    local result
    local projection
    local targetName
    local band
    local x
    local y
    local z
    local Cognition = service()
    options = type(options) == "table" and options or {}
    if not authority() then return false, "not_authority" end
    if not Cognition then return false, "cognition_service_unavailable" end
    observerID = identifier(observer)
    targetID = identifier(target)
    if not observerID or not targetID then
        return false, "observation_identity_unavailable"
    end
    if observerID == targetID then return false, "self_observation" end
    if observer and observer.alive == false then
        return false, "observer_unavailable"
    end
    if target and target.alive == false then
        return false, "target_unavailable"
    end
    at = worldAge(options)
    key = observationKey(targetID)
    if not throttle(observer, key, at) then return false, "throttled" end
    targetName = target and (target.name or target.displayName) or nil
    band = distanceBand(observer, target, options)
    x, y, z = position(target, options)
    remembered, result, projection = Cognition.Remember(observerID, {
        subject = "SEEN",
        targetID = targetID,
        targetName = targetName,
        status = "known",
        value = true,
        location = {
            distanceBand = band,
            precision = band and "band" or nil,
            observedX = x,
            observedY = y,
            observedZ = z,
        },
        source = tostring(options.source or "witnessed"),
        sourceID = observerID,
        evidence = {
            kind = "line_of_sight",
            visibilityKind = options.visibilityKind,
        },
        confidence = tonumber(options.confidence) or 0.95,
        observedAt = at,
        recordedAt = at,
        expiresAt = at + Evidence.SEEN_EXPIRY_HOURS,
    })
    if remembered ~= true then
        observer.runtime.semanticCognitionObservationAt[key] = nil
    end
    return remembered, result, projection
end

return Evidence
