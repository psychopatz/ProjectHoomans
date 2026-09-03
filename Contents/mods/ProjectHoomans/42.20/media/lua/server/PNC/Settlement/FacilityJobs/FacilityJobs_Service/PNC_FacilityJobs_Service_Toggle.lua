if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

function H.SameManualActivity(requested, active)
    requested = tostring(requested or "")
    active = tostring(active or "")
    if requested == active then return true end
    if requested == "survival.eat.inventory" and active == "food.dine"
        or requested == "water.drink" and active == "water.nearby"
    then
        return true
    end
    return false
end

local function combatActive(record, now)
    local runtime = record and record.runtime or {}
    local target = runtime.target
    local targetKind = type(target) == "table" and target.kind or nil
    return runtime.attackAction ~= nil or runtime.combatTarget ~= nil
        or targetKind ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
end

local function releaseWorkAssignment(record, reason)
    local commands = PNC.WorkService and PNC.WorkService.Commands or nil
    if not commands then return false, "WORK_SERVICE_UNAVAILABLE" end
    local ok
    local result
    if commands.ReleaseAssignment then
        ok, result = commands.ReleaseAssignment(record.id, reason)
    elseif commands.ReleaseWorker then
        ok, result = commands.ReleaseWorker(record.id, reason)
    else
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    if ok ~= true then return false, result or "WORK_RELEASE_FAILED" end
    if record.runtime and record.runtime.workOrderId then
        return false, "WORK_RELEASE_PENDING"
    end
    return true
end

function Jobs.ToggleManual(record, capability)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local requested = tostring(capability or "")
    local activeCapability = tostring(activity and activity.capability or "")
    local toggleable = requested == "sleep"
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not record or record.alive == false then
        return false, "NPC_UNAVAILABLE"
    end
    if requested == "" then return false, "UNKNOWN_MANUAL_ACTIVITY" end
    if activity and H.SameManualActivity(requested, activeCapability) then
        if not toggleable then return true, "facility_activity_active" end
        local stopped, reason = Jobs.StopControlled(record, "manual_toggle_off")
        if stopped and toggleable then
            record.runtime.manualActivityDisabled = requested
        end
        return stopped, reason
    end
    if requested == "sleep" then
        -- Manual sleep overrides fatigue and ordinary work, but combat remains
        -- an explicit safety boundary. Work is released through its durable
        -- service so progress and reservations remain recoverable.
        if combatActive(record, now) then return false, "NPC_IN_COMBAT" end
    elseif runtime and (runtime.workOrderId or runtime.attackAction
        or runtime.target or now < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false, "NPC_BUSY"
    end
    if record.health and record.health.state == "incapacitated" then
        return false, "NPC_INCAPACITATED"
    end
    if activity then
        local stopped = Jobs.StopControlled(record, "manual_activity_replaced")
        if not stopped and record.runtime.facilityActivity then
            return false, "FACILITY_ACTIVITY_BUSY"
        end
    end
    if requested == "sleep" and record.runtime
        and record.runtime.workOrderId
    then
        local released, releaseReason = releaseWorkAssignment(record,
            "manual_sleep_override")
        if not released then return false, releaseReason end
    end
    local started, reason = H.ManualStart(record, requested)
    if started and requested == "sleep" then
        record.runtime.manualActivityDisabled = nil
    end
    return started, reason
end
