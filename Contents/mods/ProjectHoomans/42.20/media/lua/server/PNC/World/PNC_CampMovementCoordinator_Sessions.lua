if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Session retention, selection, cancellation, and public lookups.
local Coordinator = PNC.CampMovementCoordinator
local Internal = Coordinator.Internal
local number = Internal.number
local runtimeNow = Internal.runtimeNow
local recordFor = Internal.recordFor
local setRecordOrder = Internal.setRecordOrder
local isLiveRecord = Internal.isLiveRecord
local Const = PNC.Const

local function removeSessionFromOrder(sessionID)
    for index = #Coordinator.SessionOrder, 1, -1 do
        if tostring(Coordinator.SessionOrder[index]) == tostring(sessionID) then
            table.remove(Coordinator.SessionOrder, index)
        end
    end
end

local function pruneSessionOrder()
    for index = #Coordinator.SessionOrder, 1, -1 do
        if not Coordinator.Sessions[Coordinator.SessionOrder[index]] then
            table.remove(Coordinator.SessionOrder, index)
        end
    end
end

local function finishSession(session, phase, reason)
    if not session then return end
    session.phase = phase or "completed"
    session.reason = reason
    session.updatedAt = runtimeNow()
    if tostring(Coordinator.ActiveSessionID or "") == tostring(session.id) then
        Coordinator.ActiveSessionID = nil
    end
    Coordinator.Sessions[session.id] = nil
    removeSessionFromOrder(session.id)
    Coordinator.PendingCount = math.max(0,
        (tonumber(Coordinator.PendingCount) or 1) - 1)
end

local function activeSession()
    local id = Coordinator.ActiveSessionID
    local session = id and Coordinator.Sessions[id] or nil
    if session and session.phase == "running" then return session end
    Coordinator.ActiveSessionID = nil
    return nil
end

local function selectSession()
    local session = activeSession()
    if session then return session end
    for index = 1, #Coordinator.SessionOrder do
        session = Coordinator.Sessions[Coordinator.SessionOrder[index]]
        if session and session.phase == "running" then
            Coordinator.ActiveSessionID = session.id
            return session
        end
    end
    return nil
end

local function cancelOwnedSessions(ownerKey, reason)
    local ids = {}
    local session
    for index = 1, #Coordinator.SessionOrder do
        session = Coordinator.Sessions[Coordinator.SessionOrder[index]]
        if session and session.ownerKey == ownerKey then
            ids[#ids + 1] = session.id
        end
    end
    for index = 1, #ids do
        Coordinator.Cancel(ids[index], reason or "camp_replaced")
    end
end

function Coordinator.IsPlacementLocked(record)
    local runtime = record and record.runtime or nil
    local placement = runtime and runtime.campPlacement or nil
    local order = record and record.orderSpec or nil
    local state = placement and placement.state
        or order and order.placementState or ""
    state = string.lower(tostring(state))
    return state == "queued" or state == "moving" or state == "failed"
end

function Coordinator.Get(campID)
    return Coordinator.Sessions[tostring(campID or "")]
end

function Coordinator.Cancel(campID, reason)
    local session = Coordinator.Sessions[tostring(campID or "")]
    local record
    local entry
    if not session then return false, "camp_session_not_found" end
    for index = 1, #session.queue do
        entry = session.queue[index]
        if entry.state == "queued" or entry.state == "moving"
            or entry.state == "failed"
        then
            record = recordFor(entry.npcID)
            if record and record.runtime and record.runtime.campPlacement
                and tostring(record.runtime.campPlacement.campID)
                    == tostring(session.id)
            then
                record.runtime.campPlacement.state = "cancelled"
                record.runtime.campPlacement.reason = reason
                if record.orderSpec
                    and tostring(record.orderSpec.campId or "")
                        == tostring(session.id)
                then
                    record.orderSpec.placementState = "cancelled"
                end
            end
            entry.state = "cancelled"
        end
    end
    finishSession(session, "cancelled", reason or "cancelled")
    return true, "cancelled"
end


Internal.removeSessionFromOrder = removeSessionFromOrder
Internal.pruneSessionOrder = pruneSessionOrder
Internal.finishSession = finishSession
Internal.activeSession = activeSession
Internal.selectSession = selectSession
Internal.cancelOwnedSessions = cancelOwnedSessions

return Coordinator
