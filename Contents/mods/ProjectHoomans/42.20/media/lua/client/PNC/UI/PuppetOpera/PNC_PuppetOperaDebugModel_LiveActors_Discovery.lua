-- Nearby live-actor discovery and read-only row materialization.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local Client = Internal.Client
local currentDraft = Internal.currentDraft
local translatedLabel = Internal.translatedLabel
local actorBinding = Internal.actorBinding
local actorDiscoveryRadius = Internal.actorDiscoveryRadius
local compactLiveID = Internal.compactLiveID
local LIVE_PLAYER_ID = Internal.LIVE_PLAYER_ID

function Model.GetNearbyNPCs(radius)
    return Client and Client.GetNearbyNPCs
        and Client.GetNearbyNPCs(radius or actorDiscoveryRadius()) or {}
end

function Model.GetActorDiscoveryRadius()
    return actorDiscoveryRadius()
end

function Model.GetSelectedNPC()
    local id = Model.State.selectedNPCID
    if not id then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == tostring(id) then return npc end
    end
    return nil
end

function Model.GetUnassignedNearbyNPCs(radius)
    local assigned = {}
    for _, bound in pairs(Internal.bindingMap()) do
        assigned[tostring(bound)] = true
    end
    local result = {}
    for _, npc in ipairs(Model.GetNearbyNPCs(radius or actorDiscoveryRadius())) do
        if not assigned[tostring(npc.id)] then result[#result + 1] = npc end
    end
    return result
end

function Model.GetLiveActorRows(radius)
    local radiusValue = tonumber(radius) or actorDiscoveryRadius()
    local refreshCache = Internal.getRefreshCache
        and Internal.getRefreshCache() or nil
    if refreshCache
        and refreshCache.liveRows
        and refreshCache.liveRowsRadius == radiusValue
    then
        return refreshCache.liveRows
    end

    local assignments = {}
    local playerAssignment
    local draft = currentDraft()
    for actorID, definition in pairs(draft and draft.actors or {}) do
        local bound = actorBinding(actorID, definition)
        if bound then
            assignments[tostring(bound)] = actorID
            if tostring(bound) == LIVE_PLAYER_ID then
                playerAssignment = actorID
            end
        end
    end

    local result = {}
    local playerBody = Client and Client.GetLocalPlayer
        and Client.GetLocalPlayer() or nil
    if playerBody and playerBody.getX and playerBody.getY then
        local playerName = playerBody.getUsername
            and playerBody:getUsername() or translatedLabel(
                "UI_PNC_PuppetOpera_LocalPlayer", "Local player")
        if not playerName or tostring(playerName) == "" then
            playerName = translatedLabel(
                "UI_PNC_PuppetOpera_LocalPlayer", "Local player")
        end
        local playerRow = {
            id = LIVE_PLAYER_ID,
            name = playerName,
            kind = "local_player",
            shortID = nil,
            distSq = 0,
            assignedActorID = playerAssignment,
            body = playerBody,
            record = nil,
            snapshot = nil,
        }
        local playerReadiness = Model.GetLiveActorReadiness(LIVE_PLAYER_ID)
        if playerReadiness then
            playerRow.ready = playerReadiness.ready
            playerRow.reason = playerReadiness.reasonDetail
                or playerReadiness.reason
            playerRow.actionState = playerReadiness.actionState
            playerRow.actionContextState = playerReadiness.actionContextState
            playerRow.owner = playerReadiness.owner
        end
        result[#result + 1] = playerRow
    end

    for _, npc in ipairs(Model.GetNearbyNPCs(radiusValue)) do
        local id = tostring(npc.id)
        local row = {
            id = id,
            name = npc.name or id,
            kind = "nearby_live_npc",
            shortID = compactLiveID(id),
            distSq = npc.distSq,
            assignedActorID = assignments[id],
            body = npc.zombie,
            record = npc.record,
            snapshot = npc.snapshot,
        }
        local readiness = Model.GetLiveActorReadiness(id)
        if readiness then
            row.ready = readiness.ready
            row.reason = readiness.reasonDetail or readiness.reason
            row.actionState = readiness.actionState
            row.actionContextState = readiness.actionContextState
            row.owner = readiness.owner
            row.distance = readiness.distance
        end
        result[#result + 1] = row
    end

    if refreshCache then
        refreshCache.liveRowsRadius = radiusValue
        refreshCache.liveRows = result
    end
    return result
end

function Model.GetNPCForActor(actorID)
    local id = Model.GetActorBinding(actorID)
    if not id then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == tostring(id) then return npc end
    end
    return nil
end

function Model.GetNPCForLiveID(liveID)
    liveID = liveID and tostring(liveID) or nil
    if not liveID then return nil end
    for _, npc in ipairs(Model.GetNearbyNPCs(actorDiscoveryRadius())) do
        if tostring(npc.id) == liveID then return npc end
    end
    return nil
end

return Model
