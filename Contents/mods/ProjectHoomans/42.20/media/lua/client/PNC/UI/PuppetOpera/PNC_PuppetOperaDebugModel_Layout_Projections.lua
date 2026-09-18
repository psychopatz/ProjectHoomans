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
            bindingID = binding,
            liveID = liveID,
            liveName = live and live.name or nil,
            liveShortID = live and live.shortID or nil,
            target = runtime and runtime.target or nil,
            owned = runtime and (
                runtime.movementOwned == true
                or runtime.animationOwned == true
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
