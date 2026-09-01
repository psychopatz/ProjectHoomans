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

local function eligible(record, currentTime)
    if not record or record.alive == false
        or not PNC.CompanionCommands
        or not PNC.CompanionCommands.IsCompanion(record)
    then return false end
    if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
        return false
    end
    if record.runtime and (record.runtime.workOrderId
        or record.runtime.facilityActivity)
    then return false end
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

local function reserved(resource)
    local key = tostring(resource and resource.resourceKey or "")
    return key ~= "" and PNC.FacilityReservations
        and PNC.FacilityReservations.ByResource
        and PNC.FacilityReservations.ByResource[key] ~= nil
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function homeSeat(record, base, live)
    if not base or not base.id then return nil end
    local facilities = PNC.FacilityService and PNC.FacilityService
        .ListByCapability and PNC.FacilityService.ListByCapability(
            base.id, "living") or {}
    for facilityIndex = 1, #facilities do
        local facility = facilities[facilityIndex]
        local resources = PNC.FacilityResources
            and PNC.FacilityResources.GetResources
            and PNC.FacilityResources.GetResources(facility, "seat") or {}
        for resourceIndex = 1, #resources do
            local resource = resources[resourceIndex]
            if not reserved(resource) then
                local targets = PNC.FacilityInteractionTargets
                    and PNC.FacilityInteractionTargets.ResolveResource
                    and PNC.FacilityInteractionTargets.ResolveResource(resource, {
                        abstract = live == nil, character = live,
                    }) or {}
                local target = targets[1]
                if target then
                    local ok = false
                    local reservation
                    if PNC.FacilityReservations
                        and PNC.FacilityReservations.ReserveResource
                    then
                        ok, reservation =
                            PNC.FacilityReservations.ReserveResource(
                                facility.id,
                                resource,
                                record.id,
                                "living",
                                30000,
                                { automatic = true }
                            )
                    end
                    if ok then
                        return {
                            ok = true,
                            facilityId = facility.id,
                            componentId = "",
                            reservationId = reservation.id,
                            role = resource.role or "living.chair",
                            resource = resource,
                            resourceKey = resource.resourceKey,
                            resourceKind = resource.resourceKind,
                            target = target,
                            targets = targets,
                            approachCandidates = targets,
                            facility = facility,
                            seating = true,
                        }
                    end
                end
            end
        end
    end
    return nil
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
