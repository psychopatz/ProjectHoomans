if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsTaskProvider = PNC.NeedsTaskProvider or {}

local Provider = PNC.NeedsTaskProvider

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function baseFor(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

function Provider.GetCandidates(npcId)
    local record = recordFor(npcId)
    local metadata = record and PNC.IndividualNeeds.Queries.GetSleepIntent(record)
    if not metadata then return {} end
    return {{
        taskId = "sleep:" .. tostring(record.id), npcId = tostring(record.id),
        kind = "SLEEP", sourceDomain = "Needs", sourceRef = "fatigue",
        precedence = metadata.precedence, urgency = metadata.urgency,
        capability = "sleep", interruptPolicy = "NORMAL", revision = 1,
    }}
end

function Provider.Validate(intent)
    local record = recordFor(intent.npcId)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not PNC.CompanionCommands.IsCompanion(record) then
        return false, "NOT_COMPANION"
    end
    if record.runtime and record.runtime.facilityActivity
        and not PNC.TaskLeaseService.ForNPC(record.id)
    then return false, "FACILITY_ACTIVITY_BUSY" end
    local base = baseFor(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false, "NOT_AT_HOME"
    end
    local metadata = PNC.IndividualNeeds.Queries.GetSleepIntent(record)
    if not metadata then return false, "SLEEP_NOT_ACTIONABLE" end
    intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
    return true
end

function Provider.Assign(intent)
    local record = recordFor(intent.npcId)
    local base = record and baseFor(record) or nil
    if not base then return nil, "BASE_NOT_FOUND" end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    PNC.Tasking.Diagnostics.counters.facilityLookups =
        PNC.Tasking.Diagnostics.counters.facilityLookups + 1
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        intent.capability, { ttlMs = 30000, abstract = live == nil })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_BED_AVAILABLE"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Provider.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        lease.capability, { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then PNC.TaskLeaseService.SetPhase(lease.leaseId,
        lease.executionMode == "LIVE" and "TRAVEL" or "WORKING") end
    return ok, reason
end

function Provider.CanContinue(lease)
    local record = recordFor(lease.npcId)
    if not record or record.alive == false then return false end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and record.runtime.attackAction
    then return false end
    local facility = PNC.SettlementRepository.GetFacility(lease.facilityId)
    local reservation = PNC.FacilityReservations.ByID[lease.reservationId]
    if not facility or not reservation then return false end
    local fatigue = tonumber(PNC.IndividualNeeds.Get(record, "fatigue")) or 0
    return fatigue > PNC.NeedsDefinitions.SLEEP_TASK.completion
end

function Provider.Cancel(lease, reason)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        record.runtime.facilityActivity.reservationId = ""
        PNC.FacilityJobs.Stop(record, reason or "task_cancelled")
    end
    return true
end

function Provider.Complete(lease)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        record.runtime.facilityActivity.reservationId = ""
        PNC.FacilityJobs.Stop(record, "rested")
    end
    return true
end

PNC.Tasking.Commands.RegisterProvider("Needs", Provider)

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            if needType == "fatigue" then
                PNC.Tasking.Commands.MarkDirty(record.id,
                    "NEED_STATE_CHANGED")
            end
        end)
end

return Provider
