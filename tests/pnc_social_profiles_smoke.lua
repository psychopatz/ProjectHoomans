local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

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
        error("unsafe persisted profile value: " .. valueType)
    end
    seen = seen or {}
    if seen[value] then error("profile cycle") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe persisted profile key")
        end
        validatePersistedValue(item, seen)
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

T.load(T.path("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"))
PNC = {}
T.load(ROOT .. "Base/PNC_Core.lua")
T.load(ROOT .. "Base/PNC_Constants.lua")
T.load(ROOT .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(ROOT .. "Identity/PNC_Identity.lua")
T.load(ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
T.load(ROOT .. "Relationships/PNC_SocialTraits.lua")
T.load(ROOT .. "Relationships/PNC_SocialProfileMath.lua")
T.load(ROOT .. "Conduct/PNC_ConductConstants.lua")
T.load(ROOT .. "Conduct/PNC_ConductTypes.lua")
T.load(ROOT .. "Conduct/PNC_ConductMath.lua")
T.load(ROOT .. "Conduct/PNC_ConductDefinitions.lua")
T.load(ROOT .. "Factions/PNC_FactionConstants.lua")
T.load(ROOT .. "Factions/PNC_FactionArchetypes.lua")
T.load(ROOT .. "Factions/PNC_FactionEmblems.lua")
T.load(ROOT .. "Factions/PNC_FactionTypes.lua")
T.load(ROOT .. "Identity/PNC_PlayerCharacterTypes.lua")
T.load(ROOT .. "Relationships/PNC_RelationshipConstants.lua")
T.load(ROOT .. "Relationships/PNC_RelationshipStates.lua")
T.load(ROOT .. "Relationships/PNC_RelationshipTypes.lua")
T.load(ROOT .. "Relationships/PNC_RelationshipMath.lua")
T.load(ROOT .. "Relationships/PNC_SocialEventDefinitions.lua")

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
T.load(ROOT .. "Base/PNC_Types.lua")
T.load(ROOT .. "Relationships/PNC_Relationships.lua")
T.load(ROOT .. "Persistence/PNC_Persistence.lua")

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

T.load(SERVER .. "Player/PNC_PlayerCharacterDebug.lua")
T.load(SERVER .. "Player/PNC_PlayerCharacterService.lua")
T.load(SERVER .. "Social/PNC_SocialProfileDebug.lua")
T.load(SERVER .. "Social/PNC_SocialProfileService.lua")
T.load(SERVER .. "Social/PNC_ConductService.lua")
T.load(SERVER .. "Social/PNC_RelationshipService.lua")
T.load(SERVER .. "Social/PNC_SocialEventDebug.lua")
T.load(SERVER .. "Social/PNC_SocialEventService.lua")

local Constants = PNC.SocialProfileConstants
local Types = PNC.SocialProfileTypes
local Profiles = PNC.SocialProfiles
local Math = PNC.SocialProfileMath

-- Pure defaults, enums, numeric repair, and deterministic generation.
local playerDefaults = Types.NewPlayerSocialProfile()
T.equal(playerDefaults.orientation, "straight",
    "player default orientation")
T.equal(playerDefaults.foodPreference, "neutral",
    "player default food")
T.equal(playerDefaults.romanceStyle, "neutral",
    "player default romance")
T.equal(playerDefaults.jealousyStyle, "normal",
    "player default jealousy")
T.equal(playerDefaults.socialStyle, "neutral",
    "player default social")
T.equal(playerDefaults.schemaVersion, 1,
    "player profile schema")

for _, orientation in ipairs({ "straight", "gay", "bisexual" }) do
    T.equal(Types.NormalizePlayerSocialProfile({
        orientation = orientation,
    }).orientation, orientation, orientation .. " enum")
end
T.equal(Types.NormalizePlayerSocialProfile({
    orientation = "future",
}).orientation, "straight", "invalid orientation")
T.equal(Types.NormalizePlayerSocialProfile({
    foodPreference = "spicy",
    romanceStyle = "reserved",
    jealousyStyle = "unpossessive",
    socialStyle = "withdrawn",
}).foodPreference, "spicy", "food enum")
T.equal(Types.NormalizePlayerSocialProfile({
    romanceStyle = "reserved",
}).romanceStyle, "reserved", "romance enum")
T.equal(Types.NormalizePlayerSocialProfile({
    jealousyStyle = "unpossessive",
}).jealousyStyle, "unpossessive", "jealousy enum")
T.equal(Types.NormalizePlayerSocialProfile({
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
T.equal(repaired.compassion, 0, "unit lower clamp")
T.equal(repaired.sociability, 1, "unit upper clamp")
T.truthy(repaired.forgiveness >= 0
    and repaired.forgiveness <= 1, "NaN repaired")
T.truthy(repaired.bravery >= 0 and repaired.bravery <= 1,
    "infinity repaired")
T.truthy(repaired.materialism >= 0
    and repaired.materialism <= 1, "negative infinity repaired")
T.truthy(Constants.VALID_ORIENTATIONS[repaired.orientation],
    "invalid NPC enum repaired")

local generatedA = Profiles.GenerateNPCProfile(3819401, "General")
local generatedA2 = Profiles.GenerateNPCProfile(3819401, "General")
local generatedB = Profiles.GenerateNPCProfile(3819402, "General")
T.truthy(deepEqual(generatedA, generatedA2),
    "same seed deterministic")
T.truthy(not deepEqual(generatedA, generatedB),
    "different seeds can differ")
T.truthy(Constants.VALID_ORIENTATIONS[generatedA.orientation],
    "generated orientation valid")
T.equal(
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
T.truthy(deepEqual(
    normalizedTwice,
    Types.NormalizeNPCPersonality(normalizedTwice, 42, "Mechanic")
), "NPC normalization idempotent")

local general = Profiles.GenerateNPCProfile(222, "General")
local doctor = Profiles.GenerateNPCProfile(222, "Doctor")
local mechanic = Profiles.GenerateNPCProfile(222, "Mechanic")
T.near(doctor.compassion - general.compassion, 0.10, 0.0001, "Doctor compassion modifier")
T.near(doctor.aggression - general.aggression, -0.05, 0.0001, "Doctor aggression modifier")
T.near(mechanic.materialism - general.materialism, 0.05, 0.0001, "Mechanic materialism modifier")
local overridden = Profiles.GenerateNPCProfile(222, "Doctor", {
    orientation = "gay",
    compassion = 0.99,
    foodPreference = "bland",
    aggression = 9,
})
T.equal(overridden.orientation, "gay",
    "authored orientation override")
T.equal(overridden.foodPreference, "bland",
    "authored food override")
T.equal(overridden.compassion, 0.99,
    "authored numeric override")
T.equal(overridden.aggression, 1,
    "authored override clamp")
local badOverride = Profiles.GenerateNPCProfile(222, "General", {
    orientation = "invalid",
    compassion = 0 / 0,
})
T.truthy(Constants.VALID_ORIENTATIONS[badOverride.orientation],
    "invalid enum override ignored")
T.truthy(badOverride.compassion == badOverride.compassion,
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
T.equal(authoredNPC.social.schemaVersion, 3, "NPC social V3")
T.equal(authoredNPC.social.personality.orientation, "gay",
    "constructor applies authored enum")
T.equal(authoredNPC.social.personality.compassion, 0.88,
    "constructor applies authored number")
local serialized = PNC.Persistence.SerializeRecord(authoredNPC)
local loaded = PNC.Persistence.DeserializeRecord(serialized)
T.truthy(deepEqual(
    authoredNPC.social.personality,
    loaded.social.personality
), "save/load does not reroll")
T.equal(serialized.schemaVersion, 15, "NPC schema V15")
validatePersistedValue(serialized.social)

local oldNPC = PNC.Persistence.DeserializeRecord({
    schemaVersion = 11,
    id = "npc_old_profile",
    tacticalClass = "neutral",
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
T.equal(oldNPC.social.schemaVersion, 3, "old NPC social migrated")
T.equal(oldNPC.social.revision, 3,
    "social migration preserves revision")
T.equal(oldNPC.social.recentEventIDs[1], "social:old",
    "social cache preserved")
T.equal(oldNPC.social.conduct.scores.courage, 0,
    "old NPC receives neutral conduct")
T.equal(#oldNPC.social.conduct.evidence, 0,
    "old relationship history not inferred as conduct")
local oldProfileFirst = oldNPC.social.personality
local oldNPCSecond = PNC.Persistence.DeserializeRecord(
    PNC.Persistence.SerializeRecord(oldNPC)
)
T.truthy(deepEqual(
    oldProfileFirst,
    oldNPCSecond.social.personality
), "NPC migration idempotent")

PNC.Registry.Data[authoredNPC.id] = authoredNPC
local readNPC = Profiles.GetNPCProfile(authoredNPC.id)
readNPC.compassion = 0
T.equal(authoredNPC.social.personality.compassion, 0.88,
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
T.equal(malformedNPC.presenceRevision, beforePresence,
    "NPC profile repair leaves presence revision")
T.equal(malformedNPC.recordRevision, beforeRecordRevision + 1,
    "NPC profile repair record revision")
T.equal(malformedNPC.social.revision,
    beforeSocialRevision + 1, "NPC profile repair social revision")

-- Player-registry V2 migration gives historical identities neutral profiles.
PNC.PlayerCharacters.Load()
local historical = PNC.PlayerCharacters.GetRegistryRecord(
    "char_historical"
)
T.equal(PNC.PlayerCharacters.GetRegistrySnapshot().schemaVersion, 6,
    "player registry V2 migration")
T.equal(historical.socialProfile.orientation, "straight",
    "historical profile neutral orientation")
T.equal(historical.socialProfile.resolvedAt, 0,
    "historical profile not guessed")
T.equal(historical.conduct.scores.reliability, 0,
    "dead historical character receives neutral conduct")
T.equal(#historical.conduct.evidence, 0,
    "historical conduct not inferred")
local normalizedRegistry = PNC.PlayerCharacterTypes.NormalizeRegistry(
    PNC.PlayerCharacters.GetRegistrySnapshot()
)
T.truthy(deepEqual(
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
T.equal(profile.orientation, "gay", "live Gay trait")
T.equal(profile.foodPreference, "spicy", "live Spice trait")
T.equal(profile.romanceStyle, "reserved", "live Reserved trait")
T.equal(profile.jealousyStyle, "jealous", "live Jealous trait")
T.equal(profile.socialStyle, "friendly", "live Friendly trait")
T.equal(profile.sourceTraits.PNC_Gay, true,
    "canonical primitive source trait")
validatePersistedValue(profile)

local recordBefore = PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
local registryBefore =
    PNC.PlayerCharacters.GetRegistrySnapshot().revision
local repeated, repeatReason =
    Profiles.ResolvePlayerProfile(player, 21)
local recordRepeated =
    PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
T.equal(repeatReason, "unchanged", "same survivor profile reused")
T.equal(recordRepeated.revision, recordBefore.revision,
    "repeat character revision unchanged")
T.equal(recordRepeated.socialProfile.revision,
    recordBefore.socialProfile.revision,
    "repeat profile revision unchanged")
T.equal(PNC.PlayerCharacters.GetRegistrySnapshot().revision,
    registryBefore, "repeat registry revision unchanged")

player.selected = { "pnc:pnc_bisexual", "pnc:pnc_withdrawn" }
local changed = Profiles.RefreshPlayerProfile(player, 22)
local recordChanged =
    PNC.PlayerCharacters.GetRegistryRecord(playerUUID)
T.equal(changed.orientation, "bisexual",
    "changed trait orientation")
T.equal(changed.socialStyle, "withdrawn",
    "changed trait social style")
T.equal(recordChanged.socialProfile.revision,
    recordBefore.socialProfile.revision + 1,
    "exactly one profile revision")
T.equal(recordChanged.revision, recordBefore.revision + 1,
    "exactly one character revision")
T.equal(PNC.PlayerCharacters.GetRegistrySnapshot().revision,
    registryBefore + 1, "exactly one registry revision")

local playerRead = Profiles.GetPlayerProfile(playerUUID)
playerRead.orientation = "gay"
T.equal(Profiles.GetPlayerProfile(playerUUID).orientation,
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
T.truthy(successorUUID ~= playerUUID,
    "new survivor receives new UUID")
T.equal(successorProfile.orientation, "gay",
    "new survivor resolves own profile")
T.equal(successorProfile.socialStyle, "friendly",
    "new survivor does not inherit")
T.truthy(deepEqual(
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
T.truthy(highTreatment.approvalEffect
    > lowTreatment.approvalEffect,
    "compassion changes treatment interpretation")
T.truthy(highTreatment.moraleEffect
    >= lowTreatment.moraleEffect,
    "compassion changes treatment morale")
T.truthy(deepEqual(treatedDefinition, treatedCopy),
    "modifier does not mutate definition")
T.truthy(deepEqual(highCompassion, profileCopy),
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
T.truthy(loyalAbandon.approvalEffect
    < disloyalAbandon.approvalEffect,
    "loyalty strengthens abandonment")
T.truthy(forgivingAbandon.approvalEffect
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
T.truthy(friendlyEffects.familiarityGain
    > withdrawnEffects.familiarityGain,
    "social style familiarity")
local negativeFamiliarity = Math.ModifySocialEvent(
    withdrawn,
    abandonedDefinition,
    { type = "abandoned_in_combat" },
    { familiarityGain = -20 }
)
T.equal(negativeFamiliarity.familiarityGain, 0,
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
T.equal(clamped.approvalEffect, 100,
    "modified approval clamp")
T.equal(clamped.respectEffect, -100,
    "modified respect clamp")
T.equal(clamped.moraleEffect, 100,
    "modified morale clamp")
T.equal(clamped.familiarityGain, 100,
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
T.truthy(
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
T.truthy(eventResult.ok, "profile-modified event accepted")
local relationship = PNC.Relationships.Get(observer.id, actorKey)
local originalMemoryEffect =
    relationship.memories[1].approvalEffect
T.equal(originalMemoryEffect, highTreatment.approvalEffect,
    "observer profile modifies new memory")
local objectiveConduct = PNC.Conduct.GetForEntity(actorKey)
local objectiveEvidence =
    objectiveConduct.evidence[#objectiveConduct.evidence]
T.equal(objectiveEvidence.effects.compassion, 2,
    "personality does not modify conduct compassion")
T.equal(objectiveEvidence.effects.generosity, 1,
    "personality does not modify conduct generosity")
T.equal(PNC.SocialEvents.Emit(event).reason, "duplicate_event",
    "profile event deduplication")
local cooldownEvent = PNC.Core.DeepCopy(event)
cooldownEvent.id = "social:profile:treatment:2"
cooldownEvent.occurredAt = 31
T.equal(PNC.SocialEvents.Emit(cooldownEvent).reason,
    "cooldown_active", "profile event cooldown")
observer.social.personality.compassion = 0
relationship = PNC.Relationships.Get(observer.id, actorKey)
T.equal(relationship.memories[1].approvalEffect,
    originalMemoryEffect, "existing memory not rewritten")
validatePersistedValue(PNC.Persistence.SerializeRecord(observer).social)
T.finish("pnc_social_profiles_smoke")

T.finish("pnc_social_profiles_smoke")
