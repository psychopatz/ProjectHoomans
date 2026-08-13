if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StockpileAccessService = PNC.StockpileAccessService or {}

local Service = PNC.StockpileAccessService
local Repository = PNC.SettlementRepository
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

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

function Service.FindNearest(baseId, x, y, z)
    local base = PNC.BaseService.Get(baseId)
    local best, bestDistance
    for id, _ in pairs(base and base.stockpileNodeIds or {}) do
        local node = Repository.GetStockpileNode(id)
        if node then
            local dx, dy, dz = node.x - x, node.y - y, node.z - z
            local distance = dx * dx + dy * dy + dz * dz
            if not bestDistance or distance < bestDistance then best, bestDistance = node, distance end
        end
    end
    return best
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
