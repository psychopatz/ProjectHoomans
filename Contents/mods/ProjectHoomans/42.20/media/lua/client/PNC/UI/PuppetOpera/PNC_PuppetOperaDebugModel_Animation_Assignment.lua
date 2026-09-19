-- Capability-checked player/NPC track assignment for Puppet Opera.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local Capabilities = Internal.Capabilities
local copy = Internal.copy
local markChanged = Internal.markChanged
local actorDefinition = Internal.actorDefinition
local ensureTracks = Internal.ensureTracks
local entryID = Internal.entryID
local bumpType = Internal.bumpType
local directNPCEntry = Internal.directNPCEntry

local function setPlayerFromEntry(beat, actorID, entry)
    local track = Capabilities.NormalizeTrack("local_player", {
        route = entry.mode == "emote" and "player_emote" or "player_action",
        mode = entry.mode or "action",
        catalog = "player",
        entryId = entryID("player", entry),
        state = entry.state,
        action = entry.action,
        emote = entry.emote,
        anim = entry.anim,
        animation = entry.anim,
        event = entry.event,
        variables = copy(entry.variables),
        playable = true,
        -- Preserve catalog provenance for the authoring draft. The runtime
        -- normalizer intentionally consumes only the safe player route, but
        -- the builder should still show whether a track came from a native
        -- player node or a PNC-prefixed player-compatible bridge.
        source = entry.source,
        sourceState = entry.sourceState,
        sourceRoute = entry.route,
        compatibility = entry.compatibility,
        bridgeFile = entry.bridgeFile,
        bridgePath = entry.bridgePath,
        fullBody = entry.fullBody == true,
        looped = entry.looped == true,
        speed = entry.speed,
    })
    local tracks = ensureTracks(beat)
    local definition = actorDefinition(actorID)
    if definition and not definition.kind then
        tracks[tostring(actorID)] = tracks[tostring(actorID)] or {}
        tracks[tostring(actorID)].byKind = tracks[tostring(actorID)].byKind
            or {}
        tracks[tostring(actorID)].byKind.local_player = track
    else
        tracks[tostring(actorID)] = track
    end
    if tostring(actorID) == "player" then beat.player = track end
end

local function setNPCFromEntry(beat, actorID, entry)
    local bump = bumpType(entry)
    if not bump then return false, "npc_catalog_entry_has_no_bump_type" end
    if not directNPCEntry(entry) then
        return false, "npc_catalog_entry_requires_selector_context"
    end
    local track = Capabilities.NormalizeTrack("nearby_live_npc", {
        route = "zombie_bump",
        mode = "bump",
        catalog = "npc",
        entryId = entryID("npc", entry),
        bump = bump,
        anim = entry.anim,
        animation = entry.anim,
        nonCombat = true,
    })
    local tracks = ensureTracks(beat)
    local definition = actorDefinition(actorID)
    if definition and not definition.kind then
        tracks[tostring(actorID)] = tracks[tostring(actorID)] or {}
        tracks[tostring(actorID)].byKind = tracks[tostring(actorID)].byKind
            or {}
        tracks[tostring(actorID)].byKind.nearby_live_npc = track
    else
        tracks[tostring(actorID)] = track
    end
    if tostring(actorID) == "npc" then beat.npc = track end
    return true
end

function Model.AssignAnimation(actorID, entry)
    local beat = Model.GetSelectedBeat()
    if not beat or type(entry) ~= "table" then
        return false, "animation_assignment_missing"
    end
    actorID = tostring(actorID or State.selectedActorID or "")
    local definition = actorDefinition(actorID)
    if not definition then return false, "actor_not_found" end
    local actorKind = Model.GetActorKind(actorID)
    if not actorKind then return false, "actor_kind_required" end
    local accepted
    local reason
    if actorKind == "local_player" then
        local approved, capabilityReason = Capabilities.IsSceneApproved(
            "local_player",
            {
                mode = entry.mode,
                action = entry.action,
                emote = entry.emote,
            }
        )
        if not approved then
            return false, capabilityReason or "player_animation_not_scene_approved"
        end
        if entry.mode == "emote" then
            if not entry.emote or entry.emote == "" then
                return false, "player_catalog_entry_has_no_emote"
            end
        elseif not entry.action or entry.action == "" then
            return false, "player_catalog_entry_has_no_action"
        end
        setPlayerFromEntry(beat, actorID, entry)
        accepted = true
    elseif actorKind == "nearby_live_npc" then
        local bump = bumpType(entry)
        local approved, capabilityReason = Capabilities.IsSceneApproved(
            "nearby_live_npc",
            { bump = bump, nonCombat = true }
        )
        if not approved then
            return false, capabilityReason or "npc_animation_not_scene_approved"
        end
        accepted, reason = setNPCFromEntry(beat, actorID, entry)
        if not accepted then return false, reason end
    else
        return false, "actor_animation_route_not_supported"
    end
    markChanged()
    return true
end

return Model
