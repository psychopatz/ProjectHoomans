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
    if runtime and (runtime.workOrderId or runtime.attackAction
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
    local started, reason = H.ManualStart(record, requested)
    if started and requested == "sleep" then
        record.runtime.manualActivityDisabled = nil
    end
    return started, reason
end

