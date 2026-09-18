-- Live-actor placement into scene slots for the Puppet Opera layout model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local markChanged = Internal.markChanged
local touch = Internal.touch
local actorBinding = Internal.actorBinding
local kindAllowed = Internal.kindAllowed
local actorDiscoveryRadius = Internal.actorDiscoveryRadius
local validateAnchorOffset = Internal.validateAnchorOffset
local commitAnchorOffset = Internal.commitAnchorOffset

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
    local validatedAnchor
    local normalizedRight = right
    local normalizedForward = forward
    local normalizedZ = z == nil and 0 or z
    if hasExplicitOffset then
        local valid, anchorOrReason, validatedRight, validatedForward,
            validatedZ = validateAnchorOffset(
            actorID,
            normalizedRight,
            normalizedForward,
            normalizedZ
        )
        if not valid then return false, anchorOrReason end
        validatedAnchor = anchorOrReason
        normalizedRight = validatedRight
        normalizedForward = validatedForward
        normalizedZ = validatedZ
    end
    local bound, bindReason = Model.BindLiveActor(actorID, id)
    if not bound then return false, bindReason end
    -- Keep the layout commit after binding. A late or rejected bind therefore
    -- cannot leave an explicit anchor offset applied to an unbound slot.
    if hasExplicitOffset then
        commitAnchorOffset(
            validatedAnchor,
            normalizedRight,
            normalizedForward,
            normalizedZ
        )
    end
    State.pendingLiveActorID = nil
    return true, actorID
end

return Model
