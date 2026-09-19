-- Knowledge, needs, director, and world-effect debug request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.RequestKnowledgeDebug(npcID, showTruth, descriptorID)
    if not Client.CanUseDebug() then return false, "not_authorized" end
    npcID = tostring(npcID or "")
    local player = Internal.GetPlayer()
    local args = {
        npcID = npcID,
        showTruth = showTruth ~= false,
        descriptorID = descriptorID,
    }
    ClientState.lastKnowledgeDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_KNOWLEDGE_DEBUG_REQUEST, args)
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.NPCKnowledge
        or not PNC.NPCKnowledge.BuildDebugSnapshotForPlayer
    then
        return false, "knowledge_service_unavailable"
    end
    local snapshot, reason = PNC.NPCKnowledge.BuildDebugSnapshotForPlayer(
        player, npcID, args.showTruth, descriptorID)
    ClientState.knowledgeDebugAuthorized = true
    ClientState.knowledgeDebug, ClientState.knowledgeDebugReason =
        snapshot, reason
    if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.ReceiveSnapshot then
        PNC.KnowledgeDebugUI.ReceiveSnapshot(snapshot)
    end
    return snapshot ~= nil, reason
end

function Client.RequestNeedsDebug(groupID, npcID)
    local player = Internal.GetPlayer()
    if not Client.CanUseDebug() then
        ClientState.needsDebugAuthorized, ClientState.needsDebug = false, nil
        ClientState.needsDebugReason = "not_authorized"
        return false
    end
    ClientState.lastNeedsDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_NEEDS_DEBUG_REQUEST,
                { groupID = groupID, npcID = npcID })
            return true
        end
        return false
    end
    if not PNC.NeedsDebug or not PNC.NeedsDebug.BuildSnapshot then
        return false
    end
    ClientState.needsDebugAuthorized = true
    ClientState.needsDebug = PNC.NeedsDebug.BuildSnapshot(
        groupID, npcID, nil)
    ClientState.needsDebugReason = nil
    ClientState.lastNeedsDebugReceiveAt = Core.Now()
    return true
end

function Client.RequestDirectorDebug(groupID, locationID, populationSectorID)
    local player = Internal.GetPlayer()
    local args = {
        groupID = groupID,
        locationID = locationID,
        populationSectorID = populationSectorID,
    }
    if not Client.CanUseDebug() then
        ClientState.directorDebugAuthorized = false
        ClientState.directorDebug = nil
        ClientState.directorDebugReason = "not_authorized"
        return false
    end
    ClientState.lastDirectorDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_DIRECTOR_DEBUG_REQUEST, args)
            return true
        end
        return false
    end
    if not PNC.AbstractDirectorDebug then return false end
    ClientState.directorDebugAuthorized = true
    ClientState.directorDebug = PNC.AbstractDirectorDebug.BuildSnapshot(
        groupID, locationID, nil, populationSectorID)
    ClientState.directorDebugReason = nil
    ClientState.lastDirectorDebugReceiveAt = Core.Now()
    return true
end

function Client.RequestWorldEffectDebug(state, kind, limit)
    local player = Internal.GetPlayer()
    local args = { state = state, kind = kind, limit = limit }
    if not Client.CanUseDebug() then
        ClientState.worldEffectDebugAuthorized = false
        ClientState.worldEffectDebug = nil
        ClientState.worldEffectDebugReason = "not_authorized"
        return false
    end
    ClientState.lastWorldEffectDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_WORLD_EFFECT_DEBUG_REQUEST, args)
            return true
        end
        return false
    end
    if not PNC.WorldEffectService
        or not PNC.WorldEffectService.BuildSnapshot
    then
        return false
    end
    ClientState.worldEffectDebugAuthorized = true
    ClientState.worldEffectDebug = PNC.WorldEffectService.BuildSnapshot(args)
    ClientState.worldEffectDebugReason = nil
    ClientState.lastWorldEffectDebugReceiveAt = Core.Now()
    return true
end

return Client
