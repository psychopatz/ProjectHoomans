local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
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

local function deepEqual(left, right, seen)
    local key
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, _ in pairs(left) do
        if not deepEqual(left[key], right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
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
        error("unsafe persisted profile value: " .. valueType)
    end
    seen = seen or {}
    if seen[value] then error("profile cycle") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe persisted profile key")
        end
        assertSaveSafe(item, seen)
    end
    seen[value] = nil
end

local globalData = {
    PNC_PlayerCharacters = {
        schemaVersion = 1,
        revision = 4,
        byUUID = {
            char_historical = {
                uuid = "char_historical",
                accountIdentity = "History",
                status = "dead",
                createdAt = 1,
                firstSeenAt = 1,
                lastSeenAt = 2,
                diedAt = 2,
                revision = 2,
            },
        },
        byAccount = {
            History = { char_historical = true },
        },
    },
}
local worldHour = 10

ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

function getGameTime()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

function getTimeInMillis()
    return math.floor(worldHour * 3600000)
end

local function javaList(values)
    return {
        values = values,
        size = function(self) return #self.values end,
        get = function(self, index) return self.values[index + 1] end,
    }
end

local function trait(resource)
    return {
        resource = resource,
        toString = function(self) return self.resource end,
        getName = function(self)
            return string.match(self.resource, ":(.+)$")
        end,
    }
end

local function makePlayer(account, selected, modData)
    local player = {
        selected = selected or {},
        data = modData or {},
    }
    player.getUsername = function() return account end
    player.getOnlineID = function() return 1 end
    player.getModData = function(self) return self.data end
    player.getDisplayName = function() return account end
    player.getDescriptor = function()
        return {
            getForename = function() return account end,
            getSurname = function() return "Survivor" end,
        }
    end
    player.getX = function() return 1 end
    player.getY = function() return 2 end
    player.getZ = function() return 0 end
    player.getCharacterTraits = function(self)
        local values = {}
        for _, resource in ipairs(self.selected) do
            values[#values + 1] = trait(resource)
        end
        return {
            getKnownTraits = function()
                return javaList(values)
            end,
        }
    end
    player.isDead = function() return false end
    return player
end

PNC = {}
dofile(ROOT .. "Base/PNC_Core.lua")
dofile(ROOT .. "Base/PNC_Constants.lua")
dofile(ROOT .. "Identity/PNC_PlayerCharacterConstants.lua")
dofile(ROOT .. "Identity/PNC_Identity.lua")
dofile(ROOT .. "Relationships/PNC_EntityRef.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
dofile(ROOT .. "Relationships/PNC_SocialTraits.lua")
dofile(ROOT .. "Relationships/PNC_SocialProfileMath.lua")
dofile(ROOT .. "Conduct/PNC_ConductConstants.lua")
dofile(ROOT .. "Conduct/PNC_ConductTypes.lua")
dofile(ROOT .. "Conduct/PNC_ConductMath.lua")
dofile(ROOT .. "Conduct/PNC_ConductDefinitions.lua")
dofile(ROOT .. "Factions/PNC_FactionConstants.lua")
dofile(ROOT .. "Factions/PNC_FactionArchetypes.lua")
dofile(ROOT .. "Factions/PNC_FactionEmblems.lua")
dofile(ROOT .. "Factions/PNC_FactionTypes.lua")
dofile(ROOT .. "Identity/PNC_PlayerCharacterTypes.lua")
dofile(ROOT .. "Relationships/PNC_RelationshipConstants.lua")
dofile(ROOT .. "Relationships/PNC_RelationshipStates.lua")
dofile(ROOT .. "Relationships/PNC_RelationshipTypes.lua")
dofile(ROOT .. "Relationships/PNC_RelationshipMath.lua")
dofile(ROOT .. "Relationships/PNC_SocialEventDefinitions.lua")

PNC.Archetypes = {
    Get = function(id)
        return {
            id = id or "General",
            label = id or "General",
            visualProfile = "colonist",
            tags = {},
            allowedJobs = {},
            looks = {},
            skillBias = {},
            loadout = {},
        }
    end,
    GetColonistDefaults = function() return { "General" } end,
    GetHostileDefaults = function() return { "General" } end,
}
PNC.Identity.ApplyRecordIdentity = function(record, definition)
    record.identitySeed = PNC.Identity.NormalizeSeed(
        definition.identitySeed or record.identitySeed,
        record.id
    )
    record.identity = definition.identity or record.identity or {
        seed = record.identitySeed,
        survivor = {},
    }
    record.name = definition.displayName or definition.name
        or record.name or record.id
    record.archetypeID = definition.archetypeID
        or record.archetypeID or "General"
    record.isFemale = definition.isFemale == true
    return record
end
dofile(ROOT .. "Base/PNC_Types.lua")
dofile(ROOT .. "Relationships/PNC_Relationships.lua")
dofile(ROOT .. "Persistence/PNC_Persistence.lua")

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

dofile(SERVER .. "PNC_PlayerCharacterDebug.lua")
dofile(SERVER .. "PNC_PlayerCharacterService.lua")
dofile(SERVER .. "PNC_SocialProfileDebug.lua")
dofile(SERVER .. "PNC_SocialProfileService.lua")
dofile(SERVER .. "PNC_ConductService.lua")
dofile(SERVER .. "PNC_RelationshipService.lua")
dofile(SERVER .. "PNC_SocialEventDebug.lua")
dofile(SERVER .. "PNC_SocialEventService.lua")

local Constants = PNC.SocialProfileConstants
local Types = PNC.SocialProfileTypes
local Profiles = PNC.SocialProfiles
local Math = PNC.SocialProfileMath

-- Pure defaults, enums, numeric repair, and deterministic generation.
local playerDefaults = Types.NewPlayerSocialProfile()
assertEqual(playerDefaults.orientation, "straight",
    "player default orientation")
assertEqual(playerDefaults.foodPreference, "neutral",
    "player default food")
assertEqual(playerDefaults.romanceStyle, "neutral",
    "player default romance")
assertEqual(playerDefaults.jealousyStyle, "normal",
    "player default jealousy")
assertEqual(playerDefaults.socialStyle, "neutral",
    "player default social")
assertEqual(playerDefaults.schemaVersion, 1,
    "player profile schema")

for _, orientation in ipairs({ "straight", "gay", "bisexual" }) do
    assertEqual(Types.NormalizePlayerSocialProfile({
        orientation = orientation,
    }).orientation, orientation, orientation .. " enum")
end
assertEqual(Types.NormalizePlayerSocialProfile({
    orientation = "future",
}).orientation, "straight", "invalid orientation")
assertEqual(Types.NormalizePlayerSocialProfile({
    foodPreference = "spicy",
    romanceStyle = "reserved",
    jealousyStyle = "unpossessive",
    socialStyle = "withdrawn",
}).foodPreference, "spicy", "food enum")
assertEqual(Types.NormalizePlayerSocialProfile({
    romanceStyle = "reserved",
}).romanceStyle, "reserved", "romance enum")
assertEqual(Types.NormalizePlayerSocialProfile({
    jealousyStyle = "unpossessive",
}).jealousyStyle, "unpossessive", "jealousy enum")
assertEqual(Types.NormalizePlayerSocialProfile({
    socialStyle = "withdrawn",
}).socialStyle, "withdrawn", "social enum")

local repaired = Types.NormalizeNPCPersonality({
    compassion = -4,
    sociability = 4,
    forgiveness = 0 / 0,
    bravery = math.huge,
    materialism = -math.huge,
    aggression = 0.25,
    loyalty = 0.75,
    orientation = "invalid",
}, 101, "General")
assertEqual(repaired.compassion, 0, "unit lower clamp")
assertEqual(repaired.sociability, 1, "unit upper clamp")
assertTrue(repaired.forgiveness >= 0
    and repaired.forgiveness <= 1, "NaN repaired")
assertTrue(repaired.bravery >= 0 and repaired.bravery <= 1,
    "infinity repaired")
assertTrue(repaired.materialism >= 0
    and repaired.materialism <= 1, "negative infinity repaired")
assertTrue(Constants.VALID_ORIENTATIONS[repaired.orientation],
    "invalid NPC enum repaired")

local generatedA = Profiles.GenerateNPCProfile(3819401, "General")
local generatedA2 = Profiles.GenerateNPCProfile(3819401, "General")
local generatedB = Profiles.GenerateNPCProfile(3819402, "General")
assertTrue(deepEqual(generatedA, generatedA2),
    "same seed deterministic")
assertTrue(not deepEqual(generatedA, generatedB),
    "different seeds can differ")
assertTrue(Constants.VALID_ORIENTATIONS[generatedA.orientation],
    "generated orientation valid")
assertEqual(
    Types.NormalizeNPCPersonality(generatedA, 999, "Doctor")
        .compassion,
    generatedA.compassion,
    "valid profile does not reroll"
)
local normalizedTwice = Types.NormalizeNPCPersonality(
    Types.NormalizeNPCPersonality(nil, 42, "Mechanic"),
    42,
    "Mechanic"
)
assertTrue(deepEqual(
    normalizedTwice,
    Types.NormalizeNPCPersonality(normalizedTwice, 42, "Mechanic")
), "NPC normalization idempotent")

local general = Profiles.GenerateNPCProfile(222, "General")
local doctor = Profiles.GenerateNPCProfile(222, "Doctor")
local mechanic = Profiles.GenerateNPCProfile(222, "Mechanic")
assertNear(doctor.compassion - general.compassion, 0.10, 0.0001,
    "Doctor compassion modifier")
assertNear(doctor.aggression - general.aggression, -0.05, 0.0001,
    "Doctor aggression modifier")
assertNear(mechanic.materialism - general.materialism, 0.05,
    0.0001, "Mechanic materialism modifier")
local overridden = Profiles.GenerateNPCProfile(222, "Doctor", {
    orientation = "gay",
    compassion = 0.99,
    foodPreference = "bland",
    aggression = 9,
})
assertEqual(overridden.orientation, "gay",
    "authored orientation override")
assertEqual(overridden.foodPreference, "bland",
    "authored food override")
assertEqual(overridden.compassion, 0.99,
    "authored numeric override")
assertEqual(overridden.aggression, 1,
    "authored override clamp")
local badOverride = Profiles.GenerateNPCProfile(222, "General", {
    orientation = "invalid",
    compassion = 0 / 0,
})
assertTrue(Constants.VALID_ORIENTATIONS[badOverride.orientation],
    "invalid enum override ignored")
assertTrue(badOverride.compassion == badOverride.compassion,
    "invalid numeric override ignored")

-- NPC constructor/migration persistence and copy/revision safety.
local authoredNPC = PNC.Types.NewRecord({
    id = "npc_authored_profile",
    displayName = "Authored",
    identitySeed = 555,
    archetypeID = "Doctor",
    social = {
        personalityOverrides = {
            orientation = "gay",
            compassion = 0.88,
        },
    },
})
assertEqual(authoredNPC.social.schemaVersion, 3, "NPC social V3")
assertEqual(authoredNPC.social.personality.orientation, "gay",
    "constructor applies authored enum")
assertEqual(authoredNPC.social.personality.compassion, 0.88,
    "constructor applies authored number")
local serialized = PNC.Persistence.SerializeRecord(authoredNPC)
local loaded = PNC.Persistence.DeserializeRecord(serialized)
assertTrue(deepEqual(
    authoredNPC.social.personality,
    loaded.social.personality
), "save/load does not reroll")
assertEqual(serialized.schemaVersion, 15, "NPC schema V15")
assertSaveSafe(serialized.social)

local oldNPC = PNC.Persistence.DeserializeRecord({
    schemaVersion = 11,
    id = "npc_old_profile",
    faction = "neutral",
    identity = {
        seed = 700,
        archetypeID = "General",
        displayName = "Old NPC",
        isFemale = false,
        survivor = {},
    },
    social = {
        schemaVersion = 1,
        revision = 3,
        relationships = {},
        recentEventIDs = { "social:old" },
    },
})
assertEqual(oldNPC.social.schemaVersion, 3, "old NPC social migrated")
assertEqual(oldNPC.social.revision, 3,
    "social migration preserves revision")
assertEqual(oldNPC.social.recentEventIDs[1], "social:old",
    "social cache preserved")
assertEqual(oldNPC.social.conduct.scores.courage, 0,
    "old NPC receives neutral conduct")
assertEqual(#oldNPC.social.conduct.evidence, 0,
    "old relationship history not inferred as conduct")
local oldProfileFirst = oldNPC.social.personality
local oldNPCSecond = PNC.Persistence.DeserializeRecord(
    PNC.Persistence.SerializeRecord(oldNPC)
)
assertTrue(deepEqual(
    oldProfileFirst,
    oldNPCSecond.social.personality
), "NPC migration idempotent")

PNC.Registry.Data[authoredNPC.id] = authoredNPC
local readNPC = Profiles.GetNPCProfile(authoredNPC.id)
readNPC.compassion = 0
assertEqual(authoredNPC.social.personality.compassion, 0.88,
    "NPC read returns copy")
local malformedNPC = PNC.Types.NewRecord({
    id = "npc_profile_repair",
    identitySeed = 808,
})
PNC.Registry.Data[malformedNPC.id] = malformedNPC
malformedNPC.social.personality = nil
local beforePresence = malformedNPC.presenceRevision
local beforeRecordRevision = malformedNPC.recordRevision
local beforeSocialRevision = malformedNPC.social.revision
Profiles.EnsureNPCProfile(malformedNPC)
assertEqual(malformedNPC.presenceRevision, beforePresence,
    "NPC profile repair leaves presence revision")
assertEqual(malformedNPC.recordRevision, beforeRecordRevision + 1,
    "NPC profile repair record revision")
assertEqual(malformedNPC.social.revision,
    beforeSocialRevision + 1, "NPC profile repair social revision")

-- Player-registry V2 migration gives historical identities neutral profiles.
PNC.PlayerCharacters.Load()
local historical = PNC.PlayerCharacters.GetRegistryRecord(
    "char_historical"
)
assertEqual(PNC.PlayerCharacters.GetRegistrySnapshot().schemaVersion, 4,
    "player registry V2 migration")
assertEqual(historical.socialProfile.orientation, "straight",
    "historical profile neutral orientation")
assertEqual(historical.socialProfile.resolvedAt, 0,
    "historical profile not guessed")
assertEqual(historical.conduct.scores.reliability, 0,
    "dead historical character receives neutral conduct")
assertEqual(#historical.conduct.evidence, 0,
    "historical conduct not inferred")
local normalizedRegistry = PNC.PlayerCharacterTypes.NormalizeRegistry(
    PNC.PlayerCharacters.GetRegistrySnapshot()
)
assertTrue(deepEqual(
    normalizedRegistry,
    PNC.PlayerCharacterTypes.NormalizeRegistry(normalizedRegistry)
), "player migration idempotent")

-- Authoritative player resolution, revision idempotence, and UUID isolation.
local uuidIndex = 0
PNC.PlayerCharacters.UUIDGenerator = function()
    uuidIndex = uuidIndex + 1
    return "char_profile_" .. tostring(uuidIndex)
end
local player = makePlayer("Patrick", {
    "pnc:pnc_gay",
    "pnc:pnc_spicelover",
    "pnc:pnc_reserved",
    "pnc:pnc_jealous",
    "pnc:pnc_friendly",
})
local profile = Profiles.ResolvePlayerProfile(player, 20)
local playerUUID = PNC.PlayerCharacters.GetCharacterUUID(player)
assertEqual(profile.orientation, "gay", "live Gay trait")
assertEqual(profile.foodPreference, "spicy", "live Spice trait")
assertEqual(profile.romanceStyle, "reserved", "live Reserved trait")
assertEqual(profile.jealousyStyle, "jealous", "live Jealous trait")
assertEqual(profile.socialStyle, "friendly", "live Friendly trait")
assertEqual(profile.sourceTraits.PNC_Gay, true,
    "canonical primitive source trait")
assertSaveSafe(profile)

local recordBefore = PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
local registryBefore =
    PNC.PlayerCharacters.GetRegistrySnapshot().revision
local repeated, repeatReason =
    Profiles.ResolvePlayerProfile(player, 21)
local recordRepeated =
    PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
assertEqual(repeatReason, "unchanged", "same survivor profile reused")
assertEqual(recordRepeated.revision, recordBefore.revision,
    "repeat character revision unchanged")
assertEqual(recordRepeated.socialProfile.revision,
    recordBefore.socialProfile.revision,
    "repeat profile revision unchanged")
assertEqual(PNC.PlayerCharacters.GetRegistrySnapshot().revision,
    registryBefore, "repeat registry revision unchanged")

player.selected = { "pnc:pnc_bisexual", "pnc:pnc_withdrawn" }
local changed = Profiles.RefreshPlayerProfile(player, 22)
local recordChanged =
    PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
assertEqual(changed.orientation, "bisexual",
    "changed trait orientation")
assertEqual(changed.socialStyle, "withdrawn",
    "changed trait social style")
assertEqual(recordChanged.socialProfile.revision,
    recordBefore.socialProfile.revision + 1,
    "exactly one profile revision")
assertEqual(recordChanged.revision, recordBefore.revision + 1,
    "exactly one character revision")
assertEqual(PNC.PlayerCharacters.GetRegistrySnapshot().revision,
    registryBefore + 1, "exactly one registry revision")

local playerRead = Profiles.GetPlayerProfile(playerUUID)
playerRead.orientation = "gay"
assertEqual(Profiles.GetPlayerProfile(playerUUID).orientation,
    "bisexual", "player read returns copy")
local oldProfileSnapshot = Profiles.GetPlayerProfile(playerUUID)
PNC.PlayerCharacters.MarkDead(player, 23, "test")
local successor = makePlayer(
    "Patrick",
    { "pnc:pnc_gay", "pnc:pnc_friendly" },
    {}
)
local successorProfile = Profiles.ResolvePlayerProfile(successor, 24)
local successorUUID =
    PNC.PlayerCharacters.GetCharacterUUID(successor)
assertTrue(successorUUID ~= playerUUID,
    "new survivor receives new UUID")
assertEqual(successorProfile.orientation, "gay",
    "new survivor resolves own profile")
assertEqual(successorProfile.socialStyle, "friendly",
    "new survivor does not inherit")
assertTrue(deepEqual(
    Profiles.GetPlayerProfile(playerUUID),
    oldProfileSnapshot
), "dead character profile unchanged")

-- Pure event modifiers: bounded, observer-only, and non-mutating.
local treatedDefinition = PNC.SocialEventDefinitions.treated_wound
local abandonedDefinition =
    PNC.SocialEventDefinitions.abandoned_in_combat
local treatedCopy = PNC.Core.DeepCopy(treatedDefinition)
local highCompassion = Profiles.GenerateNPCProfile(1, "General", {
    compassion = 1,
    socialStyle = "neutral",
})
local lowCompassion = Profiles.GenerateNPCProfile(1, "General", {
    compassion = 0,
    socialStyle = "neutral",
})
local profileCopy = PNC.Core.DeepCopy(highCompassion)
local highTreatment = Math.ModifySocialEvent(
    highCompassion,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
local lowTreatment = Math.ModifySocialEvent(
    lowCompassion,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
assertTrue(highTreatment.approvalEffect
    > lowTreatment.approvalEffect,
    "compassion changes treatment interpretation")
assertTrue(highTreatment.moraleEffect
    >= lowTreatment.moraleEffect,
    "compassion changes treatment morale")
assertTrue(deepEqual(treatedDefinition, treatedCopy),
    "modifier does not mutate definition")
assertTrue(deepEqual(highCompassion, profileCopy),
    "modifier does not mutate profile")

local loyal = Profiles.GenerateNPCProfile(2, "General", {
    loyalty = 1,
    forgiveness = 0.5,
})
local disloyal = Profiles.GenerateNPCProfile(2, "General", {
    loyalty = 0,
    forgiveness = 0.5,
})
local forgiving = Profiles.GenerateNPCProfile(2, "General", {
    loyalty = 0.5,
    forgiveness = 1,
})
local unforgiving = Profiles.GenerateNPCProfile(2, "General", {
    loyalty = 0.5,
    forgiveness = 0,
})
local loyalAbandon = Math.ModifySocialEvent(
    loyal,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    abandonedDefinition.targetMemory
)
local disloyalAbandon = Math.ModifySocialEvent(
    disloyal,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    abandonedDefinition.targetMemory
)
local forgivingAbandon = Math.ModifySocialEvent(
    forgiving,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    abandonedDefinition.targetMemory
)
local unforgivingAbandon = Math.ModifySocialEvent(
    unforgiving,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    abandonedDefinition.targetMemory
)
assertTrue(loyalAbandon.approvalEffect
    < disloyalAbandon.approvalEffect,
    "loyalty strengthens abandonment")
assertTrue(forgivingAbandon.approvalEffect
    > unforgivingAbandon.approvalEffect,
    "forgiveness softens abandonment")

local friendly = Profiles.GenerateNPCProfile(3, "General", {
    compassion = 0.5,
    socialStyle = "friendly",
})
local withdrawn = Profiles.GenerateNPCProfile(3, "General", {
    compassion = 0.5,
    socialStyle = "withdrawn",
})
local friendlyEffects = Math.ModifySocialEvent(
    friendly,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
local withdrawnEffects = Math.ModifySocialEvent(
    withdrawn,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
assertTrue(friendlyEffects.familiarityGain
    > withdrawnEffects.familiarityGain,
    "social style familiarity")
local negativeFamiliarity = Math.ModifySocialEvent(
    withdrawn,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    { familiarityGain = -20 }
)
assertEqual(negativeFamiliarity.familiarityGain, 0,
    "negative familiarity clamped")
local clamped = Math.ModifySocialEvent(
    friendly,
    treatedDefinition,
    { type = "treated_wound" },
    {
        approvalEffect = 1000,
        respectEffect = -1000,
        moraleEffect = 1000,
        familiarityGain = 1000,
    }
)
assertEqual(clamped.approvalEffect, 100,
    "modified approval clamp")
assertEqual(clamped.respectEffect, -100,
    "modified respect clamp")
assertEqual(clamped.moraleEffect, 100,
    "modified morale clamp")
assertEqual(clamped.familiarityGain, 100,
    "modified familiarity clamp")

local straightObserver = PNC.Core.DeepCopy(friendly)
local gayObserver = PNC.Core.DeepCopy(friendly)
local straightEffects
local gayEffects
straightObserver.orientation = "straight"
gayObserver.orientation = "gay"
straightEffects = Math.ModifySocialEvent(
    straightObserver,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
gayEffects = Math.ModifySocialEvent(
    gayObserver,
    treatedDefinition,
    { type = "treated_wound" },
    treatedDefinition.targetMemory
)
assertTrue(
    deepEqual(straightEffects, gayEffects),
    "orientation has no event effect"
)

-- Integrated event creation uses only the observer profile and preserves old
-- memories while retaining Phase 2 dedupe/cooldown behavior.
local observer = PNC.Types.NewRecord({
    id = "npc_profile_observer",
    displayName = "Observer",
    identitySeed = 900,
    social = { personality = highCompassion },
})
PNC.Registry.Data[observer.id] = observer
local observerKey = PNC.EntityRef.ForNPC(observer.id)
local actorKey = PNC.EntityRef.ForPlayerIdentity(
    "Patrick",
    successorUUID
)
local event = {
    id = "social:profile:treatment:1",
    type = "treated_wound",
    actorKey = actorKey,
    targetKey = observerKey,
    occurredAt = 30,
    sourceSystem = "health",
    context = {},
}
local eventResult = PNC.SocialEvents.Emit(event)
assertTrue(eventResult.ok, "profile-modified event accepted")
local relationship = PNC.Relationships.Get(observer.id, actorKey)
local originalMemoryEffect =
    relationship.memories[1].approvalEffect
assertEqual(originalMemoryEffect, highTreatment.approvalEffect,
    "observer profile modifies new memory")
local objectiveConduct = PNC.Conduct.GetForEntity(actorKey)
local objectiveEvidence =
    objectiveConduct.evidence[#objectiveConduct.evidence]
assertEqual(objectiveEvidence.effects.compassion, 2,
    "personality does not modify conduct compassion")
assertEqual(objectiveEvidence.effects.generosity, 1,
    "personality does not modify conduct generosity")
assertEqual(PNC.SocialEvents.Emit(event).reason, "duplicate_event",
    "profile event deduplication")
local cooldownEvent = PNC.Core.DeepCopy(event)
cooldownEvent.id = "social:profile:treatment:2"
cooldownEvent.occurredAt = 31
assertEqual(PNC.SocialEvents.Emit(cooldownEvent).reason,
    "cooldown_active", "profile event cooldown")
observer.social.personality.compassion = 0
relationship = PNC.Relationships.Get(observer.id, actorKey)
assertEqual(relationship.memories[1].approvalEffect,
    originalMemoryEffect, "existing memory not rewritten")
assertSaveSafe(PNC.Persistence.SerializeRecord(observer).social)

print("pnc_social_profiles_smoke: ok")
