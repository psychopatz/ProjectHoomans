-- Blueprint catalog, selection, and draft-state access for Puppet Opera.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local Blueprints = Internal.Blueprints
local loadPersistentBlueprints = Internal.loadPersistentBlueprints
local touch = Internal.touch
local currentDraft = Internal.currentDraft
local blueprintLabel = Internal.blueprintLabel

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

function Model.ClearActorBindings()
    State.actorBindings[tostring(State.blueprintID or "")] = {}
    State.selectedActorID = nil
    State.selectedNPCID = nil
    State.pendingLiveActorID = nil
    State.animationTargets = {}
    touch()
end

return Model
