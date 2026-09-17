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

local SUPPORTED_ACTOR_KINDS = {
    local_player = true,
    nearby_live_npc = true,
    future_actor = true,
}

-- The first vertical slice deliberately exposes only routes that have a
-- server-known, already-tested runtime primitive.  The editor can still show
-- the full client catalog, but an MP start must pass this shared policy until
-- a catalog entry is promoted here.
local RUNTIME_PLAYER_ACTIONS = {
    RemoveBush = true,
}

local RUNTIME_NPC_BUMPS = {
    PNC_Shove = true,
}

local function cleanText(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    if maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function validID(value, maximum)
    value = cleanText(value, maximum or 96)
    if value == "" or not string.match(value, "^[%w%._%-]+$") then
        return nil
    end
    return value
end

local function normalizeVariables(rawVariables)
    local variables = {}
    if type(rawVariables) ~= "table" then return variables end
    local index
    local raw
    local name
    local valueType
    local value
    for index, raw in ipairs(rawVariables) do
        if index > 16 or type(raw) ~= "table" then break end
        name = validID(raw.name, 64)
        valueType = type(raw.value)
        value = raw.value
        if name and (
            valueType == "boolean"
                or valueType == "string"
                or valueType == "number"
        ) then
            if valueType == "string" then
                value = cleanText(value, 96)
            elseif valueType == "number"
                and (value ~= value
                    or value == math.huge
                    or value == -math.huge)
            then
                value = nil
            end
            if value ~= nil then
                variables[#variables + 1] = {
                    name = name,
                    kind = validID(raw.kind, 16),
                    value = value,
                }
            end
        end
    end
    return variables
end

local function numberInRange(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return fallback
    end
    if number < minimum or number > maximum then return nil end
    return number
end

local function integerInRange(value, minimum, maximum, fallback)
    local number = numberInRange(value, minimum, maximum, fallback)
    if number == nil then return nil end
    if number ~= math.floor(number) then return nil end
    return number
end

local function normalizeAnchor(raw, anchorID)
    if type(raw) ~= "table" then
        return nil, "anchor_not_a_table:" .. tostring(anchorID)
    end
    local right = integerInRange(raw.right, -8, 8, 0)
    local forward = integerInRange(raw.forward, -8, 8, 0)
    local z = integerInRange(raw.z, -1, 1, 0)
    local faceTarget = validID(raw.faceTarget, 64)
    if right == nil or forward == nil or z == nil then
        return nil, "anchor_offset_invalid:" .. tostring(anchorID)
    end
    if not faceTarget then
        return nil, "anchor_face_target_required:" .. tostring(anchorID)
    end
    return {
        id = tostring(anchorID),
        right = right,
        forward = forward,
        z = z,
        faceTarget = faceTarget,
    }
end

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
        if not SUPPORTED_ACTOR_KINDS[kind] then
            return nil, "actor_kind_unsupported:" .. tostring(actorID)
        end
        anchor = validID(raw.anchor, 64)
        if not anchor or type(rawAnchors[anchor]) ~= "table" then
            return nil, "actor_anchor_missing:" .. tostring(actorID)
        end
        normalized = {
            id = actorID,
            kind = kind,
            required = raw.required ~= false,
            anchor = anchor,
            label = cleanText(raw.label, 96),
        }
        actors[actorID] = normalized
        actorCount = actorCount + 1
    end
    if actorCount < 2 then return nil, "at_least_two_actors_required" end
    if not actors.player then return nil, "player_actor_required" end
    if not actors.npc then return nil, "npc_actor_required" end
    if actors.player.kind ~= "local_player" then
        return nil, "player_actor_kind_invalid"
    end
    if actors.npc.kind ~= "nearby_live_npc" then
        return nil, "npc_actor_kind_invalid"
    end
    return actors
end

local function normalizePlayerBeat(raw, beatID, durationMs)
    if type(raw) ~= "table" then
        return nil, "player_beat_missing:" .. tostring(beatID)
    end
    local route = cleanText(raw.route or "player_action", 32)
    local action = validID(raw.action, 96)
    local animation = validID(raw.animation or raw.anim, 128)
    local catalog = validID(raw.catalog or "player", 32)
    local entryID = validID(raw.entryId or raw.entryID, 192)
    if route ~= "player_action" then
        return nil, "player_route_unsupported:" .. tostring(beatID)
    end
    if catalog ~= "player" then
        return nil, "player_catalog_unsupported:" .. tostring(beatID)
    end
    if not action or not animation then
        return nil, "player_action_missing:" .. tostring(beatID)
    end
    -- PsychopatzCore's native timed-action controller consumes maxTime in
    -- simulation ticks (60 ticks per second at normal speed), while Puppet
    -- Opera durations are serialized in milliseconds for transport.
    local actionDuration = math.max(
        1,
        math.floor((durationMs * 60 / 1000) + 0.5)
    )
    return {
        route = route,
        mode = "action",
        catalog = catalog,
        entryId = entryID,
        state = cleanText(raw.state or action, 96),
        action = action,
        anim = animation,
        playable = true,
        debugDuration = actionDuration,
        variables = normalizeVariables(raw.variables),
        event = validID(raw.event, 96),
    }
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
    return {
        route = route,
        mode = "bump",
        catalog = catalog,
        entryId = entryID,
        bump = bump,
        anim = animation,
        durationMs = durationMs,
        nonCombat = raw.nonCombat ~= false,
    }
end

local function normalizeBeats(rawBeats)
    if type(rawBeats) ~= "table" or #rawBeats == 0 then
        return nil, "beats_required"
    end
    local beats = {}
    local index
    local raw
    local beatID
    local durationMs
    local playerBeat
    local npcBeat
    local playerError
    local npcError
    for index, raw in ipairs(rawBeats) do
        if type(raw) ~= "table" then
            return nil, "beat_not_a_table:" .. tostring(index)
        end
        beatID = validID(raw.id or ("beat_" .. tostring(index)), 64)
        durationMs = integerInRange(raw.durationMs, 100, 10000, 900)
        if not beatID or not durationMs then
            return nil, "beat_metadata_invalid:" .. tostring(index)
        end
        playerBeat, playerError = normalizePlayerBeat(
            raw.player,
            beatID,
            durationMs
        )
        if not playerBeat then
            return nil, playerError
        end
        npcBeat, npcError = normalizeNPCBeat(raw.npc, beatID, durationMs)
        if not npcBeat then
            return nil, npcError
        end
        beats[index] = {
            id = beatID,
            durationMs = durationMs,
            synchronization = cleanText(
                raw.synchronization or "arrival_and_start_barrier",
                64
            ),
            player = playerBeat,
            npc = npcBeat,
        }
    end
    return beats
end

function Registry.Normalize(id, definition)
    if type(definition) ~= "table" then return nil, "definition_required" end
    local normalizedID = validID(id or definition.id, 96)
    if not normalizedID then return nil, "blueprint_id_invalid" end

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
    local beats, beatError = normalizeBeats(definition.beats)
    if not beats then return nil, beatError end

    local playback = type(definition.playback) == "table"
        and definition.playback or {}
    local defaultMode = cleanText(playback.defaultMode or "once", 16)
    if defaultMode ~= "once" and defaultMode ~= "loop" then
        return nil, "playback_mode_invalid"
    end
    local version = integerInRange(definition.version, 1, 999, 1)
    local tolerance = numberInRange(frame.tolerance, 0.25, 2.0, 0.75)
    local gapMs = integerInRange(playback.gapMs, 0, 5000, 250)
    if version == nil then return nil, "blueprint_version_invalid" end
    if tolerance == nil then return nil, "anchor_tolerance_invalid" end
    if gapMs == nil then return nil, "playback_gap_invalid" end
    return {
        id = normalizedID,
        version = version,
        label = cleanText(definition.label or normalizedID, 128),
        description = cleanText(definition.description, 256),
        actors = actors,
        anchorFrame = {
            origin = cleanText(frame.origin or "server_player_relative", 64),
            orientation = cleanText(frame.orientation or "player_facing", 64),
            tolerance = tolerance,
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
end

function Registry.IsRuntimeNPCBump(bump)
    return RUNTIME_NPC_BUMPS[tostring(bump or "")] == true
end

function Registry.ValidateRuntime(blueprint)
    if type(blueprint) ~= "table" then
        return false, "blueprint_missing"
    end
    for index, beat in ipairs(blueprint.beats or {}) do
        if not Registry.IsRuntimePlayerAction(beat.player and beat.player.action) then
            return false, "player_action_not_server_approved:" .. tostring(index)
        end
        if not Registry.IsRuntimeNPCBump(beat.npc and beat.npc.bump) then
            return false, "npc_bump_not_server_approved:" .. tostring(index)
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

local defaultBlueprint = {
    id = "social.kiss_test",
    version = 1,
    label = "Player and NPC Kiss Test",
    description = "Two actors walk to opposing anchors and play a synchronized Shove beat.",
    actors = {
        player = {
            kind = "local_player",
            required = true,
            anchor = "left",
            label = "Player",
        },
        npc = {
            kind = "nearby_live_npc",
            required = true,
            anchor = "right",
            label = "Nearby live NPC",
        },
    },
    anchorFrame = {
        origin = "server_player_relative",
        orientation = "player_facing",
        tolerance = 0.75,
        anchors = {
            left = {
                right = -1,
                forward = 0,
                z = 0,
                faceTarget = "npc",
            },
            right = {
                right = 1,
                forward = 0,
                z = 0,
                faceTarget = "player",
            },
        },
    },
    beats = {
        {
            id = "kiss",
            durationMs = 900,
            synchronization = "arrival_and_start_barrier",
            player = {
                route = "player_action",
                catalog = "player",
                entryId = "player.player_native.RemoveBush.RemoveBush",
                action = "RemoveBush",
                animation = "Bob_Shove",
            },
            npc = {
                route = "zombie_bump",
                catalog = "npc",
                entryId = "npc.bumped.PNC_Shove.PNC_Shove",
                bump = "PNC_Shove",
                animation = "Bob_Shove",
                nonCombat = true,
            },
        },
    },
    playback = {
        defaultMode = "once",
        allowLoop = true,
        gapMs = 250,
    },
}

Registry.Definitions = Registry.Definitions or {}
Registry.Register(defaultBlueprint.id, defaultBlueprint)

return Registry
