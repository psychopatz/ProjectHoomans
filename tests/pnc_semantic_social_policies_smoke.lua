local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = { Semantics = {} }

local Choice = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialChoicePolicy.lua"
)
local Turn = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialTurnPolicy.lua"
)
local Budget = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialBudget.lua"
)

local frontier = {
    { id = "generated.challenge", strategy = "CHALLENGE", stance = "NEGATIVE",
      eligibility = { allowed = true, status = "allowed" } },
    { id = "generated.deescalate", strategy = "DEESCALATE", stance = "POSITIVE",
      eligibility = { allowed = true, status = "allowed" } },
    { id = "generated.acknowledge", strategy = "ACKNOWLEDGE", stance = "NEUTRAL",
      eligibility = { allowed = true, status = "allowed" } },
    { id = "generated.ask_followup", strategy = "ASK_FOLLOWUP", stance = "NEUTRAL",
      eligibility = { allowed = true, status = "allowed" } },
}

local aggressive = Choice.Select(frontier, {
    motive = "DISPUTE",
    relevance = 0.9,
    responderProjection = {
        actor = {
            capabilities = { speech = true },
            disposition = {
                aggression = 0.95, confidence = 0.9, empathy = 0.1,
                forgiveness = 0.1, sociability = 0.4,
            },
            traits = { Brave = true },
        },
        relationship = { approval = -0.7, respect = -0.4 },
    },
})
T.equal(aggressive.selected.strategy, "CHALLENGE",
    "aggressive hostile actor prefers challenge")
T.truthy(aggressive.selectedScore >= Choice.DEFAULT_SILENCE_THRESHOLD,
    "aggressive choice clears silence threshold")

local compassionate = Choice.Select(frontier, {
    motive = "REPAIR",
    relevance = 0.9,
    responderProjection = {
        actor = {
            capabilities = { speech = true },
            disposition = {
                aggression = 0.1, confidence = 0.4, empathy = 0.95,
                forgiveness = 0.9, sociability = 0.7,
            },
            traits = { Kind = true },
        },
        relationship = { approval = 0.7, respect = 0.5 },
    },
})
T.equal(compassionate.selected.strategy, "DEESCALATE",
    "compassionate friendly actor prefers repair")

local quiet = Choice.Select(frontier, {
    motive = "SOCIALIZE",
    relevance = 0.05,
    responderProjection = {
        actor = { capabilities = { speech = true } },
    },
})
T.equal(quiet.selected, nil, "low-value social opportunity selects silence")
T.equal(quiet.reason, "relevance_below_minimum",
    "silence reason is explicit")

local mute = Choice.Select(frontier, {
    motive = "DISPUTE",
    relevance = 1,
    responderProjection = {
        actor = { capabilities = { speech = false } },
    },
})
T.equal(mute.selected, nil, "actor without speech has no affordance")
T.equal(mute.reason, "no_eligible_affordance",
    "speech-capability failure remains explainable")

local choices = {
    ["npc-b"] = {
        selected = frontier[3],
        selectedScore = 0.7,
        targetID = "npc-a",
    },
    ["npc-c"] = {
        selected = frontier[1],
        selectedScore = 0.99,
        targetID = "npc-a",
    },
}
local recipientFirst = Turn.Select({
    participants = {
        { id = "npc-a", kind = "npc" },
        { id = "npc-b", kind = "npc" },
        { id = "npc-c", kind = "npc" },
    },
    currentSpeakerID = "npc-a",
    currentRecipientID = "npc-b",
    choicesByActor = choices,
    interjections = {
        ["npc-c"] = { allowed = true, priority = 0.8, motive = "DISPUTE" },
    },
})
T.equal(recipientFirst.mode, "emit", "one NPC speaker is selected")
T.equal(recipientFirst.actorID, "npc-b",
    "current recipient wins ordinary reply priority")
T.equal(recipientFirst.targetID, "npc-a",
    "reply targets previous speaker")

local interject = Turn.Select({
    participants = {
        { id = "npc-a", kind = "npc" },
        { id = "npc-b", kind = "npc" },
        { id = "npc-c", kind = "npc" },
    },
    currentSpeakerID = "npc-a",
    currentRecipientID = "npc-b",
    choicesByActor = {
        ["npc-b"] = { selected = nil, reason = "silence_threshold" },
        ["npc-c"] = choices["npc-c"],
    },
    interjections = {
        ["npc-c"] = { allowed = true, priority = 0.8, motive = "DISPUTE" },
    },
})
T.equal(interject.actorID, "npc-c",
    "explicit interjection can speak when recipient stays silent")
T.equal(interject.reason, "explicit_interjection",
    "interjection provenance is explicit")

local noChorus = Turn.Select({
    participants = {
        { id = "npc-a", kind = "npc" },
        { id = "npc-b", kind = "npc" },
        { id = "npc-c", kind = "npc" },
        { id = "npc-d", kind = "npc" },
    },
    currentSpeakerID = "npc-a",
    currentRecipientID = "npc-b",
    choicesByActor = {
        ["npc-b"] = { selected = nil, reason = "silence_threshold" },
        ["npc-c"] = choices["npc-c"],
        ["npc-d"] = {
            selected = frontier[4], selectedScore = 0.98, targetID = "npc-a"
        },
    },
    interjections = {
        ["npc-c"] = { allowed = true, priority = 0.7 },
        ["npc-d"] = { allowed = true, priority = 0.6 },
    },
})
T.equal(noChorus.mode, "emit", "four-person arbitration still selects one turn")
T.truthy(noChorus.actorID == "npc-c" or noChorus.actorID == "npc-d",
    "one bounded interjector wins")
local selectedCount = 0
for _, row in ipairs(noChorus.rows) do
    if row.eligible then selectedCount = selectedCount + 1 end
end
T.equal(selectedCount, 2, "multiple candidates exist without chorus emission")

local playerWait = Turn.Select({
    participants = {
        { id = "npc-a", kind = "npc" },
        { id = "player-one", kind = "player", isPlayer = true },
    },
    currentSpeakerID = "npc-a",
    currentRecipientID = "player-one",
    choicesByActor = {},
})
T.equal(playerWait.mode, "wait_player",
    "addressed player is never auto-answered by NPC policy")
T.equal(playerWait.actorID, "player-one",
    "wait targets the addressed player")

local now = 1000
local budget = Budget.New({ clock = function() return now end })
local spec = {
    actorID = "npc-a", targetID = "npc-b", topic = "NEWS",
    areaKey = "settlement-1", priority = 20,
}
local reserved, reason = budget:Reserve(spec)
T.truthy(reserved, reason or "first social opening is allowed")
local allowed, blocked = budget:Check(spec)
T.falsy(allowed, "immediate duplicate social opening is suppressed")
T.equal(blocked, "social_actor_cooldown",
    "actor cooldown is the first bounded rejection")

now = now + Budget.DEFAULT_TOPIC_COOLDOWN_MS + 1
allowed = budget:Check(spec)
T.truthy(allowed, "cooldowns expire without persistence")

local areaNow = 50000
local areaBudget = Budget.New({ clock = function() return areaNow end })
for index = 1, Budget.DEFAULT_AREA_OPENINGS do
    local ok = areaBudget:Reserve({
        actorID = "npc-" .. tostring(index),
        targetID = "npc-target-" .. tostring(index),
        topic = "TOPIC_" .. tostring(index),
        areaKey = "camp",
        priority = 10,
        actorCooldownMs = 0,
        pairCooldownMs = 0,
        topicCooldownMs = 0,
    })
    T.truthy(ok, "bounded area opening " .. tostring(index) .. " reserves")
end
local areaAllowed, areaReason = areaBudget:Check({
    actorID = "npc-extra",
    targetID = "npc-target-extra",
    topic = "NEW_TOPIC",
    areaKey = "camp",
    priority = 10,
})
T.falsy(areaAllowed, "area chatter budget suppresses fourth opening")
T.equal(areaReason, "social_area_budget",
    "area budget has explicit rejection")

local urgent, urgentReason = areaBudget:Reserve({
    actorID = "npc-urgent",
    targetID = "npc-target-urgent",
    topic = "DANGER",
    areaKey = "camp",
    priority = Budget.URGENT_PRIORITY,
})
T.truthy(urgent, urgentReason or "urgent semantic event bypasses ambient budget")
T.equal(areaBudget:Snapshot().metrics.urgentBypass, 1,
    "urgent bypass is observable")

T.finish("pnc_semantic_social_policies_smoke")
