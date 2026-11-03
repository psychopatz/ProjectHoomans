local T = require "tests/support/test"

T.addPackagePaths()

-- This characterization deliberately does not load any Project Hoomans
-- SocialFlavorDefinitions_* shard.  The migrated families must still select
-- a semantic ResponsePlan and selected wording when the old prose registry is
-- absent.  Generic PsychopatzCore compatibility remains a separate boundary.
PNC = { Semantics = {} }
local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)
local Authority = PNC.Semantics.RealizationAuthority

T.falsy(PNC.SocialFlavorDefinitions,
    "semantic selection does not require first-party Flavor definitions")

local function fact(eventRef, values)
    values = values or {}
    values.eventRef = eventRef
    values.authoritative = true
    values.disclosure = "player"
    return { [eventRef] = values }
end

local function resolve(eventType, eventID, context)
    context = context or {}
    context.eventType = eventType
    context.eventRef = eventID
    context.eventID = eventID
    local result = Reactions.Resolve({
        eventType = eventType,
        eventID = eventID,
        npcID = "npc-social-event",
        act = "REACT",
        context = context,
    })
    T.truthy(result, eventType .. " selects a semantic realization")
    T.truthy(result.responsePlanID,
        eventType .. " carries a semantic response plan")
    T.truthy(result.realizationID,
        eventType .. " carries a semantic realization ID")
    T.truthy(result.fallback and result.fallback ~= "",
        eventType .. " carries selected wording")
    T.truthy(result.responsePlan,
        eventType .. " carries the selected ResponsePlan")
    T.falsy(string.find(result.fallback, "social.", 1, true),
        eventType .. " does not expose a legacy Flavor key")
    return result
end

local farewell = Authority.Resolve({
    poolID = "semantic.flow.farewell",
    responsePlanID = "semantic.flow.farewell",
    realizationFamily = "farewell",
    act = "FAREWELL",
    topic = "farewell",
    context = { socialRole = "friendly" },
    salt = "social-event-farewell",
})
T.truthy(farewell and farewell.fallback,
    "farewell selects through the semantic flow without legacy prose")

local safety = resolve(
    "conversation_safety",
    "event:social:safety",
    {
        semanticEventFacts = fact("event:social:safety", {
            summary = "danger is close",
            location = "the east road",
        }),
        factRefs = { "event:social:safety" },
    }
)
T.equal(safety.realizationID, "semantic.conversation.safety.danger",
    "safety selects the semantic danger variant")

local playerSpoke = resolve("player_spoke", "event:social:player", {
    socialRole = "colonist",
})
T.equal(playerSpoke.realizationFamily, "semantic.social.reaction",
    "player-spoke acknowledgement uses the semantic social pool")

local witness = resolve(
    "zombie_kill_witnessed",
    "event:social:witness",
    {
        combatReactionRole = "witness",
        combatReactionStyle = "practical",
        combatReactionMood = "steady",
        combatPressure = "several",
        killerActorKind = "player",
        factRefs = { "event:social:witness" },
        semanticEventFacts = fact("event:social:witness", {
            summary = "the player killed a zombie nearby",
            happened = "the player killed a zombie nearby",
            countBand = "several",
            quantity = "5 zombies are still close enough to matter.",
            health = "I'm okay.",
            nextAction = "Clear the nearby zombies before we relax.",
        }),
    }
)
T.truthy(string.find(
    witness.realizationID,
    "semantic.combat.reaction.kill_witness_practical_",
    1,
    true
), "witnessed kill selects the practical witness reaction family")
T.equal(#(witness.offerIDs or {}), 4,
    "witnessed kill exposes the four grounded event follow-ups")

local abandoned = resolve(
    "follower_abandoned_hostile_npc",
    "event:social:abandonment",
    {
        factRefs = { "event:social:abandonment" },
        semanticEventFacts = fact("event:social:abandonment", {
            summary = "the follower was left behind during combat",
            happened = "the follower was left behind during combat",
            pursuer = "hostile NPC scout",
            pursuerName = "hostile NPC scout",
        }),
    }
)
T.equal(#(abandoned.offerIDs or {}), 1,
    "abandonment exposes the grounded pursuer follow-up")
for _, id in ipairs(abandoned.offerIDs or {}) do
    T.falsy(string.find(id, "health", 1, true),
        "abandonment does not expose an unsupported health follow-up")
end

local horde = resolve(
    "zombie_horde_detected",
    "event:social:horde",
    {
        factRefs = {
            "event:social:horde",
            "event:social:horde:location",
            "event:social:horde:quantity",
        },
        semanticEventFacts = fact("event:social:horde", {
            summary = "a zombie horde was detected",
            location = "the north road",
            countBand = "several",
        }),
    }
)
T.equal(horde.realizationID, "semantic.combat.horde.default",
    "legacy horde event uses the dedicated semantic horde authority")
T.equal(#horde.offerIDs, 3,
    "horde exposes its bounded grounded follow-up set")

local retreat = resolve(
    "zombie_stamina_retreat",
    "event:social:retreat",
    {
        factRefs = { "event:social:retreat" },
        semanticEventFacts = fact("event:social:retreat", {
            summary = "the group retreated to recover stamina",
        }),
    }
)
T.equal(retreat.realizationID, "semantic.combat.reaction.retreat",
    "stamina retreat has a dedicated semantic realization")

local leader = resolve(
    "witnessed_leader_death",
    "event:social:leader",
    {
        leaderGrief = "devoted",
        factRefs = {
            "event:social:leader",
            "event:social:leader:deceased",
            "event:social:leader:next",
        },
        semanticEventFacts = fact("event:social:leader", {
            summary = "the faction leader died",
            deceasedName = "Mara",
            nextAction = "follow Rook",
        }),
    }
)
T.equal(leader.realizationID, "semantic.leader_loss.devoted",
    "leader loss uses the semantic grief realization")
T.equal(#leader.offerIDs, 3,
    "leader loss exposes its bounded grounded follow-up set")

local stale = resolve(
    "follower_abandoned_hostile_npc",
    "event:social:stale",
    {
        factRefs = { "event:social:stale" },
        semanticEventFacts = {
            ["event:social:other"] = {
                eventRef = "event:social:other",
                authoritative = true,
                disclosure = "player",
                pursuer = "wrong event",
            },
        },
    }
)
T.equal(#stale.offerIDs, 0,
    "stale event facts do not expose unsupported follow-ups")

T.finish("pnc_unified_authority_social_events_smoke")
