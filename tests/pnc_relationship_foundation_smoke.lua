local T = require "tests/support/test"

local SHARED_ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT =
    T.path("ProjectHoomans", "server", "PNC/")

local function containsMemory(relationship, memoryID)
    local _
    local memory
    for _, memory in pairs(relationship.memories or {}) do
        if memory.id == memoryID then
            return true
        end
    end
    return false
end

local function countMemories(relationship)
    local count = 0
    local _
    for _, _ in pairs(relationship.memories or {}) do
        count = count + 1
    end
    return count
end

local function validatePersistedValue(value, path, seen)
    local valueType = type(value)
    local key
    local item
    path = path or "root"
    if valueType == "nil"
        or valueType == "string"
        or valueType == "number"
        or valueType == "boolean"
    then
        return
    end
    if valueType ~= "table" then
        error("unsafe persisted value at " .. path .. ": " .. valueType)
    end
    if getmetatable(value) ~= nil then
        error("metatable found at " .. path)
    end
    seen = seen or {}
    if seen[value] then
        error("cycle found at " .. path)
    end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe key at " .. path)
        end
        validatePersistedValue(item, path .. "." .. tostring(key), seen)
    end
    seen[value] = nil
end

T.load(T.path("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"))
PNC = {}
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")

T.load(SHARED_ROOT .. "Identity/PNC_Identity.lua")
PNC.Identity.ApplyRecordIdentity =
    function(record, definition)
        record.identitySeed = tonumber(definition.identitySeed)
            or record.identitySeed or 1
        record.identity = definition.identity or record.identity or {
            seed = record.identitySeed,
            survivor = {},
        }
        record.name = definition.displayName or definition.name
            or record.name or "Relationship Test"
        record.archetypeID = definition.archetypeID
            or record.archetypeID or "General"
        record.isFemale = definition.isFemale == true
    end

T.load(SHARED_ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialTraits.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileMath.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductConstants.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductTypes.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductMath.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipConstants.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipStates.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipMath.lua")
T.load(SHARED_ROOT .. "Base/PNC_Types.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_Relationships.lua")
T.load(SHARED_ROOT .. "Persistence/PNC_Persistence.lua")

PNC.Registry = {
    Data = {},
    DirtyByID = {},
    DirtyDomains = {},
}

function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end

function PNC.Registry.MarkDirty(record, domain)
    local id = tostring(record.id)
    if not PNC.Registry.DirtyByID[id] then
        record.recordRevision =
            math.max(0, math.floor(tonumber(record.recordRevision) or 0)) + 1
    end
    PNC.Registry.DirtyByID[id] = true
    PNC.Registry.DirtyDomains[id] =
        PNC.Registry.DirtyDomains[id] or {}
    PNC.Registry.DirtyDomains[id][domain] = true
    return true
end

T.load(SERVER_ROOT .. "Social/PNC_RelationshipService.lua")
T.load(SERVER_ROOT .. "Social/PNC_RelationshipDebug.lua")

T.equal(PNC.Relationships.Personal.Queries.Get,
    PNC.Relationships.Get, "personal relationship query compatibility")
T.equal(PNC.Relationships.Personal.Commands.AddMemory,
    PNC.Relationships.AddMemory, "personal relationship command compatibility")
T.equal(PNC.Relationships.Personal.Commands.ApplyEventMutation,
    PNC.Relationships.ApplyEventMutation,
    "personal relationship event command compatibility")
T.equal(PNC.Relationships.Personal.Commands.ApplyConversationEffect,
    PNC.Relationships.ApplyConversationEffect,
    "personal relationship conversation command compatibility")

local function newRecord(id)
    local record = PNC.Types.NewRecord({
        id = id,
        displayName = id,
        tacticalClass = "neutral",
        x = 0,
        y = 0,
        z = 0,
        identity = { seed = 1, survivor = {} },
    })
    PNC.Registry.Data[id] = record
    return record
end

local function memory(id, targetKey, overrides)
    local spec = {
        id = id,
        type = "test_memory",
        aboutKey = targetKey,
        createdAt = 0,
        lastEvaluatedAt = 0,
        approvalEffect = 10,
        respectEffect = 5,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = false,
        shareable = true,
        knowledgeSource = "experienced",
        tags = { test = true },
    }
    local key
    local value
    for key, value in pairs(overrides or {}) do
        spec[key] = value
    end
    return spec
end

-- 1. New social state defaults.
local defaults = PNC.RelationshipTypes.NewSocialState()
T.equal(defaults.schemaVersion, 3, "social schema default")
T.equal(defaults.revision, 0, "social revision default")
T.equal(defaults.morale, 0, "social morale default")
T.equal(type(defaults.relationships), "table",
    "social relationships default")

-- 2-5. Directed keys and safe parsing.
local alice = newRecord("npc_alice")
local bob = newRecord("npc_bob")
T.equal(alice.affiliation.membershipStatus,
    "unaffiliated", "new NPC affiliation default")
T.equal(alice.affiliation.factionID, nil,
    "new NPC has no invented faction")
local aliceKey = PNC.EntityRef.ForNPC(alice.id)
local bobKey = PNC.EntityRef.ForNPC(bob.id)
local playerKey = PNC.EntityRef.ForPlayerIdentity(
    "Patrick",
    "char_f8d31a"
)
T.equal(PNC.EntityRef.Parse(bobKey).npcID, "npc_bob",
    "NPC key parsing")
local parsedPlayer = PNC.EntityRef.Parse(playerKey)
T.equal(parsedPlayer.accountIdentity, "Patrick",
    "player account parsing")
T.equal(parsedPlayer.characterUUID, "char_f8d31a",
    "player character parsing")
T.equal(PNC.EntityRef.Parse("player:Patrick"), nil,
    "malformed player key")
T.equal(PNC.EntityRef.Parse("npc:"), nil, "malformed NPC key")
T.equal(PNC.EntityRef.ForPlayerIdentity("Patrick", nil), nil,
    "username-only identity rejected")

T.equal(PNC.Relationships.AddMemory(
    alice.id,
    bobKey,
    memory("alice_likes_bob", bobKey)
), true, "Alice memory added")
T.equal(PNC.Relationships.AddMemory(
    bob.id,
    aliceKey,
    memory("bob_dislikes_alice", aliceKey, {
        approvalEffect = -20,
    })
), true, "Bob memory added")
T.equal(PNC.Relationships.GetApproval(alice.id, bobKey), 10,
    "Alice directed approval")
T.equal(PNC.Relationships.GetApproval(bob.id, aliceKey), -20,
    "Bob reverse approval")
T.equal(PNC.Relationships.AddMemory(
    alice.id,
    playerKey,
    memory("alice_knows_player_character", playerKey, {
        approvalEffect = 4,
        respectEffect = 2,
    })
), true, "player-character relationship added")
T.equal(PNC.Relationships.GetApproval(alice.id, playerKey), 4,
    "player-character relationship stored")
local playerChange =
    alice.runtime.relationshipDebugChanges[
        #alice.runtime.relationshipDebugChanges
    ]
T.equal(playerChange.targetKey, playerKey,
    "debug change targets exact player character")
T.equal(playerChange.kind, "memory_added",
    "debug change records memory mutation type")
T.equal(playerChange.memoryType, "test_memory",
    "debug change records social cause")
T.equal(playerChange.approvalDelta, 4,
    "debug change records approval delta")
T.equal(playerChange.respectDelta, 2,
    "debug change records respect delta")
T.equal(playerChange.stateBefore, "unknown",
    "debug change records prior state")
validatePersistedValue(playerChange, "relationshipDebugChange")
local debugFeedPayload =
    PNC.Persistence.SerializeRecord(alice)
T.equal(debugFeedPayload.runtime, nil,
    "runtime relationship change feed is not persisted")
T.equal(
    debugFeedPayload.social.relationshipDebugChanges,
    nil,
    "debug change feed does not enter social persistence"
)

-- 6-9. Numeric clamping.
local clampKey = PNC.EntityRef.ForNPC("npc_clamp")
local high = PNC.RelationshipTypes.NewRelationship(clampKey)
high.baselineApproval = 100
high.memories = {
    memory("high", clampKey, { approvalEffect = 100 }),
}
high = PNC.RelationshipMath.RecalculateRelationship(high, clampKey, 0)
T.equal(high.approval, 100, "approval upper clamp")
local low = PNC.RelationshipTypes.NewRelationship(clampKey)
low.baselineApproval = -100
low.memories = {
    memory("low", clampKey, { approvalEffect = -100 }),
}
low = PNC.RelationshipMath.RecalculateRelationship(low, clampKey, 0)
T.equal(low.approval, -100, "approval lower clamp")
local respect = PNC.RelationshipTypes.NewRelationship(clampKey)
respect.baselineRespect = -100
respect.memories = {
    memory("respect", clampKey, { respectEffect = -100 }),
}
respect = PNC.RelationshipMath.RecalculateRelationship(
    respect,
    clampKey,
    0
)
T.equal(respect.respect, -100, "respect clamp")
local familiarity = PNC.RelationshipTypes.NormalizeRelationship({
    familiarity = 1000,
}, clampKey)
T.equal(familiarity.familiarity, 100, "familiarity upper clamp")
familiarity = PNC.RelationshipTypes.NormalizeRelationship({
    familiarity = -1000,
}, clampKey)
T.equal(familiarity.familiarity, 0, "familiarity lower clamp")

-- 10-11. Deterministic temporary decay and permanent memory.
local temporary = memory("temporary", clampKey, {
    strength = 1,
    decayPerDay = 0.25,
})
T.near(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
    temporary,
    48
), 0.5, 0.000001, "temporary decay")
local permanent = memory("permanent", clampKey, {
    strength = 0.8,
    decayPerDay = 1,
    permanent = true,
})
T.near(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
    permanent,
    2400
), 0.8, 0.000001, "permanent memory")

-- 12. Duplicate IDs are rejected.
T.equal(PNC.Relationships.AddMemory(
    alice.id,
    bobKey,
    memory("alice_likes_bob", bobKey)
), false, "duplicate memory ID")
T.equal(PNC.Relationships.AddMemory(
    {},
    bobKey,
    memory("bad_observer", bobKey)
), false, "live/table observer rejected")
T.equal(PNC.Relationships.AddMemory(
    alice.id,
    "player:username-only",
    memory("bad_target", bobKey)
), false, "malformed service target rejected")
T.equal(PNC.Relationships.AddMemory(
    alice.id,
    bobKey,
    { type = "missing_id", aboutKey = bobKey }
), false, "invalid memory rejected")

-- 13-14. Limit preserves permanent entries and removes weakest temporary.
local limited = PNC.RelationshipTypes.NewRelationship(clampKey)
limited.memories[1] = memory("permanent_keep", clampKey, {
    permanent = true,
    strength = 0.1,
})
for index = 1, 20 do
    limited.memories[#limited.memories + 1] = memory(
        string.format("temporary_%02d", index),
        clampKey,
        { strength = index / 20 }
    )
end
limited = PNC.RelationshipMath.PruneMemories(
    limited,
    clampKey,
    0,
    20
)
T.equal(countMemories(limited), 20, "memory limit")
T.equal(containsMemory(limited, "permanent_keep"), true,
    "permanent preserved")
T.equal(containsMemory(limited, "temporary_01"), false,
    "weakest temporary removed")

-- 15-18. Entry thresholds and hysteresis.
local stateRel = PNC.RelationshipTypes.NewRelationship(clampKey)
stateRel.familiarity = 5
stateRel.baselineApproval = 35
stateRel.baselineRespect = 15
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "friend", "friend entry")
stateRel.baselineApproval = 25
stateRel.baselineRespect = 5
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "friend", "friend hysteresis")

stateRel = PNC.RelationshipTypes.NewRelationship(clampKey)
stateRel.familiarity = 5
stateRel.baselineApproval = -25
stateRel.baselineRespect = 25
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "rival", "rival entry")
stateRel.baselineApproval = -15
stateRel.baselineRespect = 15
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "rival", "rival hysteresis")
stateRel.baselineApproval = -14
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state ~= "rival", true, "rival exit")

stateRel = PNC.RelationshipTypes.NewRelationship(clampKey)
stateRel.familiarity = 5
stateRel.baselineApproval = -60
stateRel.baselineRespect = 0
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "enemy", "enemy entry")
stateRel.baselineApproval = -45
stateRel.baselineRespect = 50
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state, "enemy", "enemy hysteresis")
stateRel.baselineApproval = -44
stateRel = PNC.RelationshipMath.RecalculateRelationship(
    stateRel,
    clampKey,
    0
)
T.equal(stateRel.state ~= "enemy", true, "enemy exit")

-- 19. Recalculation never touches the reverse direction.
local reverseBefore = PNC.Relationships.Get(bob.id, aliceKey)
PNC.Relationships.Recalculate(alice.id, bobKey, 24)
local reverseAfter = PNC.Relationships.Get(bob.id, aliceKey)
T.equal(PNC.RelationshipTypes.AreEqual(
    reverseBefore,
    reverseAfter
), true, "reverse relationship remains independent")

-- 20-22. No-op revisions, mutation revisions, and presence isolation.
local revisionRecord = newRecord("npc_revisions")
local revisionTarget = PNC.EntityRef.ForNPC("npc_revision_target")
PNC.Registry.DirtyByID[revisionRecord.id] = nil
local presenceBefore = revisionRecord.presenceRevision
T.equal(PNC.Relationships.AddMemory(
    revisionRecord.id,
    revisionTarget,
    memory("revision_memory", revisionTarget)
), true, "revision mutation")
local revisionRelationship =
    revisionRecord.social.relationships[revisionTarget]
T.equal(revisionRelationship.revision, 1,
    "relationship revision increment")
T.equal(revisionRecord.social.revision, 1,
    "social revision increment")
T.equal(revisionRecord.recordRevision, 1,
    "record revision increment")
T.equal(revisionRecord.presenceRevision, presenceBefore,
    "presence revision unchanged")
local relationRevisionBefore = revisionRelationship.revision
local socialRevisionBefore = revisionRecord.social.revision
local recordRevisionBefore = revisionRecord.recordRevision
T.equal(PNC.Relationships.Recalculate(
    revisionRecord.id,
    revisionTarget,
    0
), false, "no-op recalculation")
T.equal(revisionRelationship.revision, relationRevisionBefore,
    "no-op relationship revision")
T.equal(revisionRecord.social.revision, socialRevisionBefore,
    "no-op social revision")
T.equal(revisionRecord.recordRevision, recordRevisionBefore,
    "no-op record revision")

-- 23. Normalization is idempotent and repairs non-finite values.
local malformed = {
    schemaVersion = 999,
    revision = -4,
    morale = 0 / 0,
    moraleBaseline = math.huge,
    relationships = {
        [clampKey] = {
            approval = math.huge,
            respect = -math.huge,
            familiarity = -5,
            state = "future_state",
            memories = {
                { id = nil, type = "invalid", aboutKey = clampKey },
                memory("valid", clampKey),
            },
        },
        ["not-a-key"] = {},
    },
}
local normalizedOnce =
    PNC.RelationshipTypes.NormalizeSocialState(malformed)
local normalizedTwice =
    PNC.RelationshipTypes.NormalizeSocialState(normalizedOnce)
T.equal(PNC.RelationshipTypes.AreEqual(
    normalizedOnce,
    normalizedTwice
), true, "normalization idempotence")
T.equal(normalizedOnce.morale, 0, "NaN repaired")
T.equal(normalizedOnce.moraleBaseline, 0, "infinity repaired")
T.equal(countMemories(
    normalizedOnce.relationships[clampKey]
), 1, "invalid memory discarded")

-- Conversation cooldowns are stored by the same persistent relationship
-- mutation boundary as the memory and score effects.
local conversationApplied = PNC.Relationships.ApplyConversationEffect(
    alice.id,
    playerKey,
    {
        memoryType = "player_admired",
        interactionType = "player_admired",
        approval = 3,
        respect = 4,
        familiarity = 1,
    },
    {
        blockID = "llm_social_reaction",
        choiceID = "conversation-cooldown",
        outcomeID = "admire",
        worldAgeHours = 24,
        cooldownType = "llm_positive_social",
        cooldownUntil = 48,
    }
)
T.truthy(conversationApplied,
    "conversation effect commits through relationship mutation")
local conversationRelationship = PNC.Relationships.Get(
    alice.id,
    playerKey
)
T.equal(conversationRelationship.cooldowns.llm_positive_social, 48,
    "conversation positive cooldown is persisted")
T.equal(conversationRelationship.memories[
    #conversationRelationship.memories
].type, "player_admired", "conversation memory type is persisted")
T.equal(#conversationRelationship.interactionJournal, 1,
    "conversation interaction is attached to the relationship journal")
T.equal(
    conversationRelationship.interactionJournal[1].interactionType,
    "player_admired",
    "relationship journal preserves the interaction type"
)
local relationshipPayload = PNC.Persistence.SerializeRecord(
    PNC.Registry.Get(alice.id)
)
local relationshipReloaded = PNC.Persistence.DeserializeRecord(
    relationshipPayload,
    alice.id
)
local reloadedJournal = relationshipReloaded.social.relationships[playerKey]
    .interactionJournal
T.equal(#reloadedJournal, 1,
    "relationship interaction journal survives record serialization")
T.equal(reloadedJournal[1].eventID,
    conversationRelationship.interactionJournal[1].eventID,
    "relationship journal event identity survives reload")

-- 24-25. Older records migrate deterministically to V15 and can run again.
T.equal(PNC.Const.PERSISTENCE_VERSION, 15,
    "persistence schema advanced to V15")
local oldRaw = {
    schemaVersion = 10,
    recordRevision = 7,
    id = "npc_migration",
    tacticalClass = "neutral",
    persist = true,
    position = { x = 1, y = 2, z = 0 },
    spawn = { x = 1, y = 2, z = 0 },
    anchor = { x = 1, y = 2, z = 0 },
    identity = {
        seed = 9,
        displayName = "Migration Test",
        survivor = {},
    },
}
local migrated = PNC.Persistence.DeserializeRecord(
    oldRaw,
    oldRaw.id
)
T.equal(migrated.social.schemaVersion, 3,
    "migration adds social data")
T.equal(next(migrated.social.relationships), nil,
    "migration keeps relationships sparse")
T.equal(migrated.social.conduct.scores.reliability, 0,
    "migration adds neutral NPC conduct")
T.equal(#migrated.social.conduct.evidence, 0,
    "migration does not infer conduct evidence")
T.equal(migrated.affiliation.membershipStatus,
    "unaffiliated", "migration adds neutral affiliation")
T.equal(migrated.affiliation.factionID, nil,
    "migration invents no faction membership")
local migratedPayload = PNC.Persistence.SerializeRecord(migrated)
T.equal(migratedPayload.schemaVersion, 15,
    "migration writes V15")
local migratedAgain = PNC.Persistence.DeserializeRecord(
    migratedPayload,
    migrated.id
)
T.equal(PNC.RelationshipTypes.AreEqual(
    migrated.social,
    migratedAgain.social
), true, "migration rerun is safe")
T.equal(PNC.FactionTypes.AreEqual(
    migrated.affiliation,
    migratedAgain.affiliation
), true, "affiliation migration rerun is safe")

-- 26. Serialized payload is primitive/table-only and has no metatables.
validatePersistedValue(migratedPayload)

-- Read-only diagnostics and existing faction behavior remain intact.
local debugText = PNC.RelationshipDebug.Inspect(
    alice.id,
    bobKey,
    24
)
T.contains(debugText, "Relationship Debug", "debug heading")
T.contains(debugText, "test_memory", "debug memory")
local neutralDefaults = PNC.Types.DefaultHostility("neutral")
T.equal(neutralDefaults.attackPlayers, false,
    "neutral faction behavior unchanged")
T.equal(PNC.Relationships.AreNPCsEnemies(
    { id = "one", tacticalClass = "neutral", hostility = neutralDefaults },
    { id = "two", tacticalClass = "hostile" }
), true, "existing faction enemy API")
T.finish("pnc_relationship_foundation_smoke")

T.finish("pnc_relationship_foundation_smoke")
