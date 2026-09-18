-- Save and rollback operations for Puppet Opera drafts.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local Blueprints = Internal.Blueprints
local copy = Internal.copy
local touch = Internal.touch
local currentDraft = Internal.currentDraft

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

return Model
