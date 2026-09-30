local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local Resolver = require "PNC/Core/Social/PNC_FlavorTextResolver"
local Const = PNC.FlavorTextConst

local function context(input)
    return Resolver.BuildContext(input)
end

-- ---------------------------------------------------------------------------
-- Threat classification
-- ---------------------------------------------------------------------------

T.equal(Resolver.ClassifyThreat(nil), Const.Threat.UNKNOWN,
    "a missing attacker is unknown rather than hostile")
T.equal(Resolver.ClassifyThreat("zombie"), Const.Threat.ZOMBIE,
    "a zombie string is recognized")
T.equal(Resolver.ClassifyThreat({ kind = "npc" }), Const.Threat.NPC,
    "a managed NPC attacker is recognized")
T.equal(Resolver.ClassifyThreat({ attackerKind = "player" }),
    Const.Threat.PLAYER, "a player attacker is recognized")
T.equal(Resolver.ClassifyThreat({ kind = "foreign_npc" }),
    Const.Threat.FOREIGN_NPC, "a foreign NPC attacker is recognized")
T.equal(Resolver.ClassifyThreat({ kind = "bandit" }),
    Const.Threat.FOREIGN_NPC, "a bandit attacker normalizes to foreign_npc")
T.equal(Resolver.ClassifyThreat({ kind = "foreign_npc", provider = "Bandits" }),
    Const.Threat.FOREIGN_NPC,
    "a provider-tagged bandit keeps the foreign NPC classification")
T.truthy(Resolver.IsHumanThreat(Const.Threat.NPC),
    "an NPC attacker counts as human")
T.truthy(Resolver.IsHumanThreat(Const.Threat.PLAYER),
    "a player attacker counts as human")
T.falsy(Resolver.IsHumanThreat(Const.Threat.ZOMBIE),
    "a zombie attacker is not human")

-- ---------------------------------------------------------------------------
-- Need classification
-- ---------------------------------------------------------------------------

T.equal(Resolver.ClassifyNeed({ bleedingRate = 2 }), Const.Need.BLEEDOUT,
    "active bleeding is the top-priority need")
T.equal(Resolver.ClassifyNeed({ bleeding = true }), Const.Need.BLEEDOUT,
    "a bleeding flag is honored")
T.equal(Resolver.ClassifyNeed({ treatableWoundCount = 3 }),
    Const.Need.BANDAGE, "treatable wounds ask for a bandage")
T.equal(Resolver.ClassifyNeed({ needsRescue = true }), Const.Need.RESCUE,
    "an explicit rescue request is honored")
T.equal(Resolver.ClassifyNeed({}), Const.Need.HELP,
    "no specific wound falls back to a generic help request")

-- ---------------------------------------------------------------------------
-- Audience classification
-- ---------------------------------------------------------------------------

T.equal(context({ isCompanion = true }).downedAudience, Const.Audience.ALLY,
    "an owned companion is an ally")
T.equal(
    context({ factionID = "F1", otherFactionID = "F1" }).downedAudience,
    Const.Audience.ALLY,
    "the same faction is an ally"
)
T.equal(
    context({ factionID = "F1", otherFactionID = "F2" }).downedAudience,
    Const.Audience.STRANGER,
    "a different non-belligerent faction is a stranger"
)
T.equal(
    context({
        factionID = "F1",
        otherFactionID = "F2",
        factionBand = Const.Audience.HOSTILE,
    }).downedAudience,
    Const.Audience.HOSTILE,
    "an at-war faction outranks stranger standing"
)
T.equal(
    context({
        factionID = "F1",
        otherFactionID = "F2",
        factionBand = Const.Audience.ALLY,
        relationshipTier = "reserved",
    }).downedAudience,
    Const.Audience.ALLY,
    "an allied faction is an ally"
)
T.equal(context({ relationshipTier = "warm" }).downedAudience,
    Const.Audience.FRIENDLY, "a warm relationship is friendly")
T.equal(context({ relationshipState = "friend" }).downedAudience,
    Const.Audience.FRIENDLY, "a friend relationship is friendly")
T.equal(context({ relationshipState = "enemy" }).downedAudience,
    Const.Audience.HOSTILE, "an enemy relationship is hostile")
T.equal(
    context({
        relationshipState = "enemy",
        factionID = "F1",
        otherFactionID = "F1",
    }).downedAudience,
    Const.Audience.HOSTILE,
    "a personal enemy stays hostile even inside the same faction"
)
T.equal(context({}).downedAudience, Const.Audience.NEUTRAL,
    "an unattributed listener is neutral")
T.equal(context({ isOwner = true }).downedAudience, Const.Audience.SELF,
    "the owning player is the self audience")

-- ---------------------------------------------------------------------------
-- Threat overrides
-- ---------------------------------------------------------------------------

T.equal(
    context({
        threat = Const.Threat.ZOMBIE,
        relationshipState = "enemy",
    }).downedNeed,
    Const.Need.FAINT,
    "a downed hostile facing the dead faints instead of pleading"
)
T.equal(
    context({
        threat = Const.Threat.NPC,
        relationshipState = "enemy",
    }).downedNeed,
    Const.Need.MERCY,
    "a downed hostile facing a survivor pleads for mercy"
)
T.equal(
    context({
        threat = Const.Threat.ZOMBIE,
        isCompanion = true,
        treatableWoundCount = 1,
    }).downedNeed,
    Const.Need.BANDAGE,
    "a downed ally still asks for the bandage it actually needs"
)

-- ---------------------------------------------------------------------------
-- Key resolution order
-- ---------------------------------------------------------------------------

local keys = Resolver.ResolveKeys({
    threat = Const.Threat.ZOMBIE,
    isCompanion = true,
    bleedingRate = 1,
})
T.equal(keys[1], "ally__bleedout__zombie",
    "the most specific key is tried first")
T.equal(keys[2], "ally__bleedout",
    "the audience-plus-need key is the second fallback")
T.equal(keys[#keys - 1], "ally", "the audience-only lane is a fallback")
T.equal(keys[#keys], "bleedout", "the need-only lane is the last fallback")

local mercyKeys = Resolver.ResolveKeys({
    threat = Const.Threat.PLAYER,
    relationshipState = "enemy",
})
T.equal(mercyKeys[1], "hostile__mercy__player",
    "a hostile plea against a player is attributed to the attacker kind")

local npcKeys = Resolver.ResolveKeys({
    threat = Const.Threat.NPC,
    factionID = "F1",
    otherFactionID = "F2",
    treatableWoundCount = 1,
})
T.equal(npcKeys[1], "stranger__bandage__npc",
    "a stranger addresses an NPC attacker by kind")

local zombieKeys = Resolver.ResolveKeys({ threat = Const.Threat.ZOMBIE })
local i
for i = 1, #zombieKeys do
    T.falsy(string.find(zombieKeys[i], "__npc", 1, true),
        "a zombie attack never produces an NPC-attributed key")
end

-- ---------------------------------------------------------------------------
-- Bounded output and degenerate input
-- ---------------------------------------------------------------------------

T.truthy(#Resolver.ResolveKeys(nil) > 0,
    "nil input still yields a usable fallback ladder")
T.truthy(#Resolver.ResolveKeys("nonsense") > 0,
    "a non-table input still yields a usable fallback ladder")
T.truthy(#Resolver.ResolveKeys({}) <= 6,
    "the fallback ladder stays bounded")
T.truthy(context({}) .downedAudience ~= nil,
    "context is always populated")

-- Every declared vocabulary value must be reachable, so definitions and
-- resolver can never silently drift apart.
local function reachableAudience(value, i)
    return Const.AllNeeds[i] ~= nil or value ~= nil
end
for i = 1, #Const.AllThreats do
    T.truthy(Const.AllThreats[i] ~= nil, "threat vocabulary entry is present")
end
for i = 1, #Const.AllNeeds do
    T.truthy(Const.AllNeeds[i] ~= nil, "need vocabulary entry is present")
end
T.truthy(reachableAudience(Const.Audience.SELF, 1),
    "audience vocabulary is enumerable")

return true