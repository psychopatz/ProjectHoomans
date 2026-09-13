PNC = PNC or {}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"
local QueueCollision = require
    "PNC/Core/Settlement/PNC_BuildingQueueCollision"
local Policy = {}

local function currentSnapshot()
    local network = PNC.Network
    local state = network and network.ClientState or nil
    local snapshot = state and state.colonyManagement or nil
    return type(snapshot) == "table" and snapshot or nil
end

local function currentSettlement()
    local snapshot = currentSnapshot()
    return snapshot and snapshot.settlement or nil
end

local function nativeObjectInfoFor(blueprint)
    local catalog = PNC.BuildRecipeCatalog
    local descriptor = catalog and catalog.Get and blueprint
        and catalog.Get(blueprint.objectInfoName) or nil
    local info = descriptor and descriptor.nativeObjectInfo or nil
    if not info and SpriteConfigManager
        and SpriteConfigManager.GetObjectInfo and blueprint
    then
        local ok, resolved = pcall(SpriteConfigManager.GetObjectInfo,
            blueprint.objectInfoName)
        info = ok and resolved or nil
    end
    return info
end

local function currentQueue()
    local snapshot = currentSnapshot()
    local building = snapshot and snapshot.building or nil
    return building and building.queue or {}
end

local function pointFromSquare(square)
    if not square then return nil end
    local function read(method)
        if type(square[method]) ~= "function" then return nil end
        local ok, value = pcall(square[method], square)
        return ok and tonumber(value) or nil
    end
    local x, y, z = read("getX"), read("getY"), read("getZ")
    if not x or not y or not z then return nil end
    return x, y, z
end

-- BuildingService validates the blueprint anchor against the base's XY
-- territory. Keep the client preview aligned with that authoritative rule;
-- the server remains the final authority if the snapshot is stale.
function Policy.IsPointInsideBase(settlement, x, y, z)
    local geometry = settlement and settlement.geometry
    local region = geometry and geometry.region or nil
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not region or not x or not y then return false end
    if GridRegion.containsXY then
        return GridRegion.containsXY(region, math.floor(x), math.floor(y))
            == true
    end
    if GridRegion.containsPoint and z then
        return GridRegion.containsPoint(region, math.floor(x), math.floor(y),
            math.floor(z)) == true
    end
    return false
end

function Policy.ValidatePoint(settlement, x, y, z)
    if not settlement then return false, "BUILD_BASE_UNAVAILABLE" end
    if not tonumber(x) or not tonumber(y) or not tonumber(z) then
        return false, "BUILD_TARGET_REQUIRED"
    end
    if not Policy.IsPointInsideBase(settlement, x, y, z) then
        return false, "BUILD_TARGET_OUTSIDE_BASE"
    end
    return true
end

function Policy.ValidateSquare(settlement, square)
    local x, y, z = pointFromSquare(square)
    return Policy.ValidatePoint(settlement, x, y, z)
end

local function addInvalidTile(levels, x, y, z)
    levels[z] = levels[z] or { rows = {} }
    local row = levels[z].rows[y] or {}
    row[#row + 1], row[#row + 2] = x, x
    levels[z].rows[y] = row
end

-- Validate every occupied tile, not only the blueprint anchor. The returned
-- invalid region is used by the placement preview to tint the offending tiles
-- without changing any persistent/freestyle zone overlay state.
function Policy.ValidateFootprint(settlement, region, queue)
    if not settlement then return false, "BUILD_BASE_UNAVAILABLE", nil, nil end
    if type(region) ~= "table" then
        return false, "BUILD_TARGET_REQUIRED", nil, nil
    end

    local normalized = GridRegion.normalize(region)
    if GridRegion.countTiles(normalized) <= 0 then
        return false, "BUILD_TARGET_REQUIRED", normalized, nil
    end

    local invalidLevels = {}
    local valid = true
    Footprint.ForEachTile(normalized, function(x, y, z)
        if not Policy.IsPointInsideBase(settlement, x, y, z) then
            valid = false
            addInvalidTile(invalidLevels, x, y, z)
        end
        return true
    end)
    local invalid = GridRegion.normalize({ levels = invalidLevels })
    if not valid then
        return false, "BUILD_TARGET_OUTSIDE_BASE", normalized, invalid
    end
    local conflictingOrder, collision = QueueCollision.Find(normalized,
        queue or currentQueue(), nativeObjectInfoFor)
    if conflictingOrder then
        return false, "BUILD_TARGET_ALREADY_QUEUED", normalized, collision,
            conflictingOrder
    end
    return true, nil, normalized, nil
end

function Policy.CurrentSettlement()
    return currentSettlement()
end

function Policy.CurrentQueue()
    return currentQueue()
end

function Policy.ValidateCurrentPoint(x, y, z)
    return Policy.ValidatePoint(currentSettlement(), x, y, z)
end

function Policy.ValidateCurrentSquare(square)
    return Policy.ValidateSquare(currentSettlement(), square)
end

function Policy.ValidateCurrentFootprint(region, queue)
    return Policy.ValidateFootprint(currentSettlement(), region, queue)
end

return Policy
