local State = {}

local function encodeKey(value)
    local encoded = tostring(value or "")
    encoded = encoded:gsub("%%", "%%25")
    return encoded:gsub("|", "%%7C")
end

local function decodeKey(value)
    local decoded = tostring(value or "")
    decoded = decoded:gsub("%%7C", "|")
    return decoded:gsub("%%25", "%%")
end

function State.Encode(groups)
    local keys = {}
    for key, collapsed in pairs(groups or {}) do
        if collapsed == true and tostring(key or "") ~= "" then
            keys[#keys + 1] = encodeKey(key)
        end
    end
    table.sort(keys)
    return table.concat(keys, "|")
end

function State.Decode(raw)
    local groups = {}
    for token in string.gmatch(tostring(raw or ""), "([^|]+)") do
        local key = decodeKey(token)
        if key ~= "" then groups[key] = true end
    end
    return groups
end

function State.Load(store)
    if store and not store.loaded then store:Load() end
    local raw = store and store:Get("workshopCollapsedGroups", "") or ""
    return State.Decode(raw)
end

function State.Save(store, groups)
    if not store then return false end
    store:Set("workshopCollapsedGroups", State.Encode(groups), true)
    return true
end

return State
