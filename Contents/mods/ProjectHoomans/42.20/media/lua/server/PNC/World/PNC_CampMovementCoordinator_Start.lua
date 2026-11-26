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

    local slots = type(campSite.slots) == "table" and campSite.slots or nil
    for index = 1, math.min(#records, Coordinator.MAX_QUEUE) do
        record = records[index]
        if record and record.id ~= nil and isLiveRecord(record) then
            assignment = directory and directory.assignments
                and directory.assignments[tostring(record.id)] or nil
            -- First iteration deliberately uses the validated root for every
            -- member, spreading members across the room's pre-analyzed open
            -- interior slots so they do not pile up at the doorway.
            zone = compactSite(root)
            if slots and #slots > 0 then
                local slotIndex = #session.queue + 1
                local slot = slots[((slotIndex - 1) % #slots) + 1]
                if type(slot) == "table"
                    and slot.x ~= nil and slot.y ~= nil
                then
                    zone.x = slot.x
                    zone.y = slot.y
                    zone.z = slot.z or zone.z
                    zone.movementX = slot.x
                    zone.movementY = slot.y
                    zone.movementZ = slot.z or zone.movementZ
                    zone.hasSlot = true
                end
            end
            entry = {
                npcID = tostring(record.id),
                index = #session.queue + 1,
                zone = zone,
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
