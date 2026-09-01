local T = require "tests/support/test"

local SHARED_ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT =
    T.path("ProjectHoomans", "server", "PNC/")

local function memoryCount(relationship, memoryType)
    local count = 0
    local _, memory
    for _, memory in pairs(relationship and relationship.memories or {}) do
        if not memoryType or memory.type == memoryType then
            count = count + 1
        end
    end
    return count
end

local function evidenceCount(conduct, eventType)
    local count = 0
    for _, evidence in ipairs(conduct and conduct.evidence or {}) do
        if not eventType or evidence.eventType == eventType then
            count = count + 1
        end
    end
    return count
end

local function validatePersistedValue(value, seen)
    local valueType = type(value)
    local key
    local item
    if valueType == "nil"
        or valueType == "string"
        or valueType == "number"
        or valueType == "boolean"
    then
        return
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        error("unsafe persisted value: " .. valueType)
    end
    seen = seen or {}
    if seen[value] then error("cycle in persisted value") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe persisted key")
        end
        validatePersistedValue(item, seen)
    end
    seen[value] = nil
end

T.load(T.path("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"))
PNC = {}
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")
T.load(SHARED_ROOT
    .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_Identity.lua")
PNC.Identity.ApplyRecordIdentity =
    function(record, definition)
        record.identitySeed = 1
        record.identity = definition.identity
            or { seed = 1, survivor = {} }
        record.name = definition.displayName
            or definition.name or record.id
        record.archetypeID = definition.archetypeID or "General"
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
T.load(SHARED_ROOT .. "Conduct/PNC_ConductDefinitions.lua")
T.load(SHARED_ROOT
    .. "Identity/PNC_PlayerCharacterTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipConstants.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipStates.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipMath.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialEventDefinitions.lua")
T.load(SHARED_ROOT .. "Base/PNC_Types.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_Relationships.lua")
T.load(SHARED_ROOT .. "Persistence/PNC_Persistence.lua")

PNC.Registry = {
    Data = {},
    DirtyByID = {},
    DirtyDomains = {},
}

local identityGlobalData = {
    PNC_PlayerCharacters =
        PNC.PlayerCharacterTypes.NewRegistry(),
}
identityGlobalData.PNC_PlayerCharacters.byUUID.char_phase2 =
    PNC.PlayerCharacterTypes.NewCharacterRecord({
        uuid = "char_phase2",
        accountIdentity = "Patrick",
        status = "active",
        createdAt = 0,
        firstSeenAt = 0,
        lastSeenAt = 0,
        revision = 1,
    })
identityGlobalData.PNC_PlayerCharacters.byAccount.Patrick = {
    char_phase2 = true,
}
ModData = {
    getOrCreate = function(key)
        identityGlobalData[key] = identityGlobalData[key] or {}
        return identityGlobalData[key]
    end,
}

function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end

function PNC.Registry.MarkDirty(record, domain)
    local id = tostring(record.id)
    if not PNC.Registry.DirtyByID[id] then
        record.recordRevision =
            (tonumber(record.recordRevision) or 0) + 1
    end
    PNC.Registry.DirtyByID[id] = true
    PNC.Registry.DirtyDomains[id] =
        PNC.Registry.DirtyDomains[id] or {}
    PNC.Registry.DirtyDomains[id][domain] = true
    return true
end

T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterDebug.lua")
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterService.lua")
PNC.PlayerCharacters.Load()
T.load(SERVER_ROOT .. "Social/PNC_ConductService.lua")
T.load(SERVER_ROOT .. "Social/PNC_RelationshipService.lua")
T.load(SERVER_ROOT .. "Social/PNC_RelationshipDebug.lua")
T.load(SERVER_ROOT .. "Social/PNC_ConductDebug.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEventDebug.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialProfileDebug.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialProfileService.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEventService.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEncounterTracker.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEventHooks.lua")

local function newRecord(id)
    local record = PNC.Types.NewRecord({
        id = id,
        displayName = id,
        tacticalClass = "neutral",
        x = 0,
        y = 0,
        z = 0,
        identity = { seed = 1, survivor = {} },
        social = {
            personality = {
                schemaVersion = 1,
                orientation = "straight",
                foodPreference = "neutral",
                romanceStyle = "neutral",
                jealousyStyle = "normal",
                socialStyle = "neutral",
                compassion = 0.5,
                sociability = 0.5,
                forgiveness = 0.5,
                bravery = 0.5,
                materialism = 0.5,
                aggression = 0.5,
                loyalty = 0.5,
                generatedFromSeed = true,
                generationVersion = 1,
            },
        },
    })
    PNC.Registry.Data[id] = record
    return record
end

local function clearDirty()
    PNC.Registry.DirtyByID = {}
    PNC.Registry.DirtyDomains = {}
end

local function event(id, eventType, actorKey, targetKey, at)
    local source = eventType == "treated_wound"
        and "wounds"
        or eventType == "saved_from_incapacitation"
            and "health"
            or "combat"
    return {
        id = id,
        type = eventType,
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = at,
        sourceSystem = source,
        context = {},
    }
end

local alice = newRecord("npc_social_alice")
local bob = newRecord("npc_social_bob")
local carol = newRecord("npc_social_carol")
local aliceKey = PNC.EntityRef.ForNPC(alice.id)
local bobKey = PNC.EntityRef.ForNPC(bob.id)
local carolKey = PNC.EntityRef.ForNPC(carol.id)
local playerKey = PNC.EntityRef.ForPlayerIdentity(
    "Patrick",
    "char_phase2"
)

-- 1. Exactly the known data-driven definitions load.
local definitionCount = 0
for _, _ in pairs(PNC.SocialEventDefinitions) do
    definitionCount = definitionCount + 1
end
T.equal(definitionCount, 14, "fourteen definitions")
T.equal(
    PNC.SocialEvents.GetDefinition("treated_wound")
        .targetMemory.approvalEffect,
    4,
    "treated wound balance"
)

-- 2-3. Unknown and malformed/unsafe events fail safely.
T.equal(PNC.SocialEvents.Emit(event(
    "social:unknown:1",
    "not_registered",
    playerKey,
    bobKey,
    1
)).reason, "unknown_event_type", "unknown event rejected")
local malformed = event(
    "social:bad:1",
    "treated_wound",
    playerKey,
    bobKey,
    1
)
malformed.context.unsafe = function() end
T.equal(
    PNC.SocialEvents.Emit(malformed).reason,
    "unsafe_event",
    "unsafe event rejected"
)

-- 4-9. Treatment effects, dedupe, cooldown, and expiry.
local treated = event(
    "social:treated_wound:1",
    "treated_wound",
    playerKey,
    bobKey,
    1
)
local first = PNC.SocialEvents.Emit(treated)
T.truthy(first.ok, "treatment event accepted")
T.truthy(string.find(
    PNC.SocialEventDebug.FormatProcessed(
        first,
        PNC.SocialEvents.GetDefinition("treated_wound")
    ),
    "Memory created:",
    1,
    true
) ~= nil, "social event debug formatter")
local bobToPlayer = PNC.Relationships.Get(bob.id, playerKey)
T.equal(memoryCount(bobToPlayer, "treated_wound"), 1,
    "target memory created")
T.equal(bobToPlayer.approval, 4, "treatment approval")
T.equal(bobToPlayer.familiarity, 2, "treatment familiarity")
T.equal(bob.social.morale, 2, "treatment morale")
local playerConduct = PNC.Conduct.GetForEntity(playerKey)
T.equal(playerConduct.scores.compassion, 2,
    "treatment actor compassion conduct")
T.equal(playerConduct.scores.generosity, 1,
    "treatment actor generosity conduct")
T.equal(evidenceCount(playerConduct, "treated_wound"), 1,
    "treatment actor evidence")
T.equal(PNC.SocialEvents.Emit(treated).reason, "duplicate_event",
    "duplicate event rejected")
T.equal(memoryCount(PNC.Relationships.Get(bob.id, playerKey)), 1,
    "duplicate creates no memory")
local cooldown = PNC.SocialEvents.Emit(event(
    "social:treated_wound:2",
    "treated_wound",
    playerKey,
    bobKey,
    2
))
T.equal(cooldown.reason, "cooldown_active",
    "treatment cooldown blocks farming")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(playerKey),
    "treated_wound"
), 1, "cooldown creates no conduct")
local afterCooldown = PNC.SocialEvents.Emit(event(
    "social:treated_wound:3",
    "treated_wound",
    playerKey,
    bobKey,
    13
))
T.truthy(afterCooldown.ok, "cooldown expiration")

-- 10. Contribution saturation clips and then rejects repeated gains.
for index = 1, 6 do
    T.truthy(PNC.SocialEvents.Emit(event(
        "social:treated_wound:cap" .. tostring(index),
        "treated_wound",
        playerKey,
        bobKey,
        13 + index * 12
    )).ok, "treatment cap setup " .. tostring(index))
end
T.equal(
    PNC.Relationships.Get(bob.id, playerKey)
        .saturation.treated_wound.approval,
    20,
    "treatment cumulative approval cap"
)
T.equal(PNC.SocialEvents.Emit(event(
    "social:treated_wound:saturated",
    "treated_wound",
    playerKey,
    bobKey,
    97
)).reason, "contribution_saturated", "saturation rejection")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(playerKey),
    "treated_wound"
), 8, "saturation creates no conduct")

-- 11-12. One rescue per episode and no nearest-player guessing.
local rescue = event(
    "social:save:episode_1:" .. playerKey,
    "saved_from_incapacitation",
    playerKey,
    carolKey,
    70
)
T.truthy(PNC.SocialEvents.Emit(rescue).ok, "rescue accepted")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(playerKey),
    "saved_from_incapacitation"
), 1, "rescue actor evidence")
T.equal(PNC.SocialEvents.Emit(rescue).reason, "duplicate_event",
    "rescue episode idempotent")
carol.health.state = "normal"
T.equal(PNC.SocialEventHooks.OnIncapacitationRecovered(
    carol,
    "downed:untracked",
    71
).reason, "unverified_rescuer", "unverified nearby player not credited")
local hookTarget = newRecord("npc_hook_rescue")
hookTarget.health.state = "incapacitated"
hookTarget.health.downedAt = 12345
local fakePlayer = {
    getUsername = function() return "Patrick" end,
    getModData = function()
        return { PNC_CharacterUUID = "char_phase2" }
    end,
}
T.truthy(PNC.SocialEventHooks.OnTreatmentCompleted(
    fakePlayer,
    hookTarget,
    "Torso_Upper",
    { occurredAt = 72, actionID = "hook_action" }
).ok, "treatment hook emits centralized event")
local hookEpisode =
    PNC.SocialEventHooks.GetDownedEpisodeID(hookTarget)
hookTarget.health.state = "normal"
T.truthy(PNC.SocialEventHooks.OnIncapacitationRecovered(
    hookTarget,
    hookEpisode,
    73
).ok, "verified treatment contributor receives rescue credit")
T.equal(memoryCount(
    PNC.Relationships.Get(hookTarget.id, playerKey),
    "saved_from_incapacitation"
), 1, "recovery hook creates one rescue memory")

-- 13-15. Protection is threat-attributed and encounter-aggregated.
PNC.SocialEncounterTracker.Reset()
local encounterID = PNC.SocialEncounterTracker.RecordNPCDamaged(
    bob,
    "zombie_1",
    80,
    { x = 1, y = 1, z = 0 }
)
PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "zombie_1",
    threatWasTargeting = true,
    occurredAt = 80,
})
T.truthy(select(1, PNC.SocialEncounterTracker.OnThreatNeutralized({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "zombie_1",
    threatWasTargeting = true,
    occurredAt = 80.01,
})), "protection accepted")
PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "zombie_2",
    threatWasTargeting = true,
    occurredAt = 80.02,
})
PNC.SocialEncounterTracker.OnThreatNeutralized({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "zombie_2",
    threatWasTargeting = true,
    occurredAt = 80.03,
})
T.equal(memoryCount(
    PNC.Relationships.Get(bob.id, aliceKey),
    "protected_from_attacker"
), 1, "several kills aggregate to one protection memory")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "protected_from_attacker"
), 1, "protection aggregated conduct evidence")
PNC.SocialEncounterTracker.Reset()
PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    threatID = "unrelated_zombie",
    threatWasTargeting = false,
    occurredAt = 81,
})
local unrelatedOK, unrelatedReason =
    PNC.SocialEncounterTracker.OnThreatNeutralized({
        actorKey = aliceKey,
        threatID = "unrelated_zombie",
        threatWasTargeting = false,
        occurredAt = 81.01,
    })
T.truthy(unrelatedOK, "unrelated kill tracked as combat")
T.equal(unrelatedReason, "neutralized_without_protection",
    "unrelated kill grants no protection")

-- 16-18. Shared combat is reciprocal for NPCs, one-sided for players, and
-- trivial encounters do not qualify.
PNC.SocialEncounterTracker.Reset()
local sharedNPC = PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    targetKey = carolKey,
    threatID = "shared_1",
    occurredAt = 90,
    targetTookDamage = true,
})
PNC.SocialEncounterTracker.RecordActivity({
    encounterID = sharedNPC,
    actorKey = aliceKey,
    targetKey = carolKey,
    threatID = "shared_2",
    occurredAt = 90.001,
})
T.truthy(select(1, PNC.SocialEncounterTracker.EndEncounter(
    sharedNPC,
    90.002
)), "NPC shared encounter ended")
T.equal(memoryCount(
    PNC.Relationships.Get(alice.id, carolKey),
    "survived_combat_together"
), 1, "Alice reciprocal shared memory")
T.equal(memoryCount(
    PNC.Relationships.Get(carol.id, aliceKey),
    "survived_combat_together"
), 1, "Carol reciprocal shared memory")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "survived_combat_together"
), 1, "Alice participant conduct")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(carolKey),
    "survived_combat_together"
), 1, "Carol participant conduct")

PNC.SocialEncounterTracker.Reset()
local sharedPlayer = PNC.SocialEncounterTracker.RecordActivity({
    actorKey = playerKey,
    targetKey = aliceKey,
    threatID = "shared_player_1",
    occurredAt = 91,
    targetTookDamage = true,
})
PNC.SocialEncounterTracker.EndEncounter(sharedPlayer, 91.002)
T.equal(memoryCount(
    PNC.Relationships.Get(alice.id, playerKey),
    "survived_combat_together"
), 1, "player NPC shared combat has NPC-owned memory")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(playerKey),
    "survived_combat_together"
), 1, "player shared-combat conduct")

PNC.SocialEncounterTracker.Reset()
local trivial = PNC.SocialEncounterTracker.RecordActivity({
    actorKey = bobKey,
    targetKey = carolKey,
    threatID = "trivial_1",
    occurredAt = 92,
})
local bobBeforeTrivial = memoryCount(
    PNC.Relationships.Get(bob.id, carolKey)
)
PNC.SocialEncounterTracker.EndEncounter(trivial, 92)
T.equal(memoryCount(
    PNC.Relationships.Get(bob.id, carolKey)
), bobBeforeTrivial, "trivial combat grants no memory")

-- 19-23. Abandonment requires continued serious danger, honors grace and
-- return cancellation, creates one negative memory, and raises familiarity.
PNC.SocialEncounterTracker.Reset()
local abandonEncounter = PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "abandon_1",
    threatWasTargeting = true,
    targetTookDamage = true,
    occurredAt = 100,
})
T.truthy(PNC.SocialEncounterTracker.MarkPotentialAbandonment(
    abandonEncounter,
    aliceKey,
    bobKey,
    100,
    "test_departure"
), "serious danger creates abandonment candidate")
PNC.SocialEncounterTracker.Pump(
    100 + PNC.SocialEncounterTracker.ABANDON_GRACE_HOURS / 2
)
local beforeAbandon = PNC.Relationships.Get(bob.id, aliceKey)
local negativeBefore = memoryCount(beforeAbandon, "abandoned_in_combat")
PNC.SocialEncounterTracker.UpdateParticipantPosition(
    aliceKey, 0, 0, 0, 100.002
)
PNC.SocialEncounterTracker.Pump(
    100 + PNC.SocialEncounterTracker.ABANDON_GRACE_HOURS + 0.001
)
T.equal(memoryCount(
    PNC.Relationships.Get(bob.id, aliceKey),
    "abandoned_in_combat"
), negativeBefore, "return during grace cancels abandonment")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "abandoned_in_combat"
), 0, "canceled abandonment creates no conduct")
T.truthy(PNC.SocialEncounterTracker.MarkPotentialAbandonment(
    abandonEncounter,
    aliceKey,
    bobKey,
    100.01,
    "test_departure"
), "second departure marked")
alice.x = 30
bob.x = 0
PNC.SocialEncounterTracker.Pump(
    100.01 + PNC.SocialEncounterTracker.ABANDON_GRACE_HOURS
        + 0.0001
)
local afterAbandon = PNC.Relationships.Get(bob.id, aliceKey)
T.equal(memoryCount(
    afterAbandon,
    "abandoned_in_combat"
), negativeBefore + 1, "confirmed abandonment creates one memory")
T.truthy(afterAbandon.familiarity > beforeAbandon.familiarity,
    "negative experience raises familiarity")
T.equal(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "abandoned_in_combat"
), 1, "confirmed abandonment actor conduct")

-- Ending danger prevents confirmation.
PNC.SocialEncounterTracker.Reset()
local safeDeparture = PNC.SocialEncounterTracker.RecordActivity({
    actorKey = aliceKey,
    targetKey = bobKey,
    threatID = "safe_departure",
    threatWasTargeting = true,
    targetTookDamage = true,
    occurredAt = 101,
})
PNC.SocialEncounterTracker.MarkPotentialAbandonment(
    safeDeparture, aliceKey, bobKey, 101, "test"
)
local safeEncounter =
    PNC.SocialEncounterTracker.GetEncounter(safeDeparture)
safeEncounter.activeThreatIDs.safe_departure = nil
PNC.SocialEncounterTracker.Pump(
    101 + PNC.SocialEncounterTracker.ABANDON_GRACE_HOURS
        + 0.0001
)
T.equal(memoryCount(
    PNC.Relationships.Get(bob.id, aliceKey),
    "abandoned_in_combat"
), negativeBefore + 1, "ended danger prevents abandonment")

-- 24-26. Accepted mutations update social/relationship/record only; rejected
-- events update no revisions, including presence.
local revisionTarget = newRecord("npc_revision_target")
local revisionKey = PNC.EntityRef.ForNPC(revisionTarget.id)
clearDirty()
local recordRevision = revisionTarget.recordRevision
local socialRevision = revisionTarget.social.revision
local presenceRevision = revisionTarget.presenceRevision
T.truthy(PNC.SocialEvents.Emit(event(
    "social:treated_wound:revision",
    "treated_wound",
    playerKey,
    revisionKey,
    110
)).ok, "revision event accepted")
local revisionRelationship =
    PNC.Relationships.Get(revisionTarget.id, playerKey)
T.truthy(revisionRelationship.revision > 0,
    "relationship revision updated")
T.truthy(revisionTarget.social.revision > socialRevision,
    "social revision updated")
T.truthy(revisionTarget.recordRevision > recordRevision,
    "record revision updated")
T.equal(revisionTarget.presenceRevision, presenceRevision,
    "presence revision unchanged")
clearDirty()
recordRevision = revisionTarget.recordRevision
socialRevision = revisionTarget.social.revision
local rejected = PNC.SocialEvents.Emit(event(
    "social:treated_wound:revision_blocked",
    "treated_wound",
    playerKey,
    revisionKey,
    111
))
T.equal(rejected.reason, "cooldown_active", "revision rejection")
T.equal(revisionTarget.recordRevision, recordRevision,
    "rejected event record revision unchanged")
T.equal(revisionTarget.social.revision, socialRevision,
    "rejected event social revision unchanged")

-- 27. Feature flag disables the pipeline without changing gameplay state.
PNC.Config.Relationships.EnableSocialEvents = false
recordRevision = revisionTarget.recordRevision
T.equal(PNC.SocialEvents.Emit(event(
    "social:treated_wound:disabled",
    "treated_wound",
    playerKey,
    revisionKey,
    130
)).reason, "feature_disabled", "feature flag")
T.equal(revisionTarget.recordRevision, recordRevision,
    "disabled feature has no mutation")
PNC.Config.Relationships.EnableSocialEvents = true

-- Conduct reads are copies, and a conduct-only mutation updates only the
-- owning conduct/social/record revisions.
local conductCopy = PNC.Conduct.GetForEntity(aliceKey)
conductCopy.scores.reliability = 99
T.truthy(PNC.Conduct.GetScore(aliceKey, "reliability") ~= 99,
    "conduct read returns copy")
local conductOnlyRelationship =
    PNC.Relationships.Get(alice.id, bobKey)
local conductOnlyRelationshipRevision =
    conductOnlyRelationship and conductOnlyRelationship.revision
local conductOnlySocialRevision = alice.social.revision
local conductOnlyRecordRevision = alice.recordRevision
local conductOnlyPresenceRevision = alice.presenceRevision
clearDirty()
local conductOnlySpec = {
    id = "conduct:social:conduct_only:" .. aliceKey,
    eventID = "social:conduct_only",
    eventType = "test",
    actorKey = aliceKey,
    subjectKey = bobKey,
    createdAt = 150,
    effects = { honesty = 3 },
    strength = 1,
    decayPerDay = 0,
    visibility = "private",
    tags = { test = true },
}
T.truthy(PNC.Conduct.AddEvidence(
    aliceKey, conductOnlySpec
), "conduct-only evidence accepted")
T.equal(PNC.Conduct.AddEvidence(
    aliceKey, conductOnlySpec
), false, "duplicate conduct evidence rejected")
T.truthy(alice.social.revision > conductOnlySocialRevision,
    "conduct-only social revision")
T.truthy(alice.recordRevision > conductOnlyRecordRevision,
    "conduct-only record revision")
T.equal(alice.presenceRevision, conductOnlyPresenceRevision,
    "conduct-only presence unchanged")
local relationshipAfterConductOnly =
    PNC.Relationships.Get(alice.id, bobKey)
T.equal(
    relationshipAfterConductOnly
        and relationshipAfterConductOnly.revision,
    conductOnlyRelationshipRevision,
    "conduct-only relationship revision unchanged"
)

-- The per-NPC dedupe cache is bounded and evicts oldest successful IDs.
local cacheRecord = newRecord("npc_event_cache")
for index = 1, 70 do
    T.truthy(PNC.Relationships.ApplyEventMutation(
        cacheRecord.id,
        playerKey,
        {
            eventID = "social:cache:" .. tostring(index),
            worldAgeHours = 200 + index,
            familiarityDelta = 0,
            moraleDelta = 0,
            memory = {
                id = "memory:cache:" .. tostring(index),
                type = "cache_test",
                aboutKey = playerKey,
                createdAt = 200 + index,
                lastEvaluatedAt = 200 + index,
                approvalEffect = 0,
                respectEffect = 0,
                strength = 1,
                decayPerDay = 0,
                permanent = false,
                shareable = false,
                knowledgeSource = "experienced",
                tags = { test = true },
            },
        }
    ), "cache mutation " .. tostring(index))
end
T.equal(#cacheRecord.social.recentEventIDs, 64,
    "recent event cache bound")
T.equal(cacheRecord.social.recentEventIDs[1], "social:cache:7",
    "recent event oldest-first eviction")
T.equal(cacheRecord.social.recentEventIDs[64], "social:cache:70",
    "recent event newest retained")
T.equal(
    #cacheRecord.runtime.relationshipDebugChanges,
    16,
    "runtime relationship change feed bounded"
)
local latestRelationshipChange =
    cacheRecord.runtime.relationshipDebugChanges[16]
T.equal(latestRelationshipChange.kind, "social_event",
    "social event change type retained")
T.equal(latestRelationshipChange.eventID,
    "social:cache:70",
    "social event ID retained")
T.equal(latestRelationshipChange.memoryType, "cache_test",
    "social memory type retained")

-- 28-30. Persisted output is save-safe, round-trips event memories, and a
-- deterministic authoritative event remains idempotent after the round trip.
validatePersistedValue(revisionTarget.social)
local serialized = PNC.Persistence.SerializeRecord(revisionTarget)
validatePersistedValue(serialized)
local loaded = PNC.Persistence.DeserializeRecord(serialized)
T.equal(memoryCount(
    loaded.social.relationships[playerKey],
    "treated_wound"
), 1, "save load preserves event memory")
PNC.Registry.Data[revisionTarget.id] = loaded
T.equal(PNC.SocialEvents.Emit(event(
    "social:treated_wound:revision",
    "treated_wound",
    playerKey,
    revisionKey,
    110
)).reason, "duplicate_event", "episode idempotent after load")

-- Deterministic temporary/permanent decay remains a Phase 1 regression guard.
local temporary = PNC.RelationshipTypes.NewMemory({
    id = "phase2_decay",
    type = "test",
    aboutKey = aliceKey,
    createdAt = 0,
    approvalEffect = 1,
    respectEffect = 1,
    strength = 1,
    decayPerDay = 0.25,
    permanent = false,
    knowledgeSource = "experienced",
})
T.near(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
    temporary, 48
), 0.5, 0.00001, "temporary decay regression")
temporary.permanent = true
T.near(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
    temporary, 480
), 1, 0.00001, "permanent decay regression")

-- Developer inspection is read-only; guarded triggers use the real event
-- service and return the independently stored reverse direction.
local debugObserver = newRecord("npc_debug_observer")
local debugTarget = newRecord("npc_debug_target")
local debugRecordRevision = debugObserver.recordRevision
local debugSocialRevision = debugObserver.social.revision
local debugPresenceRevision = debugObserver.presenceRevision
getGameTime = function()
    return {
        getWorldAgeHours = function() return 300 end,
    }
end
local debugRandom = 4241
ZombRand = function()
    debugRandom = debugRandom + 1
    return debugRandom
end
local debugRead, debugReadReason =
    PNC.RelationshipDebug.BuildSnapshotForRequest(
        fakePlayer,
        {
            observerNPCID = debugObserver.id,
            targetKind = "current_player",
        }
    )
T.truthy(debugRead ~= nil, "debug read snapshot")
T.equal(debugReadReason, nil, "debug read reason")
T.equal(debugRead.relationship.exists, false,
    "debug read previews missing relationship")
T.truthy(debugRead.observerConduct ~= nil,
    "debug read includes observer conduct")
T.truthy(debugRead.targetConduct ~= nil,
    "debug read includes target conduct")
T.equal(debugObserver.recordRevision, debugRecordRevision,
    "debug read record revision unchanged")
T.equal(debugObserver.social.revision, debugSocialRevision,
    "debug read social revision unchanged")
T.equal(debugObserver.presenceRevision, debugPresenceRevision,
    "debug read presence revision unchanged")

local debugTriggered, debugTriggerReason =
    PNC.RelationshipDebug.TriggerSocialEvent(
        fakePlayer,
        {
            observerNPCID = debugObserver.id,
            targetKind = "current_player",
            eventType = "treated_wound",
        }
    )
T.truthy(debugTriggered ~= nil, "debug trigger snapshot")
T.equal(debugTriggerReason, nil, "debug trigger reason")
T.truthy(debugTriggered.actionResult.ok,
    "debug trigger uses social event service")
T.equal(debugTriggered.relationship.exists, true,
    "debug trigger stores relationship")
T.equal(#debugTriggered.memories, 1,
    "debug trigger returns memory detail")
T.equal(debugTriggered.actionResult.conductEvidenceCreated, 1,
    "debug trigger returns conduct result")
T.truthy(debugTriggered.targetConduct.scores.compassion > 0,
    "debug trigger refreshes target conduct")
T.truthy(string.find(
    PNC.ConductDebug.Format(
        debugTriggered.targetConduct.entityKey,
        300
    ),
    "Conduct Debug",
    1,
    true
) ~= nil, "conduct debug formatter")
T.truthy(debugObserver.recordRevision > debugRecordRevision,
    "debug trigger record revision")
T.truthy(debugObserver.social.revision > debugSocialRevision,
    "debug trigger social revision")
T.equal(debugObserver.presenceRevision, debugPresenceRevision,
    "debug trigger leaves presence revision")

local reciprocalSnapshot =
    PNC.RelationshipDebug.TriggerSocialEvent(
        fakePlayer,
        {
            observerNPCID = debugObserver.id,
            targetKind = "npc",
            targetNPCID = debugTarget.id,
            eventType = "survived_combat_together",
        }
    )
T.truthy(reciprocalSnapshot.actionResult.ok,
    "debug reciprocal event")
T.truthy(reciprocalSnapshot.relationship.exists,
    "debug forward relationship")
T.truthy(reciprocalSnapshot.reverse.exists,
    "debug reverse relationship")
T.equal(
    reciprocalSnapshot.relationship.memoryCount,
    1,
    "debug forward memory"
)
T.equal(
    reciprocalSnapshot.reverse.memoryCount,
    1,
    "debug reverse memory"
)
T.equal(
    PNC.RelationshipDebug.TriggerSocialEvent(
        fakePlayer,
        {
            observerNPCID = debugObserver.id,
            targetKind = "npc",
            targetNPCID = debugTarget.id,
            eventType = "made_up_event",
        }
    ),
    nil,
    "unsupported debug event rejected"
)
T.finish("pnc_social_events_smoke")

T.finish("pnc_social_events_smoke")
