if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.HydrationTaskProvider = PNC.HydrationTaskProvider or {}

local Provider = PNC.HydrationTaskProvider

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function baseFor(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

local function policy()
    return PNC.NeedsDefinitions and PNC.NeedsDefinitions.SUPPLY
        and PNC.NeedsDefinitions.SUPPLY.thirst or {
            trigger = 0.25, target = 0.10,
        }
end

function Provider.HasSpigot(record)
    local base = record and baseFor(record)
    if not base or not PNC.FacilityService
        or not PNC.FacilityService.ListByCapability
    then return false end
    return #PNC.FacilityService.ListByCapability(base.id, "water.drink") > 0
end

function Provider.GetCandidates(npcId)
    local record = recordFor(npcId)
    local value = record and PNC.IndividualNeeds.Get(record, "thirst") or 0
    local thresholds = policy()
    if not record or value < (tonumber(thresholds.trigger) or 0.25) then
        return {}
    end
    return {{
        taskId = "drink:" .. tostring(record.id), npcId = tostring(record.id),
        kind = "DRINK", sourceDomain = "Hydration", sourceRef = "thirst",
        precedence = value >= 0.70 and "CRITICAL_NEED" or "NORMAL_NEED",
        urgency = math.max(0, math.min(1, value)), capability = "water.drink",
        interruptPolicy = "NORMAL", revision = 1,
    }}
end

function Provider.Validate(intent)
    local record = recordFor(intent.npcId)
    if not record or record.alive == false then return false end
    if not PNC.CompanionCommands.IsCompanion(record) then return false end
    if record.runtime and record.runtime.workOrderId then return false end
    local base = baseFor(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false
    end
    local value = PNC.IndividualNeeds.Get(record, "thirst") or 0
    local thresholds = policy()
    if value < (tonumber(thresholds.trigger) or 0.25) then return false end
    return Provider.HasSpigot(record)
end

function Provider.Assign(intent)
    local record = recordFor(intent.npcId)
    local base = record and baseFor(record) or nil
    if not base then return nil, "BASE_NOT_FOUND" end
    if record.runtime and record.runtime.facilityActivity
        and record.runtime.facilityActivity.automatic
        and PNC.FacilityJobs
    then
        PNC.FacilityJobs.Stop(record, "thirst_trigger")
    end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        intent.capability, { ttlMs = 30000, abstract = live == nil })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_SPIGOT_AVAILABLE"
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
    local thresholds = policy()
    return record and record.alive ~= false
        and record.runtime and record.runtime.facilityActivity ~= nil
        and (PNC.IndividualNeeds.Get(record, "thirst") or 0)
            > (tonumber(thresholds.target) or 0.10)
        and PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
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
        PNC.FacilityJobs.Stop(record, "drink_complete")
    end
    return true
end

PNC.Tasking.Commands.RegisterProvider("Hydration", Provider)

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            if needType == "thirst" then
                PNC.Tasking.Commands.MarkDirty(record.id,
                    "THIRST_TRIGGER")
            end
        end)
end

return Provider
