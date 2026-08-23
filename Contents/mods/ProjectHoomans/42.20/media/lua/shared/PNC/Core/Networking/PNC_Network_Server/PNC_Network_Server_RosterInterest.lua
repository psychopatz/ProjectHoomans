local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local ServerState = Network.ServerState

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

local function collectVisibleIDs(player, state)
    local Spatial = PNC.SpatialIndex
    local candidates = Spatial and Spatial.QueryNPCs
        and Spatial.QueryNPCs(
            player:getX(),
            player:getY(),
            Const.INTEREST_LEAVE_DISTANCE
        )
        or {}
    local nextIDs = {}
    local i
    local record
    local distance
    for i = 1, #candidates do
        record = candidates[i]
        if record and record.id and record.alive ~= false then
            distance = Core.Distance(
                player:getX(),
                player:getY(),
                record.x,
                record.y
            )
            if (
                state.ids[record.id]
                    and distance <= Const.INTEREST_LEAVE_DISTANCE
            ) or distance <= Const.INTEREST_ENTER_DISTANCE
            then
                nextIDs[record.id] = true
                if not state.ids[record.id] then
                    Internal.SendToPlayer(
                        player,
                        Const.CMD_SYNC_RECORD,
                        {
                            event = "interest_enter",
                            snapshot = Network.BuildSnapshot(record),
                        }
                    )
                end
            end
        end
    end
    return nextIDs
end

local function sendInterestExits(player, previousIDs, nextIDs)
    local id
    local record
    for id in pairs(previousIDs) do
        if not nextIDs[id] then
            record = PNC.Registry
                and PNC.Registry.Get
                and PNC.Registry.Get(id)
                or nil
            if record then
                Internal.SendToPlayer(
                    player,
                    Const.CMD_SYNC_RECORD,
                    {
                        event = "interest_exit",
                        snapshot = Network.BuildRosterSnapshot(record),
                    }
                )
            end
        end
    end
end

local function refreshPlayerInterest(player, seenPlayers)
    local key = Internal.PlayerKey(player)
    local state = ServerState.interests[key] or { ids = {} }
    local nextIDs = collectVisibleIDs(player, state)
    state.player = player
    seenPlayers[key] = true
    sendInterestExits(player, state.ids, nextIDs)
    state.ids = nextIDs
    ServerState.interests[key] = state
end

function Network.RefreshInterestSets(now)
    local seenPlayers = {}
    local key
    now = tonumber(now) or Core.Now()
    if not isServer
        or not isServer()
        or now - (tonumber(ServerState.lastInterestRefreshAt) or 0)
            < Const.INTEREST_REFRESH_MS
    then
        return
    end
    ServerState.lastInterestRefreshAt = now
    Core.ForEachPlayer(function(player)
        refreshPlayerInterest(player, seenPlayers)
    end)
    for key in pairs(ServerState.interests) do
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
        Internal.SendToPlayer(player, Const.CMD_ROSTER_DELTA, {
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
            Internal.SendToPlayer(recipients[i], Const.CMD_SYNC_RECORD, payload)
        end
        return #recipients
    end
    triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_SYNC_RECORD, payload)
    return 1
end
