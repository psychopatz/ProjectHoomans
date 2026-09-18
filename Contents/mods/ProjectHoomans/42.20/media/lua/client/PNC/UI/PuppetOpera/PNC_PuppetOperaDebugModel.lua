-- Client-side scene-builder model for Puppet Opera.
--
-- This model owns only declarative draft data and UI selection state.  It
-- never moves an actor or starts an animation; playback remains in the
-- existing Puppet Opera transport and the proven Core/Hoomans adapters.

require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"
require "PNC/Debug/PNC_AnimationDebugCatalog"

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Opera = PNC.PuppetOpera
local Client = Opera and Opera.Client
local Blueprints = Opera and Opera.Blueprints
local Anchors = Opera and Opera.Anchors
local Capabilities = Opera and Opera.AnimationCapabilities
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimationCapabilities"
local PlayerCatalog = PNC.PlayerAnimationDebugCatalog or {}
local NPCCatalog = PNC.AnimationDebugCatalog or {}

local State = Model.State or {}
Model.State = State
State.blueprintID = State.blueprintID or "social.kiss_player_npc"
State.drafts = State.drafts or {}
State.bases = State.bases or {}
State.dirtyByID = State.dirtyByID or {}
-- Selection is editor state, not an implicit runtime binding. Starting with
-- no selected slot keeps the canvas neutral and makes live-actor binding an
-- explicit builder operation.
State.selectedActorID = State.selectedActorID
State.selectedBeatIndex = tonumber(State.selectedBeatIndex) or 1
State.selectedNPCID = State.selectedNPCID
-- `zombie` was the old UI label for player-compatible bridge entries. Keep
-- old in-memory drafts readable, but expose the actual route explicitly.
State.playerSource = State.playerSource == "zombie"
    and "bridge" or State.playerSource or "player"
if State.playerSource ~= "player" and State.playerSource ~= "bridge" then
    State.playerSource = "player"
end
State.playerQuery = State.playerQuery or ""
State.npcQuery = State.npcQuery or ""
State.npcState = State.npcState or "bumped"
State.actorBindings = State.actorBindings or {}
State.animationTargets = State.animationTargets or {}
State.pendingLiveActorID = State.pendingLiveActorID
State.editorError = nil
State.changeSerial = tonumber(State.changeSerial) or 0
State.persistentBlueprintsLoaded = State.persistentBlueprintsLoaded == true

local function loadPersistentBlueprints()
    if State.persistentBlueprintsLoaded then return end
    State.persistentBlueprintsLoaded = true
    -- The test harness does not provide the game file API. Avoid loading the
    -- client storage module there, while the live game still discovers saved
    -- Opera Definitions through the same root database as Unique NPCs.
    if type(getFileReader) ~= "function" then return end
    local storage = require "PNC/UI/PuppetOpera/PNC_PuppetOperaStorage"
    for _, item in ipairs(storage.List()) do
        if item.draft and item.draft.id then
            Blueprints.Register(item.draft.id, item.draft)
        end
    end
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth > 12 then return nil end
    local result = {}
    for key, child in pairs(value) do
        local childType = type(child)
        if childType ~= "function"
            and childType ~= "userdata"
            and childType ~= "thread"
        then
            result[key] = childType == "table"
                and copy(child, depth + 1) or child
        end
    end
    return result
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function trimXML(value)
    return string.gsub(tostring(value or ""), "%.xml$", "")
end

local function entryID(catalogName, entry)
    if not entry then return nil end
    local source = entry.source or entry.folder or "entry"
    local file = trimXML(entry.file or "entry")
    local node = entry.node or entry.state or "node"
    local value = tostring(catalogName or "catalog") .. "."
        .. tostring(source) .. "." .. tostring(file) .. "."
        .. tostring(node)
    return string.gsub(value, "[^%w%._%-]", "_")
end

local function searchText(entry)
    local values = {
        tostring(entry.state or ""),
        tostring(entry.source or ""),
        tostring(entry.sourceState or ""),
        tostring(entry.mode or ""),
        tostring(entry.route or ""),
        tostring(entry.folder or ""),
        tostring(entry.file or ""),
        tostring(entry.path or ""),
        tostring(entry.node or ""),
        tostring(entry.anim or ""),
        tostring(entry.action or ""),
        tostring(entry.emote or ""),
    }
    for _, condition in ipairs(entry.conditions or {}) do
        values[#values + 1] = tostring(condition.name or "")
        values[#values + 1] = tostring(condition.kind or "")
        values[#values + 1] = tostring(condition.value or "")
    end
    for _, event in ipairs(entry.events or {}) do
        values[#values + 1] = tostring(event.name or "")
        values[#values + 1] = tostring(event.parameter or "")
    end
    return lower(table.concat(values, " "))
end

local function bumpType(entry)
    for _, condition in ipairs(entry and entry.conditions or {}) do
        if condition.name == "BumpType"
            and condition.kind == "STRING"
            and condition.value
            and condition.value ~= ""
        then
            return tostring(condition.value)
        end
    end
    return nil
end

local function directNPCEntry(entry)
    local count = 0
    for _, condition in ipairs(entry and entry.conditions or {}) do
        if condition.name ~= "PNCActor" and condition.name ~= "BumpType" then
            count = count + 1
        end
    end
    return count == 0
end

local function touch()
    State.changeSerial = State.changeSerial + 1
end

local function markChanged()
    touch()
    State.editorError = nil
    State.dirtyByID[tostring(State.blueprintID)] = true
end

local function currentDraft()
    loadPersistentBlueprints()
    local id = tostring(State.blueprintID or "social.kiss_player_npc")
    if not State.drafts[id] then
        local blueprint = Blueprints and Blueprints.Get(id) or nil
        if blueprint then
            State.drafts[id] = copy(blueprint)
            State.bases[id] = copy(blueprint)
            State.dirtyByID[id] = false
        end
    elseif not State.bases[id] and Blueprints and Blueprints.Get(id) then
        State.bases[id] = copy(Blueprints.Get(id))
    end
    return State.drafts[id]
end

local function translatedLabel(key, fallback)
    local translation = PNC.Translation
    if key and translation and translation.GetKey then
        local value = translation.GetKey(key, fallback)
        if value and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function blueprintLabel(blueprint)
    return translatedLabel(
        blueprint and blueprint.labelKey,
        blueprint and blueprint.label or blueprint and blueprint.id or "-"
    )
end

local function actorLabel(definition, fallback)
    return translatedLabel(
        definition and definition.labelKey,
        definition and definition.label ~= ""
            and definition.label or fallback
    )
end

local function actorOrder(left, right)
    local order = {
        actor_1 = 1,
        actor_2 = 2,
        player = 1,
        npc = 2,
    }
    local leftOrder = order[left.id] or 10
    local rightOrder = order[right.id] or 10
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return tostring(left.id) < tostring(right.id)
end

local function firstActorID(draft)
    local first
    for id in pairs(draft and draft.actors or {}) do
        if not first or tostring(id) < tostring(first) then first = id end
    end
    return first or "player"
end

local function actorDefinition(actorID)
    local draft = currentDraft()
    return draft and draft.actors and draft.actors[tostring(actorID)] or nil
end

local function bindingMap()
    local id = tostring(State.blueprintID or "")
    State.actorBindings[id] = State.actorBindings[id] or {}
    return State.actorBindings[id]
end

local function actorBinding(actorID, definition)
    local bindings = bindingMap()
    local bound = bindings[tostring(actorID)]
    if bound and tostring(bound) ~= "" then return tostring(bound) end
    return nil
end

local function allowedActorKinds(definition)
    if not definition then return {} end
    if definition.kind then return { definition.kind } end
    local result = {}
    for _, kind in ipairs(definition.allowedKinds or {}) do
        result[#result + 1] = tostring(kind)
    end
    if #result == 0 then
        result = { "local_player", "nearby_live_npc" }
    end
    return result
end

local function kindAllowed(definition, actorKind)
    actorKind = tostring(actorKind or "")
    for _, kind in ipairs(allowedActorKinds(definition)) do
        if kind == actorKind then return true end
    end
    return false
end

-- This is a live-list identity, not a blueprint actor id. Keeping it
-- separate prevents a drag from the live list from being confused with the
-- scene's ordinary `player` slot.
local LIVE_PLAYER_ID = "__local_player__"

local function compactLiveID(value)
    local id = tostring(value or "")
    if id == "" or id == LIVE_PLAYER_ID then return nil end
    if #id <= 8 then return id end
    return string.sub(id, -8)
end

local function findLiveActorRow(id, rows)
    id = id and tostring(id) or nil
    if not id then return nil end
    for _, row in ipairs(rows or {}) do
        if tostring(row.id) == id then return row end
    end
    return nil
end

local function liveActorName(row, fallback)
    local name = row and row.name or fallback
    name = tostring(name or "")
    return name ~= "" and name or tostring(fallback or "Unknown actor")
end

local function actorDiscoveryRadius()
    return Opera and Opera.Config
        and tonumber(Opera.Config.actorDiscoveryRadius) or 12
end

local function trackForBeat(beat, actorID, actorKind)
    if not beat then return nil end
    actorID = tostring(actorID or "")
    local track
    if type(beat.tracks) == "table" and beat.tracks[actorID] then
        track = beat.tracks[actorID]
    else
        track = beat[actorID]
    end
    if type(track) == "table" and type(track.byKind) == "table" then
        return actorKind and track.byKind[tostring(actorKind)] or track
    end
    return track
end

local function beatTrackSummary(beat)
    local ids = {}
    local tracks = beat and beat.tracks or nil
    if type(tracks) == "table" then
        for actorID in pairs(tracks) do ids[#ids + 1] = tostring(actorID) end
    else
        if beat and beat.player then ids[#ids + 1] = "player" end
        if beat and beat.npc then ids[#ids + 1] = "npc" end
    end
    table.sort(ids)
    local parts = {}
    for _, actorID in ipairs(ids) do
        local definition = actorDefinition(actorID)
        local track = trackForBeat(
            beat,
            actorID,
            definition and definition.kind or nil
        )
        local identity = actorID
        if definition then
            identity = actorLabel(definition, actorID)
                .. " [slot=" .. tostring(actorID) .. "]"
            local binding = actorBinding(actorID, definition)
            if binding then
                local live = findLiveActorRow(
                    binding,
                    Model.GetLiveActorRows(actorDiscoveryRadius())
                )
                identity = identity .. " -> "
                    .. liveActorName(live, binding)
                    .. " [" .. tostring(binding) .. "]"
            end
        end
        local value
        if track and track.mode == "emote" then
            value = track.emote
        elseif track and track.action then
            value = track.action .. "/" .. tostring(track.anim or "-")
        else
            value = track and (track.bump or track.anim) or "-"
        end
        parts[#parts + 1] = identity .. "=" .. tostring(value or "-")
    end
    return table.concat(parts, " | ")
end

local function ensureTracks(beat)
    if not beat then return nil end
    beat.tracks = beat.tracks or {}
    if beat.tracks.player == nil and beat.player ~= nil then
        beat.tracks.player = beat.player
    end
    if beat.tracks.npc == nil and beat.npc ~= nil then
        beat.tracks.npc = beat.npc
    end
    return beat.tracks
end

local function uniqueID(prefix, values)
    local base = tostring(prefix or "actor")
    local candidate = base
    local serial = 2
    while values[candidate] do
        candidate = base .. "_" .. tostring(serial)
        serial = serial + 1
    end
    return candidate
end

local function beatAt(index)
    local draft = currentDraft()
    return draft and draft.beats and draft.beats[tonumber(index) or 1] or nil
end

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

function Model.GetBlueprints()
    loadPersistentBlueprints()
    local result = {}
    local seen = {}
    for _, blueprint in ipairs(Blueprints and Blueprints.List() or {}) do
        local id = tostring(blueprint.id)
        if blueprint.legacy ~= true then
            seen[id] = true
            result[#result + 1] = {
                id = id,
                label = blueprintLabel(blueprint),
                description = blueprint.description or "",
                sceneType = blueprint.sceneType,
                dirty = State.dirtyByID[id] == true,
            }
        end
    end
    for id, draft in pairs(State.drafts) do
        if not seen[tostring(id)] and draft and draft.legacy ~= true then
            result[#result + 1] = {
                id = tostring(id),
                label = blueprintLabel(draft),
                description = draft.description or "",
                sceneType = draft.sceneType,
                dirty = true,
            }
        end
    end
    table.sort(result, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return result
end

function Model.GetBlueprintID()
    return tostring(State.blueprintID)
end

function Model.IsDirty(id)
    return State.dirtyByID[tostring(id or State.blueprintID)] == true
end

function Model.SetBlueprintID(id)
    loadPersistentBlueprints()
    id = tostring(id or "")
    if id == "" or (
        not (Blueprints and Blueprints.Get(id))
        and not State.drafts[id]
    )
    then
        return false, "blueprint_not_found"
    end
    State.blueprintID = id
    currentDraft()
    State.selectedActorID = nil
    State.selectedBeatIndex = 1
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    State.actorBindings[id] = {}
    State.editorError = nil
    touch()
    return true
end

function Model.GetDraft()
    return currentDraft()
end

function Model.DuplicateBlueprint()
    local source = currentDraft()
    if not source then return false, "blueprint_not_found" end
    local base = tostring(source.id) .. "_copy"
    local id = base
    local serial = 2
    while (Blueprints and Blueprints.Get(id)) or State.drafts[id] do
        id = base .. tostring(serial)
        serial = serial + 1
    end
    local draft = copy(source)
    draft.id = id
    draft.label = tostring(source.label or id) .. " (copy)"
    draft.legacy = nil
    State.drafts[id] = draft
    State.bases[id] = copy(draft)
    State.dirtyByID[id] = true
    State.blueprintID = id
    State.selectedActorID = nil
    State.selectedBeatIndex = 1
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    State.actorBindings[id] = {}
    markChanged()
    return true, draft
end

function Model.CreateNew()
    loadPersistentBlueprints()
    local base = "opera.new_scene"
    local id = base
    local serial = 2
    while (Blueprints and Blueprints.Get(id)) or State.drafts[id] do
        id = base .. "_" .. tostring(serial)
        serial = serial + 1
    end
    local draft = {
        id = id,
        version = 1,
        definitionType = "opera",
        sceneType = "custom",
        label = "New Opera Scene",
        description = "Author a multi-actor scene from explicit actor slots.",
        actors = {},
        anchorFrame = {
            origin = "server_player_relative",
            orientation = "player_facing",
            tolerance = 0.75,
            anchors = {},
        },
        beats = {
            {
                id = "beat_1",
                durationMs = 900,
                synchronization = "arrival_and_start_barrier",
                tracks = {},
            },
        },
        playback = {
            defaultMode = "once",
            allowLoop = true,
            gapMs = 250,
        },
    }
    State.drafts[id] = draft
    State.bases[id] = copy(draft)
    State.dirtyByID[id] = true
    State.blueprintID = id
    State.selectedActorID = nil
    State.selectedBeatIndex = 1
    State.pendingLiveActorID = nil
    State.actorBindings[id] = {}
    State.animationTargets = {}
    markChanged()
    return true, draft
end

function Model.SaveDraft()
    local draft = currentDraft()
    if not draft or not Blueprints then return false, "blueprint_not_found" end
    local normalized, reason = Blueprints.Normalize(draft.id, draft)
    if not normalized then
        State.editorError = reason
        return false, reason
    end
    if type(getFileWriter) == "function" then
        local storage = require "PNC/UI/PuppetOpera/PNC_PuppetOperaStorage"
        local stored, storeReason, storedDefinition = storage.Save(normalized)
        if not stored then
            State.editorError = storeReason
            return false, storeReason
        end
        normalized = storedDefinition or normalized
    end
    local registered, registeredValue = Blueprints.Register(
        normalized.id,
        normalized
    )
    if registered ~= true then
        State.editorError = registeredValue
        return false, registeredValue
    end
    State.drafts[normalized.id] = registeredValue
    State.bases[normalized.id] = copy(registeredValue)
    State.blueprintID = normalized.id
    State.editorError = nil
    State.dirtyByID[normalized.id] = false
    touch()
    return true, registeredValue
end

function Model.ResetDraft()
    local id = tostring(State.blueprintID)
    local base = State.bases[id] or (Blueprints and Blueprints.Get(id))
    if not base then return false, "blueprint_not_found" end
    State.drafts[id] = copy(base)
    State.editorError = nil
    State.selectedActorID = nil
    State.selectedBeatIndex = 1
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    State.actorBindings[id] = {}
    State.dirtyByID[id] = false
    touch()
    return true
end

function Model.ClearActorBindings()
    State.actorBindings[tostring(State.blueprintID or "")] = {}
    State.selectedActorID = nil
    State.selectedNPCID = nil
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    touch()
end

function Model.GetValidation()
    local draft = currentDraft()
    if not draft or not Blueprints then return false, "blueprint_not_found" end
    local normalized, reason = Blueprints.Normalize(draft.id, draft)
    if not normalized then return false, reason end
    local runtimeOK, runtimeReason = Blueprints.ValidateRuntime(normalized)
    return true, runtimeOK and nil or runtimeReason, normalized
end

function Model.GetNearbyNPCs(radius)
    return Client and Client.GetNearbyNPCs
        and Client.GetNearbyNPCs(radius or actorDiscoveryRadius()) or {}
end

function Model.GetActorDiscoveryRadius()
    return actorDiscoveryRadius()
end

function Model.RefreshPreflight(force)
    if not Client or not Client.Preflight then
        return false, "puppet_opera_preflight_unavailable"
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then return false, runtimeReason end
    local bindings = Model.GetRuntimeActorBindings() or {}
    local key = Model.GetBlueprintID() .. ":"
        .. tostring(Model.GetChangeSerial())
    return Client.Preflight(
        Model.GetBlueprintID(),
        normalized,
        bindings,
        key,
        force == true
    )
end

function Model.SetSelectedNPC(id)
    local previousID = State.selectedNPCID
    local previousPending = State.pendingLiveActorID
    State.selectedNPCID = id and tostring(id) or nil
    if not id then State.pendingLiveActorID = nil end
    if previousID ~= State.selectedNPCID
        or previousPending ~= State.pendingLiveActorID
    then
        touch()
    end
end

function Model.ClearLiveSelection()
    local changed = State.selectedNPCID ~= nil
        or State.pendingLiveActorID ~= nil
    State.selectedNPCID = nil
    State.pendingLiveActorID = nil
    if changed then touch() end
end

function Model.ResetEditorSelection()
    local changed = State.selectedActorID ~= nil
        or State.selectedNPCID ~= nil
        or State.pendingLiveActorID ~= nil
    State.selectedActorID = nil
    State.selectedNPCID = nil
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    if changed then touch() end
end

function Model.GetSelectedNPC()
    local id = State.selectedNPCID
    if not id then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == tostring(id) then return npc end
    end
    return nil
end

function Model.GetSelectedNPCID()
    return State.selectedNPCID
end

function Model.GetActorBinding(actorID)
    return actorBinding(actorID, actorDefinition(actorID))
end

function Model.BindLiveActor(actorID, liveID)
    actorID = tostring(actorID or "")
    liveID = liveID and tostring(liveID) or ""
    local definition = actorDefinition(actorID)
    if not definition then return false, "actor_not_found" end
    if liveID == "" then return false, "live_actor_id_missing" end
    local found
    for _, row in ipairs(Model.GetLiveActorRows(actorDiscoveryRadius())) do
        if tostring(row.id) == liveID
        then
            found = row
            break
        end
    end
    if not found then return false, "nearby_live_actor_not_found" end
    if not kindAllowed(definition, found.kind) then
        return false, "actor_kind_not_allowed:" .. tostring(found.kind)
    end
    for otherID, otherBinding in pairs(bindingMap()) do
        if tostring(otherID) ~= actorID
            and tostring(otherBinding or "") == liveID
        then
            return false, "live_actor_already_bound:" .. tostring(otherID)
        end
    end
    if definition.dynamic == true and not definition.kind then
        definition.kind = found.kind
        definition.allowedKinds = { found.kind }
    end
    bindingMap()[actorID] = liveID
    State.selectedActorID = actorID
    State.selectedNPCID = found.kind == "nearby_live_npc" and liveID or nil
    State.pendingLiveActorID = nil
    markChanged()
    return true, actorID
end

function Model.UnbindLiveActor(actorID)
    actorID = tostring(actorID or "")
    if not actorDefinition(actorID) then return false, "actor_not_found" end
    if not bindingMap()[actorID] then return false, "actor_unbound" end
    bindingMap()[actorID] = nil
    local definition = actorDefinition(actorID)
    if definition and definition.dynamic == true then
        definition.kind = nil
        definition.allowedKinds = { "local_player", "nearby_live_npc" }
    end
    if State.selectedActorID == actorID then State.selectedActorID = nil end
    State.pendingLiveActorID = nil
    State.selectedNPCID = nil
    markChanged()
    return true
end

function Model.GetRuntimeActorBindings()
    local draft = currentDraft()
    if not draft or type(draft.actors) ~= "table" then
        return nil, "actors_required"
    end
    local bindings = {}
    for actorID, definition in pairs(draft.actors) do
        local bound = actorBinding(actorID, definition)
        if not bound and definition.required ~= false then
            return nil, "actor_unassigned:" .. tostring(actorID)
        end
        if bound then bindings[tostring(actorID)] = bound end
    end
    return bindings
end

function Model.GetPreflight()
    return Client and Client.GetPreflight and Client.GetPreflight() or nil
end

function Model.GetLiveActorReadiness(id)
    id = id and tostring(id) or nil
    if not id then return nil end
    local preflight = Model.GetPreflight()
    for actorID, readiness in pairs(preflight and preflight.actors or {}) do
        if readiness
            and ((readiness.kind == "local_player"
                and id == LIVE_PLAYER_ID)
                or tostring(readiness.bindingID or "") == id)
        then
            return readiness
        end
    end
    return nil
end

function Model.GetUnassignedNearbyNPCs(radius)
    local assigned = {}
    for _, bound in pairs(bindingMap()) do
        assigned[tostring(bound)] = true
    end
    local result = {}
    for _, npc in ipairs(Model.GetNearbyNPCs(radius or actorDiscoveryRadius())) do
        if not assigned[tostring(npc.id)] then result[#result + 1] = npc end
    end
    return result
end

function Model.GetLiveActorRows(radius)
    local assignments = {}
    local playerAssignment
    local draft = currentDraft()
    for actorID, definition in pairs(draft and draft.actors or {}) do
        local bound = actorBinding(actorID, definition)
        if bound then
            assignments[tostring(bound)] = actorID
            if tostring(bound) == LIVE_PLAYER_ID then
                playerAssignment = actorID
            end
        end
    end
    local result = {}
    local playerBody = Client and Client.GetLocalPlayer
        and Client.GetLocalPlayer() or nil
    if playerBody and playerBody.getX and playerBody.getY then
        local playerName = playerBody.getUsername
            and playerBody:getUsername() or translatedLabel(
                "UI_PNC_PuppetOpera_LocalPlayer", "Local player")
        if not playerName or tostring(playerName) == "" then
            playerName = translatedLabel(
                "UI_PNC_PuppetOpera_LocalPlayer", "Local player")
        end
        local playerRow = {
            id = LIVE_PLAYER_ID,
            name = playerName,
            kind = "local_player",
            shortID = nil,
            distSq = 0,
            assignedActorID = playerAssignment,
            body = playerBody,
            record = nil,
            snapshot = nil,
        }
        local playerReadiness = Model.GetLiveActorReadiness(LIVE_PLAYER_ID)
        if playerReadiness then
            playerRow.ready = playerReadiness.ready
            playerRow.reason = playerReadiness.reasonDetail
                or playerReadiness.reason
            playerRow.actionState = playerReadiness.actionState
            playerRow.actionContextState = playerReadiness.actionContextState
            playerRow.owner = playerReadiness.owner
        end
        result[#result + 1] = playerRow
    end
    for _, npc in ipairs(Model.GetNearbyNPCs(radius or actorDiscoveryRadius())) do
        local id = tostring(npc.id)
        local row = {
            id = id,
            name = npc.name or id,
            kind = "nearby_live_npc",
            shortID = compactLiveID(id),
            distSq = npc.distSq,
            assignedActorID = assignments[id],
            body = npc.zombie,
            record = npc.record,
            snapshot = npc.snapshot,
        }
        local readiness = Model.GetLiveActorReadiness(id)
        if readiness then
            row.ready = readiness.ready
            row.reason = readiness.reasonDetail or readiness.reason
            row.actionState = readiness.actionState
            row.actionContextState = readiness.actionContextState
            row.owner = readiness.owner
            row.distance = readiness.distance
        end
        result[#result + 1] = row
    end
    return result
end

function Model.SelectLiveActor(id)
    id = id and tostring(id) or nil
    if not id then return false, "live_actor_id_missing" end
    local found
    for _, liveActor in ipairs(Model.GetLiveActorRows(actorDiscoveryRadius())) do
        if tostring(liveActor.id) == id then
            found = liveActor
            break
        end
    end
    if not found then return false, "nearby_live_actor_not_found" end
    State.pendingLiveActorID = id
    if found.kind == "nearby_live_npc" then
        State.selectedNPCID = id
    else
        State.selectedNPCID = nil
    end
    if found.assignedActorID then
        State.selectedActorID = found.assignedActorID
        State.pendingLiveActorID = nil
        State.animationTargets[found.kind == "local_player"
            and "player" or "npc"] = "scene:"
            .. tostring(found.assignedActorID)
    else
        -- A free live body is a preview/drag source, never an implicit
        -- assignment target.  The user must drop it onto an explicit scene
        -- slot or add a container first.
        State.selectedActorID = nil
        State.animationTargets[found.kind == "local_player"
            and "player" or "npc"] = "live:" .. id
    end
    touch()
    return true
end

function Model.GetPendingLiveActorID()
    return State.pendingLiveActorID
end

function Model.GetNPCForActor(actorID)
    local id = Model.GetActorBinding(actorID)
    if not id then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == tostring(id) then return npc end
    end
    return nil
end

function Model.GetNPCForLiveID(liveID)
    liveID = liveID and tostring(liveID) or nil
    if not liveID then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == liveID then return npc end
    end
    return nil
end

function Model.SelectActor(id)
    State.selectedActorID = id and tostring(id) or nil
    State.pendingLiveActorID = nil
    State.selectedNPCID = nil
    local definition = actorDefinition(State.selectedActorID)
    local kind = definition and Model.GetActorKind(State.selectedActorID) or nil
    if kind == "local_player" then
        State.animationTargets.player = "scene:" .. State.selectedActorID
        State.animationTargets.npc = nil
    elseif kind == "nearby_live_npc" then
        State.animationTargets.npc = "scene:" .. State.selectedActorID
        State.animationTargets.player = nil
        State.selectedNPCID = actorBinding(
            State.selectedActorID,
            definition
        )
    else
        State.animationTargets.player = nil
        State.animationTargets.npc = nil
    end
    touch()
end

function Model.GetSelectedActorID()
    return State.selectedActorID
end

function Model.GetActorKind(actorID)
    local definition = actorDefinition(actorID)
    if not definition then return nil end
    if definition.kind then return definition.kind end
    local bound = actorBinding(actorID, definition)
    if not bound then return nil end
    local row = findLiveActorRow(
        bound,
        Model.GetLiveActorRows(actorDiscoveryRadius())
    )
    return row and row.kind or nil
end

function Model.GetActorForCatalog(catalogName)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    local selected = State.selectedActorID
    if actorDefinition(selected)
        and Model.GetActorKind(selected) == wanted
    then
        return selected
    end
    local target = Model.GetAnimationTarget(catalogName)
    if target and target.previewOnly ~= true then
        local targetDefinition = actorDefinition(target.actorID)
        if targetDefinition and Model.GetActorKind(target.actorID) == wanted then
            return target.actorID
        end
    end
    return nil
end

-- Animation browsing has two kinds of target. A scene target can receive an
-- assignment; a live preview target only supplies a concrete local body. They
-- deliberately use different keys so a live NPC ID can never be mistaken for
-- a blueprint actor slot ID.
function Model.GetAnimationTargetRows(catalogName)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    local liveRows = Model.GetLiveActorRows(actorDiscoveryRadius())
    local sceneRows = Model.GetActorRows(Model.GetSnapshot())
    local result = {}
    local bound = {}
    for _, scene in ipairs(sceneRows) do
        if scene.kind == wanted then
            local liveID = scene.liveID
            if not liveID
                and tostring(scene.id) == tostring(State.selectedActorID or "")
                and State.pendingLiveActorID
            then
                local pending = findLiveActorRow(
                    State.pendingLiveActorID,
                    liveRows
                )
                if pending and pending.kind == wanted then
                    liveID = pending.id
                end
            end
            local live = findLiveActorRow(liveID, liveRows)
            local fallbackName = scene.liveName or (
                liveID and ("Unavailable [" .. tostring(liveID) .. "]")
                or "unbound")
            local name = liveActorName(live, fallbackName)
            result[#result + 1] = {
                key = "scene:" .. tostring(scene.id),
                actorID = tostring(scene.id),
                liveID = liveID,
                name = name,
                label = tostring(scene.label) .. " -> " .. name,
                previewOnly = false,
                body = live and live.body or nil,
                record = live and live.record or nil,
            }
            if liveID then bound[tostring(liveID)] = true end
        end
    end

    -- Keep the local player available for isolated player-animation preview,
    -- even when the draft has no player slot. If a slot exists, the explicit
    -- scene row above remains the assignable target.
    if catalogName == "player" then
        local player = findLiveActorRow(LIVE_PLAYER_ID, liveRows)
        if player then
            result[#result + 1] = {
                key = "live:" .. LIVE_PLAYER_ID,
                liveID = LIVE_PLAYER_ID,
                name = liveActorName(player, translatedLabel(
                    "UI_PNC_PuppetOpera_LocalPlayer", "Local player")),
                label = liveActorName(player, translatedLabel(
                    "UI_PNC_PuppetOpera_LocalPlayer", "Local player"))
                    .. " (preview only)",
                previewOnly = true,
                body = player.body,
                record = player.record,
            }
        end
    else
        -- Unbound live NPCs are preview targets. Bound NPCs are represented by
        -- their named scene rows, avoiding an ambiguous duplicate entry.
        for _, live in ipairs(liveRows) do
            if live.kind == wanted and not bound[tostring(live.id)] then
                result[#result + 1] = {
                    key = "live:" .. tostring(live.id),
                    liveID = tostring(live.id),
                    name = liveActorName(live, live.id),
                    label = liveActorName(live, live.id)
                        .. " [" .. tostring(live.id) .. "] (preview only)",
                    previewOnly = true,
                    body = live.body,
                    record = live.record,
                }
            end
        end
    end
    return result
end

function Model.GetAnimationTarget(catalogName)
    catalogName = catalogName == "player" and "player" or "npc"
    local requested = State.animationTargets[catalogName]
    local rows = Model.GetAnimationTargetRows(catalogName)
    if requested then
        for _, row in ipairs(rows) do
            if row.key == requested then return row end
        end
        -- A disappeared live body must not silently fall back to a different
        -- NPC or scene slot with a similar label.
        return nil
    end
    local selected = State.selectedActorID
    local definition = actorDefinition(selected)
    local wanted = catalogName == "player"
        and "local_player" or "nearby_live_npc"
    if definition and Model.GetActorKind(selected) == wanted then
        for _, row in ipairs(rows) do
            if row.actorID == tostring(selected) then return row end
        end
    end
    return nil
end

function Model.SetAnimationTarget(catalogName, key)
    catalogName = catalogName == "player" and "player" or "npc"
    key = key and tostring(key) or nil
    if not key or key == "" then
        State.animationTargets[catalogName] = nil
        touch()
        return true
    end
    local target
    for _, row in ipairs(Model.GetAnimationTargetRows(catalogName)) do
        if row.key == key then target = row break end
    end
    if not target then return false, "animation_target_not_found" end
    State.animationTargets[catalogName] = key
    if target.previewOnly == true then
        State.selectedActorID = nil
        State.pendingLiveActorID = target.liveID
        if catalogName == "npc" then
            State.selectedNPCID = target.liveID
        else
            State.selectedNPCID = nil
        end
    else
        State.selectedActorID = target.actorID
        State.pendingLiveActorID = nil
        if catalogName == "npc" then State.selectedNPCID = target.liveID end
    end
    touch()
    return true, key
end

function Model.GetPreviewTarget(catalogName)
    local target = Model.GetAnimationTarget(catalogName)
    if not target then return nil, "animation_target_required" end
    if catalogName == "npc" and (not target.body or not target.record) then
        return nil, "animation_target_npc_not_local"
    end
    return target
end

function Model.SelectBeat(index)
    local value = tonumber(index) or 1
    local draft = currentDraft()
    if not draft or not draft.beats or not draft.beats[value] then
        return false, "beat_not_found"
    end
    State.selectedBeatIndex = value
    touch()
    return true
end

function Model.GetSelectedBeatIndex()
    return State.selectedBeatIndex
end

function Model.GetSelectedBeat()
    return beatAt(State.selectedBeatIndex)
end

function Model.GetSnapshot()
    return Client and Client.GetSnapshot and Client.GetSnapshot() or nil
end

function Model.GetTrace()
    return Client and Client.GetTrace and Client.GetTrace() or {}
end

function Model.GetStatus()
    local status = "idle"
    local errorText = nil
    if Client and Client.GetStatus then status, errorText = Client.GetStatus() end
    return status, errorText or State.editorError
end

function Model.GetEditorStatus()
    return State.editorError
end

function Model.GetActorRows(snapshot)
    local draft = currentDraft()
    local rows = {}
    local liveRows = Model.GetLiveActorRows(actorDiscoveryRadius())
    for id, definition in pairs(draft and draft.actors or {}) do
        local runtime = snapshot and snapshot.actors
            and snapshot.actors[id] or nil
        local binding = actorBinding(id, definition)
        local liveID = binding
        local live = findLiveActorRow(liveID, liveRows)
        local resolvedKind = Model.GetActorKind(id)
        rows[#rows + 1] = {
            id = id,
            label = actorLabel(definition, id),
            kind = resolvedKind or "unbound",
            allowedKinds = allowedActorKinds(definition),
            anchor = definition.anchor or "-",
            state = runtime and runtime.state
                or (binding and "bound" or "unbound"),
            bindingID = binding,
            liveID = liveID,
            liveName = live and live.name or nil,
            liveShortID = live and live.shortID or nil,
            target = runtime and runtime.target or nil,
            owned = runtime and (
                runtime.movementOwned == true
                or runtime.animationOwned == true
            ) or false,
            supported = resolvedKind == "local_player"
                or resolvedKind == "nearby_live_npc",
        }
    end
    table.sort(rows, actorOrder)
    return rows
end

function Model.GetGridActors()
    local draft = currentDraft()
    local anchors = draft and draft.anchorFrame
        and draft.anchorFrame.anchors or {}
    local rows = {}
    for id, definition in pairs(draft and draft.actors or {}) do
        local anchor = anchors[definition.anchor]
        if anchor then
            rows[#rows + 1] = {
                id = id,
                label = actorLabel(definition, id),
                kind = Model.GetActorKind(id) or "unbound",
                allowedKinds = allowedActorKinds(definition),
                bindingID = actorBinding(id, definition),
                anchor = definition.anchor,
                right = tonumber(anchor.right) or 0,
                forward = tonumber(anchor.forward) or 0,
                z = tonumber(anchor.z) or 0,
                faceTarget = anchor.faceTarget,
                selected = id == State.selectedActorID,
            }
        end
    end
    table.sort(rows, actorOrder)
    return rows
end

function Model.GetGridPreview()
    local draft = currentDraft()
    return Anchors and Anchors.GetGridPreview
        and Anchors.GetGridPreview(draft) or {}
end

function Model.GetActorAtOffset(right, forward)
    for _, row in ipairs(Model.GetGridActors()) do
        if row.right == right and row.forward == forward then return row end
    end
    return nil
end

function Model.SetActorAnchorOffset(actorID, right, forward, z)
    local draft = currentDraft()
    local actor = draft and draft.actors and draft.actors[tostring(actorID)]
    local anchors = draft and draft.anchorFrame
        and draft.anchorFrame.anchors or nil
    local anchor = actor and anchors and anchors[actor.anchor]
    right = tonumber(right)
    forward = tonumber(forward)
    z = tonumber(z)
    if not anchor or not right or not forward or not z then
        return false, "anchor_not_found"
    end
    if right ~= math.floor(right) or forward ~= math.floor(forward)
        or z ~= math.floor(z)
        or right < -8 or right > 8
        or forward < -8 or forward > 8
        or z < -1 or z > 1
    then
        return false, "anchor_offset_out_of_range"
    end
    for _, other in ipairs(Model.GetGridActors()) do
        if other.id ~= tostring(actorID)
            and other.right == right
            and other.forward == forward
            and other.z == z
        then
            return false, "anchor_tile_occupied_by:" .. tostring(other.id)
        end
    end
    if anchor.right == right and anchor.forward == forward
        and anchor.z == z
    then
        return true
    end
    anchor.right = right
    anchor.forward = forward
    anchor.z = z
    markChanged()
    return true
end

function Model.AddActorContainer()
    local draft = currentDraft()
    if not draft or type(draft.actors) ~= "table" then
        return false, "actors_required"
    end
    draft.anchorFrame = draft.anchorFrame or {}
    draft.anchorFrame.anchors = draft.anchorFrame.anchors or {}
    local actorID = uniqueID("actor", draft.actors)
    local anchorID = uniqueID("anchor_" .. actorID,
        draft.anchorFrame.anchors)
    local occupied = {}
    for _, row in ipairs(Model.GetGridActors()) do
        occupied[tostring(row.right) .. ":" .. tostring(row.forward)
            .. ":" .. tostring(row.z)] = true
    end
    local right
    local forward
    for candidateRight = -8, 8 do
        local key = tostring(candidateRight) .. ":0:0"
        if not occupied[key] then
            right, forward = candidateRight, 0
            break
        end
    end
    if right == nil then
        return false, "no_free_anchor_tile"
    end
    local targetID
    for existingID in pairs(draft.actors) do
        if not targetID or tostring(existingID) < tostring(targetID) then
            targetID = tostring(existingID)
        end
    end
    draft.anchorFrame.anchors[anchorID] = {
        right = right,
        forward = forward,
        z = 0,
        faceTarget = targetID or actorID,
    }
    draft.actors[actorID] = {
        allowedKinds = { "local_player", "nearby_live_npc" },
        dynamic = true,
        required = true,
        anchor = anchorID,
        label = "Actor " .. tostring(actorID),
    }
    -- Adding a slot must not silently author an animation. The scene builder
    -- is intentionally explicit: the user binds a live actor, selects that
    -- actor's route, and assigns a beat track from the matching catalog tab.
    for _, beat in ipairs(draft.beats or {}) do
        local tracks = ensureTracks(beat)
        tracks[actorID] = { byKind = {} }
    end
    -- A first slot has no meaningful facing target yet. Once a second slot is
    -- added, point the first slot at it so the draft becomes a normal
    -- two-person arrangement without requiring hidden defaults.
    if targetID then
        for existingID, existingDefinition in pairs(draft.actors) do
            local existingAnchor = draft.anchorFrame.anchors[
                existingDefinition.anchor
            ]
            if existingID ~= actorID
                and existingAnchor
                and tostring(existingAnchor.faceTarget or "")
                    == tostring(existingID)
            then
                existingAnchor.faceTarget = actorID
            end
        end
    end
    State.selectedActorID = actorID
    State.pendingLiveActorID = nil
    markChanged()
    return true, actorID
end

function Model.AddLiveActorToScene(liveID, right, forward, z, targetActorID)
    local draft = currentDraft()
    local id = tostring(liveID or "")
    if not draft or not draft.actors or id == "" then
        return false, "live_actor_id_missing"
    end
    local liveActor
    for _, candidate in ipairs(Model.GetLiveActorRows(actorDiscoveryRadius())) do
        if tostring(candidate.id) == id then
            liveActor = candidate
            break
        end
    end
    if not liveActor then return false, "nearby_live_actor_not_found" end

    local assignedID = liveActor.assignedActorID
    if assignedID then
        if targetActorID and tostring(targetActorID) ~= tostring(assignedID) then
            return false, "live_actor_already_bound:" .. tostring(assignedID)
        end
        State.selectedActorID = assignedID
        if liveActor.kind == "nearby_live_npc" then
            State.selectedNPCID = id
        end
        if right ~= nil or forward ~= nil or z ~= nil then
            local moved, moveReason = Model.SetActorAnchorOffset(
                liveActor.assignedActorID,
                right,
                forward,
                z
            )
            if not moved then return false, moveReason end
        end
        State.pendingLiveActorID = nil
        touch()
        return true, liveActor.assignedActorID
    end
    local actorID = targetActorID and tostring(targetActorID)
        or State.selectedActorID and tostring(State.selectedActorID) or nil
    local definition = actorID and draft.actors[actorID] or nil
    if not definition then return false, "actor_slot_required" end
    if not kindAllowed(definition, liveActor.kind) then
        return false, "actor_kind_not_allowed:" .. tostring(liveActor.kind)
    end
    local existingBinding = actorBinding(actorID, definition)
    if existingBinding and existingBinding ~= id then
        return false, "actor_slot_already_bound:" .. tostring(actorID)
    end
    local hasExplicitOffset = right ~= nil or forward ~= nil or z ~= nil
    if hasExplicitOffset then
        local moved, moveReason = Model.SetActorAnchorOffset(
            actorID,
            right,
            forward,
            z == nil and 0 or z
        )
        if not moved then return false, moveReason end
    end
    local bound, bindReason = Model.BindLiveActor(actorID, id)
    if not bound then return false, bindReason end
    State.pendingLiveActorID = nil
    return true, actorID
end

function Model.RemoveActor(actorID)
    local draft = currentDraft()
    actorID = tostring(actorID or "")
    if not draft or not draft.actors or not draft.actors[actorID] then
        return false, "actor_not_found"
    end
    local remaining = {}
    for id in pairs(draft.actors) do
        if id ~= actorID then remaining[#remaining + 1] = id end
    end
    if #remaining < 2 then return false, "at_least_two_actors_required" end
    table.sort(remaining)
    local removed = draft.actors[actorID]
    local removedBinding = actorBinding(actorID, removed)
    draft.actors[actorID] = nil
    bindingMap()[actorID] = nil
    if draft.anchorFrame and draft.anchorFrame.anchors then
        local anchorID = removed.anchor
        draft.anchorFrame.anchors[anchorID] = nil
        for _, anchor in pairs(draft.anchorFrame.anchors) do
            if tostring(anchor.faceTarget or "") == actorID then
                anchor.faceTarget = remaining[1]
            end
        end
        -- Removing the player is the normal way to turn a three-actor draft
        -- into a two-NPC scene.  Never leave a surviving anchor facing itself.
        for survivorID, survivor in pairs(draft.actors) do
            local survivorAnchor = draft.anchorFrame.anchors[survivor.anchor]
            if survivorAnchor
                and tostring(survivorAnchor.faceTarget or "") == survivorID
            then
                for _, candidateID in ipairs(remaining) do
                    if candidateID ~= survivorID then
                        survivorAnchor.faceTarget = candidateID
                        break
                    end
                end
            end
        end
    end
    for _, beat in ipairs(draft.beats or {}) do
        local tracks = ensureTracks(beat)
        tracks[actorID] = nil
        if actorID == "player" then beat.player = nil end
        if actorID == "npc" then beat.npc = nil end
    end
    if removedBinding
        and tostring(State.selectedNPCID or "") == tostring(removedBinding)
    then
        State.selectedNPCID = nil
        for survivorID, survivor in pairs(draft.actors) do
            local survivorBinding = actorBinding(survivorID, survivor)
            if survivorBinding then
                local survivorKind = Model.GetActorKind(survivorID)
                if survivorKind == "nearby_live_npc" then
                    State.selectedNPCID = survivorBinding
                    break
                end
            end
        end
    end
    State.selectedActorID = nil
    State.pendingLiveActorID = nil
    markChanged()
    return true
end

function Model.GetBeatRows()
    local draft = currentDraft()
    local rows = {}
    for index, beat in ipairs(draft and draft.beats or {}) do
        rows[#rows + 1] = {
            index = index,
            id = beat.id or ("beat_" .. tostring(index)),
            durationMs = beat.durationMs,
            player = beat.player,
            npc = beat.npc,
            tracks = beat.tracks,
            summary = beatTrackSummary(beat),
            selected = index == State.selectedBeatIndex,
        }
    end
    return rows
end

function Model.SetBeatDuration(duration)
    local beat = Model.GetSelectedBeat()
    duration = tonumber(duration)
    if not beat then return false, "beat_not_found" end
    if not duration or duration ~= math.floor(duration)
        or duration < 100 or duration > 10000
    then
        return false, "duration_must_be_100_to_10000_ms"
    end
    beat.durationMs = duration
    markChanged()
    return true
end

function Model.AddBeat()
    local draft = currentDraft()
    if not draft then return false, "blueprint_not_found" end
    local source = beatAt(State.selectedBeatIndex) or draft.beats[1]
    if not source then return false, "beat_missing" end
    local beat = copy(source)
    local index = #draft.beats + 1
    beat.id = "beat_" .. tostring(index)
    draft.beats[index] = beat
    State.selectedBeatIndex = index
    markChanged()
    return true
end

function Model.DuplicateBeat()
    return Model.AddBeat()
end

function Model.RemoveBeat()
    local draft = currentDraft()
    if not draft or not draft.beats or #draft.beats <= 1 then
        return false, "at_least_one_beat_required"
    end
    table.remove(draft.beats, State.selectedBeatIndex)
    State.selectedBeatIndex = math.min(
        State.selectedBeatIndex,
        #draft.beats
    )
    markChanged()
    return true
end

function Model.MoveBeat(delta)
    local draft = currentDraft()
    local index = tonumber(State.selectedBeatIndex) or 1
    local nextIndex = index + (tonumber(delta) or 0)
    if not draft or not draft.beats or not draft.beats[nextIndex] then
        return false, "beat_move_out_of_range"
    end
    draft.beats[index], draft.beats[nextIndex] = draft.beats[nextIndex],
        draft.beats[index]
    State.selectedBeatIndex = nextIndex
    markChanged()
    return true
end

function Model.GetPlayerSource()
    return State.playerSource
end

function Model.SetPlayerSource(source)
    if source == "zombie" then source = "bridge" end
    if source ~= "player" and source ~= "bridge" then return false end
    State.playerSource = source
    touch()
    return true
end

function Model.GetPlayerQuery()
    return State.playerQuery
end

function Model.SetPlayerQuery(query)
    State.playerQuery = tostring(query or "")
end

function Model.GetNPCQuery()
    return State.npcQuery
end

function Model.SetNPCQuery(query)
    State.npcQuery = tostring(query or "")
end

function Model.GetNPCState()
    return State.npcState
end

function Model.SetNPCState(state)
    State.npcState = state and tostring(state) or nil
    touch()
end

function Model.GetPlayerCatalogEntries()
    local query = lower(State.playerQuery)
    local source = State.playerSource
    local result = {}
    for _, entry in ipairs(PlayerCatalog.entries or {}) do
        local inSource = source == "bridge"
            and entry.source == "zombie"
            and (entry.route == "player_bridge"
                or entry.route == "player_emote_bridge")
            or source == "player" and entry.source ~= "zombie"
        if inSource
            and entry.playable == true
            and (entry.mode == "action" or entry.mode == "emote")
            and (
                (entry.mode == "action" and entry.action
                    and entry.action ~= "")
                or (entry.mode == "emote" and entry.emote
                    and entry.emote ~= "")
            )
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            entry.puppetOperaCapability = Capabilities.DescribeEntry(
                "player",
                entry
            )
            result[#result + 1] = entry
        end
    end
    return result
end

function Model.GetNPCStates()
    local result = {}
    local seen = {}
    for state in pairs(NPCCatalog.stateCounts or {}) do
        result[#result + 1] = state
        seen[state] = true
    end
    table.sort(result)
    if not seen.bumped then table.insert(result, 1, "bumped") end
    return result
end

function Model.GetNPCCatalogEntries()
    local query = lower(State.npcQuery)
    local state = State.npcState
    local result = {}
    for _, entry in ipairs(NPCCatalog.entries or {}) do
        local bump = bumpType(entry)
        if entry.playable == true
            and (not state or state == "all" or entry.state == state)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            entry.puppetOperaBump = bump
            entry.puppetOperaDirect = directNPCEntry(entry)
            entry.puppetOperaCapability = Capabilities.DescribeEntry(
                "npc",
                entry,
                bump
            )
            result[#result + 1] = entry
        end
    end
    return result
end

function Model.PlayerEntryID(entry)
    return entryID("player", entry)
end

function Model.NPCEntryID(entry)
    return entryID("npc", entry)
end

function Model.EntryBumpType(entry)
    return bumpType(entry)
end

function Model.IsPlayerEntryServerApproved(entry)
    if not entry then return false end
    local approved = Capabilities.IsSceneApproved("local_player", {
        mode = entry.mode,
        action = entry.action,
        emote = entry.emote,
    })
    return approved == true
end

function Model.IsNPCEntryServerApproved(entry)
    local bump = bumpType(entry)
    if not entry or not bump or not directNPCEntry(entry) then return false end
    local approved = Capabilities.IsSceneApproved("nearby_live_npc", {
        bump = bump,
        nonCombat = true,
    })
    return approved == true
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

function Model.GetSelectionSummary(actorID)
    local beat = Model.GetSelectedBeat()
    actorID = tostring(actorID or State.selectedActorID or "")
    local actorKind = Model.GetActorKind(actorID)
    local track = trackForBeat(beat, actorID, actorKind)
    if not track then return "No track assigned" end
    local definition = actorDefinition(actorID)
    if definition and actorKind == "local_player" then
        if track.mode == "emote" then
            return tostring(track.emote or "-") .. " / emote"
        end
        return tostring(track.action or "-") .. " / " .. tostring(track.anim or "-")
    end
    if track.byKind then
        local variants = {}
        for kind, variant in pairs(track.byKind) do
            variants[#variants + 1] = tostring(kind) .. ":"
                .. tostring(variant.bump or variant.action or "-")
        end
        table.sort(variants)
        return table.concat(variants, " | ")
    end
    return tostring(track.bump or "-") .. " / " .. tostring(track.anim or "-")
end

function Model.GetChangeSerial()
    return State.changeSerial
end

return Model
