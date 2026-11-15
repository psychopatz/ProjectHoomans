-- Fishing WorkService order bridging for autonomous NORMAL_WORK zones and FORCED_ORDER manual jobs.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FishingWorkAdapter = PNC.FishingWorkAdapter or {}

local Adapter = PNC.FishingWorkAdapter
local Work = PNC.WorkService
local Service = PNC.FishingService
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

local function baseFor(worker, baseId)
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(worker, baseId) or nil
    if not base and PNC.BaseService then
        if baseId and PNC.BaseService.Get then base = PNC.BaseService.Get(baseId) end
        if not base and PNC.BaseService.GetForColony and worker and worker.affiliation then
            base = PNC.BaseService.GetForColony(
                worker.affiliation.communityID or worker.affiliation.communityId)
        end
    end
    return base
end

---Creates or reconciles a FORCED_ORDER WorkService order for a manual fishing job.
function Adapter.EnsureOrder(job)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not job or job.active ~= true
    then
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    local existing = job.workOrderId and Work.Queries and Work.Queries.Get
        and Work.Queries.Get(job.workOrderId) or nil
    if existing and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.FAILED
    then
        return true, existing
    end
    local zoneOrderId = "fishing-zone:" .. tostring(job.zoneId or "")
    local claimedAuto = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(zoneOrderId) or nil
    if claimedAuto and tostring(claimedAuto.workerId or "") == tostring(job.npcId or "")
        and claimedAuto.status ~= Status.CANCELLED
        and claimedAuto.status ~= Status.COMPLETED
        and claimedAuto.status ~= Status.FAILED
    then
        job.workOrderId = claimedAuto.id
        if type(claimedAuto.payload) == "table" then
            claimedAuto.payload.fishingJobId = job.id
            claimedAuto.payload.npcId = job.npcId
        end
        return true, claimedAuto
    end
    local worker = recordFor(job.npcId)
    local base = baseFor(worker, job.baseId)
    local baseId = tostring(job.baseId or (base and base.id) or "")
    if base and base.id then job.baseId = base.id end
    local order, reason = Work.Commands.Queue({
        operation = "FISHING",
        colonyId = base and base.colonyId or "",
        factionId = base and base.factionId or "",
        baseId = baseId,
        requiredWorkerId = job.npcId,
        requiredWork = 1,
        priority = 90,
        precedence = "FORCED_ORDER",
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE", returnHome = "STAY" },
        payload = { fishingJobId = job.id, zoneId = job.zoneId, npcId = job.npcId },
    })
    if not order then return false, reason or "FISHING_WORK_ORDER_FAILED" end
    job.workOrderId = order.id
    return true, order
end

---Maintains an autonomous NORMAL_WORK fishing order for an enabled fishing zone.
function Adapter.EnsureZoneOrder(zone)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not zone or not zone.id
    then
        return false, "WORK_SERVICE_UNAVAILABLE"
    end
    local orderId = "fishing-zone:" .. tostring(zone.id)
    local existing = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(orderId) or nil
    local valid = Service and Service.ValidateZone and Service.ValidateZone(zone)
    if not valid then
        if existing and not existing.workerId
            and existing.status ~= Status.CANCELLED
            and existing.status ~= Status.COMPLETED
            and existing.status ~= Status.FAILED and Work.Commands.Cancel
        then
            Work.Commands.Cancel(orderId, "fishing_zone_inactive")
        end
        return false, "FISHING_ZONE_INACTIVE"
    end
    if existing and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.FAILED
    then
        return true, existing
    end
    local base = PNC.BaseService and zone.ownerId and PNC.BaseService.GetForColony
        and PNC.BaseService.GetForColony(zone.ownerId) or nil
    local order, reason = Work.Commands.Queue({
        id = orderId,
        operation = "FISHING",
        colonyId = base and base.colonyId or "",
        factionId = base and base.factionId or "",
        baseId = tostring(zone.baseId or (base and base.id) or ""),
        requiredWorkerId = nil,
        requiredWork = 1,
        priority = 50,
        precedence = "NORMAL_WORK",
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE", returnHome = "STAY" },
        payload = { zoneId = zone.id, autonomous = true },
    })
    if not order then return false, reason or "FISHING_ZONE_ORDER_FAILED" end
    return true, order
end

---Cancels any active WorkService order linked to the fishing job.
function Adapter.CancelOrder(job, reason)
    if not job or not job.workOrderId or not Work or not Work.Commands
        or not Work.Commands.Cancel
    then
        return false
    end
    local order = Work.Queries and Work.Queries.Get and Work.Queries.Get(job.workOrderId)
    if not order or order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then
        return true
    end
    return Work.Commands.Cancel(job.workOrderId, reason or "fishing_job_cancelled") == true
end

---Ensures WorkService orders exist for active fishing jobs and valid fishing zones.
function Adapter.Reconcile()
    if not Service or not Service.Data then return 0 end
    local count = 0
    for _, job in pairs(Service.Data.jobs or {}) do
        if job and job.active == true and Adapter.EnsureOrder(job) then
            count = count + 1
        end
    end
    for _, zone in pairs(Service.Data.zones or {}) do
        if zone and Adapter.EnsureZoneOrder(zone) then
            count = count + 1
        end
    end
    return count
end

return Adapter
