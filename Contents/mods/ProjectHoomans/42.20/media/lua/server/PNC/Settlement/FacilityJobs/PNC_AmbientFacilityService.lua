-- Ambient, non-work facility activities. Seating is the first activity in
-- this service; later needs can reuse the same context, discovery, and
-- reservation seams without adding another idle behavior fork.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AmbientFacilityService = PNC.AmbientFacilityService or {}

local Service = PNC.AmbientFacilityService
Service.NextAttemptAt = Service.NextAttemptAt or {}
Service.CADENCE_MS = 5000
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function isCamp(record)
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_CAMP or "camp")
end

local function homeBase(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

local function isHome(record, base)
    return base and PNC.HomeDutyService
        and PNC.HomeDutyService.IsAtHome
        and PNC.HomeDutyService.IsAtHome(record, base.id) == true
end

local function sleepActionable(record)
    local needs = PNC.IndividualNeeds
    local queries = needs and needs.Queries
    if queries and type(queries.GetSleepIntent) == "function" then
        return queries.GetSleepIntent(record) ~= nil
    end
    local definitions = PNC.NeedsDefinitions
    local policy = definitions and definitions.SLEEP_TASK
    local fatigue = needs and type(needs.Get) == "function"
        and tonumber(needs.Get(record, "fatigue")) or nil
    return fatigue ~= nil and policy
        and fatigue >= (tonumber(policy.actionable) or 0.70)
end

local function eligible(record, currentTime)
    if not record or record.alive == false
        or not PNC.CompanionCommands
        or not PNC.CompanionCommands.IsCompanion(record)
    then return false end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        -- Ambient seating is an independent server pump. It must yield before
        -- acquiring a reservation or starting a facility activity for an
        -- actor temporarily owned by Puppet Opera.
        return false
    end
    if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
        return false
    end
    if record.runtime and (record.runtime.workOrderId
        or record.runtime.facilityActivity)
    then
        -- An automatic living-room activity may have been started in the same
        -- server tick that fatigue crossed the sleep threshold. End that idle
        -- presentation immediately; otherwise it can hold the chair until the
        -- task inbox gets its next reevaluation.
        if sleepActionable(record)
            and record.runtime.facilityActivity
            and record.runtime.facilityActivity.automatic == true
            and tostring(record.runtime.facilityActivity.capability or "")
                == "living"
            and PNC.FacilityJobs and PNC.FacilityJobs.Stop
        then
            PNC.FacilityJobs.Stop(record, "sleep_need_priority")
        end
        return false
    end
    -- Needs emits the sleep wake-up before tasking consumes it. Keep the idle
    -- service from reserving a dining chair during that arbitration window.
    if sleepActionable(record) then return false end
    -- AtHome/AtCamp can keep their durable order while responding to a
    -- nearby threat. Ambient seating is only an idle presentation and must
    -- yield while the shared combat target is live.
    if record.runtime and record.runtime.target then return false end
    local camp = isCamp(record)
    local base = not camp and homeBase(record) or nil
    if not camp and not isHome(record, base) then return false end
    local key = tostring(record.id)
    if currentTime < (tonumber(Service.NextAttemptAt[key]) or 0) then
        return false
    end
    return true, camp, base
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function homeSeat(record, base, live)
    if not base or not base.id or not PNC.FacilityService
        or not PNC.FacilityService.AcquireActivity
    then return nil end
    return PNC.FacilityService.AcquireActivity(base.id, record.id, "living", {
        ttlMs = 30000,
        abstract = live == nil,
        automatic = true,
    })
end

local function campSeat(record, live)
    if not PNC.CampResourceService
        or not PNC.CampResourceService.AcquireSeat
    then return nil end
    local acquired = PNC.CampResourceService.AcquireSeat(record, {
        abstract = live == nil,
        character = live,
    })
    return acquired
end

local function start(record, acquired, camp, live)
    if not acquired or not acquired.target
        or not PNC.FacilityJobs or not PNC.FacilityJobs.Start
    then return false end
    local facility = acquired.facility
    if not facility then
        facility = {
            id = acquired.facilityId,
            baseId = "ambient",
            definitionId = "ambient",
        }
    end
    local ok = PNC.FacilityJobs.Start(record, facility, "living", {
        acquired = acquired,
        nearby = camp == true,
        automatic = true,
        abstract = live == nil,
        campActivity = camp == true,
        campId = acquired.campId,
        campX = acquired.campX,
        campY = acquired.campY,
        campZ = acquired.campZ,
        campRadius = acquired.campRadius,
        resourceRadius = acquired.resourceRadius,
        seating = true,
        floorSeating = acquired.floorSeating == true
            or acquired.resourceKind == "floor_seating"
            or acquired.target and acquired.target.floorSeating == true,
        approachCandidates = acquired.approachCandidates
            or acquired.targets,
        resourceKind = acquired.resourceKind,
        resourceKey = acquired.resourceKey,
    })
    if not ok and PNC.FacilityReservations
        and acquired.reservationId
        and PNC.FacilityReservations.Release
    then
        PNC.FacilityReservations.Release(
            acquired.reservationId, "ambient_start_failed")
    end
    return ok == true
end

function Service.Pump(currentTime)
    currentTime = tonumber(currentTime) or now()
    if not PNC.Registry then return 0 end
    local started = 0
    local function consider(record)
        local allowed, camp, base = eligible(record, currentTime)
        if not allowed then return end
        Service.NextAttemptAt[tostring(record.id)] =
            currentTime + Service.CADENCE_MS
        local live = liveBody(record)
        local acquired
        if camp then
            acquired = campSeat(record, live)
        else
            acquired = homeSeat(record, base, live)
        end
        if start(record, acquired, camp, live) then
            started = started + 1
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else
        for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end
    end
    return started
end

return Service
