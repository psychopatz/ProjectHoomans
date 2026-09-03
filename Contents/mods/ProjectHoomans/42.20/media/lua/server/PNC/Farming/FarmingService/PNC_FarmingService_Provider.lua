-- Farming tasking provider registration and lease lifecycle.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Repository = PNC.SettlementRepository
local baseFor = Internal.BaseFor
local Recovery = PNC.Tasking and PNC.Tasking.Internal
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"

local Provider = {}

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function isFarmer(record)
    local affiliation = record and record.affiliation or {}
    local role = tostring(affiliation.role or affiliation.communityRole or "")
    return role == "farmer" or record and record.job == "Farmer"
end

function Provider.GetCandidates(npcId)
    local record = recordFor(npcId)
    if not record or record.alive == false or not isFarmer(record)
        or not WorkPolicy.IsEnabled(record, Farming.FARMER_JOB)
    then return {} end
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
    if not base then return {} end
    local output = {}
    for _, facility in ipairs(PNC.FacilityService.ListByCapability(
        base.id, "farm.work") or {}) do
        if Service.HasConfiguredWork(facility)
            and PNC.FacilityReservations.HasCapacity(facility, "farm.work")
        then
            output[#output + 1] = {
                taskId = "farm:" .. tostring(facility.id) .. ":" .. tostring(record.id),
                npcId = tostring(record.id), kind = "FARM_MAINTENANCE",
                sourceDomain = "farming", sourceRef = facility.id,
                precedence = "NORMAL_WORK", urgency = 0.35,
                workPriority = WorkPolicy.GetPriority(record,
                    Farming.FARMER_JOB),
                capability = "farm.work", revision = facility.revision,
            }
        end
    end
    return output
end

function Provider.Validate(intent)
    local record = recordFor(intent and intent.npcId)
    local facility = intent and Repository.GetFacility(intent.sourceRef)
    return record ~= nil and record.alive ~= false and facility ~= nil
        and WorkPolicy.IsEnabled(record, Farming.FARMER_JOB)
        and Service.HasConfiguredWork(facility)
end

function Provider.Assign(intent)
    local record = recordFor(intent.npcId)
    local facility = Repository.GetFacility(intent.sourceRef)
    local base = baseFor(facility)
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        "farm.work", { ttlMs = 30000, abstract = live == nil,
            deferWorldValidation = true })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Provider.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        "farm.work", { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then PNC.TaskLeaseService.SetPhase(lease.leaseId,
        lease.executionMode == "LIVE" and "TRAVEL" or "WAITING") end
    return ok, reason
end

function Provider.CanContinue(lease)
    local facility = Repository.GetFacility(lease and lease.facilityId)
    local record = recordFor(lease and lease.npcId)
    if not facility or not record or record.alive == false
        or not Repository.GetComponent(lease.componentId)
    then return false end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    return (lease.executionMode == "LIVE") == (live ~= nil)
end

function Provider.GetRecoveryState(lease)
    local record = recordFor(lease and lease.npcId)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local progressAt = activity and activity.lastProgressAt
        or lease and lease.lastProgressAt
    if not record or record.alive == false then
        return { terminal = true, phase = "WAITING",
            lastProgressAt = progressAt }
    end
    if not activity or tostring(activity.taskLeaseId or "")
        ~= tostring(lease and lease.leaseId or "")
    then
        return {
            invalid = true, phase = "WAITING", watchable = true,
            timeoutMs = 15000, recoveryReason = "farming_activity_missing",
            lastProgressAt = progressAt,
        }
    end
    local phase = tostring(activity.phase or lease and lease.phase or "WAITING")
    if phase == "TRAVELLING" then phase = "TRAVEL" end
    local snapshot = {
        phase = phase,
        lastProgressAt = progressAt,
        watchable = phase == "WORKING" or phase == "FARMING",
    }
    if phase == "QUEUED" or phase == "STARTING"
        or phase == "INTERRUPTED"
    then
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "farming_scene_start_timeout"
    end
    if phase == "TRAVEL"
        and Recovery and Recovery.ApplyMovementRecovery
    then snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record) end
    return snapshot
end

function Provider.Tick(lease)
    local record = recordFor(lease.npcId)
    if not record then return false end
    if lease.executionMode == "ABSTRACT" then Service.TickAbstract(record, lease) end
    return true
end

function Provider.Cancel(lease)
    local record = recordFor(lease and lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        PNC.FacilityJobs.Stop(record, "farming_task_cancelled")
    end
    return true
end

function Provider.Complete(lease)
    return Provider.Cancel(lease)
end

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("farming", Provider)
end

Internal.Provider = Provider

return Service
