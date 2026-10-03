-- Shared task pump timing and ownership context.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local ActorControl = PNC.ActorControl
local H = Tasking.Internal

local function clockNow(fallback)
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or fallback
    end
    return fallback
end

local function budgetExhausted(startedAt)
    local budget = math.max(1, tonumber(Tasking.TIME_BUDGET_MS) or 2)
    return clockNow(startedAt) - startedAt >= budget
end

local function puppetOperaSuspends(lease)
    local record
    if not lease or not ActorControl
        or not ActorControl.IsPuppetOwned
        or not PNC.Registry
        or not PNC.Registry.Get
    then
        return false
    end
    record = PNC.Registry.Get(lease.npcId)
    return record ~= nil and ActorControl.IsPuppetOwned(record)
end

local function promoteMaterializedLease(lease)
    if not lease or tostring(lease.executionMode or "") ~= "ABSTRACT" then
        return
    end
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(lease.npcId) or nil
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    if not record or record.presenceState ~= PNC.Const.PRESENCE_LIVE
        or not activity or activity.taskLeaseId ~= lease.leaseId
    then return end
    lease.executionMode = "LIVE"
    activity.abstract = false
end

H.PumpClockNow = clockNow
H.PumpBudgetExhausted = budgetExhausted
H.PumpPuppetOperaSuspends = puppetOperaSuspends
H.PumpPromoteMaterializedLease = promoteMaterializedLease

