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
local PlayerCatalog = PNC.PlayerAnimationDebugCatalog or {}
local NPCCatalog = PNC.AnimationDebugCatalog or {}

local State = Model.State or {}
Model.State = State
State.blueprintID = State.blueprintID or "social.kiss_test"
State.drafts = State.drafts or {}
State.bases = State.bases or {}
State.dirtyByID = State.dirtyByID or {}
State.selectedActorID = State.selectedActorID or "player"
State.selectedBeatIndex = tonumber(State.selectedBeatIndex) or 1
State.selectedNPCID = State.selectedNPCID
State.playerSource = State.playerSource or "player"
State.playerQuery = State.playerQuery or ""
State.npcQuery = State.npcQuery or ""
State.npcState = State.npcState or "bumped"
State.editorError = nil
State.changeSerial = tonumber(State.changeSerial) or 0

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
    local id = tostring(State.blueprintID or "social.kiss_test")
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

local function actorOrder(left, right)
    local order = { player = 1, npc = 2 }
    local leftOrder = order[left.id] or 10
    local rightOrder = order[right.id] or 10
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return tostring(left.id) < tostring(right.id)
end

local function beatAt(index)
    local draft = currentDraft()
    return draft and draft.beats and draft.beats[tonumber(index) or 1] or nil
end

local function setPlayerFromEntry(beat, entry)
    beat.player = beat.player or {}
    beat.player.route = "player_action"
    beat.player.catalog = "player"
    beat.player.entryId = entryID("player", entry)
    beat.player.state = entry.state
    beat.player.action = entry.action
    beat.player.anim = entry.anim
    beat.player.animation = entry.anim
    beat.player.event = nil
end

local function setNPCFromEntry(beat, entry)
    local bump = bumpType(entry)
    if not bump then return false, "npc_catalog_entry_has_no_bump_type" end
    if not directNPCEntry(entry) then
        return false, "npc_catalog_entry_requires_selector_context"
    end
    beat.npc = beat.npc or {}
    beat.npc.route = "zombie_bump"
    beat.npc.catalog = "npc"
    beat.npc.entryId = entryID("npc", entry)
    beat.npc.bump = bump
    beat.npc.anim = entry.anim
    beat.npc.animation = entry.anim
    beat.npc.nonCombat = true
    return true
end

function Model.GetBlueprints()
    local result = {}
    local seen = {}
    for _, blueprint in ipairs(Blueprints and Blueprints.List() or {}) do
        local id = tostring(blueprint.id)
        seen[id] = true
        result[#result + 1] = {
            id = id,
            label = blueprint.label or id,
            description = blueprint.description or "",
            dirty = State.dirtyByID[id] == true,
        }
    end
    for id, draft in pairs(State.drafts) do
        if not seen[tostring(id)] and draft then
            result[#result + 1] = {
                id = tostring(id),
                label = draft.label or tostring(id),
                description = draft.description or "",
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
    State.selectedActorID = "player"
    State.selectedBeatIndex = 1
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
    State.drafts[id] = draft
    State.bases[id] = copy(draft)
    State.dirtyByID[id] = true
    State.blueprintID = id
    State.selectedActorID = "player"
    State.selectedBeatIndex = 1
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
    State.selectedActorID = "player"
    State.selectedBeatIndex = 1
    State.dirtyByID[id] = false
    touch()
    return true
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
        and Client.GetNearbyNPCs(radius) or {}
end

function Model.SetSelectedNPC(id)
    State.selectedNPCID = id and tostring(id) or nil
    touch()
end

function Model.GetSelectedNPC()
    local id = State.selectedNPCID
    if not id then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(8)) do
        if tostring(npc.id) == tostring(id) then return npc end
    end
    return nil
end

function Model.GetSelectedNPCID()
    return State.selectedNPCID
end

function Model.SelectActor(id)
    State.selectedActorID = tostring(id or "player")
    touch()
end

function Model.GetSelectedActorID()
    return State.selectedActorID
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

function Model.GetActorRows(snapshot)
    local draft = currentDraft()
    local rows = {}
    for id, definition in pairs(draft and draft.actors or {}) do
        local runtime = snapshot and snapshot.actors
            and snapshot.actors[id] or nil
        rows[#rows + 1] = {
            id = id,
            label = definition.label or id,
            kind = definition.kind or "future_actor",
            anchor = definition.anchor or "-",
            state = runtime and runtime.state or "draft slot ready",
            target = runtime and runtime.target or nil,
            owned = runtime and (
                runtime.movementOwned == true
                or runtime.animationOwned == true
            ) or false,
            supported = definition.kind == "local_player"
                or definition.kind == "nearby_live_npc",
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
                label = definition.label or id,
                kind = definition.kind,
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
    anchor.right = right
    anchor.forward = forward
    anchor.z = z
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
    if source ~= "player" and source ~= "zombie" then return false end
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
        local inSource = source == "zombie"
            and entry.source == "zombie"
            or source == "player" and entry.source ~= "zombie"
        if inSource
            and entry.playable == true
            and (entry.mode == "action" or entry.mode == "emote")
            and entry.action
            and entry.action ~= ""
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
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
        if bump
            and entry.playable == true
            and (not state or state == "all" or entry.state == state)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            entry.puppetOperaBump = bump
            entry.puppetOperaDirect = directNPCEntry(entry)
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
    return Blueprints and Blueprints.IsRuntimePlayerAction
        and Blueprints.IsRuntimePlayerAction(entry and entry.action)
        or false
end

function Model.IsNPCEntryServerApproved(entry)
    return Blueprints and Blueprints.IsRuntimeNPCBump
        and Blueprints.IsRuntimeNPCBump(bumpType(entry))
        or false
end

function Model.AssignAnimation(actorID, entry)
    local beat = Model.GetSelectedBeat()
    if not beat or type(entry) ~= "table" then
        return false, "animation_assignment_missing"
    end
    actorID = tostring(actorID or State.selectedActorID or "")
    local accepted
    local reason
    if actorID == "player" then
        if not entry.action or entry.action == "" then
            return false, "player_catalog_entry_has_no_action"
        end
        setPlayerFromEntry(beat, entry)
        accepted = true
    elseif actorID == "npc" then
        accepted, reason = setNPCFromEntry(beat, entry)
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
    local track = beat and beat[actorID] or nil
    if not track then return "No track assigned" end
    if actorID == "player" then
        return tostring(track.action or "-") .. " / " .. tostring(track.anim or "-")
    end
    return tostring(track.bump or "-") .. " / " .. tostring(track.anim or "-")
end

function Model.GetChangeSerial()
    return State.changeSerial
end

return Model
