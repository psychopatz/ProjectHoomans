-- Loaded game/mod scripts, with bounded pages and lazy native validation.
PNC.NPCAuthoringCatalog = PNC.NPCAuthoringCatalog or {}
local Catalog = PNC.NPCAuthoringCatalog
local entries, byID
local clothing, creationFailures = {}, {}

function Catalog.Invalidate()
    entries, byID, clothing, creationFailures = nil, nil, {}, {}
end

function Catalog.Clothing(location)
    if not clothing[location] then clothing[location] = PNC.UniqueNPCAppearanceUI.Internal.itemOptions(location) end
    return clothing[location]
end

function Catalog.Items()
    if entries then return entries end
    local items = getAllItems and getAllItems()
    if not items then return {} end -- Do not cache a pre-script-loading failure.
    entries, byID = {}, {}
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if not item:getObsolete() and not item:isHidden() then
            local id = item:getFullName()
            local label = item:getDisplayName() or id
            local module = item.getModuleName and item:getModuleName() or string.match(id, '^([^%.]+)') or ''
            local modID = WorldDictionary and WorldDictionary.getItemModID and WorldDictionary.getItemModID(id)
            local category = item.getDisplayCategory and item:getDisplayCategory() or 'Other'
            local entry = { id = id, label = label, module = module, source = modID or module,
                category = category or 'Other', script = item,
                search = string.lower(label .. ' ' .. id .. ' ' .. tostring(modID or module)) }
            entries[#entries + 1], byID[id] = entry, entry
        end
    end
    table.sort(entries, function(a, b) return a.search < b.search end)
    return entries
end

function Catalog.Filters(field)
    local seen, out = {}, {}
    for _, item in ipairs(Catalog.Items()) do
        local value = item[field]
        if value and not seen[value] then seen[value] = true; out[#out + 1] = value end
    end
    table.sort(out)
    return out
end

function Catalog.Query(options)
    options = options or {}
    local query = string.lower(tostring(options.query or ''))
    local limit = math.max(1, math.min(200, tonumber(options.limit) or 48))
    local offset = math.max(0, tonumber(options.offset) or 0)
    local rows, total = {}, 0
    for _, item in ipairs(options.items or Catalog.Items()) do
        if (not options.source or item.source == options.source)
            and (not options.category or item.category == options.category)
            and (not options.compatibleOnly or not options.allowed or options.allowed[item.id])
            and (query == '' or string.find(item.search, query, 1, true))
        then
            total = total + 1
            if total > offset and #rows < limit then rows[#rows + 1] = item end
        end
    end
    return rows, total
end

function Catalog.Search(query, allowed)
    local rows, total = Catalog.Query({ query = query, allowed = allowed,
        compatibleOnly = true, limit = 200 })
    return rows, total > #rows
end

function Catalog.Find(id)
    Catalog.Items()
    return byID and byID[id]
end

function Catalog.Create(id)
    if creationFailures[id] then return nil, creationFailures[id] end
    local entry = Catalog.Find(id)
    local script = ScriptManager and ScriptManager.instance and ScriptManager.instance:FindItem(id)
    if not entry or not script or script:getObsolete() or script:isHidden() then return nil, 'item_unavailable' end
    local native, reason = PNC.Equipment.CreateItem(id)
    if type(native) == 'table' and native[1] then native = native[1] end
    if not native then creationFailures[id] = reason or 'item_unavailable' end
    return native, reason
end

return Catalog
