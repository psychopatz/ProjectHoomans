-- Bounded Project Zomboid object and collection access for camp-site geometry.
local Geometry = PNC and PNC.Semantics and PNC.Semantics.CampSiteGeometry
local Internal = Geometry and Geometry.Internal
if type(Internal) ~= "table" then
    error("camp-site geometry runtime access requires its entry module")
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function field(object, name)
    if not object then return nil end
    local ok, value = pcall(function() return object[name] end)
    return ok and value or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function listSize(list)
    local size = number(call(list, "size"))
    if size ~= nil then return math.max(0, math.floor(size)) end
    if type(list) == "table" then return #list end
    return 0
end

local function listItem(list, index)
    local value = call(list, "get", index)
    if value ~= nil then return value end
    if type(list) == "table" then return list[index + 1] end
    return nil
end

local function values(list, maximum)
    local output = {}
    local size = math.min(listSize(list), tonumber(maximum) or 512)
    for index = 0, size - 1 do
        local value = listItem(list, index)
        if value then output[#output + 1] = value end
    end
    return output
end

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ")) or 0
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function cellFor(options)
    options = type(options) == "table" and options or {}
    if options.cell then return options.cell end
    if type(getCell) == "function" then
        local ok, cell = pcall(getCell)
        if ok then return cell end
    end
    return nil
end

function Geometry.GetSquare(cell, x, y, z)
    cell = cell or cellFor()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ix = number(x)
    local iy = number(y)
    local iz = number(z) or 0
    if ix == nil or iy == nil then return nil end
    local ok, square = pcall(cell.getGridSquare, cell,
        math.floor(ix), math.floor(iy), math.floor(iz))
    return ok and square or nil
end


Internal.Call = call
Internal.Field = field
Internal.Number = number
Internal.Text = text
Internal.ListSize = listSize
Internal.ListItem = listItem
Internal.Values = values
Internal.Position = position
Internal.CellFor = cellFor
return Geometry
