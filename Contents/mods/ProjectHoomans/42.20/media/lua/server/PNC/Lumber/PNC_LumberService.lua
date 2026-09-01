-- Server-authoritative lumber zones, tree ledger, and shared job state.
--
-- The service deliberately stores coordinates and scalar progress only. PZ
-- IsoTree and HandWeapon objects are runtime values and must never enter
-- ModData or an NPC record.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberService = PNC.LumberService or {}

local Service = PNC.LumberService
local Const = PNC.Const or {}
local Core = PNC.Core or {}
local GridRegion
local Zones

do
    local ok, value = pcall(require, "PsychopatzCore/World/PC_GridRegion")
    if ok then GridRegion = value end
    ok, value = pcall(require, "PsychopatzCore/World/PC_ZoneRegistry")
    if ok then Zones = value end
end

Service.MODDATA_KEY = "PNC_LumberWorld_V1"
Service.SCHEMA_VERSION = 1
Service.MAX_ZONE_TILES = tonumber(Const.LUMBER_MAX_ZONE_TILES) or 10000
Service.MAX_WORKERS_PER_ZONE = 16
Service.SCAN_TILES_PER_PUMP = 128
Service.SCAN_ZONES_PER_PUMP = 1
Service.SCAN_INTERVAL_MS = 1000
Service.CLAIM_TTL_MS = 30000
Service.HIT_INTERVAL_MS = 1500
Service.ABSTRACT_MAX_ELAPSED_MS = 15000
Service.ABSTRACT_TOOL_HITS_PER_CONDITION = 8

Service.Runtime = Service.Runtime or {
    claims = {},
    previousOrders = {},
    zoneCursor = 0,
    nextPumpAt = 0,
}
Service.Data = Service.Data or nil
Service.Loaded = Service.Loaded == true
Service.Dirty = Service.Dirty == true
Service.LastSaveAt = tonumber(Service.LastSaveAt) or 0

local function now()
    if Core and type(Core.Now) == "function" then return Core.Now() end
    return 0
end

local function copy(value)
    if Core and type(Core.DeepCopy) == "function" then
        return Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function integer(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge or value ~= math.floor(value)
    then return nil end
    return value
end

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then return nil end
    return value
end

local function makeID(prefix)
    if Core and type(Core.GenerateID) == "function" then
        return tostring(Core.GenerateID(prefix))
    end
    return tostring(prefix) .. ":" .. tostring(now())
end

local function markDirty()
    Service.Dirty = true
end

local function ensureData()
    if type(Service.Data) ~= "table" then
        Service.Data = {
            schemaVersion = Service.SCHEMA_VERSION,
            zones = {},
            trees = {},
            jobs = {},
            zoneOrder = {},
        }
    end
    Service.Data.schemaVersion = Service.SCHEMA_VERSION
    Service.Data.zones = type(Service.Data.zones) == "table"
        and Service.Data.zones or {}
    Service.Data.trees = type(Service.Data.trees) == "table"
        and Service.Data.trees or {}
    Service.Data.jobs = type(Service.Data.jobs) == "table"
        and Service.Data.jobs or {}
    Service.Data.zoneOrder = type(Service.Data.zoneOrder) == "table"
        and Service.Data.zoneOrder or {}
    return Service.Data
end

local function zoneBounds(zone)
    if zone and zone.bounds then return zone.bounds end
    if GridRegion and zone and zone.geometry
        and type(GridRegion.bounds) == "function"
    then
        zone.bounds = GridRegion.bounds(zone.geometry)
    end
    return zone and zone.bounds or nil
end

local function zoneContains(zone, x, y, z)
    local bounds = zoneBounds(zone)
    if not bounds or x < bounds.minX or x > bounds.maxX
        or y < bounds.minY or y > bounds.maxY
        or z < bounds.minZ or z > bounds.maxZ
    then return false end
    if GridRegion and type(GridRegion.containsPoint) == "function" then
        return GridRegion.containsPoint(zone.geometry, x, y, z)
    end
    return true
end

local function registerCoreZone(zone)
    if not Zones or type(Zones.register) ~= "function" then return true end
    local ok, result = pcall(Zones.register, {
        id = zone.id,
        ownerType = zone.ownerType,
        ownerId = zone.ownerId,
        type = "lumber",
        subtype = "lumber_zone",
        geometry = zone.geometry,
        revision = zone.revision,
    })
    return ok and result ~= false
end

local function unregisterCoreZone(zoneId)
    if Zones and type(Zones.remove) == "function" then
        pcall(Zones.remove, zoneId)
    end
end

local function buildRectangle(minX, minY, maxX, maxY, z)
    local rows = {}
    for y = minY, maxY do rows[y] = { minX, maxX } end
    return {
        levels = {
            [z] = { rows = rows },
        },
    }
end

local function normalizeRectangle(args)
    local minX = integer(args.minX)
    local minY = integer(args.minY)
    local maxX = integer(args.maxX)
    local maxY = integer(args.maxY)
    local z = integer(args.z) or 0
    if not minX or not minY or not maxX or not maxY then
        return nil, "zone_coordinates_invalid"
    end
    if minX > maxX then minX, maxX = maxX, minX end
    if minY > maxY then minY, maxY = maxY, minY end
    local width = maxX - minX + 1
    local height = maxY - minY + 1
    if width < 1 or height < 1 or width * height > Service.MAX_ZONE_TILES then
        return nil, "zone_too_large"
    end
    return {
        minX = minX, minY = minY, maxX = maxX, maxY = maxY,
        minZ = z, maxZ = z,
        geometry = buildRectangle(minX, minY, maxX, maxY, z),
    }
end

local function normalizeRegion(args)
    if type(args.region) ~= "table" or not GridRegion
        or type(GridRegion.validate) ~= "function"
    then
        return nil, "region_unavailable"
    end
    local valid, reason, normalized = GridRegion.validate(args.region)
    if not valid then return nil, reason or "zone_empty" end
    if GridRegion.isConnected and not GridRegion.isConnected(normalized, 4) then
        return nil, "zone_disconnected"
    end
    local bounds = GridRegion.bounds(normalized)
    if not bounds then return nil, "zone_bounds_missing" end
    if bounds.minZ ~= bounds.maxZ then
        return nil, "zone_multiple_levels"
    end
    if GridRegion.countTiles(normalized) > Service.MAX_ZONE_TILES then
        return nil, "zone_too_large"
    end
    return {
        minX = bounds.minX, minY = bounds.minY,
        maxX = bounds.maxX, maxY = bounds.maxY,
        minZ = bounds.minZ, maxZ = bounds.maxZ,
        geometry = normalized,
    }
end

local function ensureZoneRuntime(zone)
    zone.workers = type(zone.workers) == "table" and zone.workers or {}
    zone.treeKeys = type(zone.treeKeys) == "table" and zone.treeKeys or {}
    zone.treeIndex = type(zone.treeIndex) == "table" and zone.treeIndex or {}
    for index = 1, #zone.treeKeys do
        zone.treeIndex[tostring(zone.treeKeys[index])] = true
    end
    zone.scan = type(zone.scan) == "table" and zone.scan or {}
    local bounds = zoneBounds(zone)
    if bounds then
        zone.scan.x = integer(zone.scan.x) or bounds.minX
        zone.scan.y = integer(zone.scan.y) or bounds.minY
        zone.scan.z = integer(zone.scan.z) or bounds.minZ
    end
    zone.scan.scannedTiles = math.max(0,
        math.floor(tonumber(zone.scan.scannedTiles) or 0))
    zone.scan.loadedTiles = math.max(0,
        math.floor(tonumber(zone.scan.loadedTiles) or 0))
    zone.scan.unloadedTiles = math.max(0,
        math.floor(tonumber(zone.scan.unloadedTiles) or 0))
    zone.scan.unresolved = type(zone.scan.unresolved) == "table"
        and zone.scan.unresolved or {}
    zone.scan.unresolvedSeen = type(zone.scan.unresolvedSeen) == "table"
        and zone.scan.unresolvedSeen or {}
    for index = 1, #zone.scan.unresolved do
        local entry = zone.scan.unresolved[index]
        if type(entry) == "table" then
            zone.scan.unresolvedSeen[
                tostring(entry.x) .. ":" .. tostring(entry.y) .. ":"
                    .. tostring(entry.z)
            ] = true
        end
    end
    zone.scan.retryCursor = math.max(1,
        math.floor(tonumber(zone.scan.retryCursor) or 1))
    zone.scan.phase = tostring(zone.scan.phase
        or (#zone.scan.unresolved > 0 and "RETRY_UNLOADED" or "INITIAL"))
    zone.scan.complete = zone.scan.complete == true
    if #zone.scan.unresolved > 0 then
        zone.scan.complete = false
        zone.scan.phase = "RETRY_UNLOADED"
    end
    zone.enabled = zone.enabled ~= false
    zone.revision = math.max(0, math.floor(tonumber(zone.revision) or 0))
    return zone
end

local function normalizeTree(tree, key)
    tree.key = tostring(tree.key or key or "")
    tree.x = integer(tree.x)
    tree.y = integer(tree.y)
    tree.z = integer(tree.z) or 0
    tree.status = tostring(tree.status or "DISCOVERED")
    tree.signature = tostring(tree.signature or "")
    tree.maxWork = math.max(1, tonumber(tree.maxWork) or 1)
    tree.remainingWork = math.max(0,
        math.min(tree.maxWork, tonumber(tree.remainingWork) or tree.maxWork))
    tree.logYield = math.max(1, math.floor(tonumber(tree.logYield) or 1))
    tree.revision = math.max(0, math.floor(tonumber(tree.revision) or 0))
    return tree
end

local function normalizeLoadedState()
    local data = ensureData()
    local zone
    local key
    for key, zone in pairs(data.zones) do
        zone.id = tostring(zone.id or key)
        ensureZoneRuntime(zone)
        data.zones[zone.id] = zone
        if zone.id ~= key then data.zones[key] = nil end
        registerCoreZone(zone)
    end
    for key, zone in pairs(data.trees) do
        data.trees[key] = normalizeTree(zone, key)
        if data.trees[key].status == "CLAIMED"
            or data.trees[key].status == "IN_PROGRESS"
        then
            data.trees[key].status = "DISCOVERED"
        end
    end
    Service.Runtime.claims = {}
    for _, job in pairs(data.jobs) do
        job.npcId = tostring(job.npcId or "")
        job.zoneId = tostring(job.zoneId or "")
        job.active = job.active ~= false
        job.state = tostring(job.state or "READY")
        job.phase = tostring(job.phase or "WAITING")
        job.revision = math.max(0, math.floor(tonumber(job.revision) or 0))
        job.leaseId = nil
    end
end

function Service.Load(force)
    if Service.Loaded and force ~= true then return true end
    local raw
    if ModData and type(ModData.getOrCreate) == "function" then
        raw = ModData.getOrCreate(Service.MODDATA_KEY)
    end
    if type(raw) == "table" then Service.Data = raw end
    ensureData()
    normalizeLoadedState()
    Service.Loaded = true
    Service.Dirty = false
    return true, "loaded"
end

function Service.Save()
    if not Service.Loaded then Service.Load(true) end
    local data = ensureData()
    if ModData and type(ModData.getOrCreate) == "function" then
        local target = ModData.getOrCreate(Service.MODDATA_KEY)
        if target then
            target.schemaVersion = Service.SCHEMA_VERSION
            target.zones = data.zones
            target.trees = data.trees
            target.jobs = data.jobs
            target.zoneOrder = data.zoneOrder
        end
    end
    Service.LastSaveAt = now()
    Service.Dirty = false
    return true, "saved"
end

function Service.GetZone(zoneId)
    ensureData()
    return Service.Data.zones[tostring(zoneId or "")]
end

function Service.GetTree(treeKey)
    ensureData()
    return Service.Data.trees[tostring(treeKey or "")]
end

function Service.GetJob(npcId)
    ensureData()
    return Service.Data.jobs[tostring(npcId or "")]
end

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
    end
    job.active = true
    job.state = job.state == "COMPLETED" and "READY" or job.state
    job.zoneId, job.npcId = zone.id, npcId
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.Data.jobs[npcId] = job
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

local function getCell()
    local engineGetCell = _G and _G.getCell or nil
    if type(engineGetCell) == "function" then
        local ok, cell = pcall(engineGetCell)
        if ok and cell then return cell end
    end
    if IsoWorld and IsoWorld.instance then
        return IsoWorld.instance.currentCell
    end
    return nil
end

function Service.GetSquare(x, y, z)
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
    return ok and square or nil
end

function Service.GetTreeAt(x, y, z)
    local square = Service.GetSquare(x, y, z)
    if not square or type(square.getTree) ~= "function" then
        return nil, square
    end
    local ok, tree = pcall(square.getTree, square)
    return ok and tree or nil, square
end

local function treeSignature(tree)
    local size = 0
    local yield = 0
    if tree and type(tree.getSize) == "function" then
        local ok, value = pcall(tree.getSize, tree)
        if ok then size = tonumber(value) or 0 end
    end
    if tree and type(tree.getLogYield) == "function" then
        local ok, value = pcall(tree.getLogYield, tree)
        if ok then yield = tonumber(value) or 0 end
    end
    return tostring(size) .. ":" .. tostring(yield)
end

local function treeHealth(tree)
    if tree and type(tree.getHealth) == "function" then
        local ok, value = pcall(tree.getHealth, tree)
        if ok and tonumber(value) then return math.max(1, tonumber(value)) end
    end
    return 100
end

local function treeYield(tree)
    if tree and type(tree.getLogYield) == "function" then
        local ok, value = pcall(tree.getLogYield, tree)
        if ok and tonumber(value) then return math.max(1, math.floor(value)) end
    end
    return 1
end

local function reconcileAbstractTree(tree, actual, square)
    if not tree or tree.status ~= "DEPLETED"
        or tree.completedMode ~= "abstract" or not actual or not square
    then return false end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        tree.invalidReason = "abstract_tree_replaced"
        markDirty()
        return false
    end
    if type(square.transmitRemoveItemFromSquare) ~= "function" then
        return false
    end
    local ok, result = pcall(square.transmitRemoveItemFromSquare,
        square, actual)
    if not ok or result == -1 then return false end
    tree.worldReconciledAt = now()
    markDirty()
    return true
end

local function reconcileLoadedSquare(square)
    if not square then return end
    local x = square.getX and square:getX() or square.x
    local y = square.getY and square:getY() or square.y
    local z = square.getZ and square:getZ() or square.z or 0
    if x == nil or y == nil then return end
    local tree = square.getTree and square:getTree() or nil
    if not tree then return end
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    reconcileAbstractTree(Service.Data and Service.Data.trees[key],
        tree, square)
end

local function upsertTree(zone, x, y, z, tree)
    local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    local signature = treeSignature(tree)
    local health = treeHealth(tree)
    local existing = Service.Data.trees[key]
    if not existing then
        existing = {
            key = key, x = x, y = y, z = z,
            signature = signature, maxWork = health,
            remainingWork = health, logYield = treeYield(tree),
            status = "DISCOVERED", revision = 1, discoveredAt = now(),
        }
        Service.Data.trees[key] = existing
    elseif existing.signature ~= signature
        and existing.status ~= "IN_PROGRESS"
    then
        existing.signature = signature
        existing.maxWork = health
        existing.remainingWork = health
        existing.logYield = treeYield(tree)
        existing.status = "DISCOVERED"
        existing.revision = (tonumber(existing.revision) or 0) + 1
    elseif existing.status == "DISCOVERED"
        and tonumber(existing.remainingWork) <= 0
    then
        existing.maxWork = health
        existing.remainingWork = health
    end
    ensureZoneRuntime(zone)
    if not zone.treeIndex[key] then
        zone.treeIndex[key] = true
        zone.treeKeys[#zone.treeKeys + 1] = key
    end
    return existing
end

local function advanceScan(zone)
    local scan = zone.scan
    local bounds = zoneBounds(zone)
    if not bounds then scan.complete = true; return end
    if scan.x < bounds.maxX then
        scan.x = scan.x + 1
        return
    end
    scan.x = bounds.minX
    if scan.y < bounds.maxY then
        scan.y = scan.y + 1
        return
    end
    scan.y = bounds.minY
    if scan.z < bounds.maxZ then
        scan.z = scan.z + 1
        return
    end
    scan.complete = true
end

function Service.ScanZone(zoneId, budget)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "zone_not_found" end
    ensureZoneRuntime(zone)
    budget = math.max(1, math.floor(tonumber(budget)
        or Service.SCAN_TILES_PER_PUMP))
    local scan = zone.scan
    if scan.phase == "RETRY_UNLOADED" then
        local unresolved = scan.unresolved
        local processed = 0
        while processed < budget and #unresolved > 0 do
            local index = math.min(scan.retryCursor, #unresolved)
            local entry = unresolved[index]
            local tree
            local square
            if type(entry) == "table" then
                tree, square = Service.GetTreeAt(entry.x, entry.y, entry.z)
            end
            scan.scannedTiles = scan.scannedTiles + 1
            if square then
                scan.loadedTiles = scan.loadedTiles + 1
                if tree then
                    local key = tostring(entry.x) .. ":"
                        .. tostring(entry.y) .. ":" .. tostring(entry.z)
                    local existing = Service.Data.trees[key]
                    if not reconcileAbstractTree(existing, tree, square) then
                        upsertTree(zone, entry.x, entry.y, entry.z, tree)
                    end
                end
                local key = tostring(entry.x) .. ":" .. tostring(entry.y)
                    .. ":" .. tostring(entry.z)
                scan.unresolvedSeen[key] = nil
                unresolved[index] = unresolved[#unresolved]
                unresolved[#unresolved] = nil
                scan.retryCursor = index > #unresolved and 1 or index
            else
                scan.retryCursor = index + 1
                if scan.retryCursor > #unresolved then
                    scan.retryCursor = 1
                end
            end
            processed = processed + 1
        end
        scan.complete = #unresolved <= 0
        if scan.complete then scan.phase = "COMPLETE" end
        if processed > 0 then markDirty() end
        return true, processed, scan.complete
    end
    local processed = 0
    while processed < budget and not scan.complete do
        local x, y, z = scan.x, scan.y, scan.z
        if zoneContains(zone, x, y, z) then
            local tree, square = Service.GetTreeAt(x, y, z)
            scan.scannedTiles = scan.scannedTiles + 1
            if square then
                scan.loadedTiles = scan.loadedTiles + 1
            else
                scan.unloadedTiles = scan.unloadedTiles + 1
                local key = tostring(x) .. ":" .. tostring(y) .. ":"
                    .. tostring(z)
                if not scan.unresolvedSeen[key] then
                    scan.unresolvedSeen[key] = true
                    scan.unresolved[#scan.unresolved + 1] = {
                        x = x, y = y, z = z,
                    }
                end
            end
            if tree then
                local key = tostring(x) .. ":" .. tostring(y) .. ":"
                    .. tostring(z)
                local existing = Service.Data.trees[key]
                if not reconcileAbstractTree(existing, tree, square) then
                    upsertTree(zone, x, y, z, tree)
                end
            end
        end
        processed = processed + 1
        advanceScan(zone)
    end
    if scan.complete then
        if #scan.unresolved > 0 then
            scan.complete = false
            scan.phase = "RETRY_UNLOADED"
            scan.retryCursor = 1
        else
            scan.phase = "COMPLETE"
        end
    end
    if processed > 0 then markDirty() end
    return true, processed, scan.complete
end

local function expireClaims(at)
    for key, claim in pairs(Service.Runtime.claims) do
        if at >= (tonumber(claim.expiresAt) or 0) then
            local tree = Service.Data.trees[key]
            if tree and tree.status ~= "DEPLETED"
                and tree.status ~= "INVALID"
            then tree.status = "DISCOVERED" end
            Service.Runtime.claims[key] = nil
            markDirty()
        end
    end
end

function Service.ClaimTree(treeKey, npcId, at)
    local key = tostring(treeKey or "")
    local tree = Service.GetTree(key)
    npcId = tostring(npcId or "")
    at = tonumber(at) or now()
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        return false, "tree_unavailable"
    end
    local current = Service.Runtime.claims[key]
    if current and at < (tonumber(current.expiresAt) or 0)
        and tostring(current.npcId) ~= npcId
    then return false, "tree_claimed" end
    Service.Runtime.claims[key] = {
        npcId = npcId, claimedAt = at,
        expiresAt = at + Service.CLAIM_TTL_MS,
    }
    tree.status = "IN_PROGRESS"
    tree.revision = (tonumber(tree.revision) or 0) + 1
    markDirty()
    return true, current and "claim_renewed" or "claimed"
end

function Service.RenewTreeClaim(treeKey, npcId, at)
    local claim = Service.Runtime.claims[tostring(treeKey or "")]
    if not claim or tostring(claim.npcId) ~= tostring(npcId or "") then
        return false, "claim_missing"
    end
    claim.expiresAt = (tonumber(at) or now()) + Service.CLAIM_TTL_MS
    return true
end

local function ensureTreeClaim(treeKey, npcId, at)
    local claim = Service.Runtime.claims[tostring(treeKey or "")]
    if claim and tostring(claim.npcId) == tostring(npcId or "")
        and (tonumber(at) or now()) < (tonumber(claim.expiresAt) or 0)
    then
        return Service.RenewTreeClaim(treeKey, npcId, at)
    end
    return Service.ClaimTree(treeKey, npcId, at)
end

local function selectClaimedTarget(npcId, at)
    for _ = 1, 4 do
        local tree = Service.SelectTarget(npcId)
        if not tree then return nil end
        if ensureTreeClaim(tree.key, npcId, at) then return tree end
    end
    return nil
end

function Service.ReleaseTree(treeKey, reason)
    local key = tostring(treeKey or "")
    if key == "" then return true end
    local tree = Service.GetTree(key)
    Service.Runtime.claims[key] = nil
    if tree and tree.status ~= "DEPLETED" and tree.status ~= "INVALID" then
        tree.status = "DISCOVERED"
        tree.revision = (tonumber(tree.revision) or 0) + 1
    end
    markDirty()
    return true, reason or "released"
end

function Service.CompleteTree(treeKey, mode)
    local tree = Service.GetTree(treeKey)
    if not tree then return false, "tree_not_found" end
    tree.remainingWork = 0
    tree.status = "DEPLETED"
    tree.completedMode = tostring(mode or "abstract")
    tree.completedAt = now()
    tree.revision = (tonumber(tree.revision) or 0) + 1
    Service.Runtime.claims[tostring(treeKey)] = nil
    markDirty()
    return true, "depleted"
end

local function distanceSq(record, x, y)
    local rx = tonumber(record and record.x) or 0
    local ry = tonumber(record and record.y) or 0
    local dx, dy = rx - x, ry - y
    return dx * dx + dy * dy
end

function Service.SelectTarget(npcId)
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId)) or nil
    if not job or not zone or zone.enabled ~= true or not record then
        return nil, "job_unavailable"
    end
    local selected
    local selectedDistance
    for index = 1, #(zone.treeKeys or {}) do
        local key = zone.treeKeys[index]
        local tree = Service.Data.trees[key]
        local claim = Service.Runtime.claims[key]
        local available = tree and tree.x ~= nil and tree.y ~= nil
            and tree.status ~= "DEPLETED"
            and tree.status ~= "INVALID"
            and (not claim or tostring(claim.npcId) == tostring(npcId))
        if available then
            local value = distanceSq(record, tree.x, tree.y)
            if not selected or value < selectedDistance
                or (value == selectedDistance and key < selected.key)
            then selected, selectedDistance = tree, value end
        end
    end
    if not selected then return nil, "no_tree_available" end
    return selected
end

local WORK_OFFSETS = {
    { x = -1, y = 0 }, { x = 1, y = 0 },
    { x = 0, y = -1 }, { x = 0, y = 1 },
}

function Service.FindApproach(tree, record)
    if not tree then return nil, "tree_missing" end
    local selected
    local selectedDistance
    for index = 1, #WORK_OFFSETS do
        local offset = WORK_OFFSETS[index]
        local x, y, z = tree.x + offset.x, tree.y + offset.y, tree.z
        local square = Service.GetSquare(x, y, z)
        local allowed = square ~= nil
        if allowed and type(square.isFree) == "function" then
            local ok, free = pcall(square.isFree, square, true)
            allowed = ok and free ~= false
        end
        -- Abstract NPCs can travel toward an unloaded approach tile. Live
        -- chopping will revalidate the square before applying a hit.
        if allowed or not square then
            local value = distanceSq(record, x, y)
            if not selected or value < selectedDistance then
                selected = { x = x + 0.5, y = y + 0.5, z = z }
                selectedDistance = value
            end
        end
    end
    return selected, selected and nil or "no_approach_point"
end

function Service.ValidateJob(npcId, jobId)
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    return job ~= nil and tostring(job.id) == tostring(jobId or "")
        and job.active == true and zone ~= nil and zone.enabled == true
        and zone.workers[tostring(npcId)] == true
end

function Service.StartJob(lease)
    local job = Service.GetJob(lease and lease.npcId)
    local record = job and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(job.npcId) or nil
    if not job or not record then return false, "npc_not_found" end
    local currentOrder = type(record.orderSpec) == "table"
        and record.orderSpec or nil
    local currentKind = currentOrder and tostring(currentOrder.kind or "") or ""
    if job.previousOrderCaptured ~= true then
        if currentKind == tostring(Const.ORDER_LUMBER or "lumber")
            and tostring(currentOrder.lumberJobId or "") == tostring(job.id)
        then
            -- A resumed job may already have its lumber order persisted on
            -- the NPC record. Do not mistake that order for the order we
            -- must restore.
            job.previousOrder = nil
        else
            job.previousOrder = copy(currentOrder)
        end
        job.previousOrderCaptured = true
    end
    Service.Runtime.previousOrders[job.npcId] = copy(job.previousOrder)
    job.leaseId = lease.leaseId
    job.executionMode = tostring(lease.executionMode or "ABSTRACT")
    job.state, job.phase = "READY", "WAITING"
    job.revision = (tonumber(job.revision) or 0) + 1
    record.runtime = record.runtime or {}
    record.runtime.lumberJobId = job.id
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, {
            kind = Const.ORDER_LUMBER or "lumber",
            lumberJobId = job.id, zoneId = job.zoneId,
        })
    end
    markDirty()
    return true
end

function Service.RestoreOrder(npcId)
    npcId = tostring(npcId or "")
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local job = Service.GetJob(npcId)
    local previous = Service.Runtime.previousOrders[npcId]
    if previous == nil and job and job.previousOrderCaptured == true then
        previous = job.previousOrder
    end
    local current = record and type(record.orderSpec) == "table"
        and record.orderSpec or nil
    local ownsCurrentOrder = current
        and tostring(current.kind or "")
            == tostring(Const.ORDER_LUMBER or "lumber")
        and job
        and tostring(current.lumberJobId or "") == tostring(job.id)
    if record and ownsCurrentOrder and PNC.OrderSystem
        and PNC.OrderSystem.SetOrder
    then
        -- SetOrder(nil) is supported and normalizes to the NPC's guard order.
        PNC.OrderSystem.SetOrder(record, previous)
    end
    Service.Runtime.previousOrders[npcId] = nil
    if job then
        job.previousOrder = nil
        job.previousOrderCaptured = nil
        markDirty()
    end
    if record and record.runtime then
        record.runtime.lumberJobId = nil
        record.runtime.lumber = nil
    end
end

function Service.CancelJob(npcId, reason)
    local job = Service.GetJob(npcId)
    if not job then return true end
    Service.ReleaseTree(job.targetKey, reason or "job_cancelled")
    job.targetKey = nil
    job.leaseId = nil
    job.state, job.phase = "CANCELLED", "CANCELLED"
    job.revision = (tonumber(job.revision) or 0) + 1
    Service.RestoreOrder(npcId)
    markDirty()
    return true
end

local function updateRuntime(record, job, tree)
    record.runtime = record.runtime or {}
    record.runtime.lumber = {
        jobId = job.id, zoneId = job.zoneId,
        treeKey = tree and tree.key or job.targetKey,
        phase = job.phase, state = job.state,
        remainingWork = tree and tree.remainingWork or nil,
        maxWork = tree and tree.maxWork or nil,
    }
end

local function zoneCenter(zone)
    local bounds = zoneBounds(zone)
    if not bounds then return nil end
    return {
        x = (bounds.minX + bounds.maxX) / 2 + 0.5,
        y = (bounds.minY + bounds.maxY) / 2 + 0.5,
        z = (bounds.minZ + bounds.maxZ) / 2,
    }
end

local function guideToZone(job, zone, record, body)
    local center = zoneCenter(zone)
    if not center then return false, "zone_center_missing" end
    if body then
        local bx = body.getX and body:getX() or record.x
        local by = body.getY and body:getY() or record.y
        local bz = body.getZ and body:getZ() or record.z
        local distance = math.abs((tonumber(bx) or 0) - center.x)
            + math.abs((tonumber(by) or 0) - center.y)
        if distance > 2
            or math.abs((tonumber(bz) or 0) - center.z) > 0.6
        then
            job.state, job.phase = "TRAVELING", "TRAVEL"
            if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
                PNC.BehaviorCommon.MoveRecord(record, body,
                    center.x, center.y, center.z, "walk", 0.7,
                    "lumber_zone")
            end
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
        if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
            PNC.BehaviorCommon.HaltMovement(record, body, "lumber_zone")
        end
        job.state, job.phase = "DISCOVERING", "DISCOVERING"
        updateRuntime(record, job, nil)
        return true, "at_zone"
    end

    if job.zoneArrived == true then
        job.state, job.phase = "DISCOVERING", "DISCOVERING"
        updateRuntime(record, job, nil)
        return true, "at_zone"
    end

    local travel = PNC.Travel and PNC.Travel.Service
    local journey = travel and travel.Get and travel.Get(record) or nil
    if job.zoneTravelId and journey
        and tostring(journey.journeyId) == tostring(job.zoneTravelId)
    then
        if journey.state == "arrived" then
            job.zoneArrived = true
            job.zoneTravelId = nil
            if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
                PNC.OrderSystem.SetOrder(record, {
                    kind = Const.ORDER_LUMBER or "lumber",
                    lumberJobId = job.id, zoneId = job.zoneId,
                })
            end
        else
            job.state, job.phase = "TRAVELING", "TRAVEL"
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
    elseif travel and type(travel.Start) == "function" then
        local started = travel.Start(record, {
            destination = center, routeProvider = "direct",
            speedProfile = "walk", visibility = "all", arrivalAction = false,
            ownerMod = "ProjectHoomans", ownerRef = "lumber_zone",
            metadata = { lumberZoneId = tostring(zone.id) },
        })
        if started then
            job.zoneTravelId = started.journeyId
            job.state, job.phase = "TRAVELING", "TRAVEL"
            updateRuntime(record, job, nil)
            return true, "traveling_to_zone"
        end
    end
    job.state, job.phase = "DISCOVERING", "DISCOVERING"
    updateRuntime(record, job, nil)
    return true, "at_zone"
end

local function resolveAbstractTool(record)
    local runtime = record and record.runtime or {}
    if type(runtime.lumberTool) == "table" then
        local override = runtime.lumberTool
        if override.canChop ~= false then
            return {
                canChop = true,
                treeDamage = math.max(1, tonumber(override.treeDamage) or 10),
                itemID = override.itemID,
                condition = tonumber(override.condition),
            }
        end
        return nil, "tool_cannot_chop"
    end
    local inventory = record and record.inventory
    local item
    if inventory and inventory.equipped and inventory.items then
        item = inventory.items[inventory.equipped.primary]
    end
    local fullType = item and item.type
        or record and record.equipment and record.equipment.primaryFullType
    fullType = tostring(fullType or "")
    local lower = string.lower(fullType)
    if not string.find(lower, "axe", 1, true)
        and not string.find(lower, "hatchet", 1, true)
        and not string.find(lower, "chopper", 1, true)
    then return nil, "lumber_tool_missing" end
    if item and tonumber(item.cond) and tonumber(item.cond) <= 0 then
        return nil, "lumber_tool_broken"
    end
    local damage = string.find(lower, "woodaxe", 1, true)
        and 40 or string.find(lower, "hatchet", 1, true)
        and 15 or 35
    return {
        canChop = true, treeDamage = damage,
        itemID = item and item.id or nil,
        condition = item and tonumber(item.cond) or nil,
    }
end

local function resolveLiveTool(record, body)
    if not body then return nil, "live_body_missing" end
    local item
    if type(body.getPrimaryHandItem) == "function" then
        local ok, value = pcall(body.getPrimaryHandItem, body)
        if ok then item = value end
    end
    if not item and PNC.Equipment and PNC.Equipment.ApplyHands then
        pcall(PNC.Equipment.ApplyHands, body, record)
        if type(body.getPrimaryHandItem) == "function" then
            local ok, value = pcall(body.getPrimaryHandItem, body)
            if ok then item = value end
        end
    end
    if not item then return nil, "lumber_tool_missing" end
    local broken = false
    if type(item.isBroken) == "function" then
        local ok, value = pcall(item.isBroken, item)
        broken = ok and value == true
    end
    if broken then return nil, "lumber_tool_broken" end
    local tagged = false
    if ItemTag and type(item.hasTag) == "function" then
        local ok, value = pcall(item.hasTag, item, ItemTag.CHOP_TREE)
        tagged = ok and value == true
    end
    local damage
    if type(item.getTreeDamage) == "function" then
        local ok, value = pcall(item.getTreeDamage, item)
        if ok then damage = tonumber(value) end
    end
    if not tagged and not damage then return nil, "tool_cannot_chop" end
    return { item = item, canChop = true, treeDamage = math.max(1, damage or 10) }
end

local function skillRate(record)
    local level = 0
    if PNC.Skills and type(PNC.Skills.GetLevel) == "function" then
        local ok, value = pcall(PNC.Skills.GetLevel, record, "Axe")
        if ok then level = math.max(0, tonumber(value) or 0) end
    end
    return 1 + math.min(0.75, level * 0.05)
end

local function adjacentToTree(body, tree)
    if not body or not tree then return false end
    local x = type(body.getX) == "function" and body:getX() or nil
    local y = type(body.getY) == "function" and body:getY() or nil
    local z = type(body.getZ) == "function" and body:getZ() or nil
    return x and y and z and math.abs(z - tree.z) < 0.6
        and math.abs(x - (tree.x + 0.5)) <= 1.2
        and math.abs(y - (tree.y + 0.5)) <= 1.2
end

local function faceTree(body, tree)
    if body and tree and type(body.faceLocationF) == "function" then
        pcall(body.faceLocationF, body, tree.x + 0.5, tree.y + 0.5)
    end
end

local function beginChopAnimation(record, body)
    if PNC.AnimationScenes and type(PNC.AnimationScenes.Request) == "function"
        and body
    then
        local scene = record.runtime and record.runtime.animationScene
        if not scene or scene.id ~= "lumber.chop" then
            pcall(PNC.AnimationScenes.Request, record, body, "lumber.chop", {
                reason = "lumber_chop", repeatMode = "loop",
            })
        end
    end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", true)
    end
end

local function stopChopAnimation(record, body)
    local scene = record and record.runtime and record.runtime.animationScene
    if scene and scene.id == "lumber.chop"
        and PNC.AnimationScenes and PNC.AnimationScenes.Stop
    then pcall(PNC.AnimationScenes.Stop, record, body, "lumber_stopped") end
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, "PNCLumbering", false)
    end
end

local function tickLive(job, record, body, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not actual then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_missing"
    end
    if tree.signature ~= treeSignature(actual) then
        tree.status = "INVALID"
        Service.Runtime.claims[tree.key] = nil
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        markDirty()
        return true, false, "tree_replaced"
    end
    local approach = job.approach
    if not approach then
        approach = Service.FindApproach(tree, record)
        job.approach = approach
    end
    if not approach then
        Service.ReleaseTree(tree.key, "no_approach")
        job.targetKey, job.approach = nil, nil
        job.state, job.phase = "READY", "BLOCKED"
        return true, false, "no_approach_point"
    end
    local bx = body and body.getX and body:getX() or record.x
    local by = body and body.getY and body:getY() or record.y
    local bz = body and body.getZ and body:getZ() or record.z
    local distance = math.abs((tonumber(bx) or 0) - approach.x)
        + math.abs((tonumber(by) or 0) - approach.y)
    if distance > 1.0 or math.abs((tonumber(bz) or 0) - approach.z) > 0.6 then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        if PNC.BehaviorCommon and PNC.BehaviorCommon.MoveRecord then
            PNC.BehaviorCommon.MoveRecord(record, body,
                approach.x, approach.y, approach.z, "walk", 0.7, "lumber")
        end
        updateRuntime(record, job, tree)
        return true, false, "traveling"
    end
    if not adjacentToTree(body, tree) then
        job.state, job.phase = "TRAVELING", "TRAVEL"
        return true, false, "not_adjacent"
    end
    if PNC.BehaviorCommon and PNC.BehaviorCommon.HaltMovement then
        PNC.BehaviorCommon.HaltMovement(record, body, "lumber_chop")
    end
    faceTree(body, tree)
    local tool, toolReason = resolveLiveTool(record, body)
    if not tool then
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    if type(body.isEnduranceSufficientForAction) == "function" then
        local ok, enough = pcall(body.isEnduranceSufficientForAction, body)
        if ok and enough == false then
            job.state, job.phase = "WAITING", "WAITING_FOR_ENDURANCE"
            updateRuntime(record, job, tree)
            return true, false, "endurance"
        end
    end
    beginChopAnimation(record, body)
    job.state, job.phase = "WORKING", "CHOPPING"
    local lastHit = tonumber(job.lastHitAt) or 0
    if at - lastHit >= Service.HIT_INTERVAL_MS then
        local ok, result = pcall(actual.WeaponHit, actual, body, tool.item)
        if not ok then
            stopChopAnimation(record, body)
            job.state, job.phase = "FAILED", "FAILED"
            return false, false, tostring(result)
        end
        job.lastHitAt = at
        if type(actual.getHealth) == "function" then
            local healthOK, health = pcall(actual.getHealth, actual)
            if healthOK and tonumber(health) then
                tree.remainingWork = math.max(0, tonumber(health))
            end
        end
        tree.revision = (tonumber(tree.revision) or 0) + 1
        markDirty()
    end
    local stillThere = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if not stillThere or tonumber(tree.remainingWork) <= 0 then
        stopChopAnimation(record, body)
        Service.CompleteTree(tree.key, "live")
        job.targetKey, job.approach, job.lastHitAt = nil, nil, nil
        job.state, job.phase = "READY", "RECONCILING"
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_vanilla_output"
    end
    updateRuntime(record, job, tree)
    return true, false, "chopping"
end

local function updateAbstractToolWear(record, job, tool)
    if not tool.itemID or not tool.condition then return end
    job.toolHitCount = (tonumber(job.toolHitCount) or 0) + 1
    if job.toolHitCount < Service.ABSTRACT_TOOL_HITS_PER_CONDITION then return end
    job.toolHitCount = 0
    if PNC.Inventory and type(PNC.Inventory.ApplyDelta) == "function" then
        local condition = math.max(0, tool.condition - 1)
        pcall(PNC.Inventory.ApplyDelta, record, {
            { op = "update", itemID = tool.itemID, cond = condition },
        }, "lumber_tool_wear")
    end
end

local function flushAbstractOutput(job, record)
    local output = job.pendingOutput
    if not output then return true end
    if PNC.Inventory and type(PNC.Inventory.AddItems) == "function" then
        local ok = PNC.Inventory.AddItems(record, {
            { type = output.fullType, stack = output.quantity },
        }, "root", "lumber_abstract_output")
        if ok then job.pendingOutput = nil; return true end
    end
    return false
end

local function tickAbstract(job, record, tree, at)
    local actual, square = Service.GetTreeAt(tree.x, tree.y, tree.z)
    if square then
        if not actual then
            -- A player or another authoritative system may have removed the
            -- tree while this worker was abstracted. Treat it as consumed by
            -- the world, never generate a second log reward.
            tree.status = "INVALID"
            Service.Runtime.claims[tree.key] = nil
            job.targetKey, job.approach = nil, nil
            job.state, job.phase = "READY", "RECONCILING"
            markDirty()
            updateRuntime(record, job, nil)
            return true, false, "physical_tree_missing"
        end
        -- A loaded physical tree is authoritative. Wait for materialization
        -- instead of silently deleting a tree that a player can observe.
        job.state, job.phase = "WAITING", "WAITING_FOR_MATERIALIZATION"
        updateRuntime(record, job, tree)
        return true, false, "loaded_tree_requires_live_execution"
    end
    local tool, toolReason = resolveAbstractTool(record)
    if not tool then
        job.state, job.phase = "WAITING", "WAITING_FOR_TOOL"
        updateRuntime(record, job, tree)
        return true, false, toolReason
    end
    local previous = tonumber(job.lastProgressAt) or at
    local elapsed = math.max(0, math.min(Service.ABSTRACT_MAX_ELAPSED_MS,
        at - previous))
    job.lastProgressAt = at
    local damage = (tool.treeDamage / (Service.HIT_INTERVAL_MS / 1000))
        * (elapsed / 1000) * skillRate(record)
    tree.remainingWork = math.max(0,
        (tonumber(tree.remainingWork) or tree.maxWork) - damage)
    job.state, job.phase = "WORKING", "CHOPPING"
    updateAbstractToolWear(record, job, tool)
    markDirty()
    if tree.remainingWork <= 0 then
        Service.CompleteTree(tree.key, "abstract")
        job.pendingOutput = {
            fullType = "Base.Log", quantity = tree.logYield,
        }
        job.targetKey = nil
        job.approach = nil
        job.lastProgressAt = at
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        if flushAbstractOutput(job, record) then
            job.state, job.phase = "READY", "OUTPUT_DELIVERED"
        end
        updateRuntime(record, job, nil)
        return true, false, "tree_depleted_abstract_output"
    end
    return true, false, actual and "physical_tree_appeared" or "abstract_chopping"
end

function Service.TickJob(lease)
    local npcId = tostring(lease and lease.npcId or "")
    local job = Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not job or not zone or not record or job.active ~= true
        or zone.enabled ~= true
    then return false, false, "job_unavailable" end
    local at = now()
    expireClaims(at)
    if job.pendingOutput and not flushAbstractOutput(job, record) then
        job.state, job.phase = "WAITING", "OUTPUT_PENDING"
        updateRuntime(record, job, nil)
        return true, false, "output_pending"
    end
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    lease.executionMode = body and "LIVE" or "ABSTRACT"
    job.executionMode = lease.executionMode
    local tree = job.targetKey and Service.GetTree(job.targetKey) or nil
    if not tree or tree.status == "DEPLETED" or tree.status == "INVALID" then
        tree = nil
        job.targetKey, job.approach = nil, nil
    end
    if not tree then
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey = tree.key
            job.approach = nil
            job.lastHitAt = nil
            job.lastProgressAt = at
            job.revision = (tonumber(job.revision) or 0) + 1
        end
    end
    if tree and not ensureTreeClaim(tree.key, npcId, at) then
        tree = nil
        job.targetKey, job.approach = nil, nil
        tree = selectClaimedTarget(npcId, at)
        if tree then
            job.targetKey, job.approach = tree.key, nil
            job.lastHitAt, job.lastProgressAt = nil, at
        end
    end
    if not tree then
        local pendingScan = zone.scan.complete ~= true
        if pendingScan then
            guideToZone(job, zone, record, body)
            return true, false, "scanning"
        end
        job.state, job.phase = "COMPLETED", "COMPLETE"
        updateRuntime(record, job, nil)
        return true, true, "zone_exhausted"
    end
    if body then return tickLive(job, record, body, tree, at) end
    return tickAbstract(job, record, tree, at)
end

function Service.GetSnapshot(zoneId)
    local zone = Service.GetZone(zoneId)
    if not zone then return nil end
    local available, inProgress, depleted = 0, 0, 0
    for index = 1, #(zone.treeKeys or {}) do
        local tree = Service.Data.trees[zone.treeKeys[index]]
        if tree then
            if tree.status == "DEPLETED" then depleted = depleted + 1
            elseif tree.status == "IN_PROGRESS" then inProgress = inProgress + 1
            elseif tree.status ~= "INVALID" then available = available + 1 end
        end
    end
    local workers = {}
    for npcId, _ in pairs(zone.workers or {}) do
        local job = Service.GetJob(npcId)
        workers[#workers + 1] = {
            npcId = npcId, jobId = job and job.id or nil,
            state = job and job.state or "MISSING",
            phase = job and job.phase or "MISSING",
            treeKey = job and job.targetKey or nil,
        }
    end
    return {
        id = zone.id, revision = zone.revision, enabled = zone.enabled,
        bounds = copy(zone.bounds), geometry = copy(zone.geometry),
        scan = copy(zone.scan),
        discovered = #(zone.treeKeys or {}), available = available,
        inProgress = inProgress, depleted = depleted, workers = workers,
    }
end

function Service.Pump(at)
    if not Service.Loaded then Service.Load(true) end
    at = tonumber(at) or now()
    if at < (tonumber(Service.Runtime.nextPumpAt) or 0) then return 0 end
    Service.Runtime.nextPumpAt = at + Service.SCAN_INTERVAL_MS
    expireClaims(at)
    local data = ensureData()
    local processed = 0
    local count = #data.zoneOrder
    if count > 0 then
        for _ = 1, Service.SCAN_ZONES_PER_PUMP do
            Service.Runtime.zoneCursor =
                (Service.Runtime.zoneCursor % count) + 1
            local zone = data.zones[data.zoneOrder[Service.Runtime.zoneCursor]]
            if zone and zone.enabled and not zone.scan.complete then
                Service.ScanZone(zone.id, Service.SCAN_TILES_PER_PUMP)
                processed = processed + 1
            end
        end
    end
    if Service.Dirty and at - Service.LastSaveAt >= 5000 then
        Service.Save()
    end
    return processed
end

if Events and Events.OnInitGlobalModData and not Service.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Service.Load(true) end)
    Service.LoadHookRegistered = true
end
if Events and Events.OnSave and not Service.SaveHookRegistered then
    Events.OnSave.Add(function() Service.Save() end)
    Service.SaveHookRegistered = true
end
if Events and Events.LoadGridsquare and not Service.LoadSquareHookRegistered then
    Events.LoadGridsquare.Add(function(square)
        if not Service.Loaded then Service.Load(true) end
        reconcileLoadedSquare(square)
    end)
    Service.LoadSquareHookRegistered = true
end

return Service
