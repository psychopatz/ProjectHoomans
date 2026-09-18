-- Explicit animation-route capabilities for Puppet Opera.
--
-- A shared animation clip does not make player and NPC routes interchangeable.
-- Capabilities describe the route, actor kind, and runtime policy separately.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.AnimationCapabilities =
    PNC.PuppetOpera.AnimationCapabilities or {}

local Capabilities = PNC.PuppetOpera.AnimationCapabilities

local DEFINITIONS = {
    ["player.action.RemoveBush"] = {
        id = "player.action.RemoveBush",
        actorKind = "local_player",
        route = "player_action",
        source = "player_native",
        scenePolicy = "scene_approved",
        gameplayEvents = true,
        loopable = false,
        warning = "player action XML contains the native Chop event",
    },
    ["player.emote.wavehi"] = {
        id = "player.emote.wavehi",
        actorKind = "local_player",
        route = "player_emote",
        source = "player_native",
        scenePolicy = "scene_approved",
        gameplayEvents = false,
        loopable = true,
    },
    ["npc.bump.PNC_Shove"] = {
        id = "npc.bump.PNC_Shove",
        actorKind = "nearby_live_npc",
        route = "zombie_bump",
        source = "PNC_xml",
        -- PNC_Shove is classified by the existing bump state machine as a
        -- combat bump.  Keep it visible for inspection/preview, but never
        -- allow it to be selected for a live Puppet Opera beat.
        scenePolicy = "preview_only",
        gameplayEvents = false,
        loopable = false,
        nonCombatRequired = true,
        warning = "combat-classified bump; preview only, use PNC_WaveHi for social scenes",
    },
    ["npc.bump.PNC_WaveHi"] = {
        id = "npc.bump.PNC_WaveHi",
        actorKind = "nearby_live_npc",
        route = "zombie_bump",
        source = "PNC_xml",
        scenePolicy = "scene_approved",
        gameplayEvents = false,
        loopable = true,
        nonCombatRequired = true,
    },
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth > 4 then return nil end
    local result = {}
    for key, child in pairs(value) do
        result[key] = type(child) == "table"
            and copy(child, depth + 1) or child
    end
    return result
end

local function clean(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

function Capabilities.Get(id)
    local definition = DEFINITIONS[tostring(id or "")]
    return definition and copy(definition) or nil
end

function Capabilities.ForTrack(actorKind, track)
    if type(track) ~= "table" then return nil end
    local id
    if actorKind == "local_player" then
        if track.mode == "emote" or track.emote then
            id = "player.emote." .. tostring(track.emote or "")
        elseif track.action then
            id = "player.action." .. tostring(track.action)
        end
    elseif actorKind == "nearby_live_npc" then
        id = "npc.bump." .. tostring(track.bump or "")
    end
    if track.capabilityId and DEFINITIONS[tostring(track.capabilityId)] then
        id = tostring(track.capabilityId)
    end
    return id and Capabilities.Get(id) or nil
end

function Capabilities.IsSceneApproved(actorKind, track)
    local capability = Capabilities.ForTrack(actorKind, track)
    if not capability then return false, "animation_capability_unknown" end
    if capability.actorKind ~= actorKind then
        return false, "animation_actor_kind_mismatch:" .. capability.id
    end
    if capability.scenePolicy ~= "scene_approved" then
        return false, "animation_capability_not_scene_approved:" .. capability.id
    end
    if actorKind == "nearby_live_npc"
        and capability.nonCombatRequired
        and track.nonCombat ~= true
    then
        return false, "npc_animation_requires_noncombat:" .. capability.id
    end
    return true, capability.id, capability
end

function Capabilities.IsRuntimePlayerAction(action)
    return Capabilities.IsSceneApproved("local_player", {
        action = action,
        mode = "action",
    })
end

function Capabilities.IsRuntimeNPCBump(bump)
    return Capabilities.IsSceneApproved("nearby_live_npc", {
        bump = bump,
        nonCombat = true,
    })
end

function Capabilities.DescribeEntry(catalogName, entry, bump)
    if catalogName == "player" then
        local track = {
            mode = entry and entry.mode,
            action = entry and entry.action,
            emote = entry and entry.emote,
        }
        local capability = Capabilities.ForTrack("local_player", track)
        if capability then return copy(capability) end
        return {
            id = "player.unknown",
            actorKind = "local_player",
            route = entry and entry.route or "unknown",
            scenePolicy = "preview_only",
            warning = "catalog entry has no registered Puppet Opera capability",
        }
    end
    local capability = Capabilities.ForTrack("nearby_live_npc", {
        bump = bump,
    })
    if capability then return copy(capability) end
    return {
        id = "npc.unknown",
        actorKind = "nearby_live_npc",
        route = "unknown",
        scenePolicy = "preview_only",
        warning = "catalog entry has no registered Puppet Opera capability",
    }
end

function Capabilities.NormalizeTrack(actorKind, track)
    local result = copy(track or {})
    local capability = Capabilities.ForTrack(actorKind, result)
    if capability then
        result.capabilityId = capability.id
        result.scenePolicy = capability.scenePolicy
        result.gameplayEvents = capability.gameplayEvents == true
        result.loopable = capability.loopable == true
    end
    return result
end

return Capabilities
