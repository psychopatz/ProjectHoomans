local PNC = _G.PNC or {}
local Opera = PNC.PuppetOpera or {}
local Normalization = Opera.BlueprintNormalization
local Capabilities = Normalization._Capabilities
local cleanText = Normalization._CleanText
local validID = Normalization._ValidID
local integerInRange = Normalization._IntegerInRange
local normalizeTrackForKind = Normalization._NormalizeTrackForKind

local function copyTrackFields(track)
    local result = {}
    for key, value in pairs(track or {}) do
        if key ~= "timeline" then result[key] = value end
    end
    return result
end

local normalizeTimelineNodes

normalizeTimelineNodes = function(
    rawNodes,
    actorKind,
    beatID,
    defaultDurationMs,
    depth
)
    if type(rawNodes) ~= "table" or #rawNodes == 0 then
        return nil, "timeline_nodes_required:" .. tostring(beatID)
    end
    depth = tonumber(depth) or 0
    if depth > 4 then
        return nil, "timeline_nesting_too_deep:" .. tostring(beatID)
    end
    local nodes = {}
    local seen = {}
    local animationCount = 0
    for index, rawNode in ipairs(rawNodes) do
        if type(rawNode) ~= "table" then
            return nil, "timeline_node_not_a_table:" .. tostring(beatID)
        end
        local nodeID = validID(
            rawNode.id or ("node_" .. tostring(index)),
            64
        )
        local nodeType = cleanText(rawNode.type or "animation", 16)
        local startMs = integerInRange(
            rawNode.startMs or rawNode.offsetMs,
            0,
            10000,
            0
        )
        if not nodeID or not startMs then
            return nil, "timeline_node_metadata_invalid:"
                .. tostring(beatID)
        end
        if seen[nodeID] then
            return nil, "timeline_node_duplicate:" .. tostring(beatID)
        end
        seen[nodeID] = true
        local node = {
            id = nodeID,
            type = nodeType,
            startMs = startMs,
            label = validID(rawNode.label, 96),
        }
        if nodeType == "animation" then
            animationCount = animationCount + 1
            local durationMs = integerInRange(
                rawNode.durationMs,
                1,
                10000,
                defaultDurationMs
            )
            if not durationMs then
                return nil, "timeline_animation_duration_invalid:"
                    .. tostring(beatID)
            end
            local payload = type(rawNode.track) == "table"
                and rawNode.track or rawNode
            local normalized, reason = normalizeTrackForKind(
                payload,
                actorKind,
                tostring(beatID) .. ":" .. tostring(nodeID),
                durationMs
            )
            if not normalized then return nil, reason end
            node.durationMs = durationMs
            node.track = copyTrackFields(normalized)
        elseif nodeType == "delay" then
            node.durationMs = integerInRange(
                rawNode.durationMs,
                0,
                10000,
                0
            )
        elseif nodeType == "sequence" or nodeType == "parallel" then
            -- The first runtime slice executes a flat cursor. Reject group
            -- nodes here instead of accepting a structure the server would
            -- silently skip. A later compiler can lower these groups into
            -- the same flat animation/delay nodes used by the cursor.
            return nil, "timeline_group_requires_compiler:"
                .. tostring(beatID)
        else
            return nil, "timeline_node_type_unsupported:" .. tostring(nodeType)
        end
        nodes[#nodes + 1] = node
    end
    if animationCount == 0 then
        return nil, "timeline_animation_required:" .. tostring(beatID)
    end
    return nodes
end

local function normalizeActorTrack(rawTrack, actorDefinition, beatID, durationMs)
    if type(rawTrack) ~= "table" then
        return nil, "actor_track_missing:" .. tostring(beatID)
    end

    -- Fixed-kind legacy blueprints retain their original direct track shape.
    -- Neutral slots use a variant map so one scene can be assigned to a
    -- player, an NPC, or two NPCs without rewriting the blueprint.
    local normalized
    local reason
    if actorDefinition.kind then
        normalized, reason = normalizeTrackForKind(
            rawTrack,
            actorDefinition.kind,
            beatID,
            durationMs
        )
    else
        local rawVariants = rawTrack.byKind or rawTrack.variants
        if type(rawVariants) ~= "table" then
            return nil, "actor_track_variants_required:" .. tostring(beatID)
        end
        local variants = {}
        for _, actorKind in ipairs(actorDefinition.allowedKinds or {}) do
            local variant = rawVariants[actorKind]
            if not variant then
                return nil, "actor_track_variant_missing:" .. tostring(beatID)
                    .. ":" .. tostring(actorDefinition.id)
                    .. ":" .. tostring(actorKind)
            end
            local variantTrack, variantReason = normalizeTrackForKind(
                variant,
                actorKind,
                beatID,
                durationMs
            )
            if not variantTrack then return nil, variantReason end
            if type(variant.timeline) == "table" then
                local timeline, timelineReason = normalizeTimelineNodes(
                    variant.timeline,
                    actorKind,
                    beatID,
                    durationMs,
                    0
                )
                if not timeline then return nil, timelineReason end
                variantTrack.timeline = timeline
            end
            variants[actorKind] = variantTrack
        end
        return { byKind = variants }
    end
    if not normalized then return nil, reason end
    if type(rawTrack.timeline) == "table" then
        local timeline, timelineReason = normalizeTimelineNodes(
            rawTrack.timeline,
            actorDefinition.kind,
            beatID,
            durationMs,
            0
        )
        if not timeline then return nil, timelineReason end
        normalized.timeline = timeline
    end
    return normalized
end

local function normalizeBeats(rawBeats, actors)
    if type(rawBeats) ~= "table" or #rawBeats == 0 then
        return nil, "beats_required"
    end
    local beats = {}
    local index
    local raw
    local beatID
    local durationMs
    local track
    local trackError
    local rawTracks
    local rawTrack
    local actorDefinition
    local actorID
    local normalizedBeat
    for index, raw in ipairs(rawBeats) do
        if type(raw) ~= "table" then
            return nil, "beat_not_a_table:" .. tostring(index)
        end
        beatID = validID(raw.id or ("beat_" .. tostring(index)), 64)
        durationMs = integerInRange(raw.durationMs, 100, 10000, 900)
        if not beatID or not durationMs then
            return nil, "beat_metadata_invalid:" .. tostring(index)
        end
        rawTracks = type(raw.tracks) == "table" and raw.tracks or {}
        -- Accept the original schema as an input format while normalizing to
        -- the actor-id keyed track map used by the scene builder.
        if rawTracks.player == nil and raw.player ~= nil then
            rawTracks.player = raw.player
        end
        if rawTracks.npc == nil and raw.npc ~= nil then
            rawTracks.npc = raw.npc
        end
        normalizedBeat = {
            id = beatID,
            durationMs = durationMs,
            synchronization = cleanText(
                raw.synchronization or "arrival_and_start_barrier",
                64
            ),
            tracks = {},
        }
        for actorID, actorDefinition in pairs(actors or {}) do
            rawTrack = rawTracks[actorID]
            if not rawTrack then
                if actorDefinition.required ~= false then
                    return nil, "actor_track_missing:" .. tostring(actorID)
                end
            else
                track, trackError = normalizeActorTrack(
                    rawTrack,
                    actorDefinition,
                    beatID,
                    durationMs
                )
                if not track then return nil, trackError end
                normalizedBeat.tracks[actorID] = track
            end
        end
        -- Compatibility aliases let existing low-level consumers continue to
        -- read the first blueprint without knowing about `tracks` yet.
        normalizedBeat.player = normalizedBeat.tracks.player
        normalizedBeat.npc = normalizedBeat.tracks.npc
        beats[index] = normalizedBeat
    end
    return beats
end
Normalization._NormalizeBeats = normalizeBeats
