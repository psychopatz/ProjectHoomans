local T = require "tests/support/test"

local CORE_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SHARED_ROOT = CORE_ROOT

T.addPackagePaths()

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, item in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(item, seen)
    end
    return output
end

local function equalValue(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    if left == right then return true end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return true end
    seen[left][right] = true
    for key, item in pairs(left) do
        if not equalValue(item, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function assertInventoryParity(before, after)
    local fields = {
        "id", "type", "stack", "container", "templateKey", "wornSlot",
        "equipSlot", "bagContainer", "wearableSlot", "fav",
        "interactionLocked", "interactionLockReason", "cond", "ammoCount",
    }
    local beforeItems = before and before.items or {}
    local afterItems = after and after.items or {}
    for itemID, item in pairs(beforeItems) do
        local restored = afterItems[itemID]
        T.truthy(restored, "inventory item missing: " .. tostring(itemID))
        for _, field in ipairs(fields) do
            T.equal(restored[field], item[field],
                "inventory field changed: " .. tostring(itemID) .. "." .. field)
        end
        T.truthy(equalValue(restored.itemState, item.itemState),
            "portable item state changed: " .. tostring(itemID))
    end
    for itemID in pairs(afterItems) do
        T.truthy(beforeItems[itemID],
            "unexpected inventory item after rehydration: " .. tostring(itemID))
    end
    T.truthy(equalValue(after.equipped, before.equipped),
        "equipped inventory slots changed")
    T.truthy(equalValue(after.worn, before.worn),
        "worn inventory slots changed")
end

local function persistedIdentityView(identity)
    local survivor = identity and identity.survivor or {}
    return {
        seed = identity and identity.seed,
        birth = identity and identity.birth,
        archetypeID = identity and identity.archetypeID,
        displayName = identity and identity.displayName,
        isFemale = identity and identity.isFemale,
        survivor = {
            forename = survivor.forename,
            surname = survivor.surname,
            hairModel = survivor.hairModel,
            beardModel = survivor.beardModel,
            skinColor = survivor.skinColor,
            hairColor = survivor.hairColor,
            skinTexture = survivor.skinTexture,
            voice = survivor.voice,
        },
    }
end

local function persistedAppearanceView(appearance)
    return {
        outfitItems = appearance and appearance.outfitItems,
        outfitItemSpecs = appearance and appearance.outfitItemSpecs,
        skinTexture = appearance and appearance.skinTexture,
        skinColor = appearance and appearance.skinColor,
        hairModel = appearance and appearance.hairModel,
        beardModel = appearance and appearance.beardModel,
        hairColor = appearance and appearance.hairColor,
        voice = appearance and appearance.voice,
    }
end

-- The engine boundary is deliberately deterministic and isolated.  The
-- production identity factory still runs; only SurvivorFactory's native
-- descriptor and equipment item construction are represented by fixtures.
ZombRand = function(maximum)
    return math.max(0, math.floor(tonumber(maximum) or 1) - 1)
end

local visual = {
    getSkinTexture = function() return "MaleBody01" end,
    getHairModel = function() return "Hair_Short" end,
    getBeardModel = function() return "Beard_Short" end,
    getSkinColor = function()
        return { r = 0.41, g = 0.32, b = 0.27 }
    end,
    getHairColor = function()
        return { r = 0.12, g = 0.08, b = 0.04 }
    end,
}

local survivorDescription = {
    isFemale = function() return false end,
    setFemale = function(self, value) self.female = value end,
    getForename = function() return "Factory" end,
    getSurname = function() return "Merchant" end,
    getVoicePrefix = function() return "parity_voice" end,
    getVoiceType = function() return 3 end,
    getVoicePitch = function() return 1.25 end,
    getHumanVisual = function(self) return visual end,
}

SurvivorType = { Neutral = 1 }
SurvivorFactory = {
    CreateSurvivor = function()
        return survivorDescription
    end,
}

PNC = {}
T.load("PsychopatzCore", "shared", "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua")
T.load(CORE_ROOT .. "Base/PNC_Core.lua")
T.load(CORE_ROOT .. "Base/PNC_Constants.lua")

local archetype = {
    id = "parity_merchant",
    label = "Parity Merchant",
    visualProfile = "civilian",
    skillBias = {},
    looks = {
        male = { { "Base.Shirt" } },
        female = { { "Base.Dress" } },
        spawnOutfit = { male = "Survivor", female = "Survivor" },
    },
    loadout = {
        bagChoices = {},
        supplies = {
            {
                key = "parity_bandage",
                type = "Base.Bandage",
                stack = 2,
                preferredContainer = "root",
            },
        },
        attached = {},
    },
    allowedJobs = { "merchant" },
}

PNC.Archetypes = {
    Get = function(id)
        return archetype
    end,
    GetColonistDefaults = function() return { archetype.id } end,
    GetHostileDefaults = function() return { archetype.id } end,
}

local bodyLocations = {
    ["Base.Shirt"] = "Torso_Upper",
    ["Base.Dress"] = "Dress",
}
PNC.Equipment = {
    NormalizeLoadoutSpec = function(value)
        value = type(value) == "table" and value or {}
        value.worn = type(value.worn) == "table" and value.worn or {}
        value.attached = type(value.attached) == "table" and value.attached or {}
        return value
    end,
    CreateItem = function(fullType)
        return {
            getBodyLocation = function()
                return bodyLocations[fullType]
            end,
            getFullType = function() return fullType end,
            IsWeapon = function()
                return fullType == "Base.HuntingKnife"
            end,
        }
    end,
}

PNC.Sandbox = {
    NPCMeleeWeaponSpawnChance = function() return 0 end,
    NPCRangedWeaponSpawnChance = function() return 0 end,
}
PNC.UniqueNPCs = {
    GetInventoryTemplate = function() return nil end,
}
PNC.SkillCatalog = {
    GetAllSkillIDs = function() return {} end,
}

T.load(CORE_ROOT .. "Identity/PNC_Identity.lua")
T.load(CORE_ROOT .. "Identity/PNC_Identity_Names.lua")
T.load(CORE_ROOT .. "Identity/PNC_Identity_Appearance.lua")
T.load(CORE_ROOT .. "Identity/PNC_Identity_Factory.lua")
T.load(CORE_ROOT .. "Identity/PNC_Identity_Profile.lua")

-- Use the production relationship normalizer so directed targets and memory
-- records are tested through the same schema used by the live service.
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
T.load(CORE_ROOT .. "Base/PNC_Types.lua")
T.load(CORE_ROOT .. "Inventory/PNC_Inventory.lua")
T.load(CORE_ROOT .. "Persistence/PNC_Persistence.lua")

PNC.Registry = {
    Data = {},
    MarkDirty = function(record, domain)
        record._baselineDirtyDomain = domain
        return true
    end,
}

local targetKey = "npc:parity_friend"
local social = PNC.RelationshipTypes.NewSocialState()
local relationship = PNC.RelationshipTypes.NewRelationship(targetKey)
relationship.approval = 21
relationship.respect = 8
relationship.familiarity = 4
relationship.memories = {
    PNC.RelationshipTypes.NewMemory({
        id = "memory:parity:friend",
        type = "trade_helped",
        aboutKey = targetKey,
        createdAt = 12,
        lastEvaluatedAt = 12,
        approvalEffect = 21,
        respectEffect = 8,
        strength = 1,
        knowledgeSource = "experienced",
        tags = { merchant = true },
    }),
}
social.relationships[targetKey] = relationship
social.revision = 2

local record = PNC.Types.NewRecord({
    id = "npc:parity:merchant",
    displayName = "Parity Merchant",
    identitySeed = 731,
    archetypeID = archetype.id,
    tacticalClass = "neutral",
    x = 104.5,
    y = 208.25,
    z = 0,
    anchorX = 100,
    anchorY = 200,
    anchorZ = 0,
    recruited = true,
    social = social,
    equipment = { worn = {}, attached = {} },
})
T.truthy(record, "canonical NPC generator returned no record")
PNC.Registry.Data[record.id] = record

local initialIdentity = deepCopy(record.identity)
local initialAppearance = deepCopy(PNC.Identity.RollAppearance(record))
T.equal(initialIdentity.displayName, "Parity Merchant", "factory display name")
T.equal(initialIdentity.survivor.voicePrefix, "parity_voice", "factory voice")
T.equal(initialIdentity.survivor.hairModel, "Hair_Short", "factory hair")
T.equal(initialIdentity.survivor.skinTexture, "MaleBody01", "factory skin texture")
T.equal(initialAppearance.outfitItems[1], "Base.Shirt", "seeded clothing")

local inventory = PNC.Inventory.CreateFromTemplate(record)
T.truthy(inventory and inventory.items, "canonical inventory template missing")
T.truthy(PNC.Inventory.ApplyDelta(record, {
    {
        op = "add",
        item = {
            id = "loot:parity:01",
            type = "Base.CustomLoot",
            stack = 3,
            container = "root",
            itemState = { modData = { source = "parity" } },
        },
    },
}, "npc_foundation_baseline"), "acquired item mutation")
T.truthy(PNC.Inventory.ApplyDelta(record, {
    {
        op = "add",
        item = {
            id = "weapon:parity:01",
            type = "Base.HuntingKnife",
            container = "root",
        },
    },
}, "npc_foundation_weapon"), "weapon mutation")
T.equal(PNC.Inventory.EquipPrimary(record, "weapon:parity:01"), true,
    "equipped weapon mutation")

local payload = PNC.Persistence.SerializeRecord(record)
T.truthy(payload, "NPC persistence payload missing")
T.equal(payload.schemaVersion, PNC.Const.PERSISTENCE_VERSION,
    "current persistence schema")
T.equal(payload.id, record.id, "stable NPC id serialized")
T.truthy(payload.identity and payload.identity.survivor,
    "resolved identity omitted")
T.truthy(payload.inventory, "personal inventory omitted")
T.truthy(payload.social and payload.social.relationships[targetKey],
    "directed social record omitted")
T.equal(payload.position.x, 104.5, "position x serialized")
T.equal(payload.anchor.x, 100, "anchor x serialized")

local restored = PNC.Persistence.DeserializeRecord(payload, record.id)
T.truthy(restored, "NPC persistence rehydration rejected current payload")
T.equal(restored.id, record.id, "stable NPC id rehydrated")
T.equal(restored.identitySeed, record.identitySeed, "identity seed changed")
T.truthy(equalValue(
    persistedIdentityView(restored.identity),
    persistedIdentityView(initialIdentity)
),
    "resolved identity changed during rehydration")
T.equal(restored.x, record.x, "position changed during rehydration")
T.equal(restored.anchorX, record.anchorX, "anchor changed during rehydration")

local restoredRelationship = restored.social.relationships[targetKey]
T.truthy(restoredRelationship, "directed relationship missing")
T.equal(restoredRelationship.approval, relationship.approval,
    "relationship approval changed")
T.equal(restoredRelationship.respect, relationship.respect,
    "relationship respect changed")
T.equal(restoredRelationship.memories[1].id,
    "memory:parity:friend", "relationship memory changed")

T.truthy(restored.persistedInventory, "inventory was not kept for lazy hydration")
T.truthy(PNC.Inventory.Deserialize(restored, restored.persistedInventory),
    "personal inventory rehydration failed")
assertInventoryParity(record.inventory, restored.inventory)
T.truthy(equalValue(
    PNC.Inventory.Serialize(record),
    PNC.Inventory.Serialize(restored)
), "inventory payload changed after rehydration")

local restoredAppearance = PNC.Identity.RollAppearance(restored)
T.truthy(equalValue(
    persistedAppearanceView(restoredAppearance),
    persistedAppearanceView(initialAppearance)
),
    "seeded resolved appearance changed during rehydration")
T.equal(restored.identity.survivor.voice,
    initialIdentity.survivor.voice, "voice changed during rehydration")
T.equal(restored.inventory.equipped.primary, "weapon:parity:01",
    "equipped primary changed during rehydration")

local unsupported = deepCopy(payload)
unsupported.schemaVersion = payload.schemaVersion - 1
T.equal(PNC.Persistence.DeserializeRecord(unsupported, record.id), nil,
    "unsupported persistence version was accepted")

T.finish("pnc_npc_foundation_parity_baseline_smoke")
