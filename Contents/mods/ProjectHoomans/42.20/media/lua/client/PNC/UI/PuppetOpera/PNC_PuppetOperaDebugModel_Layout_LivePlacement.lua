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

local function actorIDOrder(left, right)
    local leftNumber = tonumber(string.match(tostring(left), "^actor_(%d+)$"))
    local rightNumber = tonumber(string.match(tostring(right), "^actor_(%d+)$"))
    if leftNumber and rightNumber and leftNumber ~= rightNumber then
        return leftNumber < rightNumber
    end
    return tostring(left) < tostring(right)
end

-- A free live row is a drag source, not an implicit selection.  When the
-- user drops it on an empty graph tile, resolve the first compatible empty
-- slot and create one when the new draft has none.  This keeps explicit slot
-- selection authoritative while making Create New usable from the graph.
local function findDropSlot(draft, liveKind)
    local ids = {}
    for actorID in pairs(draft.actors or {}) do
        ids[#ids + 1] = tostring(actorID)
    end
    table.sort(ids, actorIDOrder)
    for _, actorID in ipairs(ids) do
        local definition = draft.actors[actorID]
        if definition
            and not actorBinding(actorID, definition)
            and kindAllowed(definition, liveKind)
        then
            return actorID
        end
    end
    return nil
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

    local actorID = targetActorID and tostring(targetActorID) or nil
    if not actorID and State.selectedActorID then
        local selectedID = tostring(State.selectedActorID)
        local selectedDefinition = draft.actors[selectedID]
        if selectedDefinition
            and not actorBinding(selectedID, selectedDefinition)
            and kindAllowed(selectedDefinition, liveActor.kind)
        then
            actorID = selectedID
        end
    end
    if not actorID then
        actorID = findDropSlot(draft, liveActor.kind)
        if not actorID and Model.AddActorContainer then
            local created, createReason = Model.AddActorContainer()
            if not created then
                return false, createReason or "actor_slot_required"
            end
            actorID = tostring(createReason)
            draft = currentDraft()
        end
    end
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
