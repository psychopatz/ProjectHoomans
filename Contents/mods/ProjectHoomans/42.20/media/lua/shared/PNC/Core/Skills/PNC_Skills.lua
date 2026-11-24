PNC = PNC or {}
PNC.Skills = PNC.Skills or {}

local Skills = PNC.Skills
local Identity = PNC.Identity
local Catalog = PNC.SkillCatalog
local Archetypes = PNC.Archetypes
local Types = PNC.Types
local Core = PNC.Core
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Curves = require "PNC/Core/Skills/PNC_Skills_Curves"

local MELEE_FOCUS = {
    "Axe",
    "LongBlade",
    "LongBlunt",
    "ShortBlade",
    "ShortBlunt",
    "Spear",
}
local RANGED_FOCUS = { "Aiming", "Reloading" }
local DIRTY_COALESCE_XP = 10
local DIRTY_COALESCE_MS = 5000

local function ensureProgress(record)
    if type(record) ~= "table" then return nil end
    if type(record.progression) ~= "table" then record.progression = {} end
    if type(record.progression.skillXP) ~= "table" then
        record.progression.skillXP = {}
    end
    if type(record.progression.skillLevelDeltas) ~= "table" then
        record.progression.skillLevelDeltas = {}
    end
    return record.progression
end

local function clampLevel(level)
    return math.max(0, math.min(10, math.floor(tonumber(level) or 0)))
end

local function baseCacheFor(record)
    local runtime = type(record) == "table" and type(record.runtime) == "table"
        and record.runtime or nil
    if not runtime then return nil end
    local key = tostring(record.identitySeed or "")
        .. "|" .. tostring(record.archetypeID or "")
        .. "|" .. tostring(record.weaponMode or "")
        .. "|" .. tostring(record.tacticalClass or "")
        .. "|" .. tostring(record.skillBaseLevels ~= nil)
    if runtime.skillBaseCacheKey ~= key or type(runtime.skillBaseCache) ~= "table" then
        runtime.skillBaseCacheKey = key
        runtime.skillBaseCache = {}
        runtime.skillSpecialtyCache = nil
    end
    return runtime.skillBaseCache, runtime
end

local function getSpecialtyMap(record, runtime)
    if type(record) ~= "table" then return {} end
    if runtime and type(runtime.skillSpecialtyCache) == "table" then
        return runtime.skillSpecialtyCache
    end
    local specialty = {
        melee = MELEE_FOCUS[Identity.Index(record.identitySeed, "melee_focus", #MELEE_FOCUS)],
        ranged = RANGED_FOCUS[Identity.Index(record.identitySeed, "ranged_focus", #RANGED_FOCUS)],
        weaponMode = tostring(record.weaponMode or "melee"),
    }
    if runtime then runtime.skillSpecialtyCache = specialty end
    return specialty
end

local function resolveBaseLevel(record, skillID)
    if type(record) ~= "table" or not skillID then return 0 end
    local authoredLevels = type(record.skillBaseLevels) == "table"
        and record.skillBaseLevels or nil
    if authoredLevels and authoredLevels[skillID] ~= nil then
        return clampLevel(authoredLevels[skillID])
    end
    local cache, runtime = baseCacheFor(record)
    if cache and cache[skillID] ~= nil then return cache[skillID] end

    local specialty = getSpecialtyMap(record, runtime)
    local lowered = string.lower(tostring(skillID))
    local level = Identity.Range(record.identitySeed, "skill:" .. tostring(skillID), 0, 3)

    if (Types and Types.IsColonist and Types.IsColonist(record))
        or record.tacticalClass == "colonist"
    then
        if lowered == "fitness" or lowered == "strength"
            or lowered == "nimble" or lowered == "sneaking"
        then
            level = Identity.Range(record.identitySeed, "skill:" .. tostring(skillID), 1, 4)
        elseif skillID == specialty.melee then
            level = Identity.Range(record.identitySeed, "skill_focus:" .. tostring(skillID), 3, 6)
        elseif skillID == "Maintenance" then
            level = Identity.Range(record.identitySeed, "skill_focus:Maintenance", 1, 4)
        end
    elseif record.tacticalClass == "hostile" then
        if specialty.weaponMode == "ranged"
            and (skillID == "Aiming" or skillID == "Reloading")
        then
            level = Identity.Range(record.identitySeed, "skill_focus:" .. tostring(skillID), 3, 6)
        elseif skillID == specialty.melee then
            level = Identity.Range(record.identitySeed, "skill_focus:" .. tostring(skillID), 2, 5)
        elseif lowered == "fitness" or lowered == "strength" then
            level = Identity.Range(record.identitySeed, "skill:" .. tostring(skillID), 2, 5)
        end
    elseif lowered == "fitness" or lowered == "strength" then
        level = Identity.Range(record.identitySeed, "skill:" .. tostring(skillID), 1, 3)
    end

    local archetype = Archetypes and Archetypes.Get
        and Archetypes.Get(record.archetypeID) or nil
    local bias = archetype and archetype.skillBias
        and archetype.skillBias[skillID] or nil
    if type(bias) == "table" then
        level = math.max(level, Identity.Range(
            record.identitySeed,
            "skill_bias:" .. tostring(archetype.id) .. ":" .. tostring(skillID),
            tonumber(bias.min) or level,
            tonumber(bias.max) or level
        ))
    end
    level = clampLevel(level)
    if cache then cache[skillID] = level end
    return level
end

function Skills.GetBaseLevel(record, skillID)
    return resolveBaseLevel(record, Curves.NormalizeSkillID(skillID))
end

-- Only player-owned / colonist NPCs can learn XP so world NPCs stay zero-delta.
function Skills.SyncRecruitment(record)
    return type(record) == "table" and (
        record.recruited == true
        or record.ownerUsername ~= nil
        or record.ownerOnlineID ~= nil
    )
end

function Skills.CanLearn(record)
    return Skills.SyncRecruitment(record)
end

function Skills.GetLevel(record, skillID)
    skillID = Curves.NormalizeSkillID(skillID)
    if type(record) ~= "table" or not skillID then return 0 end
    local progression = type(record.progression) == "table"
        and record.progression or nil
    local deltas = progression and type(progression.skillLevelDeltas) == "table"
        and progression.skillLevelDeltas or nil
    local delta = deltas and tonumber(deltas[skillID]) or 0
    return clampLevel(resolveBaseLevel(record, skillID) + delta)
end

function Skills.GetXP(record, skillID)
    skillID = Curves.NormalizeSkillID(skillID)
    if type(record) ~= "table" or not skillID then return 0 end
    local xpMap = type(record.progression) == "table"
        and type(record.progression.skillXP) == "table"
        and record.progression.skillXP or nil
    return xpMap and math.max(0, tonumber(xpMap[skillID]) or 0) or 0
end

function Skills.GetNextLevelXP(record, skillID)
    skillID = Curves.NormalizeSkillID(skillID)
    if not skillID then return 0 end
    return Curves.GetThreshold(skillID, Skills.GetLevel(record, skillID))
end

function Skills.GetAverage(record, skillIDs)
    if type(skillIDs) ~= "table" or #skillIDs <= 0 then return 0 end
    local total = 0
    for i = 1, #skillIDs do
        total = total + Skills.GetLevel(record, skillIDs[i])
    end
    return total / #skillIDs
end

local function applySingleXP(record, skillID, amount, options)
    skillID = Curves.NormalizeSkillID(skillID)
    local rawAmount = math.max(0, tonumber(amount) or 0)
    if not skillID or rawAmount <= 0 then return false, false, 0 end
    local progression = ensureProgress(record)
    local xpMap = progression.skillXP
    local baseLevel = resolveBaseLevel(record, skillID)
    local currentLevel = Skills.GetLevel(record, skillID)
    if currentLevel >= 10 then return true, false, 0 end
    local effectiveAmount = rawAmount
        * Curves.ResolveXPMultiplier(record, skillID, baseLevel, options)
    if effectiveAmount <= 0 then return true, false, 0 end

    local originalLevel = currentLevel
    local xpValue = math.max(0, tonumber(xpMap[skillID]) or 0) + effectiveAmount
    local threshold = Curves.GetThreshold(skillID, currentLevel)
    while xpValue >= threshold and currentLevel < 10 do
        xpValue = xpValue - threshold
        currentLevel = currentLevel + 1
        progression.skillLevelDeltas[skillID] = currentLevel - baseLevel
        threshold = Curves.GetThreshold(skillID, currentLevel)
    end
    if currentLevel >= 10 then xpValue = 0 end
    xpMap[skillID] = math.floor(xpValue * 100 + 0.5) / 100
    local leveledUp = currentLevel > originalLevel
    if leveledUp then
        Events.emit(EventTypes.NPC_SKILL_LEVEL_UP, record, skillID, currentLevel)
    end
    return true, leveledUp, effectiveAmount
end

local function finalizeXPDirty(record, leveledUp, gainedTotal, options)
    local runtime = type(record.runtime) == "table" and record.runtime or nil
    if leveledUp and runtime then
        runtime.skillSnapshotRevision =
            (tonumber(runtime.skillSnapshotRevision) or 0) + 1
    end
    if not PNC.Registry or not PNC.Registry.MarkDirty then return end
    local flushNow = leveledUp
        or (type(options) == "table" and options.flushDirty == true)
    if not flushNow and runtime then
        local now = Core and Core.Now and Core.Now() or 0
        runtime.skillDirtyAccum = (tonumber(runtime.skillDirtyAccum) or 0)
            + (tonumber(gainedTotal) or 0)
        local lastMark = tonumber(runtime.skillDirtyMarkedAt) or 0
        if runtime.skillDirtyAccum >= DIRTY_COALESCE_XP
            or (now - lastMark) >= DIRTY_COALESCE_MS
        then
            flushNow = true
            runtime.skillDirtyAccum = 0
            runtime.skillDirtyMarkedAt = now
        end
    else
        flushNow = true
    end
    if flushNow then
        PNC.Registry.MarkDirty(record, "skills")
    end
end

function Skills.AddXP(record, skillID, amount, options)
    if not Skills.CanLearn(record) or not skillID then return false end
    local ok, leveledUp, gained = applySingleXP(record, skillID, amount, options)
    if not ok then return false end
    finalizeXPDirty(record, leveledUp, gained, options)
    return true
end

function Skills.AddXPBatch(record, awards, options)
    if not Skills.CanLearn(record) or type(awards) ~= "table" then
        return false
    end
    local anyApplied = false
    local anyLevelUp = false
    local totalGained = 0
    for i = 1, #awards do
        local entry = awards[i]
        if type(entry) == "table" then
            local skillID = entry.skillId or entry.skillID or entry[1]
            local amount = entry.amount or entry[2]
            local ok, leveledUp, gained = applySingleXP(
                record, skillID, amount, options
            )
            if ok then
                anyApplied = true
                if leveledUp then anyLevelUp = true end
                totalGained = totalGained + gained
            end
        end
    end
    if not anyApplied then return false end
    finalizeXPDirty(record, anyLevelUp, totalGained, options)
    return true
end

function Skills.ResolveWeaponSkill(record, fullType, combatMode, weaponItem)
    return Curves.ResolveWeaponSkill(fullType, combatMode, weaponItem)
end

function Skills.BuildSnapshot(record)
    local levels = {}
    if type(record) ~= "table" then return levels end
    local runtime = type(record.runtime) == "table" and record.runtime or nil
    local cacheKey = tostring(record.recordRevision or 0)
        .. "|" .. tostring(runtime and runtime.skillSnapshotRevision or 0)
        .. "|" .. tostring(record.archetypeID or "")
        .. "|" .. tostring(record.weaponMode or "")
        .. "|" .. tostring(record.tacticalClass or "")
    if runtime
        and runtime.skillSnapshotCacheKey == cacheKey
        and type(runtime.skillSnapshotCache) == "table"
    then
        return runtime.skillSnapshotCache
    end
    local skillIDs = Catalog.GetAllSkillIDs()
    for i = 1, #skillIDs do
        levels[skillIDs[i]] = Skills.GetLevel(record, skillIDs[i])
    end
    if runtime then
        runtime.skillSnapshotCacheKey = cacheKey
        runtime.skillSnapshotCache = levels
    end
    return levels
end

Skills.Repository = require "PNC/Core/Skills/PNC_SkillsRepository"
require "PNC/Core/Skills/PNC_Exercise"
require "PNC/Core/Skills/PNC_Mood"
