--[[
    Puppet Opera blueprints.

    Blueprints are deliberately declarative.  They contain no callbacks,
    world coordinates, engine objects, or executable behavior.  The server
    normalizes them once and the session runtime consumes only the normalized
    copy.
]]

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Blueprints = PNC.PuppetOpera.Blueprints or {}

local Opera = PNC.PuppetOpera
local Registry = Opera.Blueprints
local Capabilities = Opera.AnimationCapabilities
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimationCapabilities"
local Normalization = require
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints_Normalization"

local cleanText = Normalization.CleanText
local validID = Normalization.ValidID
local numberInRange = Normalization.NumberInRange
local integerInRange = Normalization.IntegerInRange
local normalizeAnchor = Normalization.NormalizeAnchor
local normalizeActors = Normalization.NormalizeActors
local normalizeBeats = Normalization.NormalizeBeats

-- The first vertical slice deliberately exposes only routes that have a
-- server-known, already-tested runtime primitive.  The editor can still show
-- the full client catalog, but an MP start must pass this shared policy until
-- a catalog entry is promoted here.
local RUNTIME_PLAYER_ACTIONS = {
    RemoveBush = true,
}

local RUNTIME_NPC_BUMPS = {
    PNC_WaveHi = true,
}

function Registry.Normalize(id, definition)
    if type(definition) ~= "table" then return nil, "definition_required" end
    local normalizedID = validID(id or definition.id, 96)
    if not normalizedID then return nil, "blueprint_id_invalid" end
    local sceneType = validID(definition.sceneType, 64)
    local closeScene = string.find(normalizedID, "kiss", 1, true) ~= nil
        or string.find(tostring(sceneType or ""), "kiss", 1, true) ~= nil
    local defaultInteractionDistance = closeScene and 0.55 or nil
    local defaultMovementStopDistance = closeScene and 0.20 or nil
    local defaultArrivalTolerance = closeScene and 0.20 or nil

    local frame = type(definition.anchorFrame) == "table"
        and definition.anchorFrame or {}
    local rawAnchors = type(frame.anchors) == "table"
        and frame.anchors or nil
    if not rawAnchors then return nil, "anchor_frame_required" end

    local anchors = {}
    local anchorID
    local anchor
    local normalizedAnchor
    local anchorError
    for anchorID, anchor in pairs(rawAnchors) do
        anchorID = validID(anchorID, 64)
        if not anchorID then return nil, "anchor_id_invalid" end
        normalizedAnchor, anchorError = normalizeAnchor(anchor, anchorID)
        if not normalizedAnchor then
            return nil, anchorError
        end
        anchors[anchorID] = normalizedAnchor
    end

    local actors, actorError = normalizeActors(definition.actors, anchors)
    if not actors then return nil, actorError end
    local anchorTarget
    for anchorID, anchor in pairs(anchors) do
        anchorTarget = actors[anchor.faceTarget]
        if not anchorTarget then
            return nil, "anchor_face_target_unknown:" .. tostring(anchorID)
        end
    end
    local beats, beatError = normalizeBeats(definition.beats, actors)
    if not beats then return nil, beatError end

    local playback = type(definition.playback) == "table"
        and definition.playback or {}
    local defaultMode = cleanText(playback.defaultMode or "once", 16)
    if defaultMode ~= "once" and defaultMode ~= "loop" then
        return nil, "playback_mode_invalid"
    end
    local version = integerInRange(definition.version, 1, 999, 1)
    local tolerance = numberInRange(frame.tolerance, 0.25, 2.0, 0.75)
    local interactionDistance = numberInRange(
        frame.interactionDistance, 0.25, 2.0, defaultInteractionDistance
    )
    local movementStopDistance = numberInRange(
        frame.movementStopDistance, 0.10, 0.75, defaultMovementStopDistance
    )
    local arrivalTolerance = numberInRange(
        frame.arrivalTolerance, 0.10, 2.0, defaultArrivalTolerance
    )
    local gapMs = integerInRange(playback.gapMs, 0, 5000, 250)
    if version == nil then return nil, "blueprint_version_invalid" end
    if tolerance == nil then return nil, "anchor_tolerance_invalid" end
    if frame.interactionDistance ~= nil and interactionDistance == nil then
        return nil, "anchor_interaction_distance_invalid"
    end
    if frame.movementStopDistance ~= nil and movementStopDistance == nil then
        return nil, "anchor_movement_stop_distance_invalid"
    end
    if frame.arrivalTolerance ~= nil and arrivalTolerance == nil then
        return nil, "anchor_arrival_tolerance_invalid"
    end
    if gapMs == nil then return nil, "playback_gap_invalid" end
    return {
        id = normalizedID,
        version = version,
        definitionType = cleanText(
            definition.definitionType or "opera",
            32
        ),
        sceneType = sceneType,
        legacy = definition.legacy == true,
        labelKey = validID(definition.labelKey, 128),
        label = cleanText(definition.label or normalizedID, 128),
        description = cleanText(definition.description, 256),
        actors = actors,
        anchorFrame = {
            origin = cleanText(frame.origin or "server_player_relative", 64),
            orientation = cleanText(frame.orientation or "player_facing", 64),
            tolerance = tolerance,
            interactionDistance = interactionDistance,
            movementStopDistance = movementStopDistance,
            arrivalTolerance = arrivalTolerance,
            anchors = anchors,
        },
        beats = beats,
        playback = {
            defaultMode = defaultMode,
            allowLoop = playback.allowLoop ~= false,
            gapMs = gapMs,
        },
    }
end

function Registry.Register(id, definition)
    local normalized, reason = Registry.Normalize(id, definition)
    if not normalized then
        Registry.LastError = reason
        return false, reason
    end
    Registry.Definitions[normalized.id] = normalized
    Registry.LastError = nil
    return true, normalized
end

function Registry.IsRuntimePlayerAction(action)
    return RUNTIME_PLAYER_ACTIONS[tostring(action or "")] == true
        and Capabilities.IsRuntimePlayerAction(action) == true
end

function Registry.IsRuntimeNPCBump(bump)
    return RUNTIME_NPC_BUMPS[tostring(bump or "")] == true
        and Capabilities.IsRuntimeNPCBump(bump) == true
end

function Registry.GetAnimationCapability(actorKind, track)
    return Capabilities.ForTrack(actorKind, track)
end

function Registry.GetTrack(beat, actorID, actorKind)
    if type(beat) ~= "table" then return nil end
    local track
    if type(beat.tracks) == "table" then
        track = beat.tracks[tostring(actorID or "")]
    else
        track = beat[tostring(actorID or "")]
    end
    if type(track) == "table" and type(track.byKind) == "table" then
        return actorKind and track.byKind[tostring(actorKind)] or nil
    end
    return track
end

function Registry.GetTimeline(beat, actorID, actorKind)
    local track = Registry.GetTrack(beat, actorID, actorKind)
    if type(track) ~= "table" then return nil end
    if type(track.timeline) == "table" and #track.timeline > 0 then
        return track.timeline
    end
    return {
        {
            id = "legacy_" .. tostring(actorID or "actor"),
            type = "animation",
            startMs = 0,
            durationMs = tonumber(beat.durationMs) or 900,
            track = track,
        },
    }
end

function Registry.ValidateRuntime(blueprint)
    if type(blueprint) ~= "table" then
        return false, "blueprint_missing"
    end
    for index, beat in ipairs(blueprint.beats or {}) do
        for actorID, actor in pairs(blueprint.actors or {}) do
            local kinds = actor.kind and { actor.kind }
                or actor.allowedKinds or {}
            for _, actorKind in ipairs(kinds) do
                local track = Registry.GetTrack(beat, actorID, actorKind)
                if actorKind == "local_player"
                    or actorKind == "nearby_live_npc"
                then
                    local approved, capabilityReason =
                        Capabilities.IsSceneApproved(actorKind, track)
                    if not approved then
                        return false, tostring(capabilityReason)
                            .. ":beat=" .. tostring(index)
                            .. ":actor=" .. tostring(actorID)
                    end
                else
                    return false, "actor_kind_not_runtime_supported:"
                        .. tostring(actorID)
                end
            end
        end
    end
    return true
end

function Registry.Get(id)
    return id ~= nil and Registry.Definitions[tostring(id)] or nil
end

function Registry.List()
    local entries = {}
    local id
    local definition
    for id, definition in pairs(Registry.Definitions) do
        entries[#entries + 1] = definition
    end
    table.sort(entries, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return entries
end

-- Built-in scenes are declarative data loaded after normalization and
-- runtime validation APIs are available.
require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints_Builtins"

return Registry
