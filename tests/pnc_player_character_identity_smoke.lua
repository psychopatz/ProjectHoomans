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

local function assertNotEqual(left, right, label)
    if left == right then
        error((label or "assertNotEqual")
            .. ": both values=" .. tostring(left))
    end
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
    if seen[value] then
        error("cycle in persisted identity data")
    end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe persisted identity key")
        end
        assertSaveSafe(item, seen)
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
dofile(SHARED_ROOT
    .. "Relationships/PNC_RelationshipConstants.lua")
dofile(SHARED_ROOT
    .. "Relationships/PNC_RelationshipStates.lua")
dofile(SHARED_ROOT
    .. "Relationships/PNC_RelationshipTypes.lua")
dofile(SHARED_ROOT
    .. "Relationships/PNC_RelationshipMath.lua")
dofile(SHARED_ROOT
    .. "Relationships/PNC_SocialEventDefinitions.lua")
dofile(SHARED_ROOT .. "Base/PNC_Types.lua")
dofile(SHARED_ROOT
    .. "Relationships/PNC_Relationships.lua")
dofile(SHARED_ROOT .. "Persistence/PNC_Persistence.lua")

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

dofile(SERVER_ROOT .. "PNC_PlayerCharacterDebug.lua")
dofile(SERVER_ROOT .. "PNC_PlayerCharacterService.lua")
PNC.PlayerCharacters.Load()
dofile(SERVER_ROOT .. "PNC_ConductService.lua")
dofile(SERVER_ROOT .. "PNC_RelationshipService.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventDebug.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventService.lua")
dofile(SERVER_ROOT .. "PNC_SocialEncounterTracker.lua")
dofile(SERVER_ROOT .. "PNC_SocialEventHooks.lua")

local Service = PNC.PlayerCharacters
local IdentityTypes = PNC.PlayerCharacterTypes
local IdentityConstants = PNC.PlayerCharacterConstants

-- 1. New registry defaults.
local defaults = IdentityTypes.NewRegistry()
assertEqual(defaults.schemaVersion, 3, "registry schema")
assertEqual(defaults.revision, 0, "registry revision")
assertEqual(type(defaults.byUUID), "table", "registry UUID map")
assertEqual(type(defaults.byAccount), "table", "registry account map")

-- 2. New character record defaults.
local defaultRecord = IdentityTypes.NewCharacterRecord({
    uuid = "char_default",
    accountIdentity = "Account",
    createdAt = 5,
})
assertEqual(defaultRecord.status, "active", "character status")
assertEqual(defaultRecord.firstSeenAt, 5, "first seen default")
assertEqual(defaultRecord.diedAt, 0, "active diedAt")
assertEqual(defaultRecord.revision, 0, "character revision")
assertEqual(defaultRecord.conduct.scores.reliability, 0,
    "new character conduct neutral")
assertEqual(#defaultRecord.conduct.evidence, 0,
    "new character has no conduct evidence")

Service.Load()
local originalGenerator = Service.UUIDGenerator
local generatedIndex = 0
Service.UUIDGenerator = function()
    generatedIndex = generatedIndex + 1
    return "char_generated_" .. tostring(generatedIndex)
end

-- 3. Generation returns valid unique syntax.
local generated = Service.GenerateUUID()
assertTrue(IdentityTypes.IsValidUUID(generated), "generated UUID")

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
assertEqual(Service.GenerateUUID(), "char_after_collision",
    "collision retry")
assertEqual(Service.GetRegistryRecord(aliceUUID).accountIdentity,
    "Alice", "collision preserves owner")
Service.UUIDGenerator = originalGenerator

-- 5-6. Same object claim and repeated Ensure are idempotent.
local registryRevision = Service.GetRegistrySnapshot().revision
assertEqual(Service.EnsureIdentity(alice, {
    worldAgeHours = 100,
}), aliceUUID, "same survivor reuse")
assertEqual(Service.GetRegistrySnapshot().revision, registryRevision,
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
assertEqual(duplicateValid, false, "duplicate binding rejected")
assertEqual(duplicateReason, "duplicate_live_binding",
    "duplicate binding reason")
local duplicateUUID = Service.EnsureIdentity(duplicatePlayer, {
    worldAgeHours = 100,
})
assertNotEqual(duplicateUUID, aliceUUID,
    "duplicate object receives separate UUID")
Service.Unbind(duplicatePlayer, "duplicate_test_complete")

-- 7-8. Disconnect is active and reconnect reuses the mirror.
assertTrue(Service.Unbind(alice, "disconnect", 101, true),
    "disconnect unbind")
assertTrue(Service.IsCharacterActive(aliceUUID),
    "disconnect remains active")
local reconnect = makePlayer("Alice", aliceData, {
    onlineID = 12,
    forename = "Alice",
})
worldHour = 102
assertEqual(Service.EnsureIdentity(reconnect, {
    worldAgeHours = worldHour,
    callback = "reconnect",
}), aliceUUID, "reconnect UUID")

-- 9-10. Death is correct and repeat notifications are idempotent.
local historicalAliceKey = PNC.EntityRef.ForPlayerIdentity(
    "Alice",
    aliceUUID
)
assertTrue(PNC.Conduct.AddEvidence(
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
assertEqual(historicalConduct.scores.compassion, 8,
    "historical conduct score")

local beforeDeath = Service.GetRegistrySnapshot().revision
assertTrue(Service.MarkDead(reconnect, 103, "test_death"),
    "death marked")
local afterDeath = Service.GetRegistrySnapshot().revision
assertEqual(afterDeath, beforeDeath + 1, "death registry revision")
assertTrue(Service.IsCharacterDead(aliceUUID), "dead status")
assertEqual(Service.MarkDead(reconnect, 104, "duplicate"), false,
    "repeated death rejected")
assertEqual(Service.GetRegistrySnapshot().revision, afterDeath,
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
assertNotEqual(newAliceUUID, aliceUUID, "new survivor UUID")
assertTrue(Service.IsCharacterDead(aliceUUID),
    "old dead record preserved")
local snapshot = Service.GetRegistrySnapshot()
assertTrue(snapshot.byAccount.Alice[aliceUUID],
    "historical UUID indexed")
assertTrue(snapshot.byAccount.Alice[newAliceUUID],
    "new UUID indexed")
local newSurvivorConduct =
    PNC.Conduct.GetForPlayerCharacter(newAliceUUID)
local retainedHistoricalConduct =
    PNC.Conduct.GetForPlayerCharacter(aliceUUID)
assertEqual(newSurvivorConduct.scores.compassion, 0,
    "new survivor does not inherit conduct")
assertEqual(#newSurvivorConduct.evidence, 0,
    "new survivor has no inherited evidence")
assertEqual(retainedHistoricalConduct.scores.compassion, 8,
    "dead survivor conduct retained")
assertEqual(#retainedHistoricalConduct.evidence, 1,
    "dead survivor evidence retained")

-- A local single-player restart can lose the player ModData mirror. Reuse the
-- matching active account character instead of silently minting a new UUID.
assertTrue(Service.Unbind(newAlice, "restart_without_mirror"),
    "active character unbound for restart")
local recoveredAlice, recoveredAliceData = makePlayer("Alice", {}, {
    onlineID = 14,
    forename = "Alicia",
})
assertEqual(Service.EnsureIdentity(recoveredAlice, {
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
assertEqual(Service.ValidateClaim(
    mallory,
    newAliceUUID
), false, "cross-account validation")
local malloryUUID = Service.EnsureIdentity(mallory, {
    worldAgeHours = 106,
})
assertNotEqual(malloryUUID, newAliceUUID,
    "cross-account replacement")
assertEqual(Service.GetRegistryRecord(newAliceUUID).accountIdentity,
    "Alice", "ownership unchanged")

-- 16. A dead UUID claim is replaced for a live survivor.
local deadClaimData = { PNC_CharacterUUID = aliceUUID }
local deadClaimPlayer = makePlayer("Alice", deadClaimData, {
    onlineID = 14,
})
local deadReplacement = Service.EnsureIdentity(deadClaimPlayer, {
    worldAgeHours = 107,
})
assertNotEqual(deadReplacement, aliceUUID, "dead claim replacement")

-- 17. An unknown valid-looking claim is not imported.
local unknownData = { PNC_CharacterUUID = "char_untrusted" }
local unknownPlayer = makePlayer("Unknown", unknownData, {
    onlineID = 31,
})
local unknownAssigned = Service.EnsureIdentity(unknownPlayer, {
    worldAgeHours = 108,
})
assertNotEqual(unknownAssigned, "char_untrusted",
    "unknown claim replacement")
assertEqual(Service.GetRegistryRecord("char_untrusted"), nil,
    "unknown claim not imported")

-- 18. Malformed UUID claims fail validation and are replaced.
local malformedData = { PNC_CharacterUUID = "not:a:uuid" }
local malformedPlayer = makePlayer("Malformed", malformedData)
assertEqual(Service.ValidateClaim(
    malformedPlayer,
    malformedData.PNC_CharacterUUID
), false, "malformed validation")
assertTrue(IdentityTypes.IsValidUUID(Service.EnsureIdentity(
    malformedPlayer,
    { worldAgeHours = 109 }
)), "malformed replacement")

-- 19-20. Missing account identity and online ID alone fail.
local noAccount = makePlayer(nil, {}, { onlineID = 99 })
assertEqual(Service.EnsureIdentity(noAccount, {
    worldAgeHours = 110,
}), nil, "missing account")
assertEqual(Service.GetEntityKey(noAccount), nil,
    "online ID is not identity")

-- 21. Entity keys include both authoritative components.
local newAliceKey = Service.GetEntityKey(newAlice, {
    worldAgeHours = 110,
})
assertEqual(newAliceKey,
    "player:Alice:" .. newAliceUUID,
    "player entity key")

-- 22. The registry and mirror survive a save/load rebind.
assertTrue(Service.Save(), "identity registry save")
Service.Loaded = false
Service.ResetRuntimeBindings("test_reload")
Service.Load()
local loadedAlice = makePlayer("Alice", newAliceData, {
    onlineID = 15,
    forename = "Alicia",
})
assertEqual(Service.EnsureIdentity(loadedAlice, {
    worldAgeHours = 111,
}), newAliceUUID, "save/load entity identity")
assertEqual(Service.GetEntityKey(loadedAlice),
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
assertTrue(PNC.Relationships.AddMemory(
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
assertTrue(npc.social.relationships[oldAliceKey] ~= nil,
    "old relationship remains")
assertEqual(npc.social.relationships[newAliceKey], nil,
    "new survivor inherits no relationship")

-- 24-26. Identity work is isolated from every NPC revision domain.
local npcRecordRevision = npc.recordRevision
local npcPresenceRevision = npc.presenceRevision
local npcSocialRevision = npc.social.revision
Service.EnsureIdentity(loadedAlice, { worldAgeHours = 111 })
assertEqual(npc.recordRevision, npcRecordRevision,
    "NPC record revision isolated")
assertEqual(npc.presenceRevision, npcPresenceRevision,
    "NPC presence revision isolated")
assertEqual(npc.social.revision, npcSocialRevision,
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
assertTrue(infoRecordAfter.revision > infoRecordBefore.revision,
    "character info revision")
assertTrue(Service.GetRegistrySnapshot().revision
    > registryBeforeInfo, "registry info revision")

-- 28. Pure reads do not increment revisions.
local readRevision = Service.GetRegistrySnapshot().revision
Service.GetRegistryRecord(newAliceUUID)
Service.GetCharacterUUID(movedAlice)
Service.ResolveEntityKey(newAliceKey)
Service.IsCharacterActive(newAliceUUID)
assertEqual(Service.GetRegistrySnapshot().revision, readRevision,
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
assertTrue(Service.NormalizeRegistry(normalizedOnce).byUUID.char_valid
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
assertTrue(simpleEqual(normalizedOnce, normalizedTwice),
    "normalization idempotent")
assertTrue(normalizedOnce.byAccount.Repair.char_valid,
    "byAccount repaired")
assertEqual(normalizedOnce.byUUID["bad:key"], nil,
    "invalid UUID record discarded")
assertEqual(normalizedOnce.byUUID.char_missing_account, nil,
    "missing account record discarded")

-- 32-33. An old save gets an empty registry; repeating migration is safe.
local migrated = IdentityTypes.NormalizeRegistry({})
assertEqual(migrated.schemaVersion, 3, "old save migration")
assertTrue(simpleEqual(
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
assertTrue(treatmentResult.ok, "player social identity resolution")
assertTrue(socialTarget.social.relationships[newAliceKey] ~= nil,
    "social memory uses authoritative key")

-- 35. Player events fail safely without authoritative account identity.
assertEqual(PNC.SocialEventHooks.OnTreatmentCompleted(
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
assertTrue(PNC.SocialEvents.Emit({
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
assertTrue(PNC.Relationships ~= nil, "Phase 1 loaded")
assertTrue(PNC.SocialEvents ~= nil, "Phase 2 loaded")

-- The lifecycle sweep clears a replaced object before rebinding its loaded
-- survivor, avoiding a false duplicate-live assignment.
dofile(SERVER_ROOT .. "PNC_PlayerCharacterLifecycle.lua")
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
assertEqual(Service.GetCharacterUUID(replacementObject),
    newAliceUUID, "player object replacement rebind")

-- 39-40. Persisted registry is primitive-only and excludes runtime bindings.
local persisted = Service.GetRegistrySnapshot()
assertSaveSafe(persisted)
assertEqual(persisted.RuntimeByPlayer, nil,
    "runtime player bindings excluded")
assertEqual(persisted.RuntimeByUUID, nil,
    "runtime UUID bindings excluded")
assertEqual(persisted.runtime, nil, "runtime domain excluded")
assertEqual(
    persisted.schemaVersion,
    IdentityConstants.REGISTRY_SCHEMA_VERSION,
    "persisted registry schema"
)

print("pnc_player_character_identity_smoke: ok")
