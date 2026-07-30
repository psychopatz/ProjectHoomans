local SHARED_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

local function assertNear(actual, expected, epsilon, label)
    if math.abs(actual - expected) > epsilon then
        error((label or "assertNear") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

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

local function assertSaveSafe(value, seen)
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
        assertSaveSafe(item, seen)
    end
    seen[value] = nil
end

PNC = {}
dofile(SHARED_ROOT .. "Base/PNC_Core.lua")
dofile(SHARED_ROOT .. "Base/PNC_Constants.lua")
dofile(SHARED_ROOT
    .. "Identity/PNC_PlayerCharacterConstants.lua")
dofile(SHARED_ROOT .. "Identity/PNC_Identity.lua")
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
dofile(SHARED_ROOT .. "Relationships/PNC_EntityRef.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialTraits.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialProfileMath.lua")
dofile(SHARED_ROOT .. "Conduct/PNC_ConductConstants.lua")
dofile(SHARED_ROOT .. "Conduct/PNC_ConductTypes.lua")
dofile(SHARED_ROOT .. "Conduct/PNC_ConductMath.lua")
dofile(SHARED_ROOT .. "Conduct/PNC_ConductDefinitions.lua")
dofile(SHARED_ROOT
    .. "Identity/PNC_PlayerCharacterTypes.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_RelationshipConstants.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_RelationshipStates.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_RelationshipTypes.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_RelationshipMath.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_SocialEventDefinitions.lua")
dofile(SHARED_ROOT .. "Base/PNC_Types.lua")
dofile(SHARED_ROOT .. "Relationships/PNC_Relationships.lua")
dofile(SHARED_ROOT .. "Persistence/PNC_Persistence.lua")

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

dofile(SERVER_ROOT .. "PNC_PlayerCharacterDebug.lua")
dofile(SERVER_ROOT .. "PNC_PlayerCharacterService.lua")
PNC.PlayerCharacters.Load()
dofile(SERVER_ROOT .. "PNC_ConductService.lua")
dofile(SERVER_ROOT .. "PNC_RelationshipService.lua")
dofile(SERVER_ROOT .. "PNC_RelationshipDebug.lua")
dofile(SERVER_ROOT .. "PNC_ConductDebug.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventDebug.lua")
dofile(SERVER_ROOT .. "PNC_SocialProfileDebug.lua")
dofile(SERVER_ROOT .. "PNC_SocialProfileService.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventService.lua")
dofile(SERVER_ROOT .. "PNC_SocialEncounterTracker.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventHooks.lua")

local function newRecord(id)
    local record = PNC.Types.NewRecord({
        id = id,
        displayName = id,
        faction = "neutral",
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

-- 1. Exactly the five known data-driven definitions load.
local definitionCount = 0
for _, _ in pairs(PNC.SocialEventDefinitions) do
    definitionCount = definitionCount + 1
end
assertEqual(definitionCount, 5, "five definitions")
assertEqual(
    PNC.SocialEvents.GetDefinition("treated_wound")
        .targetMemory.approvalEffect,
    4,
    "treated wound balance"
)

-- 2-3. Unknown and malformed/unsafe events fail safely.
assertEqual(PNC.SocialEvents.Emit(event(
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
assertEqual(
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
assertTrue(first.ok, "treatment event accepted")
assertTrue(string.find(
    PNC.SocialEventDebug.FormatProcessed(
        first,
        PNC.SocialEvents.GetDefinition("treated_wound")
    ),
    "Memory created:",
    1,
    true
) ~= nil, "social event debug formatter")
local bobToPlayer = PNC.Relationships.Get(bob.id, playerKey)
assertEqual(memoryCount(bobToPlayer, "treated_wound"), 1,
    "target memory created")
assertEqual(bobToPlayer.approval, 4, "treatment approval")
assertEqual(bobToPlayer.familiarity, 2, "treatment familiarity")
assertEqual(bob.social.morale, 2, "treatment morale")
local playerConduct = PNC.Conduct.GetForEntity(playerKey)
assertEqual(playerConduct.scores.compassion, 2,
    "treatment actor compassion conduct")
assertEqual(playerConduct.scores.generosity, 1,
    "treatment actor generosity conduct")
assertEqual(evidenceCount(playerConduct, "treated_wound"), 1,
    "treatment actor evidence")
assertEqual(PNC.SocialEvents.Emit(treated).reason, "duplicate_event",
    "duplicate event rejected")
assertEqual(memoryCount(PNC.Relationships.Get(bob.id, playerKey)), 1,
    "duplicate creates no memory")
local cooldown = PNC.SocialEvents.Emit(event(
    "social:treated_wound:2",
    "treated_wound",
    playerKey,
    bobKey,
    2
))
assertEqual(cooldown.reason, "cooldown_active",
    "treatment cooldown blocks farming")
assertEqual(evidenceCount(
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
assertTrue(afterCooldown.ok, "cooldown expiration")

-- 10. Contribution saturation clips and then rejects repeated gains.
for index = 1, 6 do
    assertTrue(PNC.SocialEvents.Emit(event(
        "social:treated_wound:cap" .. tostring(index),
        "treated_wound",
        playerKey,
        bobKey,
        13 + index * 12
    )).ok, "treatment cap setup " .. tostring(index))
end
assertEqual(
    PNC.Relationships.Get(bob.id, playerKey)
        .saturation.treated_wound.approval,
    20,
    "treatment cumulative approval cap"
)
assertEqual(PNC.SocialEvents.Emit(event(
    "social:treated_wound:saturated",
    "treated_wound",
    playerKey,
    bobKey,
    97
)).reason, "contribution_saturated", "saturation rejection")
assertEqual(evidenceCount(
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
assertTrue(PNC.SocialEvents.Emit(rescue).ok, "rescue accepted")
assertEqual(evidenceCount(
    PNC.Conduct.GetForEntity(playerKey),
    "saved_from_incapacitation"
), 1, "rescue actor evidence")
assertEqual(PNC.SocialEvents.Emit(rescue).reason, "duplicate_event",
    "rescue episode idempotent")
carol.health.state = "normal"
assertEqual(PNC.SocialEventHooks.OnIncapacitationRecovered(
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
assertTrue(PNC.SocialEventHooks.OnTreatmentCompleted(
    fakePlayer,
    hookTarget,
    "Torso_Upper",
    { occurredAt = 72, actionID = "hook_action" }
).ok, "treatment hook emits centralized event")
local hookEpisode =
    PNC.SocialEventHooks.GetDownedEpisodeID(hookTarget)
hookTarget.health.state = "normal"
assertTrue(PNC.SocialEventHooks.OnIncapacitationRecovered(
    hookTarget,
    hookEpisode,
    73
).ok, "verified treatment contributor receives rescue credit")
assertEqual(memoryCount(
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
assertTrue(select(1, PNC.SocialEncounterTracker.OnThreatNeutralized({
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
assertEqual(memoryCount(
    PNC.Relationships.Get(bob.id, aliceKey),
    "protected_from_attacker"
), 1, "several kills aggregate to one protection memory")
assertEqual(evidenceCount(
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
assertTrue(unrelatedOK, "unrelated kill tracked as combat")
assertEqual(unrelatedReason, "neutralized_without_protection",
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
assertTrue(select(1, PNC.SocialEncounterTracker.EndEncounter(
    sharedNPC,
    90.002
)), "NPC shared encounter ended")
assertEqual(memoryCount(
    PNC.Relationships.Get(alice.id, carolKey),
    "survived_combat_together"
), 1, "Alice reciprocal shared memory")
assertEqual(memoryCount(
    PNC.Relationships.Get(carol.id, aliceKey),
    "survived_combat_together"
), 1, "Carol reciprocal shared memory")
assertEqual(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "survived_combat_together"
), 1, "Alice participant conduct")
assertEqual(evidenceCount(
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
assertEqual(memoryCount(
    PNC.Relationships.Get(alice.id, playerKey),
    "survived_combat_together"
), 1, "player NPC shared combat has NPC-owned memory")
assertEqual(evidenceCount(
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
assertEqual(memoryCount(
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
assertTrue(PNC.SocialEncounterTracker.MarkPotentialAbandonment(
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
assertEqual(memoryCount(
    PNC.Relationships.Get(bob.id, aliceKey),
    "abandoned_in_combat"
), negativeBefore, "return during grace cancels abandonment")
assertEqual(evidenceCount(
    PNC.Conduct.GetForEntity(aliceKey),
    "abandoned_in_combat"
), 0, "canceled abandonment creates no conduct")
assertTrue(PNC.SocialEncounterTracker.MarkPotentialAbandonment(
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
assertEqual(memoryCount(
    afterAbandon,
    "abandoned_in_combat"
), negativeBefore + 1, "confirmed abandonment creates one memory")
assertTrue(afterAbandon.familiarity > beforeAbandon.familiarity,
    "negative experience raises familiarity")
assertEqual(evidenceCount(
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
assertEqual(memoryCount(
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
assertTrue(PNC.SocialEvents.Emit(event(
    "social:treated_wound:revision",
    "treated_wound",
    playerKey,
    revisionKey,
    110
)).ok, "revision event accepted")
local revisionRelationship =
    PNC.Relationships.Get(revisionTarget.id, playerKey)
assertTrue(revisionRelationship.revision > 0,
    "relationship revision updated")
assertTrue(revisionTarget.social.revision > socialRevision,
    "social revision updated")
assertTrue(revisionTarget.recordRevision > recordRevision,
    "record revision updated")
assertEqual(revisionTarget.presenceRevision, presenceRevision,
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
assertEqual(rejected.reason, "cooldown_active", "revision rejection")
assertEqual(revisionTarget.recordRevision, recordRevision,
    "rejected event record revision unchanged")
assertEqual(revisionTarget.social.revision, socialRevision,
    "rejected event social revision unchanged")

-- 27. Feature flag disables the pipeline without changing gameplay state.
PNC.Config.Relationships.EnableSocialEvents = false
recordRevision = revisionTarget.recordRevision
assertEqual(PNC.SocialEvents.Emit(event(
    "social:treated_wound:disabled",
    "treated_wound",
    playerKey,
    revisionKey,
    130
)).reason, "feature_disabled", "feature flag")
assertEqual(revisionTarget.recordRevision, recordRevision,
    "disabled feature has no mutation")
PNC.Config.Relationships.EnableSocialEvents = true

-- Conduct reads are copies, and a conduct-only mutation updates only the
-- owning conduct/social/record revisions.
local conductCopy = PNC.Conduct.GetForEntity(aliceKey)
conductCopy.scores.reliability = 99
assertTrue(PNC.Conduct.GetScore(aliceKey, "reliability") ~= 99,
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
assertTrue(PNC.Conduct.AddEvidence(
    aliceKey, conductOnlySpec
), "conduct-only evidence accepted")
assertEqual(PNC.Conduct.AddEvidence(
    aliceKey, conductOnlySpec
), false, "duplicate conduct evidence rejected")
assertTrue(alice.social.revision > conductOnlySocialRevision,
    "conduct-only social revision")
assertTrue(alice.recordRevision > conductOnlyRecordRevision,
    "conduct-only record revision")
assertEqual(alice.presenceRevision, conductOnlyPresenceRevision,
    "conduct-only presence unchanged")
local relationshipAfterConductOnly =
    PNC.Relationships.Get(alice.id, bobKey)
assertEqual(
    relationshipAfterConductOnly
        and relationshipAfterConductOnly.revision,
    conductOnlyRelationshipRevision,
    "conduct-only relationship revision unchanged"
)

-- The per-NPC dedupe cache is bounded and evicts oldest successful IDs.
local cacheRecord = newRecord("npc_event_cache")
for index = 1, 70 do
    assertTrue(PNC.Relationships.ApplyEventMutation(
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
assertEqual(#cacheRecord.social.recentEventIDs, 64,
    "recent event cache bound")
assertEqual(cacheRecord.social.recentEventIDs[1], "social:cache:7",
    "recent event oldest-first eviction")
assertEqual(cacheRecord.social.recentEventIDs[64], "social:cache:70",
    "recent event newest retained")

-- 28-30. Persisted output is save-safe, round-trips event memories, and a
-- deterministic authoritative event remains idempotent after the round trip.
assertSaveSafe(revisionTarget.social)
local serialized = PNC.Persistence.SerializeRecord(revisionTarget)
assertSaveSafe(serialized)
local loaded = PNC.Persistence.DeserializeRecord(serialized)
assertEqual(memoryCount(
    loaded.social.relationships[playerKey],
    "treated_wound"
), 1, "save load preserves event memory")
PNC.Registry.Data[revisionTarget.id] = loaded
assertEqual(PNC.SocialEvents.Emit(event(
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
assertNear(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
    temporary, 48
), 0.5, 0.00001, "temporary decay regression")
temporary.permanent = true
assertNear(PNC.RelationshipMath.CalculateMemoryStrengthAtTime(
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
assertTrue(debugRead ~= nil, "debug read snapshot")
assertEqual(debugReadReason, nil, "debug read reason")
assertEqual(debugRead.relationship.exists, false,
    "debug read previews missing relationship")
assertTrue(debugRead.observerConduct ~= nil,
    "debug read includes observer conduct")
assertTrue(debugRead.targetConduct ~= nil,
    "debug read includes target conduct")
assertEqual(debugObserver.recordRevision, debugRecordRevision,
    "debug read record revision unchanged")
assertEqual(debugObserver.social.revision, debugSocialRevision,
    "debug read social revision unchanged")
assertEqual(debugObserver.presenceRevision, debugPresenceRevision,
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
assertTrue(debugTriggered ~= nil, "debug trigger snapshot")
assertEqual(debugTriggerReason, nil, "debug trigger reason")
assertTrue(debugTriggered.actionResult.ok,
    "debug trigger uses social event service")
assertEqual(debugTriggered.relationship.exists, true,
    "debug trigger stores relationship")
assertEqual(#debugTriggered.memories, 1,
    "debug trigger returns memory detail")
assertEqual(debugTriggered.actionResult.conductEvidenceCreated, 1,
    "debug trigger returns conduct result")
assertTrue(debugTriggered.targetConduct.scores.compassion > 0,
    "debug trigger refreshes target conduct")
assertTrue(string.find(
    PNC.ConductDebug.Format(
        debugTriggered.targetConduct.entityKey,
        300
    ),
    "Conduct Debug",
    1,
    true
) ~= nil, "conduct debug formatter")
assertTrue(debugObserver.recordRevision > debugRecordRevision,
    "debug trigger record revision")
assertTrue(debugObserver.social.revision > debugSocialRevision,
    "debug trigger social revision")
assertEqual(debugObserver.presenceRevision, debugPresenceRevision,
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
assertTrue(reciprocalSnapshot.actionResult.ok,
    "debug reciprocal event")
assertTrue(reciprocalSnapshot.relationship.exists,
    "debug forward relationship")
assertTrue(reciprocalSnapshot.reverse.exists,
    "debug reverse relationship")
assertEqual(
    reciprocalSnapshot.relationship.memoryCount,
    1,
    "debug forward memory"
)
assertEqual(
    reciprocalSnapshot.reverse.memoryCount,
    1,
    "debug reverse memory"
)
assertEqual(
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

print("PNC social event smoke tests passed")
