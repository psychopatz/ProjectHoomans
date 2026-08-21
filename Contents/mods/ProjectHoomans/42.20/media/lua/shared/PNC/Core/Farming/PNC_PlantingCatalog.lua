PNC = PNC or {}
PNC.FarmingCatalog = PNC.FarmingCatalog or {}

local Catalog = PNC.FarmingCatalog
local cache

local function safeText(key, fallback)
    if type(getText) ~= "function" then return fallback end
    local ok, value = pcall(getText, key)
    if ok and value and value ~= key then return tostring(value) end
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

local function build()
    local output, byId = {}, {}
    local props = farming_vegetableconf and farming_vegetableconf.props or {}
    for id, value in pairs(props) do
        if type(value) == "table" then
            local crop = string.lower(tostring(id))
            local types = seedTypes(value)
            if crop ~= "" and #types > 0 then
                local display = tostring(value.displayName or value.name or crop)
                display = safeText("Farming_" .. crop, display)
                local entry = {
                    id = crop,
                    displayName = display,
                    seedTypes = types,
                    vegetableName = value.vegetableName,
                    growBack = value.growBack == true,
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
    return ensure().byId[string.lower(tostring(crop or ""))]
end

function Catalog.List()
    local output = {}
    for index, value in ipairs(ensure().list) do
        output[index] = PNC.Core and PNC.Core.DeepCopy
            and PNC.Core.DeepCopy(value) or value
    end
    return output
end

function Catalog.Resolve(crop)
    local entry = Catalog.Get(crop)
    if not entry then return nil, "UNKNOWN_CROP" end
    return entry
end

return Catalog
