-- Bounded reactions and permanent witnessed-death memories for NPC deaths and corpses.

PNC = PNC or {}
PNC.CorpseAwareness = PNC.CorpseAwareness or {}

local Awareness = PNC.CorpseAwareness
Awareness.Internal = Awareness.Internal or {}
local MEMORY_TYPE = "death_witnessed"
local MEMORY_ID_PREFIX = "death_witnessed:"
local MEMORY_LIMIT_PER_NPC = 24
local MAX_WITNESSES_PER_CORPSE = 12
local MAX_RELATIONSHIPS_TO_COUNT = 256
local MAX_RELATIONSHIP_MEMORIES_TO_SCAN = 32
local MAX_CORPSE_ITEMS_TO_SCAN = 256
local MAX_NPCS_TO_SCORE = 64
local MAX_VISIBILITY_CHECKS = 12
local MAX_CORPSE_REACTIONS_PER_SCAN = 8
local SCAN_INTERVAL_MS = 15000
local DETECTION_RADIUS = 10
local DETECTION_RADIUS_SQ = DETECTION_RADIUS * DETECTION_RADIUS
local CACHE_SCHEMA_VERSION = 1
local KINSHIP_MARKERS = {
    relative = true,
    relatives = true,
    family = true,
    kin = true,
    kinship = true,
    sibling = true,
    brother = true,
    sister = true,
    parent = true,
    mother = true,
    father = true,
    mom = true,
    dad = true,
    child = true,
    son = true,
    daughter = true,
    spouse = true,
    husband = true,
    wife = true,
    partner = true,
    lover = true,
    cousin = true,
    grandparent = true,
    grandchild = true,
}
local RELATION_PRIORITY = {
    relative = 5,
    friend = 4,
    hostile = 3,
    comrade = 2,
    neutral = 1,
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function safeDisplayText(value, fallback)
    local text = tostring(value or "")
    text = string.gsub(text, "[%c]", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.sub(text, 1, 120)
    if text == "" then return fallback end
    return text
end

local function nowMs()
    return PNC.Core and PNC.Core.Now
        and math.max(0, tonumber(PNC.Core.Now()) or 0) or 0
end

local function worldAgeHours()
    local hooks = PNC.SocialEventHooks
    local value
    local gameTime
    if hooks and type(hooks.WorldAgeHours) == "function" then
        value = hooks.WorldAgeHours()
        if tonumber(value) then
            return math.max(0, tonumber(value))
        end
    end
    gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        value = gameTime:getWorldAgeHours()
        if tonumber(value) then
            return math.max(0, tonumber(value))
        end
    end
    return 0
end

local function knownKillerName(attribution)
    return Awareness.Internal.Identity.knownKillerName(attribution)
end

local Relationship = {}

local function classify(...)
    return Relationship.classify(...)
end

local function relationFor(...)
    return Relationship.relationFor(...)
end

local function deathMemoryID(...)
    return Relationship.deathMemoryID(...)
end

local function hasMemory(...)
    return Relationship.hasMemory(...)
end

local function deathMemoryCount(...)
    return Relationship.deathMemoryCount(...)
end

local function rememberWitness(...)
    return Awareness.Internal.Reactions.rememberWitness(...)
end

local function hasSpokenMemory(...)
    return Awareness.Internal.Reactions.hasSpokenMemory(...)
end

local function speak(...)
    return Awareness.Internal.Reactions.speak(...)
end

Awareness.Internal.Relationship = Relationship
Awareness.Internal.RelationshipDeps = {
    lower = lower,
    MEMORY_TYPE = MEMORY_TYPE,
    MEMORY_ID_PREFIX = MEMORY_ID_PREFIX,
    MEMORY_LIMIT_PER_NPC = MEMORY_LIMIT_PER_NPC,
    MAX_RELATIONSHIPS_TO_COUNT = MAX_RELATIONSHIPS_TO_COUNT,
    MAX_RELATIONSHIP_MEMORIES_TO_SCAN = MAX_RELATIONSHIP_MEMORIES_TO_SCAN,
    KINSHIP_MARKERS = KINSHIP_MARKERS,
    RELATION_PRIORITY = RELATION_PRIORITY,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Relationship"
Awareness.Internal.IdentityDeps = {
    safeDisplayText = safeDisplayText,
    MAX_CORPSE_ITEMS_TO_SCAN = MAX_CORPSE_ITEMS_TO_SCAN,
    CACHE_SCHEMA_VERSION = CACHE_SCHEMA_VERSION,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Identity_Corpse"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Identity_Death"
local Identity = Awareness.Internal.Identity
Awareness.Internal.ReactionDeps = {
    lower = lower,
    safeDisplayText = safeDisplayText,
    worldAgeHours = worldAgeHours,
    deathMemoryID = Identity.deathMemoryID or deathMemoryID,
    hasMemory = hasMemory,
    knownKillerName = Identity.knownKillerName,
    MEMORY_TYPE = MEMORY_TYPE,
    MEMORY_LIMIT_PER_NPC = MEMORY_LIMIT_PER_NPC,
    DETECTION_RADIUS_SQ = DETECTION_RADIUS_SQ,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Reactions"
Awareness.Internal.CandidateDeps = {
    relationFor = relationFor,
    classify = classify,
    RELATION_PRIORITY = RELATION_PRIORITY,
    DETECTION_RADIUS = DETECTION_RADIUS,
    DETECTION_RADIUS_SQ = DETECTION_RADIUS_SQ,
    MAX_NPCS_TO_SCORE = MAX_NPCS_TO_SCORE,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Candidates"
local Candidates = Awareness.Internal.Candidates
Awareness.Internal.WitnessDeps = {
    deathMemoryID = Identity.deathMemoryID or deathMemoryID,
    deathMemoryCount = deathMemoryCount,
    hasSpokenMemory = Awareness.Internal.Reactions.hasSpokenMemory,
    rememberWitness = Awareness.Internal.Reactions.rememberWitness,
    speak = Awareness.Internal.Reactions.speak,
    knownKillerName = Identity.knownKillerName,
    collectCandidates = Candidates.collectCandidates,
    MEMORY_LIMIT_PER_NPC = MEMORY_LIMIT_PER_NPC,
    MAX_WITNESSES_PER_CORPSE = MAX_WITNESSES_PER_CORPSE,
    MAX_VISIBILITY_CHECKS = MAX_VISIBILITY_CHECKS,
    MAX_CORPSE_REACTIONS_PER_SCAN = MAX_CORPSE_REACTIONS_PER_SCAN,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_Witnesses"
local Witnesses = Awareness.Internal.Witnesses
Awareness.Internal.ObserveDeps = {
    modDataOf = Identity.modDataOf,
    nowMs = nowMs,
    deathIdentityFromRecord = Identity.deathIdentityFromRecord,
    deathAttribution = Identity.deathAttribution,
    copyDeathIdentity = Identity.copyDeathIdentity,
    corpseIdentity = Identity.corpseIdentity,
    cachedDeathAttribution = Identity.cachedDeathAttribution,
    cacheCorpseIdentity = Identity.cacheCorpseIdentity,
    cacheDeathAttribution = Identity.cacheDeathAttribution,
    cacheDeathAwarenessState = Identity.cacheDeathAwarenessState,
    deathMemoryID = deathMemoryID,
    processWitnesses = Witnesses.processWitnesses,
    MAX_WITNESSES_PER_CORPSE = MAX_WITNESSES_PER_CORPSE,
    CACHE_SCHEMA_VERSION = CACHE_SCHEMA_VERSION,
    SCAN_INTERVAL_MS = SCAN_INTERVAL_MS,
}
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_ObserveDeath"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness_ObserveCorpse"

return Awareness
