if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StockpileAccessService = PNC.StockpileAccessService or {}

local Service = PNC.StockpileAccessService
local Repository = PNC.SettlementRepository
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function numericKeys(source)
    local keys = {}
    for key, _ in pairs(type(source) == "table" and source or {}) do
        local number = tonumber(key)
        if number then keys[#keys + 1] = number end
    end
    table.sort(keys)
    return keys
end

local function regionRows(level)
    return type(level) == "table" and (level.rows or level) or nil
end

local function baseGeometry(base)
    local zone = base and base.baseZoneId and Zones.get(base.baseZoneId) or nil
    return zone and zone.geometry or nil
end

local function isInsideBase(base, x, y, z)
    local geometry = baseGeometry(base)
    if not geometry then return false end
    if GridRegion.containsPoint then
        return GridRegion.containsPoint(geometry, x, y, z)
    end
    return GridRegion.containsXY(geometry, x, y)
end

local function squareState(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return "unknown"
    end
    local ok, square = pcall(cell.getGridSquare, cell, math.floor(x),
        math.floor(y), math.floor(z))
    if not ok or not square then return "unloaded" end

    local pathInternal = PNC.PathService and PNC.PathService.Internal
    if pathInternal and pathInternal.isSquareWalkable then
        local checked, walkable = pcall(pathInternal.isSquareWalkable,
            x, y, z)
        if checked then return walkable == true and "walkable" or "blocked" end
    end
    if type(square.isSolid) == "function" then
        local checked, solid = pcall(square.isSolid, square)
        if checked and solid == true then return "blocked" end
    end
    if type(square.isSolidTrans) == "function" then
        local checked, solid = pcall(square.isSolidTrans, square)
        if checked and solid == true then return "blocked" end
    end
    if type(square.isFree) == "function" then
        local checked, free = pcall(square.isFree, square, false)
        if checked then return free == true and "walkable" or "blocked" end
    end
    return "walkable"
end

local function accessPoint(region, base, preferredX, preferredY, preferredZ,
    requireLoaded, allowOutsideBase)
    local best, deferred, seen = nil, nil, {}
    local bestDistance, deferredDistance

    local function consider(x, y, z)
        x, y, z = tonumber(x), tonumber(y), tonumber(z)
        if not x or not y or not z
            or (allowOutsideBase ~= true and not isInsideBase(base, x, y, z))
        then
            return
        end
        local key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
        if seen[key] then return end
        seen[key] = true
        local state = squareState(x, y, z)
        if state == "blocked" or requireLoaded and state ~= "walkable" then
            return
        end
        local dx = x - (tonumber(preferredX) or x)
        local dy = y - (tonumber(preferredY) or y)
        local dz = z - (tonumber(preferredZ) or z)
        local distance = dx * dx + dy * dy + dz * dz
        local point = { x = x, y = y, z = z }
        if state == "walkable"
            and (not best or distance < bestDistance)
        then
            best, bestDistance = point, distance
        elseif state ~= "walkable"
            and (not deferred or distance < deferredDistance)
        then
            deferred, deferredDistance = point, distance
        end
    end

    local levels = type(region) == "table" and region.levels or {}
    for _, z in ipairs(numericKeys(levels)) do
        local rows = regionRows(levels[z])
        for _, y in ipairs(numericKeys(rows)) do
            local spans = rows[y]
            for index = 1, #(spans or {}), 2 do
                local first, last = tonumber(spans[index]),
                    tonumber(spans[index + 1])
                if first and last and first <= last then
                    for x = first, last do consider(x, y, z) end
                end
            end
        end
    end

    -- A stockpile tile can be occupied by an item/container. In that case
    -- target a nearby access tile while retaining the stockpile node identity.
    for _, z in ipairs(numericKeys(levels)) do
        local rows = regionRows(levels[z])
        for _, y in ipairs(numericKeys(rows)) do
            local spans = rows[y]
            for index = 1, #(spans or {}), 2 do
                local first, last = tonumber(spans[index]),
                    tonumber(spans[index + 1])
                if first and last and first <= last then
                    for x = first, last do
                        consider(x + 1, y, z)
                        consider(x - 1, y, z)
                        consider(x, y + 1, z)
                        consider(x, y - 1, z)
                    end
                end
            end
        end
    end
    return best or deferred
end

local function validStoredNode(base, node, requireLoaded)
    if not node or not isInsideBase(base, node.x, node.y, node.z) then
        return false
    end
    local state = squareState(node.x, node.y, node.z)
    return state ~= "blocked"
        and (not requireLoaded or state == "walkable")
end

local function facilityNode(base, facility, preferredX, preferredY, preferredZ,
    requireLoaded)
    if not facility or facility.definitionId ~= "stockpile"
        or (facility.constructionState ~= "BUILT"
            and facility.constructionState ~= "RECONSTRUCTING")
    then return nil end
    local region
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true and Repository.GetComponent(componentId)
            or nil
        if component and component.role == "storage.stockpile" then
            region = component.region
            break
        end
    end
    local point = accessPoint(region or facility.constructionRegion, base,
        preferredX, preferredY, preferredZ, requireLoaded, true)
    if not point then return nil end
    return { schemaVersion = 1, id = "facility:" .. tostring(facility.id),
        facilityId = facility.id, baseId = base.id, region = region,
        x = point.x, y = point.y, z = point.z, radius = 2, revision = 0 }
end

function Service.Create(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService.Get(args.baseId)
    if not base then return { ok = false, reason = "BASE_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    if args.expectedRevision ~= nil and tonumber(args.expectedRevision) ~= base.revision then
        return { ok = false, reason = "REVISION_CONFLICT", revision = base.revision }
    end
    local x, y, z = math.floor(tonumber(args.x) or 0),
        math.floor(tonumber(args.y) or 0), math.floor(tonumber(args.z) or 0)
    local zone = Zones.get(base.baseZoneId)
    if not zone or not GridRegion.containsXY(zone.geometry, x, y) then
        return { ok = false, reason = "OUTSIDE_BASE" }
    end
    if squareState(x, y, z) == "blocked" then
        return { ok = false, reason = "INVALID_ACCESS_POINT" }
    end
    local id = tostring(args.nodeId or PNC.Core.GenerateID("stockpile_node"))
    local node = { schemaVersion = 1, id = id, baseId = base.id,
        storageId = args.storageId and tostring(args.storageId) or nil,
        x = x, y = y, z = z, radius = math.max(1, tonumber(args.radius) or 2), revision = 0 }
    Repository.State.stockpileNodes[id] = node
    base.stockpileNodeIds[id] = true
    base.revision = base.revision + 1
    Repository.MarkDirty()
    if EventsBus and EventsBus.emit then EventsBus.emit(PNC.EventTypes.STOCKPILE_NODE_CHANGED,
        { baseId = base.id, nodeId = id, operation = "ADD" }) end
    return { ok = true, node = node, event = "StockpileAccessNodeAdded" }
end

function Service.AttachModData(object, nodeId)
    local node = Repository.GetStockpileNode(nodeId)
    if not node or not object or not object.getModData then return false, "INVALID_TARGET" end
    local data = object:getModData()
    data.PNC = { type = "stockpileAccess", nodeId = node.id, baseId = node.baseId }
    if object.transmitModData then object:transmitModData() end
    return true, data.PNC
end

function Service.ResolveObject(object)
    local data = object and object.getModData and object:getModData() or nil
    local identity = data and data.PNC or nil
    if type(identity) ~= "table" or identity.type ~= "stockpileAccess" then return nil end
    return Repository.GetStockpileNode(identity.nodeId)
end

function Service.Remove(player, args)
    args = type(args) == "table" and args or {}
    local node = Repository.GetStockpileNode(args.nodeId)
    local base = node and PNC.BaseService.Get(node.baseId) or nil
    if not base then return { ok = false, reason = "STOCKPILE_NODE_NOT_FOUND" } end
    if not PNC.BaseValidationService.CanUse(player, base) then return { ok = false, reason = "NO_PERMISSION" } end
    Repository.State.stockpileNodes[node.id] = nil
    base.stockpileNodeIds[node.id] = nil
    base.revision = base.revision + 1
    Repository.MarkDirty()
    if EventsBus and EventsBus.emit then EventsBus.emit(PNC.EventTypes.STOCKPILE_NODE_CHANGED,
        { baseId = base.id, nodeId = node.id, operation = "REMOVE" }) end
    return { ok = true, event = "StockpileAccessNodeRemoved" }
end

function Service.FindNearest(baseId, x, y, z, options)
    options = type(options) == "table" and options or {}
    local base = PNC.BaseService.Get(baseId)
    local best, bestDistance
    for id, _ in pairs(base and base.stockpileNodeIds or {}) do
        local node = Repository.GetStockpileNode(id)
        if validStoredNode(base, node, options.requireLoaded == true) then
            local dx, dy, dz = node.x - x, node.y - y, node.z - z
            local distance = dx * dx + dy * dy + dz * dz
            if not bestDistance or distance < bestDistance then best, bestDistance = node, distance end
        end
    end
    for facilityId, present in pairs(base and base.facilityIds or {}) do
        local node = present == true and facilityNode(
            base, Repository.GetFacility(facilityId), x, y, z,
            options.requireLoaded == true) or nil
        if node then
            local dx, dy, dz = node.x - x, node.y - y, node.z - z
            local distance = dx * dx + dy * dy + dz * dz
            if not bestDistance or distance < bestDistance then
                best, bestDistance = node, distance
            end
        end
    end
    return best
end

-- Returns the persisted storage region for a built stockpile facility. This
-- is intentionally separate from the access node: access is a navigation
-- concern, while corpse drops must land on a tile contained by the region.
function Service.GetFacilityRegion(facilityId)
    local facility = Repository.GetFacility(facilityId)
    if not facility or facility.definitionId ~= "stockpile" then return nil end
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true
            and Repository.GetComponent(componentId) or nil
        if component and component.role == "storage.stockpile" then
            return component.region, facility, component
        end
    end
    return nil
end

function Service.ContainsFacilityRegionTile(facilityId, x, y, z)
    local region = Service.GetFacilityRegion(facilityId)
    if not region or not GridRegion.containsPoint then return false end
    return GridRegion.containsPoint(region, math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0), math.floor(tonumber(z) or 0)) == true
end

function Service.HasArrived(nodeOrId, x, y, z)
    local node = type(nodeOrId) == "table" and nodeOrId
        or Repository.GetStockpileNode(nodeOrId)
    if not node or math.floor(tonumber(z) or 0) ~= node.z then return false end
    local dx, dy = node.x - x, node.y - y
    return dx * dx + dy * dy <= node.radius * node.radius
end

function Service.ResolveAbstractTransfer(baseId, callback)
    if not PNC.BaseService.Get(baseId) then return false, "BASE_NOT_FOUND" end
    if type(callback) ~= "function" then return false, "INVALID_TRANSFER" end
    return callback()
end

return Service
