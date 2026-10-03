if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Group camp admission and one-at-a-time placement queue creation.
local Coordinator = PNC.CampMovementCoordinator
local Internal = Coordinator.Internal
local compactSite = Internal.compactSite
local compactAssignment = Internal.compactAssignment
local runtimeNow = Internal.runtimeNow
local isLiveRecord = Internal.isLiveRecord
local setRecordOrder = Internal.setRecordOrder
local cancelOwnedSessions = Internal.cancelOwnedSessions
local pruneSessionOrder = Internal.pruneSessionOrder
local selectSession = Internal.selectSession
local finishSession = Internal.finishSession

function Coordinator.StartGroupCamp(campSite, records, directory, options)
    local root
    local ownerKey
    local sessionID
    local session
    local assignment
    local zone
    local entry
    local record
    local state
    local accepted = 0
    local affectedTargets = {}
    local activeAssigned = false
    local slotOccupied
    local at
    options = type(options) == "table" and options or {}
    if type(campSite) ~= "table" or type(records) ~= "table"
        or #records == 0
    then
        return nil, "camp_coordinator_input_invalid"
    end
    root = compactSite(campSite)
    if root.x == nil or root.y == nil then
        return nil, "camp_root_position_missing"
    end
    sessionID = tostring(options.campId or "")
    if sessionID == "" then return nil, "camp_session_id_missing" end
    ownerKey = tostring(options.ownerKey or "player")
    cancelOwnedSessions(ownerKey, "camp_replaced")
    pruneSessionOrder()
    if #Coordinator.SessionOrder >= Coordinator.MAX_SESSIONS then
        return 0, "camp_coordinator_busy", affectedTargets
    end
    slotOccupied = selectSession() ~= nil
    session = {
        version = Coordinator.VERSION,
        id = sessionID,
        ownerKey = ownerKey,
        root = root,
        directoryRevision = directory and directory.revision or nil,
        queue = {},
        cursor = 1,
        activeEntry = nil,
        phase = "running",
        startedAt = runtimeNow(options.now),
        updatedAt = runtimeNow(options.now),
        nextEligibleAt = 0,
    }
    Coordinator.Sessions[sessionID] = session
    Coordinator.SessionOrder[#Coordinator.SessionOrder + 1] = sessionID
    Coordinator.PendingCount = (tonumber(Coordinator.PendingCount) or 0) + 1
    at = session.startedAt

    for index = 1, math.min(#records, Coordinator.MAX_QUEUE) do
        record = records[index]
        if record and record.id ~= nil and isLiveRecord(record) then
            assignment = directory and directory.assignments
                and directory.assignments[tostring(record.id)] or nil
            -- First iteration deliberately uses the validated root for every
            -- member. Adjacent-room/need placement is a later coordinator
            -- policy; it must not reintroduce a second broad scan here.
            zone = root
            entry = {
                npcID = tostring(record.id),
                index = #session.queue + 1,
                zone = compactSite(zone),
                assignment = compactAssignment(assignment, zone),
                state = "queued",
            }
            if not slotOccupied and not activeAssigned then
                state = "moving"
            else
                state = "queued"
            end
            local applied, applyReason = setRecordOrder(
                session, entry, record, state, at, "camp_started")
            if applied then
                entry.state = state
                session.queue[#session.queue + 1] = entry
                accepted = accepted + 1
                affectedTargets[#affectedTargets + 1] = tostring(record.id)
                if state == "moving" then
                    entry.startedAt = at
                    session.activeEntry = entry
                    activeAssigned = true
                    slotOccupied = true
                end
            else
                entry.state = "skipped"
                entry.reason = applyReason
            end
        end
    end
    if accepted <= 0 then
        finishSession(session, "failed", "no_live_targets")
        return 0, "no_targets", affectedTargets
    end
    if activeAssigned then Coordinator.ActiveSessionID = sessionID end
    Coordinator.NextPumpAt = 0
    return accepted, "commanded", affectedTargets
end


return Coordinator
