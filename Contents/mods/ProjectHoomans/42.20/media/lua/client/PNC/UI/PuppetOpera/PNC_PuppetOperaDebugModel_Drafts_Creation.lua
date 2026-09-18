-- New and duplicate draft construction for Puppet Opera.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local Blueprints = Internal.Blueprints
local loadPersistentBlueprints = Internal.loadPersistentBlueprints
local copy = Internal.copy
local markChanged = Internal.markChanged
local currentDraft = Internal.currentDraft

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

return Model
