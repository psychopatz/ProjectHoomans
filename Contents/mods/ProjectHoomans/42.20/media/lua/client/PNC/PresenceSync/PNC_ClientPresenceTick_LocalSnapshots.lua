--[[
    PNC Client Presence Tick: single-player/listen-server snapshot production.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local Network = PNC.Network
local Registry = PNC.Registry
local ClientState = PNC.Network and PNC.Network.ClientState
local canRequestRemoteSync = Internal.CanRequestRemoteSync
local Tick = Internal.PresenceTick or {}
Internal.PresenceTick = Tick
local LocalSnapshots = Tick.LocalSnapshots or {}
Tick.LocalSnapshots = LocalSnapshots

local function localSnapshotInterval(record, previous, now)
    local runtime = record and record.runtime or nil
    local attack = runtime and runtime.attackAction or nil
    local pathing = runtime and runtime.pathing or nil
    local previousVisual = previous and previous.visualState or nil
    if (previousVisual and previousVisual.attackActive == true)
        or (attack and now < (tonumber(attack.finishAt) or 0))
    then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_ATTACK_MS) or 50
    end
    if record and record.presenceState == Const.PRESENCE_LIVE
        and pathing
        and (
            pathing.phase == "requested"
            or pathing.phase == "active"
            or now < (tonumber(pathing.visualMovingUntil) or 0)
            or now < (tonumber(pathing.specialMoveUntil) or 0)
        )
    then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_MOVE_MS) or 150
    end
    if record and record.presenceState == Const.PRESENCE_LIVE then
        return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_IDLE_MS) or 500
    end
    return tonumber(Const.CLIENT_LOCAL_SNAPSHOT_IDLE_MS) or 500
end

local function mergeLocalPresenceSnapshot(current, incoming)
    local key
    if type(current) ~= "table" then
        return incoming
    end
    if type(incoming) ~= "table" then
        return nil
    end
    if type(incoming.travel) == "table"
        and incoming.travel.route == nil
        and type(current.travel) == "table"
        and current.travel.route ~= nil
    then
        -- Presence deltas intentionally omit the detailed travel route.
        -- Preserve it for local consumers that still use the last detailed
        -- route while movement fields are refreshed.
        incoming.travel.route = current.travel.route
    end
    for key, value in pairs(incoming) do
        current[key] = value
    end
    return current
end

local function refreshLocalAuthoritySnapshots(now)
    local snapshots
    local builtAtByID
    local seen = {}
    local changedIDs = {}
    local rebuilt = false
    local id
    local previous
    local dueAt
    local snapshot
    local presenceDelta
    local hasIncapacitated = false
    if canRequestRemoteSync() then
        return false
    end
    if not Registry or not Registry.ForEach or not Network or not Network.BuildSnapshot then
        return false
    end
    if now < ((tonumber(Sync.lastLocalSnapshotBuildAt) or 0)
        + (tonumber(Const.CLIENT_LOCAL_SNAPSHOT_SCAN_MS) or 50))
    then
        return false
    end
    Sync.lastLocalSnapshotBuildAt = now
    snapshots = ClientState.snapshots or {}
    builtAtByID = Sync.LocalSnapshotAtByID or {}
    Sync.LocalSnapshotAtByID = builtAtByID
    local function collectLiveRecord(record)
        if not record
            or record.presenceState ~= Const.PRESENCE_LIVE
            or record.alive == false
        then
            return
        end
        id = tostring(record and record.id or "")
        seen[id] = true
        if record and record.health
            and record.health.state == "incapacitated"
        then
            hasIncapacitated = true
        end
        previous = snapshots[id]
        dueAt = (tonumber(builtAtByID[id]) or 0)
            + localSnapshotInterval(record, previous, now)
        if not previous
            or previous.deathMarker == true
            or previous.interestDetailed == false
        then
            snapshot = Network.BuildSnapshot(record)
        elseif tonumber(previous.presenceRevision) ~= tonumber(record.presenceRevision)
            or now >= dueAt
        then
            if type(Network.BuildPresenceDelta) == "function" then
                presenceDelta = Network.BuildPresenceDelta(record)
                if type(presenceDelta) == "table"
                    and presenceDelta.id ~= nil
                    and tostring(presenceDelta.id) == id
                then
                    -- Keep the first detailed snapshot's static fields and
                    -- refresh only the compact presence fields while the
                    -- local-authority body is moving or otherwise due.
                    snapshot = mergeLocalPresenceSnapshot(
                        previous,
                        presenceDelta
                    )
                else
                    -- A malformed/missing delta must never erase detail or
                    -- leave presentation with a stale dynamic state.
                    snapshot = Network.BuildSnapshot(record)
                end
            else
                -- Keep compatibility with older load orders and test doubles
                -- that expose only the established full-snapshot API.
                snapshot = Network.BuildSnapshot(record)
            end
        else
            snapshot = nil
        end
        if snapshot and snapshot.id then
            id = tostring(snapshot.id)
            snapshots[id] = snapshot
            builtAtByID[id] = now
            changedIDs[id] = true
            rebuilt = true
        end
    end
    -- Local-authority presentation only consumes embodied NPCs. Walking the
    -- entire persistent registry here made every abstract NPC build a detailed
    -- snapshot on the same two-second boundary, producing population-scaled
    -- hitches even when no NPC body was loaded near the player.
    if Registry.ForEachLive then
        Registry.ForEachLive(collectLiveRecord)
    else
        Registry.ForEach(function(record)
            collectLiveRecord(record)
        end)
    end
    for id, _ in pairs(snapshots) do
        if not seen[tostring(id)] then
            snapshots[id] = nil
            builtAtByID[tostring(id)] = nil
            changedIDs[tostring(id)] = true
            rebuilt = true
        end
    end
    ClientState.snapshots = snapshots
    ClientState.lastSyncReceiveAt = now
    Sync.hasLocalIncapacitatedSnapshots = hasIncapacitated
    Sync.LocalSnapshotChangedByID = changedIDs
    return rebuilt
end


LocalSnapshots.RefreshAuthority = refreshLocalAuthoritySnapshots
