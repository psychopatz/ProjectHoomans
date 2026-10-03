if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Bounded movement advancement and scheduler pump.
local Coordinator = PNC.CampMovementCoordinator
local Internal = Coordinator.Internal
local runtimeNow = Internal.runtimeNow
local recordFor = Internal.recordFor
local isLiveRecord = Internal.isLiveRecord
local liveBody = Internal.liveBody
local reached = Internal.reached
local movementState = Internal.movementState
local setRecordOrder = Internal.setRecordOrder
local finishSession = Internal.finishSession
local selectSession = Internal.selectSession
local Const = PNC.Const

local function nextQueued(session)
    local entry
    while session.cursor <= #session.queue do
        entry = session.queue[session.cursor]
        session.cursor = session.cursor + 1
        if entry and entry.state == "queued" then return entry end
    end
    return nil
end

local function markEntry(session, entry, state, at, reason)
    local record = recordFor(entry.npcID)
    local applied
    if record then
        applied = setRecordOrder(session, entry, record, state, at, reason)
    end
    entry.state = state
    entry.reason = reason
    entry.updatedAt = at
    if applied == true and state == "arrived"
        and PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        -- Needs may be evaluated while a member is queued, but must not take
        -- the movement tick away from AtCamp. Re-open need selection only at
        -- the authoritative arrival boundary.
        PNC.Tasking.Events.Emit("NPC_NEEDS_CHANGED", {
            npcId = entry.npcID,
            source = "CampMovementCoordinator",
            entityId = entry.npcID,
            cause = "CAMP_PLACEMENT_ARRIVED",
        })
    end
    return applied == true
end

local function advanceSession(session, at)
    local entry = session.activeEntry
    local record
    local body
    local path
    local progressAt
    local nextEntry
    local applied
    local reason
    if entry then
        record = recordFor(entry.npcID)
        if not record or not isLiveRecord(record)
            or tostring(record.orderSpec and record.orderSpec.kind or "")
                ~= tostring(Const and Const.ORDER_CAMP or "camp")
            or tostring(record.orderSpec and record.orderSpec.campId or "")
                ~= tostring(session.id)
        then
            entry.state = "skipped"
            entry.reason = "npc_unavailable_or_order_replaced"
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        body = liveBody(record)
        if reached(entry.zone, body, record) then
            markEntry(session, entry, "arrived", at, "camp_zone_reached")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        path = movementState(record, body, at)
        progressAt = path and tonumber(path.lastProgressAt) or nil
        if path and path.forceRecovery == true then
            markEntry(session, entry, "failed", at, "camp_path_recovery_required")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        if path and path.phase == "blocked"
            and at - (progressAt or entry.startedAt or at)
                >= Coordinator.BLOCKED_TIMEOUT_MS
        then
            markEntry(session, entry, "failed", at, "camp_path_blocked")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        if at - (entry.startedAt or session.startedAt or at)
            >= Coordinator.MAX_MOVE_MS
        then
            markEntry(session, entry, "failed", at, "camp_move_timeout")
            session.activeEntry = nil
            session.nextEligibleAt = at + Coordinator.NEXT_PLACEMENT_DELAY_MS
            return
        end
        return
    end
    if at < (tonumber(session.nextEligibleAt) or 0) then return end
    nextEntry = nextQueued(session)
    if not nextEntry then
        finishSession(session, "completed", "all_targets_processed")
        return
    end
    record = recordFor(nextEntry.npcID)
    if not record or not isLiveRecord(record)
        or tostring(record.orderSpec and record.orderSpec.kind or "")
            ~= tostring(Const and Const.ORDER_CAMP or "camp")
        or tostring(record.orderSpec and record.orderSpec.campId or "")
            ~= tostring(session.id)
    then
        nextEntry.state = "skipped"
        nextEntry.reason = "npc_unavailable_or_order_replaced"
        session.nextEligibleAt = at
        return
    end
    applied, reason = setRecordOrder(
        session, nextEntry, record, "moving", at, "camp_placement_started")
    if applied then
        nextEntry.state = "moving"
        nextEntry.startedAt = at
        session.activeEntry = nextEntry
    else
        nextEntry.state = "skipped"
        nextEntry.reason = reason or "camp_order_failed"
        session.nextEligibleAt = at
    end
end

function Coordinator.Pump(at)
    local session
    at = runtimeNow(at)
    if (tonumber(Coordinator.PendingCount) or 0) <= 0 then return false end
    if at < (tonumber(Coordinator.NextPumpAt) or 0) then return false end
    Coordinator.NextPumpAt = at + Coordinator.PUMP_INTERVAL_MS
    session = selectSession()
    if not session then return false end
    session.updatedAt = at
    advanceSession(session, at)
    return true
end


return Coordinator
