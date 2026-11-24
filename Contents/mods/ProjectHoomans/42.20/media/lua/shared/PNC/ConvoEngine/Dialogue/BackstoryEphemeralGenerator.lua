-- Ephemeral, deterministic identity-seed backstory & hometown generator.
-- Avoids static per-town or per-NPC definition files:
--   * Hometowns are drawn dynamically from WorldMapTownCatalog (vanilla + all
--     loaded modded maps like Raven Creek, Bedford Falls, Grapeseed, etc.).
--   * Backstory facets are generated deterministically from identitySeed with
--     lightweight cross-facet coherence (e.g. medical jobs -> medical education,
--     travel-heavy jobs -> higher out-of-town geographic familiarity).
--   * Cached ephemerally in a small bounded ring buffer (zero ModData bloat).

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Generator = PNC.ConvoEngine.BackstoryEphemeralGenerator or {}
PNC.ConvoEngine.BackstoryEphemeralGenerator = Generator

Generator.VERSION = 1
Generator.CACHE_LIMIT = 128
Generator.BASE_FAMILIARITY_PCT = 45
Generator.TRAVELER_BONUS_PCT = 30
Generator.LOCAL_SPAWN_BIAS_PCT = 55

local TownCatalog = PNC.ConvoEngine.WorldMapTownCatalog
    or require "PNC/ConvoEngine/Dialogue/WorldMapTownCatalog"

local profileCache = {}
local profileOrder = {}
local profileHead = 1
local profileCount = 0

local JOBS = {
    { id = "carpenter",      label = "a carpenter",            tags = { trade = true } },
    { id = "mechanic",       label = "a mechanic",             tags = { trade = true, traveler = true } },
    { id = "nurse",          label = "a nurse",                tags = { medical = true } },
    { id = "doctor",         label = "a doctor",               tags = { medical = true } },
    { id = "paramedic",      label = "a paramedic",            tags = { medical = true, traveler = true } },
    { id = "farmer",         label = "a farmer",               tags = { rural = true } },
    { id = "driver",         label = "a delivery driver",      tags = { traveler = true } },
    { id = "trucker",        label = "a long-haul trucker",    tags = { traveler = true } },
    { id = "teacher",        label = "a school teacher",       tags = { academic = true } },
    { id = "cook",           label = "a line cook",            tags = { service = true } },
    { id = "electrician",    label = "an electrician",         tags = { trade = true } },
    { id = "security_guard", label = "a security guard",       tags = { tactical = true } },
    { id = "firefighter",    label = "a firefighter",          tags = { tactical = true } },
    { id = "park_ranger",    label = "a park ranger",          tags = { rural = true, traveler = true } },
    { id = "smuggler",       label = "a back-road runner",     tags = { traveler = true, street = true } },
    { id = "scavenger",      label = "a scrap collector",      tags = { traveler = true, street = true } },
    { id = "clerk",          label = "a store clerk",          tags = { service = true } },
    { id = "librarian",      label = "a librarian",            tags = { academic = true } },
}

local EDUCATIONS = {
    { id = "nursing_program", label = "went through nursing school",     tag = "medical" },
    { id = "med_school",      label = "studied medicine",                tag = "medical" },
    { id = "trade_school",    label = "finished trade school",           tag = "trade" },
    { id = "apprenticeship",  label = "learned through an apprenticeship", tag = "trade" },
    { id = "state_college",   label = "went to state college",           tag = "academic" },
    { id = "community_col",   label = "took community college classes",  tag = "service" },
    { id = "self_taught",     label = "learned everything on the job",   tag = "street" },
    { id = "high_school",     label = "started working right after high school", tag = "rural" },
}

local HOBBIES = {
    "fishing on quiet mornings", "tending a small garden", "fixing up old radios",
    "playing guitar", "sketching maps and notebooks", "working on engines",
    "cooking from scratch", "woodworking", "reading old paperbacks", "hiking back trails",
}

local FAMILIES = {
    "grew up with a couple of siblings", "was an only child",
    "was raised by grandparents", "came from a big loud family",
    "moved around a lot with family", "was mostly on my own since eighteen",
}

local VALUES = {
    "looking out for the people who have your back",
    "standing on your own two feet",
    "keeping your word no matter what",
    "not leaving anyone behind if you can help it",
    "staying practical when everyone else panics",
}

local SURVIVAL_ORIGINS = {
    "got stuck on the highway during the evacuation",
    "held out at home until supplies ran dry",
    "was out on the road when the broadcasts cut out",
    "walked out of town with whatever fit in one bag",
    "bounced between empty houses until finding a safe spot",
}

local TRAGEDIES = {
    "lost my home in the first week",
    "got separated from family when the roads jammed",
    "watched a whole neighborhood fall apart overnight",
    "lost a close friend on a supply run",
}

local FEARS = {
    "getting trapped in a burning building",
    "ending up completely alone out here",
    "running out of daylight in unfamiliar territory",
    "getting cornered with nowhere to run",
}

local TRAVELER_ROLES = {
    trader = true, looter = true, bandit = true, raider = true,
    driver = true, smuggler = true, scavenger = true, courier = true,
}

local function hashInt(seed, salt)
    local h = tonumber(seed) or 0
    if h < 0 then h = -h end
    h = (math.floor(h) * 2654435761) % 2147483647
    local s = tostring(salt or "")
    for i = 1, #s do
        h = (h * 31 + string.byte(s, i)) % 2147483647
    end
    return h
end

local function pick(list, seed, salt)
    if type(list) ~= "table" or #list == 0 then return nil end
    local idx = (hashInt(seed, salt) % #list) + 1
    return list[idx]
end

local function extractSeed(record)
    if type(record) ~= "table" then return hashInt(0, tostring(record or "anon")) end
    local identity = type(record.identity) == "table" and record.identity or {}
    local raw = tonumber(identity.seed or record.identitySeed or record.seed)
    if raw and raw > 0 then return math.floor(raw) end
    local idStr = tostring(record.id or record.npcID or identity.id or "anon")
    return hashInt(17, idStr)
end

local function storeProfile(key, val)
    if profileCache[key] == nil then
        if profileCount >= Generator.CACHE_LIMIT then
            local oldest = profileOrder[profileHead]
            if oldest ~= nil then profileCache[oldest] = nil end
            profileOrder[profileHead] = key
            profileHead = (profileHead % Generator.CACHE_LIMIT) + 1
        else
            local slot = ((profileHead + profileCount - 1) % Generator.CACHE_LIMIT) + 1
            profileOrder[slot] = key
            profileCount = profileCount + 1
        end
    end
    profileCache[key] = val
end

local function resolveHometown(record, seed, worldOverride)
    -- Respect an explicitly stored hometown if already present on the record.
    local identity = type(record) == "table" and type(record.identity) == "table" and record.identity or nil
    local stored = identity and type(identity.backstory) == "table" and identity.backstory.hometown or nil
    if type(stored) == "table" and tostring(stored.value or "") ~= "" then
        local found = TownCatalog.FindByName(stored.value, worldOverride)
        return {
            id = found and found.id or TownCatalog.NormalizeTownID(stored.value),
            name = found and found.name or tostring(stored.value),
            source = "stored",
        }
    end
    if type(record) == "table" and tostring(record.hometown or "") ~= "" then
        local found = TownCatalog.FindByName(record.hometown, worldOverride)
        return {
            id = found and found.id or TownCatalog.NormalizeTownID(record.hometown),
            name = found and found.name or tostring(record.hometown),
            source = "record",
        }
    end

    local towns = TownCatalog.GetTowns(worldOverride)
    if type(towns) ~= "table" or #towns == 0 then
        return { id = "muldraugh", name = "Muldraugh", source = "fallback" }
    end

    -- Local-spawn bias: NPCs spawned in a town (including modded maps!) have a
    -- 55% chance of being local to that town, 45% from elsewhere in the world.
    local spawnTown = type(record) == "table" and record.spawnTown or nil
    if spawnTown and tostring(spawnTown) ~= "" then
        local matched = TownCatalog.FindByName(spawnTown, worldOverride)
        if matched and (hashInt(seed, "hometown_local_bias") % 100) < Generator.LOCAL_SPAWN_BIAS_PCT then
            return { id = matched.id, name = matched.name, source = "spawn_local" }
        end
    end

    local chosen = pick(towns, seed, "hometown")
    return {
        id = chosen.id,
        name = chosen.name,
        source = chosen.source or "ephemeral",
    }
end

local function pickCoherentEducation(job, seed)
    local tags = type(job) == "table" and job.tags or {}
    local matching = {}
    for i = 1, #EDUCATIONS do
        if tags[EDUCATIONS[i].tag] then
            matching[#matching + 1] = EDUCATIONS[i]
        end
    end
    if #matching > 0 and (hashInt(seed, "edu_coherence") % 100) < 75 then
        return pick(matching, seed, "education_coherent")
    end
    return pick(EDUCATIONS, seed, "education")
end

function Generator.GenerateProfile(record, worldOverride)
    local seed = extractSeed(record)
    local spawnKey = type(record) == "table" and tostring(record.spawnTown or record.hometown or "") or ""
    local key = tostring(seed) .. ":" .. spawnKey
    if profileCache[key] ~= nil then
        return profileCache[key]
    end

    local hometown = resolveHometown(record, seed, worldOverride)
    local job = pick(JOBS, seed, "former_job")
    local education = pickCoherentEducation(job, seed)
    local profile = {
        seed = seed,
        hometown = hometown.name,
        hometownID = hometown.id,
        hometownSource = hometown.source,
        formerJob = job.label,
        formerJobID = job.id,
        isTraveler = job.tags and job.tags.traveler == true or false,
        education = education.label,
        hobby = pick(HOBBIES, seed, "hobby"),
        familyBackground = pick(FAMILIES, seed, "family_background"),
        value = pick(VALUES, seed, "value"),
        survivalOrigin = pick(SURVIVAL_ORIGINS, seed, "survival_origin"),
        tragedy = pick(TRAGEDIES, seed, "tragedy"),
        fear = pick(FEARS, seed, "fear"),
    }
    storeProfile(key, profile)
    return profile
end

function Generator.ResolveLocationFamiliarity(record, locationInfo, worldOverride)
    locationInfo = type(locationInfo) == "table" and locationInfo or {}
    local profile = Generator.GenerateProfile(record, worldOverride)

    -- 1. Own settlement/base is always known.
    if tostring(locationInfo.settlementName or "") ~= "" then
        return {
            level = "local",
            familiar = true,
            isHometown = false,
            hometown = profile.hometown,
            reason = "settlement",
        }
    end

    local currentTown = tostring(locationInfo.townName or "")
    if currentTown == "" then
        -- No town name on this tile (e.g. deep wilderness); immediate zone/room still visible.
        return {
            level = "familiar",
            familiar = true,
            isHometown = false,
            hometown = profile.hometown,
            reason = "no_town_scope",
        }
    end

    local currentTownID = TownCatalog.NormalizeTownID(currentTown)
    -- 2. NPC's own hometown is ALWAYS 100% known with local flavor!
    if currentTownID ~= "" and currentTownID == profile.hometownID then
        return {
            level = "local",
            familiar = true,
            isHometown = true,
            hometown = profile.hometown,
            reason = "hometown_local",
        }
    end

    -- 3. Out-of-town deterministic identity-seed roll.
    local role = string.lower(tostring(
        (type(record) == "table" and (record.npcType or record.role)) or ""
    ))
    local threshold = Generator.BASE_FAMILIARITY_PCT
    if profile.isTraveler or TRAVELER_ROLES[role] or (type(record) == "table" and record.isTrader == true) then
        threshold = threshold + Generator.TRAVELER_BONUS_PCT
    end
    local roll = hashInt(profile.seed, "familiarity:" .. currentTownID) % 100
    local familiar = roll < threshold
    return {
        level = familiar and "familiar" or "unfamiliar",
        familiar = familiar,
        isHometown = false,
        hometown = profile.hometown,
        roll = roll,
        threshold = threshold,
        reason = familiar and "seed_familiar" or "seed_unfamiliar",
    }
end

function Generator.ResetCache()
    profileCache = {}
    profileOrder = {}
    profileHead = 1
    profileCount = 0
end

return Generator
