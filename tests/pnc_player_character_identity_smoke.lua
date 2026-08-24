local T = require "tests/support/test"

local SHARED_ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT =
    T.path("ProjectHoomans", "server", "PNC/")

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
    if seen[value] then
        error("cycle in persisted identity data")
    end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe persisted identity key")
        end
        validatePersistedValue(item, seen)
    end
    seen[value] = nil
end

local globalData = {}
local worldHour = 100
local randomSequence = 0

ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

function getGameTime()
    return {
        getWorldAgeHours = function()
            return worldHour
        end,
    }
end

function getTimeInMillis()
    return math.floor(worldHour * 3600000)
end

function ZombRand()
    randomSequence = randomSequence + 1
    return randomSequence
end

local function makePlayer(accountIdentity, modData, options)
    local player = {}
    options = options or {}
    modData = modData or {}
    player.getUsername = function()
        return accountIdentity
    end
    player.getOnlineID = function()
        return options.onlineID or 1
    end
    player.getModData = function()
        return modData
    end
    player.getDisplayName = function()
        return options.displayName or accountIdentity
    end
    player.getDescriptor = function()
        return {
            getForename = function()
                return options.forename or "Test"
            end,
            getSurname = function()
                return options.surname or "Survivor"
            end,
        }
    end
    player.getX = function() return options.x or 10 end
    player.getY = function() return options.y or 20 end
    player.getZ = function() return options.z or 0 end
    player.isDead = function() return options.dead == true end
    player.getObjectName = function() return "Player" end
    return player, modData
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
T.load(SHARED_ROOT
    .. "Relationships/PNC_RelationshipConstants.lua")
T.load(SHARED_ROOT
    .. "Relationships/PNC_RelationshipStates.lua")
T.load(SHARED_ROOT
    .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED_ROOT
    .. "Relationships/PNC_RelationshipMath.lua")
T.load(SHARED_ROOT
    .. "Relationships/PNC_SocialEventDefinitions.lua")
T.load(SHARED_ROOT .. "Base/PNC_Types.lua")
T.load(SHARED_ROOT
    .. "Relationships/PNC_Relationships.lua")
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
T.load(SERVER_ROOT .. "Social/PNC_SocialEventDebug.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEventService.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEncounterTracker.lua")
T.load(SERVER_ROOT .. "Social/PNC_SocialEventHooks.lua")

local Service = PNC.PlayerCharacters
local IdentityTypes = PNC.PlayerCharacterTypes
local IdentityConstants = PNC.PlayerCharacterConstants

-- 1. New registry defaults.
local defaults = IdentityTypes.NewRegistry()
T.equal(defaults.schemaVersion, 6, "registry schema")
T.equal(defaults.revision, 0, "registry revision")
T.equal(type(defaults.byUUID), "table", "registry UUID map")
T.equal(type(defaults.byAccount), "table", "registry account map")
T.equal(type(defaults.byAccountKey), "table", "registry account-key map")
T.equal(type(defaults.uuidAliases), "table", "registry alias map")

-- 2. New character record defaults.
local defaultRecord = IdentityTypes.NewCharacterRecord({
    uuid = "char_default",
    accountIdentity = "Account",
    createdAt = 5,
})
T.equal(defaultRecord.status, "active", "character status")
T.equal(defaultRecord.firstSeenAt, 5, "first seen default")
T.equal(defaultRecord.diedAt, 0, "active diedAt")
T.equal(defaultRecord.revision, 0, "character revision")
T.equal(defaultRecord.conduct.scores.reliability, 0,
    "new character conduct neutral")
T.equal(#defaultRecord.conduct.evidence, 0,
    "new character has no conduct evidence")
local promotedGrant = IdentityTypes.NewCharacterRecord({
    uuid = "char_old_starting_grant",
    accountIdentity = "Account",
    startingCompanion = {
        status = "granted",
        traitID = "PNC_HasBrother",
        relationshipKind = "brother",
        npcID = "pnc_starting_char_old_starting_grant",
    },
})
T.truthy(promotedGrant.startingCompanions.resolved,
    "version five starting grant promoted to resolved collection")
T.equal(promotedGrant.startingCompanions.grants.PNC_HasBrother.npcID,
    "pnc_starting_char_old_starting_grant",
    "version five companion identity preserved")

Service.Load()
local originalGenerator = Service.UUIDGenerator
local generatedIndex = 0
Service.UUIDGenerator = function()
    generatedIndex = generatedIndex + 1
    return "char_generated_" .. tostring(generatedIndex)
end

-- 3. Generation returns valid unique syntax.
local generated = Service.GenerateUUID()
T.truthy(IdentityTypes.IsValidUUID(generated), "generated UUID")

-- 4. A collision is skipped without overwriting the existing record.
globalData.PNC_PlayerCharacters = globalData.PNC_PlayerCharacters or {}
local alice, aliceData = makePlayer("Alice", {}, {
    onlineID = 11,
    forename = "Alice",
})
local aliceUUID = Service.EnsureIdentity(alice, {
    worldAgeHours = 100,
    callback = "test_new",
})
local collisionCalls = 0
Service.UUIDGenerator = function()
    collisionCalls = collisionCalls + 1
    if collisionCalls == 1 then return aliceUUID end
    return "char_after_collision"
end
T.equal(Service.GenerateUUID(), "char_after_collision",
    "collision retry")
T.equal(Service.GetRegistryRecord(aliceUUID).accountIdentity,
    "Alice", "collision preserves owner")
Service.UUIDGenerator = originalGenerator

-- 5-6. Same object claim and repeated Ensure are idempotent.
local registryRevision = Service.GetRegistrySnapshot().revision
T.equal(Service.EnsureIdentity(alice, {
    worldAgeHours = 100,
}), aliceUUID, "same survivor reuse")
T.equal(Service.GetRegistrySnapshot().revision, registryRevision,
    "repeated ensure revision")

-- A simultaneous same-account object cannot share the live UUID.
local duplicatePlayer = makePlayer("Alice", {
    PNC_CharacterUUID = aliceUUID,
    PNC_CharacterIdentityVersion = 1,
}, {
    onlineID = 19,
})
local duplicateValid, duplicateReason = Service.ValidateClaim(
    duplicatePlayer,
    aliceUUID
)
T.equal(duplicateValid, false, "duplicate binding rejected")
T.equal(duplicateReason, "duplicate_live_binding",
    "duplicate binding reason")
local duplicateUUID = Service.EnsureIdentity(duplicatePlayer, {
    worldAgeHours = 100,
})
T.falsy(duplicateUUID == aliceUUID, "duplicate object receives separate UUID")
Service.Unbind(duplicatePlayer, "duplicate_test_complete")

-- 7-8. Disconnect is active and reconnect reuses the mirror.
T.truthy(Service.Unbind(alice, "disconnect", 101, true),
    "disconnect unbind")
T.truthy(Service.IsCharacterActive(aliceUUID),
    "disconnect remains active")
local reconnect = makePlayer("Alice", aliceData, {
    onlineID = 12,
    forename = "Alice",
})
worldHour = 102
T.equal(Service.EnsureIdentity(reconnect, {
    worldAgeHours = worldHour,
    callback = "reconnect",
}), aliceUUID, "reconnect UUID")

-- 9-10. Death is correct and repeat notifications are idempotent.
local historicalAliceKey = PNC.EntityRef.ForPlayerIdentity(
    "Alice",
    aliceUUID
)
T.truthy(PNC.Conduct.AddEvidence(
    historicalAliceKey,
    {
        id = "conduct:social:identity:historical:"
            .. historicalAliceKey,
        eventID = "social:identity:historical",
        eventType = "saved_from_incapacitation",
        actorKey = historicalAliceKey,
        subjectKey = "npc:npc_identity_history_subject",
        createdAt = 102,
        effects = {
            compassion = 8,
            courage = 5,
        },
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        visibility = "direct",
        shareable = true,
        tags = { identity_test = true },
    }
), "historical survivor conduct")
local historicalConduct =
    PNC.Conduct.GetForPlayerCharacter(aliceUUID)
T.equal(historicalConduct.scores.compassion, 8,
    "historical conduct score")

local beforeDeath = Service.GetRegistrySnapshot().revision
T.truthy(Service.MarkDead(reconnect, 103, "test_death"),
    "death marked")
local afterDeath = Service.GetRegistrySnapshot().revision
T.equal(afterDeath, beforeDeath + 1, "death registry revision")
T.truthy(Service.IsCharacterDead(aliceUUID), "dead status")
T.equal(Service.MarkDead(reconnect, 104, "duplicate"), false,
    "repeated death rejected")
T.equal(Service.GetRegistrySnapshot().revision, afterDeath,
    "repeated death revision")

-- 11-13. A new survivor gets a new UUID; history stays indexed.
local newAlice, newAliceData = makePlayer("Alice", {}, {
    onlineID = 13,
    forename = "Alicia",
})
local newAliceUUID = Service.EnsureIdentity(newAlice, {
    worldAgeHours = 105,
    callback = "new_survivor",
})
T.falsy(newAliceUUID == aliceUUID, "new survivor UUID")
T.truthy(Service.IsCharacterDead(aliceUUID),
    "old dead record preserved")
local snapshot = Service.GetRegistrySnapshot()
T.truthy(snapshot.byAccount.Alice[aliceUUID],
    "historical UUID indexed")
T.truthy(snapshot.byAccount.Alice[newAliceUUID],
    "new UUID indexed")
local newSurvivorConduct =
    PNC.Conduct.GetForPlayerCharacter(newAliceUUID)
local retainedHistoricalConduct =
    PNC.Conduct.GetForPlayerCharacter(aliceUUID)
T.equal(newSurvivorConduct.scores.compassion, 0,
    "new survivor does not inherit conduct")
T.equal(#newSurvivorConduct.evidence, 0,
    "new survivor has no inherited evidence")
T.equal(retainedHistoricalConduct.scores.compassion, 8,
    "dead survivor conduct retained")
T.equal(#retainedHistoricalConduct.evidence, 1,
    "dead survivor evidence retained")

-- A local single-player restart can lose the player ModData mirror. Reuse the
-- matching active account character instead of silently minting a new UUID.
T.truthy(Service.Unbind(newAlice, "restart_without_mirror"),
    "active character unbound for restart")
local recoveredAlice, recoveredAliceData = makePlayer("Alice", {}, {
    onlineID = 14,
    forename = "Alicia",
})
T.equal(Service.EnsureIdentity(recoveredAlice, {
    worldAgeHours = 106,
    callback = "restart_without_mirror",
}), newAliceUUID, "missing local mirror recovers active character")
newAlice, newAliceData = recoveredAlice, recoveredAliceData

-- 14-15. Another account cannot claim Alice's active UUID.
local malloryData = {
    PNC_CharacterUUID = newAliceUUID,
    PNC_CharacterIdentityVersion = 1,
}
local mallory = makePlayer("Mallory", malloryData, {
    onlineID = 21,
})
T.equal(Service.ValidateClaim(
    mallory,
    newAliceUUID
), false, "cross-account validation")
local malloryUUID = Service.EnsureIdentity(mallory, {
    worldAgeHours = 106,
})
T.falsy(malloryUUID == newAliceUUID, "cross-account replacement")
T.equal(Service.GetRegistryRecord(newAliceUUID).accountIdentity,
    "Alice", "ownership unchanged")

-- 16. A dead UUID claim is replaced for a live survivor.
local deadClaimData = { PNC_CharacterUUID = aliceUUID }
local deadClaimPlayer = makePlayer("Alice", deadClaimData, {
    onlineID = 14,
})
local deadReplacement = Service.EnsureIdentity(deadClaimPlayer, {
    worldAgeHours = 107,
})
T.falsy(deadReplacement == aliceUUID, "dead claim replacement")

-- 17. An unknown valid-looking claim is not imported.
local unknownData = { PNC_CharacterUUID = "char_untrusted" }
local unknownPlayer = makePlayer("Unknown", unknownData, {
    onlineID = 31,
})
local unknownAssigned = Service.EnsureIdentity(unknownPlayer, {
    worldAgeHours = 108,
})
T.falsy(unknownAssigned == "char_untrusted", "unknown claim replacement")
T.equal(Service.GetRegistryRecord("char_untrusted"), nil,
    "unknown claim not imported")

-- 18. Malformed UUID claims fail validation and are replaced.
local malformedData = { PNC_CharacterUUID = "not:a:uuid" }
local malformedPlayer = makePlayer("Malformed", malformedData)
T.equal(Service.ValidateClaim(
    malformedPlayer,
    malformedData.PNC_CharacterUUID
), false, "malformed validation")
T.truthy(IdentityTypes.IsValidUUID(Service.EnsureIdentity(
    malformedPlayer,
    { worldAgeHours = 109 }
)), "malformed replacement")

-- 19-20. Missing account identity and online ID alone fail.
local noAccount = makePlayer(nil, {}, { onlineID = 99 })
T.equal(Service.EnsureIdentity(noAccount, {
    worldAgeHours = 110,
}), nil, "missing account")
T.equal(Service.GetEntityKey(noAccount), nil,
    "online ID is not identity")

-- 21. Entity keys include both authoritative components.
local newAliceKey = Service.GetEntityKey(newAlice, {
    worldAgeHours = 110,
})
T.equal(newAliceKey,
    "player:Alice:" .. newAliceUUID,
    "player entity key")

-- 22. The registry and mirror survive a save/load rebind.
T.truthy(Service.Save(), "identity registry save")
Service.Loaded = false
Service.ResetRuntimeBindings("test_reload")
Service.Load()
local loadedAlice = makePlayer("Alice", newAliceData, {
    onlineID = 15,
    forename = "Alicia",
})
T.equal(Service.EnsureIdentity(loadedAlice, {
    worldAgeHours = 111,
}), newAliceUUID, "save/load entity identity")
T.equal(Service.GetEntityKey(loadedAlice),
    newAliceKey, "save/load entity key")

local npc = PNC.Types.NewRecord({
    id = "npc_identity_memory",
    displayName = "Identity Memory NPC",
    faction = "neutral",
    identity = { seed = 1, survivor = {} },
})
PNC.Registry.Data[npc.id] = npc
local oldAliceKey = PNC.EntityRef.ForPlayerIdentity(
    "Alice",
    aliceUUID
)
T.truthy(PNC.Relationships.AddMemory(
    npc.id,
    oldAliceKey,
    {
        id = "memory_old_alice",
        type = "identity_history",
        aboutKey = oldAliceKey,
        createdAt = 100,
        approvalEffect = 10,
        respectEffect = 5,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        shareable = false,
        knowledgeSource = "experienced",
        tags = { identity_test = true },
    }
), "old identity memory")

-- 23. New-survivor assignment never retargets old memories.
T.truthy(npc.social.relationships[oldAliceKey] ~= nil,
    "old relationship remains")
T.equal(npc.social.relationships[newAliceKey], nil,
    "new survivor inherits no relationship")

-- 24-26. Identity work is isolated from every NPC revision domain.
local npcRecordRevision = npc.recordRevision
local npcPresenceRevision = npc.presenceRevision
local npcSocialRevision = npc.social.revision
Service.EnsureIdentity(loadedAlice, { worldAgeHours = 111 })
T.equal(npc.recordRevision, npcRecordRevision,
    "NPC record revision isolated")
T.equal(npc.presenceRevision, npcPresenceRevision,
    "NPC presence revision isolated")
T.equal(npc.social.revision, npcSocialRevision,
    "NPC social revision isolated")

-- 27. Meaningful registry changes increment both revision levels.
local infoRecordBefore =
    Service.GetRegistryRecord(newAliceUUID)
local registryBeforeInfo = Service.GetRegistrySnapshot().revision
Service.Unbind(loadedAlice, "info_update")
local movedAlice = makePlayer("Alice", newAliceData, {
    onlineID = 16,
    forename = "Alicia",
    x = 44,
})
Service.EnsureIdentity(movedAlice, { worldAgeHours = 112 })
local infoRecordAfter = Service.GetRegistryRecord(newAliceUUID)
T.truthy(infoRecordAfter.revision > infoRecordBefore.revision,
    "character info revision")
T.truthy(Service.GetRegistrySnapshot().revision
    > registryBeforeInfo, "registry info revision")

-- 28. Pure reads do not increment revisions.
local readRevision = Service.GetRegistrySnapshot().revision
Service.GetRegistryRecord(newAliceUUID)
Service.GetCharacterUUID(movedAlice)
Service.ResolveEntityKey(newAliceKey)
Service.IsCharacterActive(newAliceUUID)
T.equal(Service.GetRegistrySnapshot().revision, readRevision,
    "pure reads revision")

-- 29-31. Normalization is idempotent, repairs byAccount, and drops bad data.
local malformedRegistry = {
    schemaVersion = 99,
    revision = 4,
    byUUID = {
        char_valid = {
            uuid = "wrong",
            accountIdentity = "Repair",
            status = "active",
            createdAt = 1,
        },
        ["bad:key"] = {
            accountIdentity = "Bad",
        },
        char_missing_account = {
            status = "active",
        },
    },
    byAccount = {
        Wrong = { char_fake = true },
    },
}
local normalizedOnce =
    IdentityTypes.NormalizeRegistry(malformedRegistry)
local normalizedTwice =
    IdentityTypes.NormalizeRegistry(normalizedOnce)
T.truthy(Service.NormalizeRegistry(normalizedOnce).byUUID.char_valid
    ~= nil, "normalization callable")
local function simpleEqual(left, right)
    local key
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, _ in pairs(left) do
        if not simpleEqual(left[key], right[key]) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end
T.truthy(simpleEqual(normalizedOnce, normalizedTwice),
    "normalization idempotent")
T.truthy(normalizedOnce.byAccount.Repair.char_valid,
    "byAccount repaired")
T.equal(normalizedOnce.byUUID["bad:key"], nil,
    "invalid UUID record discarded")
T.equal(normalizedOnce.byUUID.char_missing_account, nil,
    "missing account record discarded")

-- 32-33. An old save gets an empty registry; repeating migration is safe.
local migrated = IdentityTypes.NormalizeRegistry({})
T.equal(migrated.schemaVersion, 6, "old save migration")
T.truthy(simpleEqual(
    migrated,
    IdentityTypes.NormalizeRegistry(migrated)
), "repeat registry migration")

-- 34. Player social hooks now resolve the identity service automatically.
local socialTarget = PNC.Types.NewRecord({
    id = "npc_identity_social",
    displayName = "Social Target",
    faction = "neutral",
    identity = { seed = 1, survivor = {} },
})
PNC.Registry.Data[socialTarget.id] = socialTarget
local treatmentResult = PNC.SocialEventHooks.OnTreatmentCompleted(
    movedAlice,
    socialTarget,
    "Hand_L",
    {
        occurredAt = 113,
        actionID = "identity_test",
        woundType = "scratch",
    }
)
T.truthy(treatmentResult.ok, "player social identity resolution")
T.truthy(socialTarget.social.relationships[newAliceKey] ~= nil,
    "social memory uses authoritative key")

-- 35. Player events fail safely without authoritative account identity.
T.equal(PNC.SocialEventHooks.OnTreatmentCompleted(
    noAccount,
    socialTarget,
    "Hand_R",
    {
        occurredAt = 114,
        actionID = "identity_failure",
    }
).ok, false, "social identity failure")

-- 36. NPC-to-NPC Phase 2 processing is unchanged.
local npcActor = PNC.Types.NewRecord({
    id = "npc_identity_actor",
    displayName = "NPC Actor",
    faction = "neutral",
    identity = { seed = 1, survivor = {} },
})
PNC.Registry.Data[npcActor.id] = npcActor
T.truthy(PNC.SocialEvents.Emit({
    id = "social:identity:npc_to_npc",
    type = "treated_wound",
    actorKey = PNC.EntityRef.ForNPC(npcActor.id),
    targetKey = PNC.EntityRef.ForNPC(socialTarget.id),
    occurredAt = 130,
    sourceSystem = "wounds",
    context = {},
}).ok, "NPC social event regression")

-- 37-38 are executed separately by the repository runner:
-- pnc_relationship_foundation_smoke.lua and pnc_social_events_smoke.lua.
T.truthy(PNC.Relationships ~= nil, "Phase 1 loaded")
T.truthy(PNC.SocialEvents ~= nil, "Phase 2 loaded")

-- The lifecycle sweep clears a replaced object before rebinding its loaded
-- survivor, avoiding a false duplicate-live assignment.
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterLifecycle.lua")
local replacementObject = makePlayer("Alice", newAliceData, {
    onlineID = 17,
    forename = "Alicia",
    x = 44,
})
PNC.Core.ForEachPlayer = function(callback)
    callback(replacementObject)
end
PNC.PlayerCharacterLifecycle.LastPumpAt = nil
PNC.PlayerCharacterLifecycle.Pump(999999, true)
T.equal(Service.GetCharacterUUID(replacementObject),
    newAliceUUID, "player object replacement rebind")

-- 39-40. Persisted registry is primitive-only and excludes runtime bindings.
local persisted = Service.GetRegistrySnapshot()
validatePersistedValue(persisted)
T.equal(persisted.RuntimeByPlayer, nil,
    "runtime player bindings excluded")
T.equal(persisted.RuntimeByUUID, nil,
    "runtime UUID bindings excluded")
T.equal(persisted.runtime, nil, "runtime domain excluded")
T.equal(
    persisted.schemaVersion,
    IdentityConstants.REGISTRY_SCHEMA_VERSION,
    "persisted registry schema"
)
T.finish("pnc_player_character_identity_smoke")

T.finish("pnc_player_character_identity_smoke")
