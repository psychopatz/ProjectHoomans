local PNC = _G.PNC or {}
local Opera = PNC.PuppetOpera or {}
local Normalization = Opera.BlueprintNormalization
local Capabilities = Normalization._Capabilities
local cleanText = Normalization._CleanText
local validID = Normalization._ValidID
local normalizeVariables = Normalization._NormalizeVariables
local integerInRange = Normalization._IntegerInRange
local SUPPORTED_ACTOR_KINDS = {
    local_player = true,
    nearby_live_npc = true,
    future_actor = true,
}
local DEFAULT_ACTOR_KINDS = {
    "local_player",
    "nearby_live_npc",
}

local function normalizeActors(rawActors, rawAnchors)
    if type(rawActors) ~= "table" then
        return nil, "actors_required"
    end
    local actors = {}
    local actorCount = 0
    local actorID
    local raw
    local kind
    local anchor
    local normalized
    for actorID, raw in pairs(rawActors) do
        actorID = validID(actorID, 64)
        if not actorID then return nil, "actor_id_invalid" end
        if type(raw) ~= "table" then
            return nil, "actor_not_a_table:" .. tostring(actorID)
        end
        kind = cleanText(raw.kind, 32)
        if kind == "" then kind = nil end
        if kind and not SUPPORTED_ACTOR_KINDS[kind] then
            return nil, "actor_kind_unsupported:" .. tostring(actorID)
        end
        anchor = validID(raw.anchor, 64)
        if not anchor or type(rawAnchors[anchor]) ~= "table" then
            return nil, "actor_anchor_missing:" .. tostring(actorID)
        end
        local allowedKinds = {}
        local allowedCount = 0
        local allowedSource = type(raw.allowedKinds) == "table"
            and raw.allowedKinds or nil
        if allowedSource then
            for _, allowedKind in ipairs(allowedSource) do
                allowedKind = cleanText(allowedKind, 32)
                if allowedKind ~= "" and SUPPORTED_ACTOR_KINDS[allowedKind]
                    and not allowedKinds[allowedKind]
                then
                    allowedKinds[allowedKind] = true
                    allowedCount = allowedCount + 1
                end
            end
        elseif kind then
            allowedKinds[kind] = true
            allowedCount = 1
        else
            for _, allowedKind in ipairs(DEFAULT_ACTOR_KINDS) do
                allowedKinds[allowedKind] = true
                allowedCount = allowedCount + 1
            end
        end
        if allowedCount == 0 then
            return nil, "actor_allowed_kinds_missing:" .. tostring(actorID)
        end
        local allowedList = {}
        for allowedKind in pairs(allowedKinds) do
            allowedList[#allowedList + 1] = allowedKind
        end
        table.sort(allowedList)
        normalized = {
            id = actorID,
            kind = kind,
            allowedKinds = allowedList,
            required = raw.required ~= false,
            anchor = anchor,
            labelKey = validID(raw.labelKey, 128),
            label = cleanText(raw.label, 96),
        }
        actors[actorID] = normalized
        actorCount = actorCount + 1
    end
    if actorCount < 2 then return nil, "at_least_two_actors_required" end

    -- Actor ids are scene-local slot names.  The old builder required the
    -- literal `player` and `npc` keys, which made a two-NPC scene impossible
    -- even though the rest of the anchor/session model is already generic.
    -- Keep the useful invariant that a blueprint contains at most one local
    -- player slot; any number of nearby live-NPC slots is valid.
    local localPlayerCount = 0
    for _, definition in pairs(actors) do
        if definition.kind == "local_player" then
            localPlayerCount = localPlayerCount + 1
        end
    end
    if localPlayerCount > 1 then return nil, "too_many_local_player_actors" end
    return actors
end

local function normalizePlayerBeat(raw, beatID, durationMs)
    if type(raw) ~= "table" then
        return nil, "player_beat_missing:" .. tostring(beatID)
    end
    local mode = cleanText(
        raw.mode or (raw.emote and "emote" or "action"),
        16
    )
    local route = cleanText(
        raw.route or (mode == "emote" and "player_emote" or "player_action"),
        32
    )
    local action = validID(raw.action, 96)
    local emote = validID(raw.emote, 96)
    local animation = validID(raw.animation or raw.anim, 128)
    local catalog = validID(raw.catalog or "player", 32)
    local entryID = validID(raw.entryId or raw.entryID, 192)
    if mode == "action" and route ~= "player_action" then
        return nil, "player_route_unsupported:" .. tostring(beatID)
    end
    if mode == "emote" and route ~= "player_emote" then
        return nil, "player_route_unsupported:" .. tostring(beatID)
    end
    if catalog ~= "player" then
        return nil, "player_catalog_unsupported:" .. tostring(beatID)
    end
    if mode ~= "action" and mode ~= "emote" then
        return nil, "player_mode_unsupported:" .. tostring(beatID)
    end
    if mode == "action" and (not action or not animation) then
        return nil, "player_action_missing:" .. tostring(beatID)
    end
    if mode == "emote" and not emote then
        return nil, "player_emote_missing:" .. tostring(beatID)
    end
    -- PsychopatzCore's native timed-action controller consumes maxTime in
    -- simulation ticks (60 ticks per second at normal speed), while Puppet
    -- Opera durations are serialized in milliseconds for transport.
    local actionDuration = math.max(
        1,
        math.floor((durationMs * 60 / 1000) + 0.5)
    )
    local normalized = {
        route = route,
        mode = mode,
        catalog = catalog,
        entryId = entryID,
        state = cleanText(raw.state or action or emote, 96),
        action = action,
        emote = emote,
        anim = animation,
        playable = true,
        debugDuration = mode == "action" and actionDuration or nil,
        variables = normalizeVariables(raw.variables),
        event = validID(raw.event, 96),
    }
    return Capabilities.NormalizeTrack("local_player", normalized)
end

local function normalizeNPCBeat(raw, beatID, durationMs)
    if type(raw) ~= "table" then
        return nil, "npc_beat_missing:" .. tostring(beatID)
    end
    local route = cleanText(raw.route or "zombie_bump", 32)
    local bump = validID(raw.bump, 96)
    local animation = validID(raw.animation or raw.anim, 128)
    local catalog = validID(raw.catalog or "npc", 32)
    local entryID = validID(raw.entryId or raw.entryID, 192)
    if route ~= "zombie_bump" then
        return nil, "npc_route_unsupported:" .. tostring(beatID)
    end
    if catalog ~= "npc" then
        return nil, "npc_catalog_unsupported:" .. tostring(beatID)
    end
    if not bump then return nil, "npc_bump_missing:" .. tostring(beatID) end
    local normalized = {
        route = route,
        mode = "bump",
        catalog = catalog,
        entryId = entryID,
        bump = bump,
        anim = animation,
        durationMs = durationMs,
        nonCombat = raw.nonCombat ~= false,
    }
    return Capabilities.NormalizeTrack("nearby_live_npc", normalized)
end

local function normalizeFutureBeat(raw, beatID, durationMs)
    if type(raw) ~= "table" then
        return nil, "actor_track_missing:" .. tostring(beatID)
    end
    local normalized = {
        route = cleanText(raw.route or "future", 32),
        mode = cleanText(raw.mode or "future", 16),
        catalog = validID(raw.catalog or "future", 32),
        entryId = validID(raw.entryId or raw.entryID, 192),
        state = cleanText(raw.state, 96),
        action = validID(raw.action, 96),
        emote = validID(raw.emote, 96),
        bump = validID(raw.bump, 96),
        anim = validID(raw.animation or raw.anim, 128),
        durationMs = durationMs,
        nonCombat = raw.nonCombat ~= false,
    }
    return normalized
end

local function normalizeTrackForKind(rawTrack, actorKind, beatID, durationMs)
    if actorKind == "local_player" then
        return normalizePlayerBeat(rawTrack, beatID, durationMs)
    elseif actorKind == "nearby_live_npc" then
        return normalizeNPCBeat(rawTrack, beatID, durationMs)
    end
    return normalizeFutureBeat(rawTrack, beatID, durationMs)
end
Normalization._NormalizeActors = normalizeActors
Normalization._NormalizeTrackForKind = normalizeTrackForKind
