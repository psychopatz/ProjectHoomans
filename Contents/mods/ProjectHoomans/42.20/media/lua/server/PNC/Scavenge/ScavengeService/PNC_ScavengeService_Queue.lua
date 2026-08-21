if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Policy = PNC.ScavengePolicy
local ACTIVE_STATES = Internal.ACTIVE_STATES
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local increment = Internal.Increment
local emit = Internal.Emit
local touch = Internal.Touch
local activity = Internal.Activity
local ownerMatches = Internal.OwnerMatches
local authorizeNPC = Internal.AuthorizeNPC
local sessionForNPC = Internal.SessionForNPC
local forEachWorker = Internal.ForEachWorker
local restorePreviousOrder = Internal.RestorePreviousOrder
local releaseReservations = Internal.ReleaseReservations
local removeSession = Internal.RemoveSession

function Service.QueueMultiple(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    local reason
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end
    if TERMINAL_STATES[session.state] or session.state == "PAUSED" then
        return false, "session_not_selectable"
    end
    if tonumber(arguments.revision) ~= tonumber(session.revision) then
        return false, "revision_conflict"
    end
    local ids = type(arguments.entryIds) == "table" and arguments.entryIds or {}
    if #ids < 1 then return false, "selection_empty" end
    local selected = {}
    for index = 1, #ids do
        local entry = session.manifestById[tostring(ids[index] or "")]
        if not entry or entry.status ~= "AVAILABLE"
            and entry.status ~= "QUEUED"
        then return false, "entry_invalid" end
        if selected[entry.entryId] then return false, "entry_duplicate" end
        selected[entry.entryId] = entry
    end
    releaseReservations(session, "queue_replaced")
    for _, entry in ipairs(session.manifest) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.failureReason = nil
            entry.assignedNpcId = nil
        end
    end
    local bySource = {}
    local sourceOrder = {}
    for index = 1, #ids do
        local entry = selected[tostring(ids[index] or "")]
        local reservation
        reservation, reason = WorldLoot.ReserveItem(entry.sourceToken,
            entry.itemToken, session.id)
        if not reservation then
            entry.status = "UNAVAILABLE"
            entry.failureReason = reason
            session.unavailableCount = session.unavailableCount + 1
            increment("UnavailablePickups")
            activity(session, "UNAVAILABLE", entry, reason)
        else
            entry.reservationToken = reservation.reservationToken
            entry.status = "QUEUED"
            activity(session, "QUEUED", entry)
            local group = bySource[entry.sourceToken]
            if not group then
                group = { sourceToken = entry.sourceToken,
                    sourceType = entry.sourceType,
                    sourceLabel = entry.sourceLabel,
                    x = entry.x, y = entry.y, z = entry.z,
                    entries = {}, distanceSq = entry.distanceSq or 0 }
                bySource[entry.sourceToken] = group
                sourceOrder[#sourceOrder + 1] = group
            end
            group.entries[#group.entries + 1] = entry
        end
    end
    table.sort(sourceOrder, function(left, right)
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return left.sourceToken < right.sourceToken
    end)
    session.queue = sourceOrder
    session.queueIndex = 1
    session.queueEntryIndex = 1
    session.queueCount = 0
    for _, group in ipairs(sourceOrder) do
        session.queueCount = session.queueCount + #group.entries
    end
    if session.queueCount < 1 then
        touch(session, "ItemUnavailable", {
            reason = "no_available_entries",
        }, "immediate")
        return false, "no_available_entries"
    end
    session.state = "COLLECTION_QUEUED"
    session.phase = "COLLECTION_QUEUED"
    session.runActive = true
    session.lastFailure = nil
    touch(session, "PickupQueued", { count = session.queueCount },
        "immediate")
    increment("PickupRequests", session.queueCount)
    forEachWorker(session, function(npcId)
        local worker = session.workers and session.workers[npcId] or nil
        if worker and worker.phase == "IDLE" then worker.phase = "READY" end
        PNC.Tasking.Commands.MarkDirty(npcId, "SCAVENGE_COLLECTION_QUEUED")
        PNC.Tasking.Commands.Reevaluate(npcId, "SCAVENGE_COLLECTION_QUEUED")
    end)
    return true, "collection_queued", Service.BuildSnapshot(session)
end

function Service.QueuePickup(player, arguments)
    arguments = copy(arguments or {})
    arguments.entryIds = { arguments.entryId }
    return Service.QueueMultiple(player, arguments)
end

function Service.StartCollection(player, arguments)
    return Service.QueueMultiple(player, arguments)
end

return Service
