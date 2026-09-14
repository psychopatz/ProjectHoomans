local T = require "tests/support/test"

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

local factoryCalls = 0
local factoryDescription = {
    isFemale = function() return false end,
    setFemale = function(self, value) self.female = value end,
    getForename = function() return "FactoryFirst" end,
    getSurname = function() return "FactoryLast" end,
    getVoicePrefix = function() return "factory_voice" end,
    getVoiceType = function() return 2 end,
    getVoicePitch = function() return 4.5 end,
    getHumanVisual = function(self) return self.visual end,
    visual = {},
}

SurvivorType = { Neutral = 1 }
SurvivorFactory = {
    CreateSurvivor = function()
        factoryCalls = factoryCalls + 1
        return factoryDescription
    end,
}
ZombRand = function(maximum) return math.max(0, math.floor(maximum) - 1) end

PNC = {
    Core = { DeepCopy = deepCopy },
    Identity = {},
    Registry = { Loaded = true, Data = {} },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Names.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Factory.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_ID.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_UniqueNPCs.lua")

local Unique = PNC.UniqueNPCs

local ok, reason = Unique.RegisterInventoryTemplate({
    id = "unique:gorgon_ramsee:v1",
    version = 1,
    items = {
        { templateKey = "money", type = "Base.Money", stack = 1000 },
    },
})
T.truthy(ok, reason)

local template = Unique.GetInventoryTemplate("unique:gorgon_ramsee:v1")
T.equal(template.items[1].type, "Base.Money", "template item type")
T.equal(template.items[1].stack, 1000, "template item stack")

ok, reason = Unique.Register({
    id = "gorgon_ramsee",
    displayName = "Gorgon Ramsee",
    isFemale = true,
    identity = { survivor = { surname = "Ramsee" } },
    hpMax = 175,
    combatProfile = { meleeDamage = 42 },
    equipment = { primaryFullType = "Base.KitchenKnife" },
    skillLevels = { Cooking = 10 },
    inventoryTemplateRef = "unique:gorgon_ramsee:v1",
})
T.truthy(ok, reason)

local resolved = Unique.Resolve(Unique.Get("gorgon_ramsee"), {
    seed = 42,
    archetypeID = "Chef",
})
T.equal(factoryCalls, 1, "SurvivorFactory used for unique identity")
T.equal(resolved.isFemale, true, "factory-compatible boolean gender")
T.equal(resolved.identity.displayName, "Gorgon Ramsee", "display name")
T.equal(resolved.identity.survivor.forename, "Gorgon",
    "display name supplies readable forename")
T.equal(resolved.identity.survivor.surname, "Ramsee",
    "surname override")
T.equal(resolved.identity.survivor.voicePrefix, "factory_voice",
    "voice prefix comes from SurvivorFactory")
T.equal(resolved.identity.survivor.voiceType, 2,
    "voice type comes from SurvivorFactory")
T.equal(resolved.identity.survivor.voicePitch, 4.5,
    "voice pitch comes from SurvivorFactory")
T.equal(resolved.skillLevels.Cooking, 10, "authored skill level")
T.equal(resolved.hpMax, 175, "authored health")
T.equal(resolved.combatProfile.meleeDamage, 42, "authored combat profile")
T.equal(resolved.equipment.primaryFullType, "Base.KitchenKnife",
    "authored equipment")
T.equal(resolved.inventoryTemplateRef, "unique:gorgon_ramsee:v1",
    "inventory reference")

local runtimeID = PNC.Identity.GenerateNPCID(resolved.identity, "seed")
T.truthy(string.match(runtimeID, "^npcGorgonRamsee_[0-9A-Z]+$"),
    "readable runtime NPC ID")

SurvivorFactory.CreateSurvivor = function() return nil end
local fallback = PNC.Identity.GenerateResolvedIdentity({
    id = "factory_fallback",
    isFemale = false,
    identitySeed = 11,
})
T.equal(fallback.displayName,
    PNC.IdentityNames.Generate(11, false, nil),
    "deterministic name fallback")

PNC.AbstractWorldStore = {
    Registry = { uniqueNPCsByID = {} },
    EnsureLoaded = function() return true end,
    WorldAgeHours = function() return 12 end,
    Touch = function(_, reasonValue)
        PNC.AbstractWorldStore.lastTouch = reasonValue
    end,
}
PNC.DirectorConfig = {
    UNIQUE_NPC_POOL_CHANCE = 1,
}
PNC.Core.IsAuthority = function() return true end
T.load("ProjectHoomans", "server", "PNC/Director/PNC_UniqueNPCRegistry.lua")
PNC.Registry.Get = function(npcID)
    return PNC.Registry.Data[npcID]
end

local claim, claimReason = PNC.UniqueNPCRegistry.ReserveForGeneration({
    generationId = "generation_unique_test",
    seed = 42,
    force = true,
})
T.truthy(claim, claimReason)
T.equal(claim.definitionId, "gorgon_ramsee", "reserved definition")

local committed, commitReason = PNC.UniqueNPCRegistry.CommitSpawn(
    claim,
    { id = runtimeID },
    12
)
T.truthy(committed, commitReason)
T.equal(PNC.UniqueNPCRegistry.Get("gorgon_ramsee").status,
    "alive", "unique becomes alive")

local duplicateClaim = PNC.UniqueNPCRegistry.ReserveForGeneration({
    generationId = "generation_unique_duplicate",
    seed = 43,
    force = true,
})
T.falsy(duplicateClaim, "alive unique cannot be reserved twice")

local dead, deadReason = PNC.UniqueNPCRegistry.MarkDead({
    id = runtimeID,
    uniqueDefinitionId = "gorgon_ramsee",
    identitySeed = claim.identitySeed,
}, "test_death", 13)
T.truthy(dead, deadReason)
T.equal(PNC.UniqueNPCRegistry.Get("gorgon_ramsee").status,
    "dead", "unique becomes permanently dead")

PNC.Registry.Data[runtimeID] = {
    id = runtimeID,
    name = "Gorgon Ramsee",
    uniqueDefinitionId = "gorgon_ramsee",
    alive = false,
    presenceState = "corpse",
    tacticalClass = "neutral",
    x = 10,
    y = 20,
    z = 0,
    health = { current = 0, max = 175, state = "dead" },
    skillBaseLevels = { Cooking = 10 },
    affiliation = {
        factionID = "faction:kitchen",
        membershipStatus = "member",
        role = "chef",
        rank = "lead",
        communityID = "community:kitchen",
        communityRole = "cook",
    },
}
PNC.Factions = {
    GetPresentation = function() return {
        name = "Kitchen Faction", status = "active",
    } end,
}
PNC.Communities = {
    Get = function() return {
        name = "Kitchen Community", status = "stable",
    } end,
}

ok, reason = Unique.Register({
    id = "reconcile_me",
    displayName = "Reconcile Me",
    isFemale = false,
})
T.truthy(ok, reason)
local interruptedClaim = PNC.UniqueNPCRegistry.ReserveForGeneration({
    generationId = "generation_unique_interrupted",
    seed = 44,
    force = true,
})
T.truthy(interruptedClaim, "interrupted reservation created")
T.truthy(PNC.UniqueNPCRegistry.Reconcile(), "reconcile completed")
T.falsy(PNC.UniqueNPCRegistry.Get("reconcile_me"),
    "orphaned reservation is released")

local debugSnapshot, debugReason = PNC.UniqueNPCRegistry.BuildDebugSnapshot()
T.truthy(debugSnapshot, debugReason)
T.equal(debugSnapshot.counts.total, 2, "unique debug count")
T.equal(debugSnapshot.counts.dead, 1, "dead unique debug count")
local gorgonDebug
for _, entry in ipairs(debugSnapshot.entries) do
    if entry.definitionId == "gorgon_ramsee" then gorgonDebug = entry end
end
T.truthy(gorgonDebug, "unique debug entry")
T.equal(gorgonDebug.status, "dead", "debug lifecycle status")
T.equal(gorgonDebug.runtime.affiliation.name, "Kitchen Faction",
    "debug faction presentation")
T.equal(gorgonDebug.runtime.community.name, "Kitchen Community",
    "debug community presentation")
T.equal(gorgonDebug.runtime.healthState, "dead", "debug health state")

T.finish("pnc_unique_npc_smoke")
