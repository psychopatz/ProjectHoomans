-- Lumber zone lifecycle and worker membership.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local normalizeRegion = Internal.NormalizeRegion
local normalizeRectangle = Internal.NormalizeRectangle
local makeID = Internal.MakeID
local now = Internal.Now
local registerCoreZone = Internal.RegisterCoreZone
local unregisterCoreZone = Internal.UnregisterCoreZone
local markDirty = Internal.MarkDirty

function Service.CreateZone(args)
    args = type(args) == "table" and args or {}
    if not Service.Loaded then Service.Load(true) end
    local rectangle
    local reason
    if args.region ~= nil then
        rectangle, reason = normalizeRegion(args)
    else
        rectangle, reason = normalizeRectangle(args)
    end
    if not rectangle then return nil, reason end
    local id = tostring(args.id or makeID("lumber_zone"))
    if id == "" or Service.Data.zones[id] then
        return nil, "zone_exists"
    end
    local zone = {
        schemaVersion = Service.SCHEMA_VERSION,
        id = id,
        ownerType = tostring(args.ownerType or "player"),
        ownerId = tostring(args.ownerId or ""),
        geometry = rectangle.geometry,
        bounds = {
            minX = rectangle.minX, minY = rectangle.minY,
            maxX = rectangle.maxX, maxY = rectangle.maxY,
            minZ = rectangle.minZ, maxZ = rectangle.maxZ,
        },
        enabled = true,
        revision = 1,
        workers = {},
        treeKeys = {},
        treeIndex = {},
        scan = {
            x = rectangle.minX, y = rectangle.minY, z = rectangle.minZ,
            scannedTiles = 0, loadedTiles = 0, unloadedTiles = 0,
            complete = false,
        },
        createdAt = now(),
    }
    if GridRegion and type(GridRegion.validate) == "function" then
        local valid, validationReason, normalized =
            GridRegion.validate(zone.geometry)
        if not valid then return nil, validationReason end
        zone.geometry = normalized
        zone.bounds = GridRegion.bounds(normalized)
    end
    if not registerCoreZone(zone) then return nil, "zone_registry_rejected" end
    Service.Data.zones[id] = zone
    Service.Data.zoneOrder[#Service.Data.zoneOrder + 1] = id
    local ids = type(args.npcIds) == "table" and args.npcIds or {}
    for index = 1, math.min(#ids, Service.MAX_WORKERS_PER_ZONE) do
        Service.AssignWorker(id, ids[index])
    end
    markDirty()
    Service.Save()
    return zone
end

function Service.AssignWorker(zoneId, npcId)
    local zone = Service.GetZone(zoneId)
    npcId = tostring(npcId or "")
    if not zone then return false, "zone_not_found" end
    if npcId == "" then return false, "npc_required" end
    if not zone.workers[npcId] then
        local workerCount = 0
        for _, _ in pairs(zone.workers) do workerCount = workerCount + 1 end
        if workerCount >= Service.MAX_WORKERS_PER_ZONE then
            return false, "zone_worker_limit"
        end
    end
    local current = Service.Data.jobs[npcId]
    if current and current.zoneId ~= zone.id then
        Service.CancelWorkOrder(npcId, "worker_reassigned")
        Service.ReleaseTree(current.targetKey, "worker_reassigned")
        current.active = false
        Service.RestoreOrder(npcId)
        local previousZone = Service.GetZone(current.zoneId)
        if previousZone and previousZone.workers then
            previousZone.workers[npcId] = nil
        end
    end
    zone.workers[npcId] = true
    local job = current and current.zoneId == zone.id and current or {
        id = makeID("lumber_job"), npcId = npcId, zoneId = zone.id,
        active = true, state = "READY", phase = "WAITING", revision = 1,
    }
    if job.state == "COMPLETED" or job.state == "CANCELLED" then
        job.previousOrder = nil
        job.previousOrderCaptured = nil
        job.state, job.phase = "READY", "WAITING"
    end
    job.active = true
    job.state = job.state == "COMPLETED" and "READY" or job.state
    job.zoneId, job.npcId = zone.id, npcId
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.Data.jobs[npcId] = job
    local adapter = PNC.LumberWorkAdapter
    if adapter and adapter.EnsureOrder then
        adapter.EnsureOrder(job)
    end
    zone.revision = (tonumber(zone.revision) or 0) + 1
    markDirty()
    if PNC.Tasking and PNC.Tasking.Events
        and type(PNC.Tasking.Events.Emit) == "function"
    then
        PNC.Tasking.Events.Emit("LUMBER_JOB_AVAILABLE", {
            npcId = npcId, source = "LumberService", entityId = job.id,
        })
    end
    return true, job
end

function Service.UnassignWorker(zoneId, npcId, reason)
    local zone = Service.GetZone(zoneId)
    npcId = tostring(npcId or "")
    local job = Service.GetJob(npcId)
    if not zone or not job or job.zoneId ~= zone.id then
        return false, "worker_not_assigned"
    end
    Service.ReleaseTree(job.targetKey, reason or "worker_unassigned")
    Service.CancelWorkOrder(npcId, reason or "worker_unassigned")
    zone.workers[npcId] = nil
    job.active = false
    job.state, job.phase = "CANCELLED", "CANCELLED"
    job.targetKey = nil
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.RestoreOrder(npcId)
    zone.revision = (tonumber(zone.revision) or 0) + 1
    markDirty()
    return true, "unassigned"
end

function Service.DisableZone(zoneId, reason)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "zone_not_found" end
    zone.enabled = false
    zone.revision = (tonumber(zone.revision) or 0) + 1
    for npcId, _ in pairs(zone.workers or {}) do
        local job = Service.GetJob(npcId)
        if job then
            Service.ReleaseTree(job.targetKey, reason or "zone_disabled")
            Service.CancelWorkOrder(npcId, reason or "zone_disabled")
            job.active = false
            job.state, job.phase = "CANCELLED", "CANCELLED"
            job.targetKey = nil
            Service.RestoreOrder(npcId)
        end
    end
    markDirty()
    return true, "disabled"
end

function Service.DeleteZone(zoneId, reason)
    local zone = Service.GetZone(zoneId)
    local data = ensureData()
    local id = tostring(zoneId or "")
    if not zone then return false, "zone_not_found" end
    local workerIds = {}
    for npcId, _ in pairs(zone.workers or {}) do
        workerIds[#workerIds + 1] = npcId
    end
    for _, npcId in ipairs(workerIds) do
        if Service.UnassignWorker then
            Service.UnassignWorker(id, npcId, reason or "zone_deleted")
        else
            zone.workers[npcId] = nil
        end
    end
    unregisterCoreZone(id)
    data.zones[id] = nil
    for index = #data.zoneOrder, 1, -1 do
        if tostring(data.zoneOrder[index]) == id then
            table.remove(data.zoneOrder, index)
        end
    end
    markDirty()
    Service.Save()
    return true, "deleted"
end

return Service
