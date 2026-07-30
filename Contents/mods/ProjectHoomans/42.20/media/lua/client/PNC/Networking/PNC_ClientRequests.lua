--[[
    PNC Client Requests
    Owns full-sync, debug-roster, and character-detail requests.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local isWorldReady = Internal.IsWorldReady

local function requestFullSync()
    local player = getSpecificPlayer(0)
    if not isWorldReady() then
        return
    end
    ClientState.lastFullSyncRequestAt = Core.Now()
    if player and sendClientCommand then
        sendClientCommand(player, Const.MODULE, Const.CMD_FULL_SYNC_REQUEST, {})
        return
    end
    if PNC.Registry and PNC.Network and PNC.Network.BuildSnapshot then
        ClientState.snapshots = {}
        PNC.Registry.ForEach(function(record)
            local snapshot = PNC.Network.BuildSnapshot(record)
            ClientState.snapshots[snapshot.id] = snapshot
        end)
        ClientState.lastSyncReceiveAt = Core.Now()
    end
end

Client.RequestFullSync = requestFullSync

function Client.CanUseDebug()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local access
    access = player and player.getAccessLevel and tostring(player:getAccessLevel() or "") or ""
    if string.lower(access) == "admin" then
        return true
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        return false
    end
    if isDebugEnabled then
        return isDebugEnabled() == true
    end
    return getCore and getCore() and getCore():getDebug() == true or false
end

function Client.RequestDebugRoster(forceAudit)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local diagnostics = {}
    if not Client.CanUseDebug() then
        ClientState.debugAuthorized = false
        ClientState.debugRoster = {}
        return false
    end
    ClientState.lastDebugRosterRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG_ROSTER_REQUEST, { audit = forceAudit == true })
            return true
        end
        return false
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        -- The monitor is also available in single-player, where there may be
        -- no remote server request to drive corpse cleanup. The audit owns its
        -- own throttling, so ordinary refreshes safely keep markers current.
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), forceAudit == true)
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.BuildDebugRoster then
        diagnostics = PNC.BodyLifecycle.BuildDebugRoster()
    end
    ClientState.debugRoster = diagnostics
    ClientState.debugAuthorized = true
    ClientState.debugAudit = PNC.BodyLifecycle and PNC.BodyLifecycle.LastAudit or {}
    return true
end

function Client.RequestRelationshipDebug(
    observerNPCID,
    targetKind,
    targetNPCID
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local args = {
        observerNPCID = observerNPCID,
        targetKind = targetKind,
        targetNPCID = targetNPCID,
    }
    local snapshot
    local reason
    if not Client.CanUseDebug() then
        ClientState.relationshipDebugAuthorized = false
        ClientState.relationshipDebug = nil
        ClientState.relationshipDebugReason = "not_authorized"
        return false
    end
    ClientState.lastRelationshipDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_RELATIONSHIP_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.RelationshipDebug
        or not PNC.RelationshipDebug.BuildSnapshotForRequest
    then
        return false
    end
    snapshot, reason =
        PNC.RelationshipDebug.BuildSnapshotForRequest(
            player,
            args
        )
    ClientState.relationshipDebugAuthorized = true
    ClientState.relationshipDebug = snapshot
    ClientState.relationshipDebugReason = reason
    ClientState.lastRelationshipDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestFactionDebug(factionID, npcID)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local args = {
        factionID = factionID,
        npcID = npcID,
    }
    local snapshot
    if not Client.CanUseDebug() then
        ClientState.factionDebugAuthorized = false
        ClientState.factionDebug = nil
        ClientState.factionDebugReason = "not_authorized"
        return false
    end
    ClientState.lastFactionDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_FACTION_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.FactionDebug
        or not PNC.FactionDebug.BuildSnapshot
    then
        return false
    end
    snapshot = PNC.FactionDebug.BuildSnapshot(
        factionID,
        npcID
    )
    ClientState.factionDebugAuthorized = true
    ClientState.factionDebug = snapshot
    ClientState.factionDebugReason = nil
    ClientState.lastFactionDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestCharacterPayload(npcId)
    local player = getSpecificPlayer(0)
    local payload
    local cached
    local inventoryRevision
    if not npcId then
        return false
    end
    if not sendClientCommand and PNC.API and PNC.API.GetCharacterPayload then
        payload = PNC.API.GetCharacterPayload(npcId)
        if payload then
            ClientState.characterPayloads = ClientState.characterPayloads or {}
            ClientState.characterPayloads[npcId] = payload
            if payload.snapshot and payload.snapshot.id then
                ClientState.snapshots[payload.snapshot.id] = payload.snapshot
            end
            return true
        end
        return false
    end
    if not player or not sendClientCommand then
        return false
    end
    cached = ClientState.characterPayloads and ClientState.characterPayloads[npcId] or nil
    inventoryRevision = cached and cached.inventory and cached.inventory.summary
        and tonumber(cached.inventory.summary.revision) or nil
    sendClientCommand(player, Const.MODULE, Const.CMD_REQUEST_CHARACTER, {
        id = npcId,
        inventoryRevision = inventoryRevision,
    })
    return true
end
