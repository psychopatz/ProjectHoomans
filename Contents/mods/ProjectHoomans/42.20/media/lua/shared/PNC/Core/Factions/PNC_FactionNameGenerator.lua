-- Pure archetype-aware faction and community name generation.
--
-- A caller supplies a stable seed. This module never reads engine state and
-- never stores random-generator objects in persistence.

PNC = PNC or {}
PNC.FactionNameGenerator =
    PNC.FactionNameGenerator or {}

local Generator = PNC.FactionNameGenerator

local POOLS = {}
local FALLBACK_POOL = {
    first = { "Survivor" },
    second = { "Group" },
    site = { "Camp" },
}

function Generator.RegisterPool(archetypeID, pool)
    archetypeID = tostring(archetypeID or "")
    if archetypeID == "" or type(pool) ~= "table"
        or type(pool.first) ~= "table" or #pool.first == 0
        or type(pool.second) ~= "table" or #pool.second == 0
        or type(pool.site) ~= "table" or #pool.site == 0
    then
        return false
    end
    POOLS[archetypeID] = pool
    return true
end

function Generator.GetPool(archetypeID)
    return POOLS[tostring(archetypeID or "")]
end

local okReg, reg = pcall(require, "PNC/Definitions/Factions/Register")
if okReg and type(reg) == "table" and type(reg.Apply) == "function" then
    reg.Apply(nil, Generator)
end

local function stableNumber(value)
    local hash = 5381
    local source = tostring(value or "")
    local index
    for index = 1, #source do
        hash = (
            hash * 33 + string.byte(source, index)
        ) % 2147483647
    end
    return hash
end

local function poolFor(archetypeID)
    return POOLS[tostring(archetypeID or "")]
        or POOLS.settler
        or FALLBACK_POOL
end

local function pick(values, seed, salt)
    local index = (
        stableNumber(tostring(seed) .. ":" .. tostring(salt))
            % #values
    ) + 1
    return values[index]
end

local function stripArticle(value)
    value = tostring(value or "")
    if string.sub(value, 1, 4) == "The " then
        return string.sub(value, 5)
    end
    return value
end

function Generator.GenerateFactionName(archetypeID, seed)
    local pool = poolFor(archetypeID)
    local first = pick(pool.first, seed, "first")
    local second = pick(pool.second, seed, "second")
    local name = first .. " " .. second
    if pool.article == true then name = "The " .. name end
    return name
end

function Generator.GenerateCommunityName(
    archetypeID,
    factionName,
    seed
)
    local pool = poolFor(archetypeID)
    local base = stripArticle(factionName)
    local suffix = pick(pool.site, seed, "site")
    if string.lower(string.sub(base, -#suffix))
        == string.lower(suffix)
    then
        local index
        for index = 1, #pool.site do
            if string.lower(pool.site[index])
                ~= string.lower(suffix)
            then
                suffix = pool.site[index]
                break
            end
        end
    end
    return base .. " " .. suffix
end

function Generator.Seed(value)
    return stableNumber(value)
end

return Generator
