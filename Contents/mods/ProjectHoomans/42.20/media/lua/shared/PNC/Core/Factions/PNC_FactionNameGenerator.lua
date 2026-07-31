-- Pure archetype-aware faction and community name generation.
--
-- A caller supplies a stable seed. This module never reads engine state and
-- never stores random-generator objects in persistence.

PNC = PNC or {}
PNC.FactionNameGenerator =
    PNC.FactionNameGenerator or {}

local Generator = PNC.FactionNameGenerator

local POOLS = {
    settler = {
        first = {
            "Ashwood", "Cedar", "Clearwater", "Fairview",
            "Greenfield", "Maple", "Oakridge", "Pinecrest",
            "Riverside", "Stonebridge", "Westhaven", "Willow",
        },
        second = {
            "Community", "Enclave", "Haven", "Homestead",
            "Refuge", "Settlement",
        },
        site = { "Haven", "Homestead", "Settlement" },
    },
    looter = {
        first = {
            "Ash", "Black", "Broken", "Burning", "Cold",
            "Crimson", "Iron", "Ragged", "Red", "Rust",
            "Scar", "Vulture",
        },
        second = {
            "Crows", "Fangs", "Hand", "Hounds", "Jackals",
            "Knives", "Raiders", "Ravens", "Reavers", "Wolves",
        },
        site = { "Den", "Hideout", "Hold", "Lair" },
        article = true,
    },
    trader = {
        first = {
            "Bluegrass", "Bridgeway", "Crossroads", "Frontier",
            "Iron Road", "Long Haul", "Northstar", "Riverside",
            "Safe Passage", "Three Rivers", "Westbound",
        },
        second = {
            "Caravan", "Exchange", "Mercantile",
            "Supply Company", "Trading Company",
        },
        site = { "Depot", "Exchange", "Market", "Waystation" },
    },
    refugee = {
        first = {
            "Dawn", "Eastbound", "Hope", "Lantern", "New Day",
            "Northbound", "Open Road", "Safe Harbor", "Westward",
        },
        second = {
            "Caravan", "Collective", "Refugees", "Sanctuary",
            "Survivors",
        },
        site = { "Camp", "Refuge", "Sanctuary", "Shelter" },
    },
}

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
