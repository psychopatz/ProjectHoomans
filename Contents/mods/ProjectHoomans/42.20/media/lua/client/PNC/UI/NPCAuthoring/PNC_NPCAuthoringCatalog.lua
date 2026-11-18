-- Loaded game/mod scripts, with bounded pages and lazy native validation.
PNC.NPCAuthoringCatalog = PNC.NPCAuthoringCatalog or {}
local Catalog = PNC.NPCAuthoringCatalog
local entries, byID
local clothing, creationFailures = {}, {}
local blockedTypes = {
    ['Base.YardstickDEBUG'] = true,
    ['Base.FISH_DEV_ITEM'] = true,
    ['Base.BareHands'] = true,
}

local function locationID(location)
    return string.lower(string.match(tostring(location or ''), '([^:]+)$') or '')
end

local function cosmeticLocation(location)
    return location == 'wound' or location == 'makeupfullface' or location == 'makeupeyes'
        or location == 'makeupeyesshadow' or location == 'makeuplips'
        or location == 'makeup_fullface' or location == 'makeup_eyes'
        or location == 'makeup_eyesshadow' or location == 'makeup_lips'
end

local function hiddenCosmetic(item)
    local location = item.getBodyLocation and locationID(item:getBodyLocation())
    if location and cosmeticLocation(location) then return location end
end

function Catalog.Invalidate()
    entries, byID, clothing, creationFailures = nil, nil, {}, {}
end

function Catalog.Clothing(location, isFemale)
    local key = locationID(location)
    if key == 'zeddmg' or key == 'zombiedamage' then return {} end
    if not clothing[location] then
        local rows = {}
        for _, option in ipairs(PNC.UniqueNPCAppearanceUI.Internal.itemOptions(location)) do
            local item = Catalog.Find(option.id)
            if item and (not item.cosmeticLocation or item.cosmeticLocation == key) then
                rows[#rows + 1] = option
            end
        end
        clothing[location] = rows
    end
    if key ~= 'wound' or isFemale == nil then return clothing[location] end
    local rows = {}
    local wrongBody = isFemale and '_male$' or '_female$'
    for _, option in ipairs(clothing[location]) do
        if not string.match(string.lower(option.id), wrongBody) then rows[#rows + 1] = option end
    end
    return rows
end

function Catalog.Items()
    if entries then return entries end
    local items = getAllItems and getAllItems()
    if not items then return {} end -- Do not cache a pre-script-loading failure.
    entries, byID = {}, {}
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local hidden = item:isHidden()
        local cosmetic = hidden and hiddenCosmetic(item)
        local id = item:getFullName()
        local category = item.getDisplayCategory and item:getDisplayCategory() or 'Other'
        if not blockedTypes[id] and category ~= 'Hidden' and not item:getObsolete() and (not hidden or cosmetic) then
            local label = item:getDisplayName() or id
            local module = item.getModuleName and item:getModuleName() or string.match(id, '^([^%.]+)') or ''
            local modID = WorldDictionary and WorldDictionary.getItemModID and WorldDictionary.getItemModID(id)
            local entry = { id = id, label = label, module = module, source = modID or module,
                category = category or 'Other', script = item,
                cosmeticLocation = cosmetic,
                search = string.lower(label .. ' ' .. id .. ' ' .. tostring(modID or module)) }
            entries[#entries + 1], byID[id] = entry, entry
        end
    end
    table.sort(entries, function(a, b) return a.search < b.search end)
    return entries
end

local function matches(item, allowed, query)
    if (allowed or item.cosmeticLocation) and not (allowed and allowed[item.id]) then return false end
    return query == '' or string.find(item.search, query, 1, true) ~= nil
end

function Catalog.Filters(allowed, search, source)
    local seenSources, seenCategories, sources, categories = {}, {}, {}, {}
    local query = string.lower(tostring(search or ''))
    for _, item in ipairs(Catalog.Items()) do
        if matches(item, allowed, query) then
            if item.source and not seenSources[item.source] then
                seenSources[item.source] = true; sources[#sources + 1] = item.source
            end
            if (not source or item.source == source) and item.category and not seenCategories[item.category] then
                seenCategories[item.category] = true; categories[#categories + 1] = item.category
            end
        end
    end
    table.sort(sources); table.sort(categories)
    return sources, categories
end

-- Script metadata includes vanilla and mod weapons without constructing them.
function Catalog.Weapons()
    local allowed = {}
    for _, entry in ipairs(Catalog.Items()) do
        if not entry.cosmeticLocation and entry.script.getItemType and entry.script:getItemType() == ItemType.WEAPON then allowed[entry.id] = true end
    end
    return allowed
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
            and matches(item, options.allowed, query)
        then
            total = total + 1
            if total > offset and #rows < limit then rows[#rows + 1] = item end
        end
    end
    return rows, total
end

function Catalog.Search(query, allowed)
    local rows, total = Catalog.Query({ query = query, allowed = allowed,
        limit = 200 })
    return rows, total > #rows
end

function Catalog.Find(id)
    Catalog.Items()
    return byID and byID[id]
end

function Catalog.Create(id, location)
    local entry = Catalog.Find(id)
    local script = ScriptManager and ScriptManager.instance and ScriptManager.instance:FindItem(id)
    if not entry or not script or script:getObsolete() then return nil, 'item_unavailable' end
    if script:isHidden() and hiddenCosmetic(script) ~= locationID(location) then return nil, 'item_unavailable' end
    if creationFailures[id] then return nil, creationFailures[id] end
    local native, reason = PNC.Equipment.CreateItem(id)
    if type(native) == 'table' and native[1] then native = native[1] end
    if not native then creationFailures[id] = reason or 'item_unavailable' end
    return native, reason
end

return Catalog
