-- Actor-slot lifecycle editing for the Puppet Opera layout model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local markChanged = Internal.markChanged
local actorBinding = Internal.actorBinding
local ensureTracks = Internal.ensureTracks
local uniqueID = Internal.uniqueID

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
    Internal.bindingMap()[actorID] = nil
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

return Model
