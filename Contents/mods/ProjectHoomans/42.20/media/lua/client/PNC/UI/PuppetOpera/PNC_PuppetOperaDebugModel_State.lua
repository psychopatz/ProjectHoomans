-- Shared state and bounded data helpers for the Puppet Opera debug model.
--
-- This module owns editor state initialization and the small set of helpers
-- that must be shared by the model's responsibility-specific spokes.  It
-- does not attach UI operations or invoke runtime playback.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

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
            Internal.Blueprints.Register(item.draft.id, item.draft)
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

local function touch()
    State.changeSerial = State.changeSerial + 1
    if Internal.invalidateRefreshCache then
        Internal.invalidateRefreshCache()
    end
end

local function markChanged()
    touch()
    State.editorError = nil
    State.dirtyByID[tostring(State.blueprintID)] = true
end

local function currentDraft()
    loadPersistentBlueprints()
    local id = tostring(State.blueprintID or "social.kiss_player_npc")
    local blueprints = Internal.Blueprints
    if not State.drafts[id] then
        local blueprint = blueprints and blueprints.Get(id) or nil
        if blueprint then
            State.drafts[id] = copy(blueprint)
            State.bases[id] = copy(blueprint)
            State.dirtyByID[id] = false
        end
    elseif not State.bases[id] and blueprints and blueprints.Get(id) then
        State.bases[id] = copy(blueprints.Get(id))
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

Internal.State = State
Internal.loadPersistentBlueprints = loadPersistentBlueprints
Internal.copy = copy
Internal.touch = touch
Internal.markChanged = markChanged
Internal.currentDraft = currentDraft
Internal.translatedLabel = translatedLabel
Internal.blueprintLabel = blueprintLabel

function Model.GetChangeSerial()
    return State.changeSerial
end

return State
