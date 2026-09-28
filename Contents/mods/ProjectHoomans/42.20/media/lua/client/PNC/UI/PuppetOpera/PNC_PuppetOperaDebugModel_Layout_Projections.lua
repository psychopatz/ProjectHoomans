-- Scene actor and grid projections for the Puppet Opera layout model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local State = Internal.State or Model.State
local currentDraft = Internal.currentDraft
local actorLabel = Internal.actorLabel
local actorOrder = Internal.actorOrder
local actorBinding = Internal.actorBinding
local allowedActorKinds = Internal.allowedActorKinds
local findLiveActorRow = Internal.findLiveActorRow
local actorDiscoveryRadius = Internal.actorDiscoveryRadius
local Anchors = Internal.Anchors

local function snapshotIsActive(snapshot)
    local phase = snapshot and tostring(snapshot.phase or "") or ""
    return snapshot ~= nil
        and phase ~= "completed"
        and phase ~= "restored"
        and phase ~= "aborted"
end

local function runtimeFlowStage(bindingID, state, phase)
    if not bindingID then return "Unassigned" end
    state = tostring(state or "")
    phase = tostring(phase or "")
    if phase == "completed" or phase == "restored"
        or phase == "aborted"
    then
        return "Done / " .. phase
    end
    if phase == "stopping" then return "Stopping" end
    if state == "moving" or state == "arrived" or state == "facing"
        or state == "preview_ready" or state == "pending"
    then
        return "Position / " .. (state == "preview_ready" and "ready"
            or state)
    end
    if state == "animation_queued" or state == "animation_ready"
        or state == "animating" or state == "animation_delay"
        or state == "animation_finished"
    then
        local suffix = state
        if state == "animation_queued" then suffix = "queued" end
        if state == "animation_ready" then suffix = "ready" end
        if state == "animating" then suffix = "playing" end
        if state == "animation_delay" then suffix = "delay" end
        if state == "animation_finished" then suffix = "finished" end
        return "Animation / " .. suffix
    end
    return "Idle / " .. (state ~= "" and state or "bound")
end

function Model.GetActorRows(snapshot)
    local refreshCache = Internal.getRefreshCache
        and Internal.getRefreshCache() or nil
    if refreshCache
        and refreshCache.actorRowsSet
        and refreshCache.actorRowsSnapshot == snapshot
    then
        return refreshCache.actorRows
    end
    local draft = currentDraft()
    local rows = {}
    local liveRows = Model.GetLiveActorRows(actorDiscoveryRadius())
    for id, definition in pairs(draft and draft.actors or {}) do
        local runtime = snapshot and snapshot.actors
            and snapshot.actors[id] or nil
        local binding = actorBinding(id, definition)
        local liveID = binding
        local live = findLiveActorRow(liveID, liveRows)
        local resolvedKind = Model.GetActorKind(id)
        rows[#rows + 1] = {
            id = id,
            label = actorLabel(definition, id),
            kind = resolvedKind or "unbound",
            allowedKinds = allowedActorKinds(definition),
            anchor = definition.anchor or "-",
            state = runtime and runtime.state
                or (binding and "bound" or "unbound"),
            flow = runtimeFlowStage(
                binding,
                runtime and runtime.state or (binding and "bound" or "unbound"),
                snapshot and snapshot.phase
            ),
            bindingID = binding,
            liveID = liveID,
            liveName = live and live.name or nil,
            liveShortID = live and live.shortID or nil,
            target = runtime and runtime.target or nil,
            arrived = runtime and runtime.arrived == true or false,
            facing = runtime and runtime.facing == true or false,
            lastReason = runtime and runtime.lastReason or nil,
            timelineNodeID = runtime and runtime.timelineNodeID or nil,
            timelineNodeType = runtime and runtime.timelineNodeType or nil,
            timelineElapsedMs = runtime and runtime.timelineElapsedMs or nil,
            movementOwned = runtime and runtime.movementOwned == true
                or false,
            animationOwned = runtime and runtime.animationOwned == true
                or false,
            overrideOwned = runtime and runtime.overrideOwned == true
                or false,
            overrideOwnerKind = runtime and runtime.overrideOwnerKind or nil,
            controlled = runtime ~= nil and snapshotIsActive(snapshot) or false,
            owned = runtime and (
                runtime.movementOwned == true
                or runtime.animationOwned == true
                or runtime.overrideOwned == true
            ) or false,
            supported = resolvedKind == "local_player"
                or resolvedKind == "nearby_live_npc",
        }
    end
    table.sort(rows, actorOrder)
    if refreshCache then
        refreshCache.actorRowsSet = true
        refreshCache.actorRowsSnapshot = snapshot
        refreshCache.actorRows = rows
    end
    return rows
end

function Model.GetGridActors()
    local refreshCache = Internal.getRefreshCache
        and Internal.getRefreshCache() or nil
    if refreshCache and refreshCache.gridRows then
        return refreshCache.gridRows
    end
    local draft = currentDraft()
    local anchors = draft and draft.anchorFrame
        and draft.anchorFrame.anchors or {}
    local rows = {}
    for id, definition in pairs(draft and draft.actors or {}) do
        local anchor = anchors[definition.anchor]
        if anchor then
            rows[#rows + 1] = {
                id = id,
                label = actorLabel(definition, id),
                kind = Model.GetActorKind(id) or "unbound",
                allowedKinds = allowedActorKinds(definition),
                bindingID = actorBinding(id, definition),
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
    if refreshCache then refreshCache.gridRows = rows end
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

return Model
