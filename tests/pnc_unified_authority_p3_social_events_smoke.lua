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
    "P3 semantic selection does not require first-party Flavor definitions")

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
        npcID = "npc-p3",
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
    salt = "p3-farewell",
})
T.truthy(farewell and farewell.fallback,
    "farewell selects through the semantic flow without legacy prose")

local safety = resolve(
    "conversation_safety",
    "event:p3:safety",
    {
        semanticEventFacts = fact("event:p3:safety", {
            summary = "danger is close",
            location = "the east road",
        }),
        factRefs = { "event:p3:safety" },
    }
)
T.equal(safety.realizationID, "semantic.conversation.safety.danger",
    "safety selects the semantic danger variant")

local playerSpoke = resolve("player_spoke", "event:p3:player", {
    socialRole = "colonist",
})
T.equal(playerSpoke.realizationFamily, "semantic.social.reaction",
    "player-spoke acknowledgement uses the semantic social pool")

local witness = resolve(
    "witnessed_player_kill",
    "event:p3:witness",
    {
        factRefs = { "event:p3:witness" },
        semanticEventFacts = fact("event:p3:witness", {
            summary = "the player killed a zombie",
            happened = "the player killed a zombie",
        }),
    }
)
T.truthy(witness.offerIDs and #witness.offerIDs == 1,
    "witnessed kill exposes only the grounded event follow-up")

local abandoned = resolve(
    "follower_abandoned_hostile_npc",
    "event:p3:abandonment",
    {
        factRefs = { "event:p3:abandonment" },
        semanticEventFacts = fact("event:p3:abandonment", {
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
    "event:p3:horde",
    {
        factRefs = {
            "event:p3:horde",
            "event:p3:horde:location",
            "event:p3:horde:quantity",
        },
        semanticEventFacts = fact("event:p3:horde", {
            summary = "a zombie horde was detected",
            location = "the north road",
            countBand = "several",
        }),
    }
)
T.equal(horde.realizationID, "semantic.combat.reaction.threat",
    "horde uses the semantic combat threat realization")
T.equal(#horde.offerIDs, 3,
    "horde exposes its bounded grounded follow-up set")

local retreat = resolve(
    "zombie_stamina_retreat",
    "event:p3:retreat",
    {
        factRefs = { "event:p3:retreat" },
        semanticEventFacts = fact("event:p3:retreat", {
            summary = "the group retreated to recover stamina",
        }),
    }
)
T.equal(retreat.realizationID, "semantic.combat.reaction.retreat",
    "stamina retreat has a dedicated semantic realization")

local leader = resolve(
    "witnessed_leader_death",
    "event:p3:leader",
    {
        leaderGrief = "devoted",
        factRefs = {
            "event:p3:leader",
            "event:p3:leader:deceased",
            "event:p3:leader:next",
        },
        semanticEventFacts = fact("event:p3:leader", {
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
    "event:p3:stale",
    {
        factRefs = { "event:p3:stale" },
        semanticEventFacts = {
            ["event:p3:other"] = {
                eventRef = "event:p3:other",
                authoritative = true,
                disclosure = "player",
                pursuer = "wrong event",
            },
        },
    }
)
T.equal(#stale.offerIDs, 0,
    "stale event facts do not expose unsupported follow-ups")

T.finish("pnc_unified_authority_p3_social_events_smoke")
