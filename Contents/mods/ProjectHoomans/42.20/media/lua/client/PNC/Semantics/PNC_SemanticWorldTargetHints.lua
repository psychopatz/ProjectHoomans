-- Client-side orchestration for bounded world-target hints.
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

local Matcher = require "PNC/Semantics/PNC_SemanticWorldTargetMatcher"
local Origin = require "PNC/Semantics/PNC_SemanticWorldTargetOrigin"
local HintDiagnostics = require
    "PNC/Semantics/PNC_SemanticWorldTargetHintDiagnostics"
Hints.VERSION = 2
Hints.DEFAULT_RADIUS = 16
Hints.MAX_RADIUS = 24
Hints.DEFAULT_CACHE_MS = 750
Hints.MIN_SCORE = 0.62
Hints.MIN_PROFILE_MARGIN = 0.08
Hints.DEFAULT_MAX_OBJECTS = ObservationCache.MAX_OBJECTS or 512
Hints.Cache = Hints.Cache or {}

local function cacheKey(query, profile, x, y, z, radius, maxObjects)
    return tostring(profile and profile.kind or "") .. "|"
        .. Catalog.Normalize(query) .. "|" .. tostring(math.floor(x)) .. ":"
        .. tostring(math.floor(y)) .. ":" .. tostring(z) .. "|"
        .. tostring(radius) .. "|" .. tostring(maxObjects)
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
    if Matcher.Number(target.x or target.targetX) ~= nil
        or Matcher.Number(target.y or target.targetY) ~= nil
        or target.targetID ~= nil or target.worldID ~= nil
    then
        return nil, "target_already_resolved"
    end

    local query = Matcher.TargetQuery(target)
    if query == "" then return nil, "target_query_missing" end
    local _, originX, originY, originZ = Origin.Resolve(context, options)
    if originX == nil or originY == nil then
        return nil, "world_origin_unavailable"
    end
    local radius = math.max(1, math.min(Hints.MAX_RADIUS,
        math.floor(Matcher.Number(options.radius) or Hints.DEFAULT_RADIUS)))
    local profiles, profileStats = Matcher.ProfilesFor(
        target, query, Hints.MIN_PROFILE_MARGIN
    )
    local profile = profiles[1]
    if not profile then
        return nil, profileStats and profileStats.reason
            or "target_profile_unavailable"
    end

    local maxObjects = math.max(1, math.min(
        ObservationCache.MAX_OBJECTS_HARD or 1024,
        math.floor(Matcher.Number(options.maxObjects) or Hints.DEFAULT_MAX_OBJECTS)
    ))
    local key = cacheKey(query, profile, originX, originY, originZ, radius,
        maxObjects)
    local timestamp = Origin.NowMs()
    local cached = Hints.Cache[key]
    local cacheMs = math.max(0, Matcher.Number(options.cacheMs)
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
        HintDiagnostics.Record(
            query, profile, originX, originY, originZ, radius, {}, 0,
            nil, observationReason, observationStats
        )
        return nil, observationReason
    end

    local candidates = {}
    for index = 1, #observations do
        Matcher.AddCandidate(candidates, profile, observations[index],
            originX, originY, originZ, query)
    end
    local objectCount = observationStats
        and observationStats.objectCount or #observations
    Matcher.SortCandidates(candidates)
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
            semanticName = top.commandName,
            targetID = top.targetID,
            resourceKey = top.resourceKey,
            query = Matcher.Text(query, 64),
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
    HintDiagnostics.Record(
        query, profile, originX, originY, originZ, radius, candidates,
        objectCount, hint, reason, observationStats
    )
    return hint, reason
end

return Hints
