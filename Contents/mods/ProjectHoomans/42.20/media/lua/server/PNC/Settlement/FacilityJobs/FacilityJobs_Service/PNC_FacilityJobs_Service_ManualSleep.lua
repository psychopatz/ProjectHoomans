if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal

-- Home and camp sleep acquisition policies for manual activity commands.

function H.ManualHomeActivity(record, capability, options)
    local base = H.BaseForRecord(record)
    local acquired
    if not base or not PNC.FacilityService
        or not PNC.FacilityService.AcquireActivity
    then
        return nil, "BASE_NOT_FOUND"
    end
    acquired = PNC.FacilityService.AcquireActivity(
        base.id, record.id, capability,
        { ttlMs = 30000, abstract = options and options.abstract == true })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    if capability == "sleep" then
        acquired.sleepVariant = "HOME_BARRACKS"
        acquired.sleepTargetPolicy = "BARRACKS_BED_FIRST"
    end
    return acquired
end

-- Manual sleep follows the same two physical-resource policies as automatic
-- sleep. A camped companion must never be sent through the home resolver: the
-- camp service owns the bounded nearby-bed snapshot and its reservation.
function H.ManualSleepActivity(record, options)
    options = type(options) == "table" and options or {}
    local routes = PNC.NeedFacilityAwayRoutes
    local camped = routes and routes.IsCamped
        and routes.IsCamped(record) == true
    if camped then
        local service = PNC.CampResourceService
        if not service or not service.AcquireSleep then
            return nil, "CAMP_RESOURCES_UNAVAILABLE"
        end
        local acquired, reason = service.AcquireSleep(record, {
            abstract = options.abstract == true,
            allowFloor = options.allowFloor,
        })
        if not acquired or acquired.ok ~= true then
            return nil, reason or acquired and acquired.reason
                or "CAMP_SLEEP_UNAVAILABLE"
        end
        acquired.sleepVariant = "CAMP_NEARBY"
        acquired.sleepTargetPolicy = acquired.resourceKind == "sleep_surface"
            and "CAMP_NEARBY_BED" or "CAMP_FLOOR_FALLBACK"
        return acquired
    end
    return H.ManualHomeActivity(record, "sleep", options)
end

return H
