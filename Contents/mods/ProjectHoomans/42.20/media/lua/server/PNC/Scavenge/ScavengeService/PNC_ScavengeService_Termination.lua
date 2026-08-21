if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Policy = PNC.ScavengePolicy
local increment = Internal.Increment
local touch = Internal.Touch
local activity = Internal.Activity
local ownerMatches = Internal.OwnerMatches
local sessionForNPC = Internal.SessionForNPC
local forEachWorker = Internal.ForEachWorker
local restorePreviousOrder = Internal.RestorePreviousOrder
local releaseReservations = Internal.ReleaseReservations
local removeSession = Internal.RemoveSession
local flushRecordBroadcasts = Internal.FlushRecordBroadcasts

local function findOwnedSession(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
        or sessionForNPC(arguments.npcId)
    if not session then return nil, "session_not_found" end
    if not ownerMatches(session, player) then
        return nil, "session_not_owned"
    end
    return session
end

local function setFollowing(player, npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId)) or nil
    if not record then return false end
    local order = {
        kind = PNC.Const.ORDER_FOLLOW or "follow",
        ownerUsername = player and player.getUsername
            and player:getUsername() or nil,
        ownerOnlineID = player and player.getOnlineID
            and player:getOnlineID() or nil,
    }
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "order")
        end
    end
    return true
end

function Service.Cancel(player, arguments)
    local session, reason = findOwnedSession(player, arguments)
    if not session then return false, reason end
    if session.state == "ATOMIC_TRANSFER" then
        session.cancelAfterAtomic = true
        activity(session, "CANCEL_PENDING", nil, "atomic_transfer")
        touch(session, "CollectionCancelPending", nil, true)
        return true, "cancel_pending", Service.BuildSnapshot(session)
    end
    session.state = "CANCELLED"
    session.phase = "CANCELLED"
    flushRecordBroadcasts(session, "scavenge_cancelled")
    releaseReservations(session, "cancelled")
    WorldLoot.ReleaseSession(session.worldLootSessionId)
    session.worldLootReleased = true
    activity(session, "CANCELLED", nil,
        type(arguments) == "table" and arguments.reason or nil)
    touch(session, "CollectionCancelled", nil, "immediate")
    session.runActive = false
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_CANCELLED")
        restorePreviousOrder(session, npcId)
    end)
    increment("Cancelled")
    return true, "cancelled", Service.BuildSnapshot(session)
end

function Service.CancelSearch(player, arguments)
    return Service.Cancel(player, arguments)
end

function Service.CancelCollection(player, arguments)
    return Service.Cancel(player, arguments)
end

function Service.Pause(player, arguments)
    local session, reason = findOwnedSession(player, arguments)
    if not session then return false, reason end
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end
    releaseReservations(session, "paused")
    flushRecordBroadcasts(session, "scavenge_paused")
    for _, entry in ipairs(session.manifest or {}) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.failureReason = nil
            entry.assignedNpcId = nil
        end
    end
    session.queue = nil
    session.queueIndex = 1
    session.queueEntryIndex = 1
    session.queueCount = 0
    session.state = "PAUSED"
    session.phase = "PAUSED"
    session.runActive = false
    activity(session, "PAUSED", nil, "return_to_follow")
    touch(session, "ScavengePaused", { reason = "return_to_follow" },
        "immediate")
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_PAUSED")
        restorePreviousOrder(session, npcId)
    end)
    increment("Paused")
    return true, "paused", Service.BuildSnapshot(session)
end

function Service.Disband(player, arguments)
    local session, reason = findOwnedSession(player, arguments)
    if not session then return false, reason end
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end

    -- Stop task authority before issuing follow orders so movement cannot race.
    session.runActive = false
    releaseReservations(session, "disbanded")
    flushRecordBroadcasts(session, "scavenge_disbanded")
    if not session.worldLootReleased then
        WorldLoot.ReleaseSession(session.worldLootSessionId)
        session.worldLootReleased = true
    end
    session.queue = nil
    session.queueCount = 0
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_DISBANDED")
    end)
    forEachWorker(session, function(npcId)
        setFollowing(player, npcId)
    end)

    session.state = "DISBANDED"
    session.phase = "DISBANDED"
    session.disbanded = true
    activity(session, "DISBANDED", nil, "return_to_follow")
    Policy.Save()
    touch(session, "ScavengeDisbanded", {
        reason = "return_to_follow",
    }, "immediate")
    local snapshot = Service.BuildSnapshot(session)
    removeSession(session, "disbanded")
    increment("Disbanded")
    return true, "disbanded_following", snapshot
end

return Service
