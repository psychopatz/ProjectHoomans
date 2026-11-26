-- Autonomy executor for camp/home living-room facility seating (no standalone polling).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.FacilitySeat = PNC.AutonomyExecutors.FacilitySeat or {}

local Service = PNC.AutonomyExecutors.FacilitySeat
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

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

function Service.IsEligible(record)
    if not record then return false end
    local npcContextSvc = PNC.Tasking and PNC.Tasking.NPCContext or nil
    local ctx = npcContextSvc and type(npcContextSvc.For) == "function"
        and npcContextSvc.For(record) or nil
    if ctx then
        if not ctx.alive or not ctx.isCompanion or ctx.puppetOwned then
            return false
        end
        if ctx.currentLease
            and tostring(ctx.currentLease.sourceDomain or "") ~= "autonomy"
        then
            return false
        end
        local hasAutonomyActivity = record.runtime
            and record.runtime.autonomyAdId ~= nil
            and record.runtime.facilityActivity ~= nil
        if ctx.hasWorkOrder
            or (ctx.hasFacilityActivity and not hasAutonomyActivity)
        then
            if ctx.sleepActionable
                and record.runtime and record.runtime.facilityActivity
                and record.runtime.facilityActivity.automatic == true
                and tostring(record.runtime.facilityActivity.capability or "")
                    == "living"
                and PNC.FacilityJobs and PNC.FacilityJobs.Stop
            then
                PNC.FacilityJobs.Stop(record, "sleep_need_priority")
            end
            return false
        end
        if ctx.sleepActionable or ctx.combatActive then return false end
        if ctx.isCamp then
            if ctx.campPlacementLocked then return false end
            return true, true, nil
        end
        if not ctx.isHome then return false end
        return true, false, ctx.homeBase
    end
    if record.alive == false
        or not PNC.CompanionCommands
        or not PNC.CompanionCommands.IsCompanion(record)
    then return false end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    local currentLease = PNC.TaskLeaseService
        and PNC.TaskLeaseService.ForNPC(record.id) or nil
    if currentLease
        and tostring(currentLease.sourceDomain or "") ~= "autonomy"
    then
        return false
    end
    local hasAutonomyActivity = record.runtime
        and record.runtime.autonomyAdId ~= nil
        and record.runtime.facilityActivity ~= nil
    if record.runtime and (record.runtime.workOrderId
        or (record.runtime.facilityActivity and not hasAutonomyActivity))
    then
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
    if sleepActionable(record) then return false end
    if record.runtime and record.runtime.target then return false end
    local camp = isCamp(record)
    if camp then
        local placement = string.lower(tostring(
            record.orderSpec and record.orderSpec.placementState or "arrived"))
        if placement == "queued" or placement == "moving" then
            return false
        end
    end
    local base = not camp and homeBase(record) or nil
    if not camp and not isHome(record, base) then return false end
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
    return PNC.CampResourceService.AcquireSeat(record, {
        abstract = live == nil,
        character = live,
    })
end

function Service.PreviewSeat(record, _, camp, base)
    if camp then
        if not PNC.CampResourceService
            or not PNC.CampResourceService.AcquireSeat
        then
            return nil
        end
        return {
            camp = true,
            facilityId = record and record.orderSpec
                and record.orderSpec.campId or "camp",
            x = record and tonumber(record.x) or 0,
            y = record and tonumber(record.y) or 0,
        }
    end
    if base and base.id and PNC.FacilityService
        and PNC.FacilityService.ListByCapability
    then
        local facilities = PNC.FacilityService.ListByCapability(
            base.id, "living")
        local facility = type(facilities) == "table" and facilities[1] or nil
        if not facility then return nil end
        return {
            camp = false,
            baseId = base.id,
            facilityId = facility.id,
            x = tonumber(facility.x) or (record and tonumber(record.x)) or 0,
            y = tonumber(facility.y) or (record and tonumber(record.y)) or 0,
        }
    end
    return nil
end

function Service.AcquireSeat(record, live, camp, base)
    if live == nil then live = liveBody(record) end
    if camp == nil and base == nil then
        camp = isCamp(record)
        base = not camp and homeBase(record) or nil
    end
    local acquired
    if camp then
        acquired = campSeat(record, live)
    else
        acquired = homeSeat(record, base, live)
    end
    return acquired, camp, base
end

function Service.StartSeat(record, acquired, camp, live)
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

function Service.StopSeat(record, reason)
    if not record or not PNC.FacilityJobs or not PNC.FacilityJobs.Stop then
        return false
    end
    return PNC.FacilityJobs.Stop(
        record, reason or "ambient_seat_stopped") == true
end

return Service
