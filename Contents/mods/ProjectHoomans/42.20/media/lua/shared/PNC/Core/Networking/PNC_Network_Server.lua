--[[
    PNC Networking - Server Replication
    Owns transport fan-out, interest sets, roster deltas, and detail payloads.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local Inventory = PNC.Inventory
local MotionHints = PNC.MotionHints
local ServerState = Network.ServerState

local function playerKey(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return tostring(player)
end

local function sendToPlayer(player, command, payload)
    if isServer and isServer() and player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, command, payload)
        return true
    end
    if not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
        return true
    end
    return false
end

local function sendToInterestedNPC(npcId, command, payload)
    local state
    local count = 0
    npcId = npcId and tostring(npcId) or nil
    if not npcId then
        return 0
    end
    for _, state in pairs(ServerState.interests) do
        if state.player and state.ids and state.ids[npcId] then
            sendToPlayer(state.player, command, payload)
            count = count + 1
        end
    end
    return count
end

Internal.PlayerKey = playerKey
Internal.SendToPlayer = sendToPlayer
Internal.SendToInterestedNPC = sendToInterestedNPC

function Network.QueueRosterDelta(record, removed, reason, includeTravelRoute)
    local id = type(record) == "table" and record.id or record
    local snapshot
    if id == nil then
        return false
    end
    if removed ~= true and type(record) ~= "table" then
        return false
    end
    id = tostring(id)
    -- Lua's `condition and nil or value` idiom can never produce nil: the `or`
    -- branch runs because nil is falsey. Build removal entries explicitly so an
    -- NPC id string is never passed to BuildRosterSnapshot as though it were a
    -- record table.
    if removed ~= true then
        snapshot = Network.BuildRosterSnapshot(
            record,
            includeTravelRoute ~= false
        )
    end
    return Network.QueueRosterSnapshot(id, snapshot, removed, reason)
end

function Network.QueueRosterSnapshot(id, snapshot, removed, reason)
    if id == nil then return false end
    if removed ~= true and type(snapshot) ~= "table" then return false end
    id = tostring(id)
    ServerState.rosterRevision = (tonumber(ServerState.rosterRevision) or 0) + 1
    ServerState.rosterDeltas[id] = {
        id = id,
        removed = removed == true,
        reason = reason,
        revision = ServerState.rosterRevision,
        snapshot = snapshot,
    }
    return true
end

function Network.QueuePeriodicRoster(record, now)
    local runtime
    local signature
    if not record or not record.id then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    now = tonumber(now) or Core.Now()
    signature = table.concat({
        tostring(math.floor(tonumber(record.x) or 0)),
        tostring(math.floor(tonumber(record.y) or 0)),
        tostring(math.floor(tonumber(record.z) or 0)),
        tostring(record.presenceState or ""),
        tostring(record.health and record.health.state or ""),
        tostring(record.orderSpec and record.orderSpec.kind or ""),
        tostring(record.travel and record.travel.state or ""),
        tostring(record.travel and record.travel.revision or 0),
    }, ":")
    if runtime.rosterSignature == signature then
        return false
    end
    if now - (tonumber(runtime.lastRosterQueuedAt) or 0) < Const.ROSTER_DELTA_INTERVAL_MS then
        return false
    end
    runtime.rosterSignature = signature
    runtime.lastRosterQueuedAt = now
    Network.QueueRosterDelta(record, false, "periodic", false)
    return true
end

function Network.RefreshInterestSets(now)
    local Spatial = PNC.SpatialIndex
    local seenPlayers = {}
    now = tonumber(now) or Core.Now()
    if not isServer or not isServer() or now - (tonumber(ServerState.lastInterestRefreshAt) or 0) < Const.INTEREST_REFRESH_MS then
        return
    end
    ServerState.lastInterestRefreshAt = now
    Core.ForEachPlayer(function(player)
        local key = playerKey(player)
        local state = ServerState.interests[key] or { ids = {} }
        local candidates = Spatial and Spatial.QueryNPCs and Spatial.QueryNPCs(
            player:getX(), player:getY(), Const.INTEREST_LEAVE_DISTANCE
        ) or {}
        local nextIDs = {}
        local i
        local record
        local distance
        state.player = player
        seenPlayers[key] = true
        for i = 1, #candidates do
            record = candidates[i]
            if record and record.id and record.alive ~= false then
                distance = Core.Distance(player:getX(), player:getY(), record.x, record.y)
                if (state.ids[record.id] and distance <= Const.INTEREST_LEAVE_DISTANCE)
                    or distance <= Const.INTEREST_ENTER_DISTANCE
                then
                    nextIDs[record.id] = true
                    if not state.ids[record.id] then
                        sendToPlayer(player, Const.CMD_SYNC_RECORD, {
                            event = "interest_enter",
                            snapshot = Network.BuildSnapshot(record),
                        })
                    end
                end
            end
        end
        for id, _ in pairs(state.ids) do
            if not nextIDs[id] then
                record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
                if record then
                    sendToPlayer(player, Const.CMD_SYNC_RECORD, {
                        event = "interest_exit",
                        snapshot = Network.BuildRosterSnapshot(record),
                    })
                end
            end
        end
        state.ids = nextIDs
        ServerState.interests[key] = state
    end)
    for key, _ in pairs(ServerState.interests) do
        if not seenPlayers[key] then
            ServerState.interests[key] = nil
        end
    end
end

function Network.FlushRosterDeltas(now, force)
    local entries = {}
    local id
    now = tonumber(now) or Core.Now()
    if not force and now - (tonumber(ServerState.lastRosterFlushAt) or 0) < Const.ROSTER_DELTA_INTERVAL_MS then
        return 0
    end
    for id, _ in pairs(ServerState.rosterDeltas) do
        entries[#entries + 1] = ServerState.rosterDeltas[id]
    end
    if #entries <= 0 then
        ServerState.lastRosterFlushAt = now
        return 0
    end
    Core.ForEachPlayer(function(player)
        sendToPlayer(player, Const.CMD_ROSTER_DELTA, {
            directoryRevision = ServerState.rosterRevision,
            entries = entries,
        })
    end)
    ServerState.rosterDeltas = {}
    ServerState.lastRosterFlushAt = now
    return #entries
end

function Internal.QueueBroadcastRoster(record, eventName)
    if eventName ~= "tick" and eventName ~= "materialize" and eventName ~= "interest_enter" then
        return Network.QueueRosterDelta(record, false, eventName)
    end
    return false
end

function Internal.CollectRecordRecipients(record)
    local recipients = {}
    local state
    if isServer and isServer() then
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[record.id] then
                recipients[#recipients + 1] = state.player
            end
        end
    end
    return recipients
end

function Internal.BuildRecordPayload(record, eventName)
    return {
        event = eventName or "update",
        snapshot = eventName == "tick" and Network.BuildPresenceDelta(record)
            or Network.BuildSnapshot(record),
    }
end

function Internal.SendRecordPayload(recipients, payload)
    if isServer and isServer() then
        local i
        for i = 1, #recipients do
            sendToPlayer(recipients[i], Const.CMD_SYNC_RECORD, payload)
        end
        return #recipients
    end
    triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
    return 1
end

function Network.BroadcastRecord(record, eventName)
    local payload
    local path
    local recipients
    if not Core.IsAuthority() then
        return
    end
    -- Single-player shares the authoritative registry and live body with its
    -- UI; rebuilding and loopback-dispatching a presence payload every sync
    -- interval has no consumer-side value. Keep explicit mutation events for
    -- existing UI hooks, but remove the high-frequency tick payload and its
    -- observed 11-15 ms BuildPayload spikes.
    if eventName == "tick"
        and (not isServer or isServer() ~= true)
    then
        return
    end
    Internal.QueueBroadcastRoster(record, eventName)
    recipients = Internal.CollectRecordRecipients(record)
    if isServer and isServer() and #recipients <= 0 then return end
    payload = Internal.BuildRecordPayload(record, eventName)
    path = record and record.runtime and record.runtime.pathing or nil
    if path and MotionHints and MotionHints.MarkBroadcast then
        MotionHints.MarkBroadcast(record, path, Core.Now())
    end
    Internal.SendRecordPayload(recipients, payload)
end

function Network.BroadcastRemoval(id, reason)
    local payload = { id = id, reason = reason }
    local marker
    local record
    local snapshot
    if not Core.IsAuthority() then
        return
    end
    if tostring(reason or "") == "death" then
        marker = PNC.Registry and PNC.Registry.GetDeathMarker
            and PNC.Registry.GetDeathMarker(id) or nil
        record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
        snapshot = marker and Network.BuildDeathMarkerSnapshot
            and Network.BuildDeathMarkerSnapshot(marker)
            or record and Network.BuildSnapshot(record)
            or nil
        if snapshot then
            Network.QueueRosterSnapshot(id, snapshot, false, reason)
            payload = { event = "death", snapshot = snapshot }
            if isServer and isServer() then
                local state
                for _, state in pairs(ServerState.interests) do
                    if state.player and state.ids and state.ids[id] then
                        sendToPlayer(state.player, Const.CMD_SYNC_RECORD, payload)
                        state.ids[id] = nil
                    end
                end
            else
                triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
            end
            return
        end
    end
    Network.QueueRosterDelta(id, true, reason)
    if isServer and isServer() then
        local state
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[id] then
                sendToPlayer(state.player, Const.CMD_REMOVE_RECORD, payload)
                state.ids[id] = nil
            end
        end
    else
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_REMOVE_RECORD, payload)
    end
end

function Network.BroadcastDeathMarkerRemoval(id, reason)
    local payload
    if not Core.IsAuthority() or id == nil then
        return false
    end
    id = tostring(id)
    payload = {
        id = id,
        reason = tostring(reason or "corpse_removed"),
    }
    Network.QueueRosterDelta(id, true, payload.reason)
    if isServer and isServer() then
        Core.ForEachPlayer(function(player)
            sendToPlayer(player, Const.CMD_REMOVE_RECORD, payload)
        end)
        for _, state in pairs(ServerState.interests) do
            if state.ids then
                state.ids[id] = nil
            end
        end
    else
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_REMOVE_RECORD,
            payload
        )
    end
    return true
end

function Network.BroadcastBodyRemoval(id, bodyInstanceID, bodyOnlineID, reason)
    local payload
    if not Core.IsAuthority() then
        return false
    end
    payload = {
        id = id and tostring(id) or nil,
        bodyInstanceID = bodyInstanceID ~= nil and tostring(bodyInstanceID) or nil,
        bodyOnlineID = tonumber(bodyOnlineID),
        reason = tostring(reason or "stale_body"),
    }
    if isServer and isServer() then
        -- A stale engine zombie can be present on a client before that client
        -- has entered the NPC interest set. Send instance removals to every
        -- connected player instead of relying on roster interest membership.
        Core.ForEachPlayer(function(player)
            sendToPlayer(player, Const.CMD_REMOVE_BODY, payload)
        end)
    else
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_REMOVE_BODY, payload)
    end
    return true
end

function Network.BroadcastFullSync(targetPlayer, records)
    local chunkSize = math.max(1, tonumber(Const.ROSTER_CHUNK_SIZE) or 50)
    local total = #(records or {})
    local chunkCount = math.ceil(total / chunkSize)
    local chunkIndex
    local startIndex
    local finishIndex
    local chunk
    local i
    sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_BEGIN, {
        directoryRevision = ServerState.rosterRevision,
        total = total,
        chunkCount = chunkCount,
    })
    for chunkIndex = 1, chunkCount do
        chunk = {}
        startIndex = ((chunkIndex - 1) * chunkSize) + 1
        finishIndex = math.min(total, startIndex + chunkSize - 1)
        for i = startIndex, finishIndex do
            chunk[#chunk + 1] = records[i]
        end
        sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_CHUNK, {
            directoryRevision = ServerState.rosterRevision,
            chunkIndex = chunkIndex,
            snapshots = chunk,
        })
    end
    sendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_END, {
        directoryRevision = ServerState.rosterRevision,
        total = total,
    })
    if isServer and isServer() and targetPlayer then
        local state = ServerState.interests[playerKey(targetPlayer)]
        if state then
            state.ids = {}
        end
        ServerState.lastInterestRefreshAt = 0
    end
end

function Network.SendCharacterPayload(targetPlayer, record)
    local payload
    if not record then
        return
    end
    payload = Network.BuildCharacterPayload(record)
    if not payload then
        return
    end
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
    end
end

function Network.CanViewCharacter(player, record)
    local access
    local distance
    if not player or not record then
        return false
    end
    access = player.getAccessLevel and string.lower(tostring(player:getAccessLevel() or "")) or ""
    if access == "admin" then
        return true
    end
    if record.ownerUsername and player.getUsername and tostring(record.ownerUsername) == tostring(player:getUsername()) then
        return true
    end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(tonumber(record.z) or 0) then
        return false
    end
    distance = Core.Distance(player:getX(), player:getY(), record.x, record.y)
    return distance <= Const.CHARACTER_DETAIL_DISTANCE
end

function Network.SendInventoryDelta(targetPlayer, record, sinceRevision)
    local delta = Inventory and Inventory.BuildDeltaPayload and Inventory.BuildDeltaPayload(record, sinceRevision) or nil
    if not delta or delta.fullRequired == true then
        Network.SendCharacterPayload(targetPlayer, record)
        return false
    end
    sendToPlayer(targetPlayer, Const.CMD_INVENTORY_DELTA, delta)
    return true
end

function Network.SendDebugRoster(targetPlayer, diagnostics, authorized, audit)
    local payload = {
        authorized = authorized == true,
        diagnostics = diagnostics or {},
        audit = audit or {},
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_DEBUG_ROSTER, payload)
    end
end

function Network.SendRelationshipDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_RELATIONSHIP_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_RELATIONSHIP_DEBUG,
            payload
        )
    end
end

function Network.SendConversationRelationship(targetPlayer, summary, reason)
    local payload = {
        summary = summary,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_CONVERSATION_RELATIONSHIP,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_CONVERSATION_RELATIONSHIP,
            payload
        )
    end
end

function Network.SendNPCKnowledge(targetPlayer, snapshot, reason)
    local payload = { snapshot = snapshot, reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_NPC_KNOWLEDGE, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_NPC_KNOWLEDGE, payload)
    end
end

local function sendIdentityPayload(targetPlayer, command, payload)
    payload = payload or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, command, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
    end
end

function Network.SendPlayerBootstrap(targetPlayer, payload)
    sendIdentityPayload(targetPlayer, Const.CMD_PLAYER_BOOTSTRAP, payload)
end

function Network.SendNPCPresentation(targetPlayer, payload)
    sendIdentityPayload(targetPlayer, Const.CMD_NPC_PRESENTATION, payload)
end

function Network.SendKnowledgeDisclosure(targetPlayer, payload)
    sendIdentityPayload(targetPlayer, Const.CMD_KNOWLEDGE_DISCLOSURE, payload)
end

function Network.SendKnowledgeDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true, snapshot = authorized == true and snapshot or nil, reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_KNOWLEDGE_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_KNOWLEDGE_DEBUG, payload)
    end
end

function Network.SendFactionDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_FACTION_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_FACTION_DEBUG,
            payload
        )
    end
end

function Network.SendFactionMembers(
    targetPlayer,
    snapshot,
    reason
)
    local payload = {
        snapshot = snapshot,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS,
            payload
        )
    end
end

function Network.SendCommunityDebug(
    targetPlayer,
    snapshot,
    authorized,
    reason
)
    local payload = {
        authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason,
        serverTime = Core.Now(),
    }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_COMMUNITY_DEBUG,
            payload
        )
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_COMMUNITY_DEBUG,
            payload
        )
    end
end

function Network.SendNeedsDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true, snapshot = authorized == true and snapshot or nil,
        reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_NEEDS_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_NEEDS_DEBUG, payload)
    end
end

function Network.SendDirectorDebug(targetPlayer, snapshot, authorized, reason)
    local payload = { authorized = authorized == true,
        snapshot = authorized == true and snapshot or nil,
        reason = reason, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE,
            Const.CMD_DIRECTOR_DEBUG, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_DIRECTOR_DEBUG, payload)
    end
end

function Network.SendColonyManagement(targetPlayer, snapshot)
    local payload = { snapshot=snapshot, serverTime=Core.Now() }
    if isServer and isServer() and targetPlayer then sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_COLONY_MANAGEMENT, payload)
    elseif not isServer or not isServer() then triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_COLONY_MANAGEMENT, payload) end
end

function Network.SendWorldDiscovery(targetPlayer, payload)
    sendIdentityPayload(
        targetPlayer,
        Const.CMD_WORLD_DISCOVERY_STATE,
        payload
    )
end
