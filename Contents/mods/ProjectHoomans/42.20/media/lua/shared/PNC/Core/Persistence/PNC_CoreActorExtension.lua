-- Single sparse durable Hoomans-only extension authority for Core-backed
-- SurvivorWorld actors (`actor.extensions["ProjectHoomans.ActorExtension"]`).
--
-- Ownership & exclusion contract (LightweightNPCRuntime L1):
--   Core owns: identity, appearance, personalInventory, social/persona/knowledge,
--     SurvivorWorld affiliation/world/location/journey, and providerLease.
--   Hoomans extension owns ONLY non-default Hoomans gameplay deltas:
--     * uniqueDefinitionId / uniqueDefinitionVersion (bound: <=128 chars, int>=1)
--     * tacticalClass (non-"neutral"), hostility (non-default for class)
--     * recruited, ownerUsername, ownerCharacterUUID (bound: <=128 chars)
--     * orderSpec (non-idle/non-transitory), patrolPoints (bound: <=32), patrolIndex
--     * health (non-default full normal), stamina (non-full)
--     * weaponMode / attackType (non-default for tacticalClass)
--     * allowedJobs / jobPriorities (bound: <=32 entries)
--     * progression (skill deltas / XP), skillBaseLevels (authored), recipeKnowledge
--     * conditionStats, npcTraits, authored vanillaTraits / dynamicTraits
--     * followerAbandonment, colonistDeparture
--     * generation (bound: <=8 scalar entries), spawn / anchor (when != actor pos)
--     * alive == false / corpse (pre-retirement death safety)
--
-- Default/unmodified promoted bystanders return `nil` from Encode() so zero
-- extra bytes are stored on canonical Core actors.

local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local HealthRepository = require "PNC/Core/Health/PNC_HealthRepository"
local SkillsRepository = require "PNC/Core/Skills/PNC_SkillsRepository"
local CompanionRecordRepository =
    require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local CombatRecordRepository =
    require "PNC/Core/Combat/PNC_CombatRecordRepository"
local BodyRepository = require "PNC/Core/Presence/PNC_BodyRepository"

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Extension = Persistence.CoreActorExtension or {}
Persistence.CoreActorExtension = Extension

Extension.EXTENSION_ID = "ProjectHoomans.ActorExtension"
Extension.SCHEMA_VERSION = 1

local MAX_STRING_LEN = 128
local MAX_MAP_ENTRIES = 32
local MAX_GENERATION_KEYS = 8

local STARTUP_ACTIVE_ORDERS = {
    follow = true,
    camp = true,
    patrol = true,
    guard = true,
    work = true,
    facility = true,
    escort = true,
    travel = true,
}

local function deepCopy(value)
    if PNC.Core and type(PNC.Core.DeepCopy) == "function" then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = deepCopy(v)
    end
    return out
end

local function valuesEqual(left, right)
    if left == right then return true end
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return false end
    for k, v in pairs(left) do
        if not valuesEqual(v, right[k]) then return false end
    end
    for k, _ in pairs(right) do
        if left[k] == nil then return false end
    end
    return true
end

local function boundedString(value, limit)
    local text = Codec.normalizeString(value)
    if not text then return nil end
    limit = tonumber(limit) or MAX_STRING_LEN
    if #text > limit then
        text = string.sub(text, 1, limit)
    end
    return text
end

local function actorPoint(actor)
    local world = type(actor) == "table" and type(actor.world) == "table"
        and actor.world or {}
    local loc = type(world.location) == "table" and world.location or {}
    local pt = type(loc.position) == "table" and loc.position
        or (type(world.position) == "table" and world.position)
        or {}
    return tonumber(pt.x) or 0, tonumber(pt.y) or 0, tonumber(pt.z) or 0
end

local function pointDiffers(x1, y1, z1, x2, y2, z2)
    return math.abs((tonumber(x1) or 0) - (tonumber(x2) or 0)) > 0.01
        or math.abs((tonumber(y1) or 0) - (tonumber(y2) or 0)) > 0.01
        or math.abs((tonumber(z1) or 0) - (tonumber(z2) or 0)) > 0.01
end

local function boundedBooleanOrNumberMap(source, valueKind, maxEntries)
    if type(source) ~= "table" then return nil end
    local keys = {}
    for k, v in pairs(source) do
        if type(k) == "string" and k ~= "" then
            if valueKind == "boolean" and v == true then
                keys[#keys + 1] = k
            elseif valueKind == "number" and tonumber(v) ~= nil then
                keys[#keys + 1] = k
            end
        end
    end
    if #keys == 0 then return nil end
    table.sort(keys)
    local out = {}
    local limit = math.min(#keys, tonumber(maxEntries) or MAX_MAP_ENTRIES)
    for i = 1, limit do
        local k = keys[i]
        out[k] = valueKind == "boolean" and true or tonumber(source[k])
    end
    return out
end

local function defaultAllowedJobs(record)
    local archetypes = PNC.Archetypes
    if not archetypes or type(archetypes.Get) ~= "function" then
        return nil
    end
    local identity = PNC.Identity
    local archID = (identity and type(identity.ResolveArchetypeID) == "function"
        and identity.ResolveArchetypeID(record))
        or record.archetypeID
    local arch = archetypes.Get(archID)
    return arch and type(arch.allowedJobs) == "table" and arch.allowedJobs or nil
end

local function sanitizeGeneration(generation)
    if type(generation) ~= "table" then return nil end
    local keys = {}
    for k, v in pairs(generation) do
        local vt = type(v)
        if type(k) == "string" and k ~= ""
            and (vt == "string" or vt == "number" or vt == "boolean")
        then
            keys[#keys + 1] = k
        end
    end
    if #keys == 0 then return nil end
    table.sort(keys)
    local out = {}
    local limit = math.min(#keys, MAX_GENERATION_KEYS)
    for i = 1, limit do
        local k = keys[i]
        local v = generation[k]
        if type(v) == "string" and #v > MAX_STRING_LEN then
            v = string.sub(v, 1, MAX_STRING_LEN)
        end
        out[k] = v
    end
    return out
end

local function serializeAuthoredTraits(record, field, authoredField, normalizeFn)
    if type(record) ~= "table" or record[authoredField] ~= true
        or type(normalizeFn) ~= "function"
    then
        return nil
    end
    local traits = normalizeFn(record[field])
    return Codec.hasTableEntries(traits) and traits or nil
end

local function trimOrder(order)
    if type(order) ~= "table" then return nil end
    local kind = tostring(order.kind or "")
    if kind == "" or kind == "facility_activity" then return nil end
    if kind == "idle"
        and order.ownerUsername == nil
        and order.ownerCharacterUUID == nil
        and order.x == nil
        and order.points == nil
    then
        return nil
    end
    return order
end

--- Encode ONLY non-default Hoomans-owned durable deltas for a Core-backed record.
--- Returns `nil` when nothing diverges from canonical Core/defaults.
function Extension.Encode(record, actor)
    if type(record) ~= "table" then return nil end
    local out = {}
    local hasFields = false
    local function put(key, val)
        if val ~= nil then
            out[key] = val
            hasFields = true
        end
    end

    local uniqueID = boundedString(record.uniqueDefinitionId, MAX_STRING_LEN)
    if uniqueID then
        put("uniqueDefinitionId", uniqueID)
        if tonumber(record.uniqueDefinitionVersion) then
            put("uniqueDefinitionVersion", math.max(
                1, math.floor(tonumber(record.uniqueDefinitionVersion))
            ))
        end
    end

    local tacticalClass = boundedString(record.tacticalClass, 32) or "neutral"
    if tacticalClass ~= "neutral" then
        put("tacticalClass", tacticalClass)
    end

    local normalizedHostility = CombatRecordRepository.NormalizeHostility(
        record.hostility, tacticalClass
    )
    local defaultHostility = CombatRecordRepository.NormalizeHostility(
        nil, tacticalClass
    )
    if not valuesEqual(normalizedHostility, defaultHostility) then
        put("hostility", normalizedHostility)
    end

    if record.recruited == true then
        put("recruited", true)
        put("ownerUsername", boundedString(record.ownerUsername, MAX_STRING_LEN))
        put("ownerCharacterUUID", boundedString(
            record.ownerCharacterUUID, MAX_STRING_LEN
        ))
    end

    local isEphemeralOrder = type(record.orderSpec) == "table"
        and record.orderSpec.ephemeralDefault == true
    local serializedOrder = not isEphemeralOrder
        and trimOrder(CompanionRecordRepository.SerializeOrder(record)) or nil
    if serializedOrder then
        put("orderSpec", serializedOrder)
        local isPatrol = tostring(serializedOrder.kind or "") == "patrol"
        local patrolPoints = CompanionRecordRepository.SerializePatrolPoints(record)
        if type(patrolPoints) == "table" and (#patrolPoints > 1 or isPatrol) then
            local bounded = {}
            local limit = math.min(#patrolPoints, MAX_MAP_ENTRIES)
            for i = 1, limit do
                bounded[i] = patrolPoints[i]
            end
            put("patrolPoints", bounded)
        end
        if isPatrol and tonumber(record.patrolIndex)
            and math.floor(tonumber(record.patrolIndex)) > 1
        then
            put("patrolIndex", math.max(1, math.floor(tonumber(record.patrolIndex))))
        end
    end

    local fallbackMax = record.health and record.health.max
        or (PNC.Const and PNC.Const.DEFAULT_HP_MAX) or 100
    local serializedHealth = HealthRepository.Serialize(record.health, fallbackMax)
    if type(serializedHealth) == "table" and Codec.hasTableEntries(serializedHealth) then
        put("health", serializedHealth)
    end

    put("stamina", HealthRepository.SerializeStamina(record.stamina))

    local defaultWeaponMode = tacticalClass == "hostile" and "mixed" or "melee"
    local weaponMode = boundedString(record.weaponMode, 32) or defaultWeaponMode
    if weaponMode ~= defaultWeaponMode then
        put("weaponMode", weaponMode)
    end
    local attackType = CombatRecordRepository.NormalizeAttackType(
        record.attackType, weaponMode
    )
    local defaultAttackType = CombatRecordRepository.NormalizeAttackType(
        nil, weaponMode
    )
    if attackType ~= defaultAttackType then
        put("attackType", attackType)
    end

    local jobs = boundedBooleanOrNumberMap(
        record.allowedJobs, "boolean", MAX_MAP_ENTRIES
    )
    local defJobs = boundedBooleanOrNumberMap(
        defaultAllowedJobs(record), "boolean", MAX_MAP_ENTRIES
    )
    if jobs ~= nil and not valuesEqual(jobs, defJobs) then
        put("allowedJobs", jobs)
    end
    put("jobPriorities", boundedBooleanOrNumberMap(
        record.jobPriorities, "number", MAX_MAP_ENTRIES
    ))

    local progression = SkillsRepository.SerializeRecord(record)
    if type(progression) == "table" and Codec.hasTableEntries(progression) then
        -- `recruited` is already explicitly encoded above; keep progression
        -- solely for skill deltas/XP unless deltas/XP exist.
        if progression.skillLevelDeltas ~= nil or progression.skillXP ~= nil then
            put("progression", progression)
        end
    end
    put("skillBaseLevels", SkillsRepository.SerializeBaseLevels(record))
    if PNC.RecipeKnowledge and type(PNC.RecipeKnowledge.Serialize) == "function" then
        put("recipeKnowledge", PNC.RecipeKnowledge.Serialize(record))
    end

    if PNC.ConditionStats
        and type(PNC.ConditionStats.NormalizeState) == "function"
        and type(record.conditionStats) == "table"
    then
        put("conditionStats", PNC.ConditionStats.NormalizeState(record.conditionStats, 0))
    end
    if PNC.NPCTraits and type(PNC.NPCTraits.NormalizeSet) == "function"
        and Codec.hasTableEntries(record.npcTraits)
    then
        local traits = PNC.NPCTraits.NormalizeSet(record.npcTraits)
        if Codec.hasTableEntries(traits) then
            put("npcTraits", traits)
        end
    end
    if record.vanillaTraitsAuthored == true and PNC.PlayerNeedsModel then
        local vt = serializeAuthoredTraits(
            record, "vanillaTraits", "vanillaTraitsAuthored",
            PNC.PlayerNeedsModel.NormalizeTraits
        )
        if vt then
            put("vanillaTraits", vt)
            put("vanillaTraitsAuthored", true)
        end
    end
    if record.dynamicTraitsAuthored == true and PNC.ConditionStats then
        local dt = serializeAuthoredTraits(
            record, "dynamicTraits", "dynamicTraitsAuthored",
            PNC.ConditionStats.NormalizeTraits
        )
        if dt then
            put("dynamicTraits", dt)
            put("dynamicTraitsAuthored", true)
        end
    end

    put("followerAbandonment", CompanionRecordRepository.NormalizeAbandonment(
        record.followerAbandonment
    ))
    put("colonistDeparture", CompanionRecordRepository.NormalizeDeparture(
        record.colonistDeparture
    ))
    if record.survivalStartHours ~= nil then
        put("survivalStartHours", Codec.normalizeNumber(
            record.survivalStartHours, 0
        ))
    end
    if record.lastMilestoneHours ~= nil then
        put("lastMilestoneHours", Codec.normalizeNumber(
            record.lastMilestoneHours, 0
        ))
    end
    if record.milestoneCount ~= nil then
        put("milestoneCount", math.max(0, math.floor(
            Codec.normalizeNumber(record.milestoneCount, 0)
        )))
    end
    put("generation", sanitizeGeneration(record.generation))

    local ax, ay, az = actorPoint(actor)
    if record.spawnX ~= nil and record.spawnY ~= nil
        and pointDiffers(record.spawnX, record.spawnY, record.spawnZ or 0, ax, ay, az)
    then
        put("spawn", {
            x = Codec.normalizeNumber(record.spawnX, ax),
            y = Codec.normalizeNumber(record.spawnY, ay),
            z = Codec.normalizeNumber(record.spawnZ, az),
        })
    end
    if record.anchorX ~= nil and record.anchorY ~= nil
        and pointDiffers(record.anchorX, record.anchorY, record.anchorZ or 0, ax, ay, az)
    then
        put("anchor", {
            x = Codec.normalizeNumber(record.anchorX, ax),
            y = Codec.normalizeNumber(record.anchorY, ay),
            z = Codec.normalizeNumber(record.anchorZ, az),
        })
    end

    if record.alive == false then
        put("alive", false)
    end
    put("corpse", BodyRepository.NormalizeCorpse(record.corpse, record))

    if not hasFields then return nil end
    out.schemaVersion = Extension.SCHEMA_VERSION
    return out
end

--- Restore sparse Hoomans durable deltas onto a newly promoted Core-backed record.
function Extension.Apply(record, ext)
    if type(record) ~= "table" or type(ext) ~= "table" then
        return record
    end
    if ext.uniqueDefinitionId ~= nil then
        record.uniqueDefinitionId = Codec.normalizeString(ext.uniqueDefinitionId)
    end
    if ext.uniqueDefinitionVersion ~= nil then
        record.uniqueDefinitionVersion = math.max(
            1, math.floor(Codec.normalizeNumber(ext.uniqueDefinitionVersion, 1))
        )
    end
    if ext.tacticalClass ~= nil then
        record.tacticalClass = PNC.Types and PNC.Types.NormalizeTacticalClass
            and PNC.Types.NormalizeTacticalClass(ext.tacticalClass)
            or tostring(ext.tacticalClass)
    end
    if type(ext.hostility) == "table" then
        record.hostility = CombatRecordRepository.NormalizeHostility(
            ext.hostility, record.tacticalClass
        )
    end

    record.recruited = ext.recruited == true
    if ext.ownerUsername ~= nil then
        record.ownerUsername = Codec.normalizeString(ext.ownerUsername)
    end
    if ext.ownerCharacterUUID ~= nil then
        record.ownerCharacterUUID = Codec.normalizeString(ext.ownerCharacterUUID)
    end

    if type(ext.spawn) == "table" then
        record.spawnX = Codec.normalizeNumber(ext.spawn.x, record.x)
        record.spawnY = Codec.normalizeNumber(ext.spawn.y, record.y)
        record.spawnZ = Codec.normalizeNumber(ext.spawn.z, record.z)
    end
    if type(ext.anchor) == "table" then
        record.anchorX = Codec.normalizeNumber(ext.anchor.x, record.x)
        record.anchorY = Codec.normalizeNumber(ext.anchor.y, record.y)
        record.anchorZ = Codec.normalizeNumber(ext.anchor.z, record.z)
    end

    CompanionRecordRepository.RestoreDirective(record, {
        patrolPoints = ext.patrolPoints,
        patrolIndex = ext.patrolIndex,
        orderSpec = ext.orderSpec,
    })

    if type(ext.health) == "table" then
        HealthRepository.RestoreHealth(record, ext.health)
    end
    if ext.alive == false then
        record.alive = false
    end
    if type(ext.stamina) == "table" then
        HealthRepository.RestoreStamina(ext.stamina, record)
    end

    if ext.weaponMode ~= nil or ext.attackType ~= nil then
        record.weaponMode = tostring(ext.weaponMode or record.weaponMode or "melee")
        record.attackType = CombatRecordRepository.NormalizeAttackType(
            ext.attackType, record.weaponMode
        )
    end

    if type(ext.allowedJobs) == "table" then
        record.allowedJobs = deepCopy(ext.allowedJobs)
    end
    if type(ext.jobPriorities) == "table" then
        record.jobPriorities = deepCopy(ext.jobPriorities)
    end

    if type(ext.progression) == "table" then
        local progression = SkillsRepository.NormalizeProgression(ext.progression)
        progression.recruited = record.recruited == true
        SkillsRepository.RestoreRecord(record, progression)
    end
    if type(ext.skillBaseLevels) == "table" then
        record.skillBaseLevels = SkillsRepository.NormalizeBaseLevels(
            ext.skillBaseLevels
        )
    end
    if ext.recipeKnowledge ~= nil and PNC.RecipeKnowledge
        and type(PNC.RecipeKnowledge.Normalize) == "function"
    then
        record.recipeKnowledge = PNC.RecipeKnowledge.Normalize(ext.recipeKnowledge)
        if record.runtime then record.runtime.recipeKnowledgeIndex = nil end
    end

    if type(ext.conditionStats) == "table" and PNC.ConditionStats
        and type(PNC.ConditionStats.NormalizeState) == "function"
    then
        record.conditionStats = PNC.ConditionStats.NormalizeState(
            ext.conditionStats, 0
        )
    end
    if type(ext.npcTraits) == "table" and PNC.NPCTraits
        and type(PNC.NPCTraits.NormalizeSet) == "function"
    then
        record.npcTraits = PNC.NPCTraits.NormalizeSet(ext.npcTraits)
        if type(PNC.NPCTraits.Fingerprint) == "function" then
            record.npcTraitFingerprint = PNC.NPCTraits.Fingerprint(record.npcTraits)
        end
    end
    if ext.vanillaTraitsAuthored == true and type(ext.vanillaTraits) == "table"
        and PNC.PlayerNeedsModel
        and type(PNC.PlayerNeedsModel.NormalizeTraits) == "function"
    then
        record.vanillaTraits = PNC.PlayerNeedsModel.NormalizeTraits(ext.vanillaTraits)
        record.vanillaTraitsAuthored = true
    end
    if ext.dynamicTraitsAuthored == true and type(ext.dynamicTraits) == "table"
        and PNC.ConditionStats
        and type(PNC.ConditionStats.NormalizeTraits) == "function"
    then
        record.dynamicTraits = PNC.ConditionStats.NormalizeTraits(ext.dynamicTraits)
        record.dynamicTraitsAuthored = true
        if PNC.NPCTraits and type(PNC.NPCTraits.Fingerprint) == "function" then
            record.dynamicTraitFingerprint =
                PNC.NPCTraits.Fingerprint(record.dynamicTraits)
        end
    end

    CompanionRecordRepository.RestoreMarkers(record, ext)
    if type(ext.generation) == "table" then
        record.generation = deepCopy(ext.generation)
    end
    if ext.corpse ~= nil or record.alive == false then
        BodyRepository.RestoreCorpse(record, ext.corpse)
    end
    return record
end

--- True only when a persisted Core actor has an active Hoomans responsibility
--- that requires immediate promotion on server startup instead of staying
--- abstract in Core until range-enter.
function Extension.RequiresStartupPromotion(ext, actor)
    local lease = type(actor) == "table" and type(actor.providerLease) == "table"
        and actor.providerLease or nil
    if lease and lease.state == "materialized" then
        return true
    end
    if type(ext) ~= "table" then return false end
    if ext.recruited == true
        or Codec.normalizeString(ext.ownerCharacterUUID) ~= nil
        or Codec.normalizeString(ext.ownerUsername) ~= nil
    then
        return true
    end
    if type(ext.generation) == "table"
        and tostring(ext.generation.source or "") == "starting_companion_trait"
    then
        return true
    end
    if type(ext.orderSpec) == "table"
        and STARTUP_ACTIVE_ORDERS[tostring(ext.orderSpec.kind or "")] == true
    then
        return true
    end
    if type(ext.health) == "table" then
        local st = tostring(ext.health.state or "")
        if st == "incapacitated" or st == "downed" then
            return true
        end
    end
    if ext.alive == false then
        return true
    end
    return false
end

return Extension
