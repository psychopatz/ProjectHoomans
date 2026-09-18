-- Editor selection and animation-target resolution for live Puppet Opera actors.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local touch = Internal.touch
local actorDefinition = Internal.actorDefinition
local actorBinding = Internal.actorBinding
local actorDiscoveryRadius = Internal.actorDiscoveryRadius
local findLiveActorRow = Internal.findLiveActorRow

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

function Model.GetSelectedNPCID()
    return State.selectedNPCID
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

return Model
