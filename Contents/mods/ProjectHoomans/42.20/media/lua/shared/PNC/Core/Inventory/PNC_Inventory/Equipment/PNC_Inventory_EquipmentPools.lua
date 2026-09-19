-- Identity-seeded equipment pool registration and weighted selection.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Identity = PNC.Identity

Inventory.EquipmentSpawnPools = Inventory.EquipmentSpawnPools or {}

local function normalizeString(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function copyGrant(source)
    if type(source) ~= "table" or not normalizeString(source.type) then return nil end
    return {
        key = normalizeString(source.key),
        type = tostring(source.type),
        stack = math.max(1, math.floor(tonumber(source.stack) or 1)),
        uses = tonumber(source.uses),
        cond = tonumber(source.cond),
        preferredContainer = normalizeString(source.preferredContainer),
    }
end

local function normalizeEntry(source)
    local entry
    local grant
    local grants
    local i
    if type(source) == "string" then source = { type = source } end
    if type(source) ~= "table" or not normalizeString(source.type) then return nil end
    entry = {
        type = tostring(source.type),
        weight = math.max(1, math.floor(tonumber(source.weight) or 1)),
        cond = tonumber(source.cond),
        grants = {},
    }
    grants = source.grants or source.supplies or {}
    if type(grants) ~= "table" then grants = {} end
    for i = 1, #grants do
        grant = copyGrant(grants[i])
        if grant then entry.grants[#entry.grants + 1] = grant end
    end
    return entry
end

local function normalizeCategory(source)
    local output = {}
    local entry
    local i
    if type(source) ~= "table" then return output end
    for i = 1, #source do
        entry = normalizeEntry(source[i])
        if entry then output[#output + 1] = entry end
    end
    return output
end

function Inventory.RegisterEquipmentSpawnPool(poolID, specification)
    local categories = {}
    local sourceCategories
    local category
    local entries
    poolID = normalizeString(poolID)
    if not poolID or type(specification) ~= "table" then return false end
    sourceCategories = specification.categories or specification
    if type(sourceCategories) ~= "table" then return false end
    for category, entries in pairs(sourceCategories) do
        category = normalizeString(category)
        if category then categories[category] = normalizeCategory(entries) end
    end
    Inventory.EquipmentSpawnPools[poolID] = { categories = categories }
    return true
end

function Inventory.AddEquipmentSpawnEntry(poolID, category, entry)
    local pool
    local normalized
    poolID = normalizeString(poolID)
    category = normalizeString(category)
    if not poolID or not category then return false end
    normalized = normalizeEntry(entry)
    if not normalized then return false end
    pool = Inventory.EquipmentSpawnPools[poolID]
    if not pool then
        pool = { categories = {} }
        Inventory.EquipmentSpawnPools[poolID] = pool
    end
    pool.categories = type(pool.categories) == "table" and pool.categories or {}
    pool.categories[category] = type(pool.categories[category]) == "table"
        and pool.categories[category]
        or {}
    pool.categories[category][#pool.categories[category] + 1] = normalized
    return true
end

function Inventory.GetEquipmentSpawnPool(poolID)
    return Inventory.EquipmentSpawnPools[normalizeString(poolID) or "Default"]
end

local function weightedStartIndex(entries, seed, salt)
    local total = 0
    local ticket
    local i
    for i = 1, #entries do
        total = total + math.max(1, tonumber(entries[i].weight) or 1)
    end
    if total <= 0 then return nil end
    ticket = Identity.MixSeed(seed, salt) % total
    for i = 1, #entries do
        ticket = ticket - math.max(1, tonumber(entries[i].weight) or 1)
        if ticket < 0 then return i end
    end
    return 1
end

function Inventory.ChooseEquipmentSpawnEntry(poolID, category, seed, salt, validator)
    local pool = Inventory.GetEquipmentSpawnPool(poolID)
    local entries = pool and pool.categories and pool.categories[category] or {}
    local start = weightedStartIndex(entries, seed, salt)
    local index
    local offset
    if not start then return nil end
    for offset = 0, #entries - 1 do
        index = ((start - 1 + offset) % #entries) + 1
        if not validator or validator(entries[index]) then
            return normalizeEntry(entries[index])
        end
    end
    return nil
end
