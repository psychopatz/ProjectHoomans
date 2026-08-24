-- Shared Project Zomboid farming engine and tile primitives.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}
PNC.PZFarmingAdapter.Internal = PNC.PZFarmingAdapter.Internal or {}

local Adapter = PNC.PZFarmingAdapter
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog
local Research = PNC.FarmingResearch

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    return fn(object, ...)
end

local function farmingSystem()
    return SFarmingSystem and SFarmingSystem.instance or nil
end

local function squareAt(x, y, z)
    local cell = getCell and getCell() or nil
    return cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
        or nil
end

function Adapter.GetPlantAt(x, y, z)
    local system = farmingSystem()
    if not system or type(system.getLuaObjectAt) ~= "function" then
        return nil, "FARMING_SYSTEM_UNAVAILABLE"
    end
    return system:getLuaObjectAt(math.floor(x), math.floor(y), math.floor(z))
end

local function eachTile(component, visitor)
    local valid, reason, info = Farming.RectangleInfo(component and component.region)
    if not valid then return false, reason end
    for y = info.minY, info.maxY do
        for x = info.minX, info.maxX do
            local ok, value = visitor(x, y, info.z)
            if ok == false then return false, value end
        end
    end
    return true
end

local Internal = Adapter.Internal
Internal.Call = call
Internal.FarmingSystem = farmingSystem
Internal.SquareAt = squareAt
Internal.EachTile = eachTile

return Internal
