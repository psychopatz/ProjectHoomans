if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Definitions = PNC.NeedFacilityTriggerDefinitions

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function baseFor(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

function Triggers.HasFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local base = record and baseFor(record)
    if not definition or not base or not PNC.FacilityService
        or not PNC.FacilityService.ListByCapability
    then return false end
    local facilities = PNC.FacilityService.ListByCapability(
        base.id, definition.capability)
    for index = 1, #facilities do
        if not PNC.FacilityReservations
            or not PNC.FacilityReservations.HasCapacity
            or PNC.FacilityReservations.HasCapacity(
                facilities[index], definition.capability)
        then return true end
    end
    return false
end

function Triggers.PreferFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local actionable = definition and Definitions.Evaluate(
        definition, record, false)
    if not actionable or not Triggers.HasFacility(record, triggerId) then
        return false
    end
    if PNC.Tasking and PNC.Tasking.Commands then
        PNC.Tasking.Commands.MarkDirty(record.id,
            "NEED_FACILITY_" .. string.upper(definition.id))
    end
    return true
end

function Triggers.GetCandidates(npcId)
    local record = recordFor(npcId)
    local candidates = {}
    if not record then return candidates end
    for _, definition in ipairs(Definitions.List()) do
        local actionable, metadata = Definitions.Evaluate(
            definition, record, false)
        if actionable and Triggers.HasFacility(record, definition.id) then
            candidates[#candidates + 1] = {
                taskId = "need_facility:" .. definition.id .. ":"
                    .. tostring(record.id),
                npcId = tostring(record.id), kind = definition.kind,
                sourceDomain = "NeedFacility", sourceRef = definition.id,
                precedence = metadata.precedence,
                urgency = metadata.urgency,
                capability = definition.capability,
                interruptPolicy = "NORMAL", revision = 1,
            }
        end
    end
    return candidates
end

function Triggers.Validate(intent)
    local record = recordFor(intent.npcId)
    local definition = Definitions.Get(intent.sourceRef)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not definition then return false, "TRIGGER_NOT_FOUND" end
    if not PNC.CompanionCommands.IsCompanion(record) then
        return false, "NOT_COMPANION"
    end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and (record.runtime.workOrderId
            or record.runtime.attackAction)
    then return false, "NPC_BUSY" end
    local activity = record.runtime and record.runtime.facilityActivity
    local activityLease = PNC.TaskLeaseService.ForNPC(record.id)
    if activity and not activityLease and activity.automatic ~= true then
        return false, "FACILITY_ACTIVITY_BUSY"
    end
    local base = baseFor(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false, "NOT_AT_HOME"
    end
    local actionable, metadata = Definitions.Evaluate(
        definition, record, false)
    if not actionable or not Triggers.HasFacility(record, definition.id) then
        return false, "NEED_ROUTE_NOT_ACTIONABLE"
    end
    intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
    return true
end

function Triggers.Assign(intent)
    local record = recordFor(intent.npcId)
    local base = record and baseFor(record) or nil
    if not base then return nil, "BASE_NOT_FOUND" end
    if record.runtime and record.runtime.facilityActivity
        and record.runtime.facilityActivity.automatic == true
        and PNC.FacilityJobs
    then
        PNC.FacilityJobs.Stop(record,
            "need_trigger_" .. tostring(intent.sourceRef))
    end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    PNC.Tasking.Diagnostics.counters.facilityLookups =
        PNC.Tasking.Diagnostics.counters.facilityLookups + 1
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        intent.capability, { ttlMs = 30000, abstract = live == nil })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Triggers.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        lease.capability, { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then
        PNC.TaskLeaseService.SetPhase(lease.leaseId,
            lease.executionMode == "LIVE" and "TRAVEL" or "WORKING")
    end
    return ok, reason
end

function Triggers.CanContinue(lease)
    local record = recordFor(lease.npcId)
    local definition = Definitions.Get(lease.sourceRef)
    if not record or record.alive == false or not definition then return false end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and record.runtime.attackAction
    then return false end
    return PNC.SettlementRepository.GetFacility(lease.facilityId) ~= nil
        and PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
        and Definitions.Evaluate(definition, record, true) == true
end

local function stop(lease, reason)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        record.runtime.facilityActivity.reservationId = ""
        PNC.FacilityJobs.Stop(record, reason)
    end
    return true
end

function Triggers.Cancel(lease, reason)
    return stop(lease, reason or "task_cancelled")
end

function Triggers.Complete(lease)
    return stop(lease, "need_complete")
end

PNC.Tasking.Commands.RegisterProvider("NeedFacility", Triggers)

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            for _, definition in ipairs(Definitions.List()) do
                if definition.needType == needType then
                    PNC.Tasking.Commands.MarkDirty(record.id,
                        "NEED_STATE_CHANGED")
                    return
                end
            end
        end)
end

return Triggers
