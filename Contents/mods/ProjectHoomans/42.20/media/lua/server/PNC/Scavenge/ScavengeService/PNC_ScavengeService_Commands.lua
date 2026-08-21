if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Policy = PNC.ScavengePolicy
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local increment = Internal.Increment
local touch = Internal.Touch
local activity = Internal.Activity
local ownerMatches = Internal.OwnerMatches
local authorizeNPC = Internal.AuthorizeNPC
local sessionForNPC = Internal.SessionForNPC
local forEachWorker = Internal.ForEachWorker
local restorePreviousOrder = Internal.RestorePreviousOrder
local releaseReservations = Internal.ReleaseReservations
local removeSession = Internal.RemoveSession

function Service.Cancel(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
        or sessionForNPC(arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    if session.state == "ATOMIC_TRANSFER" then
        session.cancelAfterAtomic = true
        activity(session, "CANCEL_PENDING", nil, "atomic_transfer")
        touch(session, "CollectionCancelPending", nil, true)
        return true, "cancel_pending", Service.BuildSnapshot(session)
    end
    session.state = "CANCELLED"
    session.phase = "CANCELLED"
    releaseReservations(session, "cancelled")
    WorldLoot.ReleaseSession(session.worldLootSessionId)
    session.worldLootReleased = true
    activity(session, "CANCELLED", nil, arguments.reason)
    touch(session, "CollectionCancelled", nil, true)
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
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
        or sessionForNPC(arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end
    releaseReservations(session, "paused")
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
    touch(session, "ScavengePaused", { reason = "return_to_follow" }, true)
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_PAUSED")
        restorePreviousOrder(session, npcId)
    end)
    increment("Paused")
    return true, "paused", Service.BuildSnapshot(session)
end

function Service.SetAutoGrab(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local ok, result = Policy.SetAutoGrab(player, arguments.fullType,
        arguments.enabled == true)
    if not ok then return false, result end
    local session = Service.GetSession(arguments.sessionId)
    if session and ownerMatches(session, player) then
        for _, entry in ipairs(session.manifest) do
            if entry.fullType == arguments.fullType then
                entry.autoGrab = arguments.enabled == true
            end
        end
        touch(session, "AutoGrabChanged", {
            fullType = arguments.fullType,
            enabled = arguments.enabled == true,
        }, true)
    end
    return true, "auto_grab_updated", result
end

function Service.RemoveAutoGrab(player, arguments)
    arguments = copy(arguments or {})
    arguments.enabled = false
    return Service.SetAutoGrab(player, arguments)
end

function Service.SetSearchPreferences(player, arguments)
    local ok, result = Policy.SetPreferences(player,
        arguments and arguments.sourcePolicy)
    return ok, ok and "preferences_updated" or result, result
end

function Service.RequestPolicy(player, arguments)
    local record, reason = authorizeNPC(player, arguments and arguments.npcId)
    if not record then return false, reason end
    return true, "policy_snapshot", {
        policyOnly = true,
        npcId = tostring(record.id),
        npcName = tostring(record.name or record.id),
        sourcePolicy = Policy.GetPreferences(player),
        policy = Policy.Snapshot(player),
        revision = 0,
    }
end

function Service.RequestSnapshot(player, arguments)
    local session = Service.GetSession(arguments and arguments.sessionId)
        or sessionForNPC(arguments and arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    Service.SendSnapshot(session, player)
    return true, "snapshot_sent", Service.BuildSnapshot(session)
end

function Service.BringBack(record, player)
    local session = record and sessionForNPC(record.id) or nil
    if session then
        releaseReservations(session, "bring_back")
        if not TERMINAL_STATES[session.state] then
            session.state = "CANCELLED"
            session.phase = "CANCELLED"
            activity(session, "BRING_BACK", nil, "return_home")
            WorldLoot.ReleaseSession(session.worldLootSessionId)
            session.worldLootReleased = true
            touch(session, "CollectionCancelled", {
                reason = "bring_back",
            }, true)
        end
        if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
            PNC.Tasking.Commands.CancelForNPC(record.id, "SCAVENGE_BRING_BACK")
        end
    end
    if PNC.ColonyStorageService
        and PNC.ColonyStorageService.RequestNPCCourierDeposit
    then
        local ok = PNC.ColonyStorageService.RequestNPCCourierDeposit(player, {
            npcId = record.id,
            requestId = PNC.Core.GenerateID("scavenge_bring_back"),
        })
        if ok == true then return true end
    end
    return false
end

function Service.ReleaseTerminal(sessionId)
    local session = Service.GetSession(sessionId)
    if not session or not TERMINAL_STATES[session.state] then return false end
    return removeSession(session, "terminal_release")
end

return Service
