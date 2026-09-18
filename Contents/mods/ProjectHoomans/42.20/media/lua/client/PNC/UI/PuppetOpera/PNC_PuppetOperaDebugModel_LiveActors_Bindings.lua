-- Authoritative editor binding transitions for live Puppet Opera actors.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local markChanged = Internal.markChanged
local actorDefinition = Internal.actorDefinition
local actorBinding = Internal.actorBinding
local bindingMap = Internal.bindingMap
local kindAllowed = Internal.kindAllowed
local actorDiscoveryRadius = Internal.actorDiscoveryRadius

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
        if tostring(row.id) == liveID then
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

return Model
