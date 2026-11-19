local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local MotionHints = PNC.MotionHints
local ServerState = Network.ServerState

local MAX_REPAIR_REQUESTS_PER_SECOND = 16
local repairWindows = setmetatable({}, { __mode = "k" })

local function nextReplicaSequence(record)
    local runtime
    if not record then
        return 0
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.replicaSequence = (tonumber(runtime.replicaSequence) or 0) + 1
    return runtime.replicaSequence
end

local function cloneInlinePortraitVariant(record, payload)
    local legacy = Core.ShallowCopy(payload)
    legacy.snapshot = Core.ShallowCopy(payload.snapshot)
    legacy.snapshot.portraitRef = nil
    local identity = PNC.Identity
    legacy.snapshot.portrait = identity and identity.BuildPortraitSummary
        and identity.BuildPortraitSummary(record) or nil
    return legacy
end

local function dispatchPayloadBatch(record, recipientList, payload, anyLean)
    if not payload.snapshot or not payload.snapshot.portraitRef or not anyLean then
        Internal.SendRecordPayload(recipientList, payload)
        return
    end
    local legacy
    for _, player in ipairs(recipientList) do
        local selected = payload
        if not Internal.UsesLeanRosterPortraits(player) then
            legacy = legacy or cloneInlinePortraitVariant(record, payload)
            selected = legacy
        end
        Internal.SendToPlayer(player, Const.CMD_SYNC_RECORD, selected)
    end
end

function Network.BroadcastRecord(record, eventName)
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
    nextReplicaSequence(record)
    Internal.QueueBroadcastRoster(record, eventName)
    recipients = Internal.CollectRecordRecipients(record)
    local serverMode = isServer and isServer() == true
    if serverMode and #recipients <= 0 then return end

    path = record and record.runtime and record.runtime.pathing or nil
    if path and MotionHints and MotionHints.MarkBroadcast then
        MotionHints.MarkBroadcast(record, path, Core.Now())
    end

    if not serverMode then
        local payload = Internal.BuildRecordPayload(record, eventName, false)
        Internal.SendRecordPayload(recipients, payload)
        return
    end

    local deltaRecipients = {}
    local fallbackRecipients = {}
    local anyDeltaLean = false
    local anyFallbackLean = false
    local usesDeltaFn = Internal.UsesDomainDeltas

    for _, player in ipairs(recipients) do
        local lean = Internal.UsesLeanRosterPortraits(player)
        if not usesDeltaFn or usesDeltaFn(player) then
            deltaRecipients[#deltaRecipients + 1] = player
            if lean then anyDeltaLean = true end
        else
            fallbackRecipients[#fallbackRecipients + 1] = player
            if lean then anyFallbackLean = true end
        end
    end

    if #deltaRecipients > 0 then
        local deltaPayload = Internal.BuildRecordPayload(
            record, eventName, anyDeltaLean
        )
        dispatchPayloadBatch(record, deltaRecipients, deltaPayload, anyDeltaLean)
    end

    if #fallbackRecipients > 0 then
        if Network.Metrics then
            Network.Metrics.fallbackSnapshots =
                (tonumber(Network.Metrics.fallbackSnapshots) or 0) + 1
        end
        local fallbackPayload = Internal.BuildRecordPayload(
            record, eventName or "fallback", anyFallbackLean, true
        )
        dispatchPayloadBatch(
            record, fallbackRecipients, fallbackPayload, anyFallbackLean
        )
    end
end

function Network.SendRecordRepair(player, record, reason)
    if not Core.IsAuthority() or not player or type(record) ~= "table" then
        return false
    end
    local now = Core.Now and Core.Now() or 0
    local window = math.floor(now / 1000)
    local state = repairWindows[player]
    if not state or state.window ~= window then
        state = { window = window, count = 0 }
        repairWindows[player] = state
    end
    if state.count >= MAX_REPAIR_REQUESTS_PER_SECOND then
        return false
    end
    state.count = state.count + 1

    local repairReason = tostring(reason or "gap_repair")
    local lean = Internal.UsesLeanRosterPortraits
        and Internal.UsesLeanRosterPortraits(player) or false
    local payload = Internal.BuildRecordPayload(
        record, repairReason, lean, true
    )
    if repairReason ~= "repair" and repairReason ~= "gap_repair"
        and repairReason ~= "reconnect" and repairReason ~= "unsupported_delta"
        and repairReason ~= "missing_baseline"
        and repairReason ~= "incarnation_mismatch"
        and Network.Metrics
    then
        Network.Metrics.repairSnapshots =
            (tonumber(Network.Metrics.repairSnapshots) or 0) + 1
    end
    return Internal.SendToPlayer(player, Const.CMD_SYNC_RECORD, payload)
end

local function sendInterestRemoval(id, command, payload)
    local state
    if isServer and isServer() then
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[id] then
                Internal.SendToPlayer(state.player, command, payload)
                state.ids[id] = nil
            end
        end
    else
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
    end
end

local function deathRemovalSnapshot(id)
    local marker
    local record
    marker = PNC.Registry
        and PNC.Registry.GetDeathMarker
        and PNC.Registry.GetDeathMarker(id)
        or nil
    record = PNC.Registry
        and PNC.Registry.Get
        and PNC.Registry.Get(id)
        or nil
    return marker
        and Network.BuildDeathMarkerSnapshot
        and Network.BuildDeathMarkerSnapshot(marker)
        or record and Network.BuildSnapshot(record)
        or nil
end

local function broadcastDeathRemoval(id, reason)
    local marker = PNC.Registry
        and PNC.Registry.GetDeathMarker
        and PNC.Registry.GetDeathMarker(id) or nil
    local snapshot
    local payload
    -- Lifecycle-only markers exist solely to drive infected corpse
    -- reanimation. They must not become player-visible roster/map deaths.
    if marker and marker.lifecycleOnly == true then
        return false
    end
    snapshot = deathRemovalSnapshot(id)
    if not snapshot then return false end
    Network.QueueRosterSnapshot(id, snapshot, false, reason)
    payload = { event = "death", snapshot = snapshot }
    payload.directoryRevision = ServerState.rosterRevision
    sendInterestRemoval(id, Const.CMD_SYNC_RECORD, payload)
    return true
end

function Network.BroadcastRemoval(id, reason)
    local payload = { id = id, reason = reason }
    local entry
    local removalReason = tostring(reason or "")
    if not Core.IsAuthority() then
        return
    end
    if string.sub(removalReason, 1, 5) == "death"
        and broadcastDeathRemoval(id, reason)
    then
        return
    end
    Network.QueueRosterDelta(id, true, reason)
    entry = ServerState.rosterDeltas[tostring(id)]
    if entry then
        payload.revision = entry.revision
    end
    sendInterestRemoval(id, Const.CMD_REMOVE_RECORD, payload)
end

function Network.BroadcastDeathMarkerRemoval(id, reason)
    local payload
    local entry
    if not Core.IsAuthority() or id == nil then
        return false
    end
    id = tostring(id)
    payload = {
        id = id,
        reason = tostring(reason or "corpse_removed"),
    }
    Network.QueueRosterDelta(id, true, payload.reason)
    entry = ServerState.rosterDeltas[id]
    if entry then
        payload.revision = entry.revision
    end
    if isServer and isServer() then
        Core.ForEachPlayer(function(player)
            Internal.SendToPlayer(player, Const.CMD_REMOVE_RECORD, payload)
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

function Network.BroadcastBodyRemoval(id, bodyInstanceID, bodyOnlineID, reason, bodyLease)
    if not Core.IsAuthority() then return false end
    if not isServer or isServer() ~= true then return true end
    local binding = require "PNC/Core/Networking/PNC_MultiplayerBodyBinding"
    local message = binding.Removal(id, bodyLease, bodyOnlineID)
    if not message then return false end
    local payload = { id = tostring(id), bodyBinding = message,
        reason = tostring(reason or "stale_body") }
    -- Only clients with this NPC in their interest set can possess a bound
    -- replica. Other clients never gain identity from a removal message.
    for _, state in pairs(ServerState.interests) do
        if state.player and state.ids and state.ids[tostring(id)] then
            Internal.SendToPlayer(state.player, Const.CMD_REMOVE_BODY, payload)
        end
    end
    return true
end

function Network.BroadcastFullSync(targetPlayer, records, requestID, portraitProtocol)
    local chunkSize = math.max(1, tonumber(Const.ROSTER_CHUNK_SIZE) or 50)
    local total = #(records or {})
    local chunkCount = math.ceil(total / chunkSize)
    local syncID
    local directoryRevision = tonumber(ServerState.rosterRevision) or 0
    local chunkIndex
    local startIndex
    local finishIndex
    local chunk
    local i
    ServerState.fullSyncSerial = (tonumber(ServerState.fullSyncSerial) or 0) + 1
    syncID = requestID and tostring(requestID)
        or "server:roster:" .. tostring(Core.Now()) .. ":"
            .. tostring(ServerState.fullSyncSerial)
    Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_BEGIN, {
        syncID = syncID,
        directoryRevision = directoryRevision,
        portraitProtocol = portraitProtocol,
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
        Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_CHUNK, {
            syncID = syncID,
            directoryRevision = directoryRevision,
            total = total,
            chunkCount = chunkCount,
            chunkIndex = chunkIndex,
            snapshots = chunk,
        })
    end
    Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_END, {
        syncID = syncID,
        directoryRevision = directoryRevision,
        portraitProtocol = portraitProtocol,
        total = total,
        chunkCount = chunkCount,
    })
    if isServer and isServer() and targetPlayer then
        local state = ServerState.interests[Internal.PlayerKey(targetPlayer)]
        if state then
            state.ids = {}
        end
        ServerState.lastInterestRefreshAt = 0
    end
end
