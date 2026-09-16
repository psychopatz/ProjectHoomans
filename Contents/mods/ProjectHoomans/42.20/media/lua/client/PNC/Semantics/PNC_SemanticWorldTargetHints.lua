-- Client-side observation and fuzzy matching for semantic world targets.
--
-- This module is deliberately an observer.  It scans only the loaded client
-- cell, returns a small primitive hint, and never moves an NPC or mutates a
-- world object.  The server must still resolve and validate the candidate
-- before an action plan receives an authoritative assignment.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local ObservationCache = PNC.Semantics.ClientWorldTargetObservationCache
    or require "PNC/Semantics/PNC_SemanticWorldTargetObservationCache"
local Hints = PNC.Semantics.ClientWorldTargetHints or {}
PNC.Semantics.ClientWorldTargetHints = Hints

local Diagnostics = PNC.Semantics.SemanticDiagnostics
Hints.VERSION = 1
Hints.DEFAULT_RADIUS = 16
Hints.MAX_RADIUS = 24
Hints.DEFAULT_CACHE_MS = 750
Hints.MIN_SCORE = 0.62
Hints.MIN_PROFILE_MARGIN = 0.08
Hints.DEFAULT_MAX_OBJECTS = ObservationCache.MAX_OBJECTS or 512
Hints.Cache = Hints.Cache or {}

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum)
    if maximum and #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and number(value) then return number(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and number(value) then return number(value) end
    end
    return 0
end

local function coordinateSource(value)
    if not value then return nil end
    local x = call(value, "getX")
    local y = call(value, "getY")
    local z = call(value, "getZ")
    if x ~= nil and y ~= nil then
        return number(x), number(y), number(z) or 0
    end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function liveNPCBody(npcID)
    local registry = PNC.Registry
    local body
    local sync
    local snapshot
    local key = tostring(npcID or "")
    if key == "" then return nil end
    if registry and type(registry.GetLiveZombie) == "function" then
        local ok, result = pcall(registry.GetLiveZombie, key)
        if ok and result then return result end
    end
    sync = PNC.ClientPresenceSync
    snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[key] or nil
    if sync and type(sync.ResolveBodyForNPC) == "function" then
        local ok, result = pcall(sync.ResolveBodyForNPC, key, snapshot)
        if ok and result then body = result end
    end
    return body
end

local function originFor(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    local candidates = {}
    local function add(value) if value then candidates[#candidates + 1] = value end end
    add(options.origin)
    add(context.origin)
    add(context.worldOrigin)
    add(liveNPCBody(context.npcID or context.targetID))
    add(context.player)
    if type(getSpecificPlayer) == "function" then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok then add(player) end
    end
    for index = 1, #candidates do
        local x, y, z = coordinateSource(candidates[index])
        if x ~= nil and y ~= nil then
            return candidates[index], x, y, z
        end
    end
    return nil
end

local function split(value)
    local output = {}
    for token in string.gmatch(text(value), "%S+") do
        output[#output + 1] = token
    end
    return output
end

local function swapped(a, b)
    if #a ~= #b then return false end
    local first
    local second
    for index = 1, #a do
        if string.sub(a, index, index) ~= string.sub(b, index, index) then
            if not first then
                first = index
            elseif not second then
                second = index
            else
                return false
            end
        end
    end
    return first ~= nil and second ~= nil
        and string.sub(a, first, first) == string.sub(b, second, second)
        and string.sub(a, second, second) == string.sub(b, first, first)
end

local function editDistance(a, b)
    if a == b then return 0 end
    local previous = {}
    local current = {}
    local index
    for index = 0, #b do previous[index] = index end
    for index = 1, #a do
        current[0] = index
        for other = 1, #b do
            local cost = string.sub(a, index, index)
                == string.sub(b, other, other) and 0 or 1
            current[other] = math.min(
                current[other - 1] + 1,
                previous[other] + 1,
                previous[other - 1] + cost
            )
        end
        previous, current = current, previous
    end
    return previous[#b] or math.max(#a, #b)
end

local function wordScore(left, right)
    left = Catalog.Normalize(left)
    right = Catalog.Normalize(right)
    if left == "" or right == "" then return 0 end
    if left == right then return 1 end
    if swapped(left, right) then return 0.90 end
    local shorter = math.min(#left, #right)
    if shorter >= 4
        and string.sub(left, 1, shorter) == string.sub(right, 1, shorter)
    then
        return 0.84
    end
    local maximum = math.max(#left, #right)
    local distance = editDistance(left, right)
    local allowed = math.max(1, math.floor(maximum * 0.34))
    if distance <= allowed then
        return math.max(0, 1 - distance / math.max(1, maximum))
    end
    return 0
end

local function phraseScore(query, alias)
    query = Catalog.Normalize(query)
    alias = Catalog.Normalize(alias)
    if query == "" or alias == "" then return 0 end
    if query == alias then return 1 end
    if string.find(alias, query, 1, true)
        or string.find(query, alias, 1, true)
    then
        return 0.92
    end

    local queryTokens = split(query)
    local aliasTokens = split(alias)
    local total = 0
    local best
    for index = 1, #queryTokens do
        best = 0
        for other = 1, #aliasTokens do
            best = math.max(best,
                wordScore(queryTokens[index], aliasTokens[other]))
        end
        total = total + best
    end
    if #queryTokens == 0 then return 0 end
    return total / #queryTokens
end

local function profileAliasScore(query, profile)
    local best = 0
    for index = 1, #(profile and profile.aliases or {}) do
        best = math.max(best, phraseScore(query, profile.aliases[index]))
    end
    return best
end

local function targetQuery(target)
    if type(target) ~= "table" then return "" end
    return text(target.text or target.value or target.category
        or target.concept or target.id, 64)
end

local function profilesFor(target, query)
    local output = {}
    local exact = Catalog.ResolveKind(target)
    local profile = exact and Catalog.Get(exact) or nil
    if profile then
        output[1] = profile
        return output, { exact = true, score = 1 }
    end

    local bestProfile
    local bestScore = 0
    local secondScore = 0
    for _, candidate in ipairs(Catalog.List()) do
        local score = profileAliasScore(query, candidate)
        if score > bestScore then
            secondScore = bestScore
            bestScore = score
            bestProfile = candidate
        elseif score > secondScore then
            secondScore = score
        end
    end
    if not bestProfile or bestScore < 0.55 then
        return output, {
            reason = "target_profile_unavailable",
            score = bestScore,
            secondScore = secondScore,
        }
    end
    if secondScore > 0
        and bestScore - secondScore < Hints.MIN_PROFILE_MARGIN
    then
        return output, {
            reason = "ambiguous_target_profile",
            score = bestScore,
            secondScore = secondScore,
        }
    end
    output[1] = bestProfile
    return output, {
        score = bestScore,
        secondScore = secondScore,
    }
end

local function objectLabelScore(query, metadata)
    local best = 0
    for index = 1, #(metadata and metadata.labels or {}) do
        best = math.max(best, phraseScore(query, metadata.labels[index]))
    end
    return best
end

local function candidateKey(candidate)
    return tostring(candidate.x) .. ":" .. tostring(candidate.y)
        .. ":" .. tostring(candidate.z) .. ":" .. tostring(candidate.kind)
end

local function addCandidate(candidates, profile, observation,
    originX, originY, originZ, query)
    local metadata = observation and observation.metadata or {}
    if not observation or not Catalog.Matches(profile.kind, metadata) then
        return
    end
    local x = number(observation.x)
    local y = number(observation.y)
    local z = number(observation.z) or originZ
    if x == nil or y == nil or z ~= originZ then return end
    local dx = x - originX
    local dy = y - originY
    local distanceSq = dx * dx + dy * dy
    local score = math.max(
        profileAliasScore(query, profile),
        objectLabelScore(query, metadata)
    )
    score = math.min(1, score + 0.04)
    candidates[#candidates + 1] = {
        kind = profile.kind,
        label = text(profile.label, 64),
        x = x,
        y = y,
        z = z,
        score = score,
        distanceSq = distanceSq,
        source = "client_loaded_world",
    }
end

local function sortCandidates(candidates)
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return candidateKey(left) < candidateKey(right)
    end)
end

local function cacheKey(query, profile, x, y, z, radius, maxObjects)
    return tostring(profile and profile.kind or "") .. "|"
        .. Catalog.Normalize(query) .. "|" .. tostring(math.floor(x)) .. ":"
        .. tostring(math.floor(y)) .. ":" .. tostring(z) .. "|"
        .. tostring(radius) .. "|" .. tostring(maxObjects)
end

local function audit(query, profile, originX, originY, originZ, radius,
    candidates, objectCount, hint, reason, observationStats)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return
    end
    local top = candidates and candidates[1] or nil
    local second = candidates and candidates[2] or nil
    Diagnostics.Record("semantic.world_target.client_hint", {
        query = query,
        requestedKind = profile and profile.kind or nil,
        originX = originX,
        originY = originY,
        originZ = originZ,
        radius = radius,
        inspectedObjects = objectCount,
        observationCacheHit = observationStats
            and observationStats.cached == true or false,
        observationScanTruncated = observationStats
            and observationStats.truncated == true or false,
        observationMaxObjects = observationStats
            and observationStats.maxObjects or nil,
        candidates = candidates and #candidates or 0,
        topKind = top and top.kind or nil,
        topLabel = top and top.label or nil,
        topX = top and top.x or nil,
        topY = top and top.y or nil,
        topScore = top and top.score or nil,
        secondScore = second and second.score or nil,
        status = hint and "attached" or "not_attached",
        reason = reason,
    })
end

function Hints.ClearCache()
    Hints.Cache = {}
    if ObservationCache
        and type(ObservationCache.ClearCache) == "function"
    then
        ObservationCache.ClearCache()
    end
end

function Hints.Resolve(target, context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    if type(target) ~= "table" or not Catalog then
        return nil, "target_hint_unavailable"
    end
    if number(target.x or target.targetX) ~= nil
        or number(target.y or target.targetY) ~= nil
        or target.targetID ~= nil or target.worldID ~= nil
    then
        return nil, "target_already_resolved"
    end

    local query = targetQuery(target)
    if query == "" then return nil, "target_query_missing" end
    local _, originX, originY, originZ = originFor(context, options)
    if originX == nil or originY == nil then
        return nil, "world_origin_unavailable"
    end
    local radius = math.max(1, math.min(Hints.MAX_RADIUS,
        math.floor(number(options.radius) or Hints.DEFAULT_RADIUS)))
    local profiles, profileStats = profilesFor(target, query)
    local profile = profiles[1]
    if not profile then
        return nil, profileStats and profileStats.reason
            or "target_profile_unavailable"
    end

    local maxObjects = math.max(1, math.min(
        ObservationCache.MAX_OBJECTS_HARD or 1024,
        math.floor(number(options.maxObjects) or Hints.DEFAULT_MAX_OBJECTS)
    ))
    local key = cacheKey(query, profile, originX, originY, originZ, radius,
        maxObjects)
    local timestamp = nowMs()
    local cached = Hints.Cache[key]
    local cacheMs = math.max(0, number(options.cacheMs)
        or Hints.DEFAULT_CACHE_MS)
    if cached and timestamp - cached.at <= cacheMs then
        return cached.hint, cached.reason
    end

    local cell = options.cell
    if not cell and type(getCell) == "function" then
        local ok, result = pcall(getCell)
        if ok then cell = result end
    end
    if not cell then
        Hints.Cache[key] = { at = timestamp, reason = "cell_unavailable" }
        return nil, "cell_unavailable"
    end

    local observations, observationStats = ObservationCache.Observe(
        cell, originX, originY, originZ, {
            radius = radius,
            maxObjects = maxObjects,
            cacheMs = cacheMs,
            nowMs = timestamp,
        })
    if not observations then
        local observationReason = observationStats
            and observationStats.reason or "observation_unavailable"
        Hints.Cache[key] = { at = timestamp, reason = observationReason }
        audit(query, profile, originX, originY, originZ, radius, {}, 0,
            nil, observationReason, observationStats)
        return nil, observationReason
    end

    local candidates = {}
    for index = 1, #observations do
        addCandidate(candidates, profile, observations[index],
            originX, originY, originZ, query)
    end
    local objectCount = observationStats
        and observationStats.objectCount or #observations
    sortCandidates(candidates)
    local top = candidates[1]
    local hint
    local reason
    if not top then
        reason = "no_matching_loaded_object"
    elseif top.score < Hints.MIN_SCORE then
        reason = "candidate_score_too_low"
    else
        -- Only primitive fields cross the network boundary.  In particular,
        -- do not include `top.object`, the square, or any Java userdata.
        hint = {
            version = Hints.VERSION,
            source = "client_loaded_world",
            kind = top.kind,
            label = top.label,
            query = text(query, 64),
            x = top.x,
            y = top.y,
            z = top.z,
            radius = radius,
            score = top.score,
            observedAt = timestamp,
        }
    end
    Hints.Cache[key] = {
        at = timestamp,
        hint = hint,
        reason = reason,
    }
    audit(query, profile, originX, originY, originZ, radius, candidates,
        objectCount, hint, reason, observationStats)
    return hint, reason
end

return Hints
