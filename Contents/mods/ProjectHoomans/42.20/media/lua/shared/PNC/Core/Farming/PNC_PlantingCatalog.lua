PNC = PNC or {}
PNC.FarmingCatalog = PNC.FarmingCatalog or {}

local Catalog = PNC.FarmingCatalog
local cache

local function safeText(key, fallback)
    if type(getText) ~= "function" then return fallback end
    local value = getText(key)
    if value and value ~= key then return tostring(value) end
    return fallback
end

local function seedTypes(props)
    local output = {}
    local source = props and props.seedTypes
    if type(source) ~= "table" then
        source = props and props.seedName and { props.seedName } or {}
    end
    for _, value in ipairs(source) do
        value = tostring(value or "")
        if value ~= "" then output[#output + 1] = value end
    end
    return output
end

local function copyList(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    for index, entry in ipairs(value) do output[index] = entry end
    return output
end

local function firstNumber(props, keys)
    for _, key in ipairs(keys) do
        local value = tonumber(props and props[key])
        if value ~= nil then return value end
    end
    return nil
end

local function titleFallback(value)
    value = tostring(value or "")
    value = string.gsub(value, "[_%-]+", " ")
    local first = string.sub(value, 1, 1)
    if first == "" then return value end
    return string.upper(first) .. string.sub(value, 2)
end

local function build()
    local output, byId = {}, {}
    local props = farming_vegetableconf and farming_vegetableconf.props or {}
    for id, value in pairs(props) do
        if type(value) == "table" then
            local typeOfSeed = tostring(id)
            local crop = string.lower(typeOfSeed)
            local types = seedTypes(value)
            if crop ~= "" and #types > 0 then
                local display = tostring(value.displayName or value.name
                    or titleFallback(typeOfSeed))
                display = safeText("Farming_" .. typeOfSeed, display)
                local entry = {
                    id = crop,
                    typeOfSeed = typeOfSeed,
                    displayNameKey = "Farming_" .. typeOfSeed,
                    displayName = display,
                    seedTypes = types,
                    seedName = value.seedName,
                    icon = value.icon,
                    texture = value.texture,
                    vegetableName = value.vegetableName,
                    growBack = value.growBack == true,
                    sowMonth = copyList(value.sowMonth),
                    badMonth = copyList(value.badMonth),
                    bestMonth = copyList(value.bestMonth),
                    riskMonth = copyList(value.riskMonth),
                    coldHardy = value.coldHardy == true,
                    minTemperature = firstNumber(value, {
                        "minTemperature", "minTemp", "temperatureMin",
                    }),
                    maxTemperature = firstNumber(value, {
                        "maxTemperature", "maxTemp", "temperatureMax",
                    }),
                    timeToGrow = tonumber(value.timeToGrow),
                    waterLvl = tonumber(value.waterLvl),
                    mature = tonumber(value.mature),
                    fullGrown = tonumber(value.fullGrown),
                    harvestLevel = tonumber(value.harvestLevel),
                }
                output[#output + 1] = entry
                byId[crop] = entry
            end
        end
    end
    table.sort(output, function(a, b)
        return tostring(a.displayName) < tostring(b.displayName)
    end)
    return output, byId
end

function Catalog.Refresh()
    local list, byId = build()
    cache = { list = list, byId = byId }
    return list
end

local function ensure()
    if not cache then Catalog.Refresh() end
    return cache
end

function Catalog.Get(crop)
    local key = string.lower(tostring(crop or ""))
    local entry = ensure().byId[key]
    if not entry then
        Catalog.Refresh()
        entry = cache.byId[key]
    end
    return entry
end

function Catalog.List()
    local output = {}
    for index, value in ipairs(ensure().list) do
        output[index] = PNC.Core and PNC.Core.DeepCopy
            and PNC.Core.DeepCopy(value) or value
    end
    return output
end

function Catalog.InventoryCounts(storage)
    local counts = {}
    for _, row in ipairs(storage and storage.rows or {}) do
        local fullType = string.lower(tostring(row.fullType or ""))
        local quantity = math.max(0, math.floor(tonumber(row.quantity) or 0))
        if fullType ~= "" and quantity > 0 then
            counts[fullType] = (counts[fullType] or 0) + quantity
        end
    end
    return counts
end

function Catalog.ListPlantable(storage)
    local counts = Catalog.InventoryCounts(storage)
    local output = {}
    for _, entry in ipairs(ensure().list) do
        local seedCount = 0
        for _, seedType in ipairs(entry.seedTypes or {}) do
            seedCount = seedCount + (counts[string.lower(tostring(seedType))] or 0)
        end
        if seedCount > 0 then
            local copy = PNC.Core and PNC.Core.DeepCopy
                and PNC.Core.DeepCopy(entry) or entry
            copy.seedCount = seedCount
            output[#output + 1] = copy
        end
    end
    return output
end

function Catalog.Resolve(crop)
    local entry = Catalog.Get(crop)
    if not entry then return nil, "UNKNOWN_CROP" end
    return entry
end

return Catalog
