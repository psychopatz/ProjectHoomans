local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Situation = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSituation.lua"
)

local projection = Situation.Build({
    relationshipState = "Acquaintance",
    relationship = { approval = 12, respect = 18, familiarity = 0.4 },
    conversationBlockContext = {
        npcPersonality = { socialStyle = "friendly" },
    },
    worldContext = {
        timeBand = "dusk",
        weather = { raining = true, foggy = false },
        environment = { indoors = false },
    },
    entry = {
        snapshot = {
            activeBehavior = "Fishing:WAITING",
            healthState = "injured",
            conditionStats = { stress = 0.20, boredom = 10, panic = 82 },
            needs = { hunger = 0.10, thirst = 0.82, fatigue = 0.20 },
        },
    },
    semanticDialogueState = {
        currentTopic = "weather",
        previousTopic = "greeting",
        pendingRequest = { action = "FETCH" },
    },
})

T.equal(projection.npc.activity.id, "fishing",
    "engine behavior is projected into a stable activity concept")
T.equal(projection.npc.activity.busy, true,
    "activity projection preserves whether the NPC is occupied")
T.equal(projection.npc.needs.highest, "thirst",
    "need projection identifies the most urgent need")
T.equal(projection.npc.needs.urgency, "severe",
    "need projection exposes a bounded urgency band")
T.equal(projection.npc.healthState, "injured",
    "health state is available to the local response policy")
T.equal(projection.npc.emotion.highest, "panic",
    "condition state identifies the strongest emotional pressure")
T.equal(projection.npc.emotion.urgency, "critical",
    "emotional pressure is reduced to a bounded urgency band")
T.equal(projection.social.relationshipState, "Acquaintance",
    "relationship identity remains in the social projection")
T.equal(projection.social.style, "friendly",
    "personality is reduced to a response-safe social style")
T.equal(projection.conversation.currentTopic, "weather",
    "conversation continuity is projected separately from world state")
T.equal(projection.world.raining, true,
    "world signals remain scalar and presentation-safe")

PNC.ActivityStatus = {
    Build = function()
        return { activityId = "job:Fishing", fallback = "Fishing" }
    end,
}
local canonical = Situation.Build({ npcRecord = { activeBehavior = "unknown" } })
T.equal(canonical.npc.activity.id, "fishing",
    "situation projection reuses the existing activity abstraction")
PNC.ActivityStatus = nil

local registered, rule = Situation.RegisterActivityRule({
    id = "custom_activity",
    label = "checking the radio",
    patterns = { "radio_check" },
    priority = 250,
    busy = true,
})
T.equal(registered, true, "domain activity rules are extensible")
T.equal(rule.id, "custom_activity", "registered activity returns its stable id")
local custom = Situation.Build({ activeBehavior = "radio_check" })
T.equal(custom.npc.activity.id, "custom_activity",
    "registered activity rules are used without parser changes")

local originalRule = {
    id = "bounded_activity",
    label = string.rep("x", 180),
    patterns = { " RADIO_CHECK ", "radio_check", "radio_check_2" },
    priority = 999999,
    busy = true,
}
local boundedRegistered, boundedRule = Situation.RegisterActivityRule(originalRule)
T.equal(boundedRegistered, true,
    "activity rule registration accepts and normalizes domain data")
T.equal(boundedRule.label, string.rep("x", 96),
    "activity labels are bounded before entering presentation context")
T.equal(boundedRule.priority, 1000,
    "activity priorities are bounded before rule selection")
T.equal(#boundedRule.patterns, 3,
    "activity patterns are retained as a deduplicated bounded list")
T.equal(originalRule.id, "bounded_activity",
    "activity registration does not mutate caller-owned rule data")

local invalidRegistered, invalidReason = Situation.RegisterActivityRule({
    id = "bad activity id",
    patterns = { "never" },
})
T.equal(invalidRegistered, false,
    "invalid activity identifiers are rejected safely")
T.equal(invalidReason, "invalid_activity_rule",
    "invalid activity rules expose a stable diagnostic")

T.finish("pnc_semantic_situation_smoke")
