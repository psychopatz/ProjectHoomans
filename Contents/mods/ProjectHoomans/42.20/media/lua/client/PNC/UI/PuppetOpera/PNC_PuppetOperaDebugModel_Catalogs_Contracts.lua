-- Shared catalog identity, search, and route contracts.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function trimXML(value)
    return string.gsub(tostring(value or ""), "%.xml$", "")
end

local function entryID(catalogName, entry)
    if not entry then return nil end
    local source = entry.source or entry.folder or "entry"
    local file = trimXML(entry.file or "entry")
    local node = entry.node or entry.state or "node"
    local value = tostring(catalogName or "catalog") .. "."
        .. tostring(source) .. "." .. tostring(file) .. "."
        .. tostring(node)
    return string.gsub(value, "[^%w%._%-]", "_")
end

local function searchText(entry)
    local values = {
        tostring(entry.state or ""),
        tostring(entry.source or ""),
        tostring(entry.sourceState or ""),
        tostring(entry.mode or ""),
        tostring(entry.route or ""),
        tostring(entry.folder or ""),
        tostring(entry.file or ""),
        tostring(entry.path or ""),
        tostring(entry.node or ""),
        tostring(entry.anim or ""),
        tostring(entry.action or ""),
        tostring(entry.emote or ""),
    }
    for _, condition in ipairs(entry.conditions or {}) do
        values[#values + 1] = tostring(condition.name or "")
        values[#values + 1] = tostring(condition.kind or "")
        values[#values + 1] = tostring(condition.value or "")
    end
    for _, event in ipairs(entry.events or {}) do
        values[#values + 1] = tostring(event.name or "")
        values[#values + 1] = tostring(event.parameter or "")
    end
    return lower(table.concat(values, " "))
end

local function bumpType(entry)
    for _, condition in ipairs(entry and entry.conditions or {}) do
        if condition.name == "BumpType"
            and condition.kind == "STRING"
            and condition.value
            and condition.value ~= ""
        then
            return tostring(condition.value)
        end
    end
    return nil
end

local function directNPCEntry(entry)
    local count = 0
    for _, condition in ipairs(entry and entry.conditions or {}) do
        if condition.name ~= "PNCActor" and condition.name ~= "BumpType" then
            count = count + 1
        end
    end
    return count == 0
end

Internal.lower = lower
Internal.entryID = entryID
Internal.searchText = searchText
Internal.bumpType = bumpType
Internal.directNPCEntry = directNPCEntry

return Model
