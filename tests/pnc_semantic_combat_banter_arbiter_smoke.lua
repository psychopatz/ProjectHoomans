local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

PNC = { Semantics = {} }
local Moment = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatMoment.lua"
)
local Arbiter = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatBanterArbiter.lua"
)

local ordinary = Moment.Build({
    kind = "kill",
    eventType = "zombie_kill_witnessed",
    actorKind = "player",
    actorID = "player:p1",
    targetKind = "zombie",
    outcome = "killed",
    pressureBand = "several",
    nearbyCount = 5,
    occurredAt = 1000,
})
T.equal(ordinary.schema, "semantic.combat.moment.v1",
    "combat moment has bounded explicit schema")
T.equal(ordinary.priority, 24, "ordinary kill has low chatter priority")
T.equal(ordinary.presentationClass, "BARK",
    "ordinary moment defaults to non-blocking bark")
T.falsy(ordinary.llmEligible, "combat moment is routine non-LLM context")
T.falsy(ordinary.memoryEligible, "combat moment is routine non-memory context")

local tactical = Moment.Build({
    kind = "tactical_prompt",
    eventType = "zombie_horde_encounter",
    actorKind = "npc",
    actorID = "npc-a",
    targetKind = "zombie_group",
    encounterID = "horde:one",
    presentationClass = "TACTICAL_PROMPT",
    occurredAt = 1000,
})
T.equal(tactical.priority, 100, "tactical prompt outranks ordinary banter")
T.equal(tactical.urgency, "critical", "tactical prompt is critical urgency")

Arbiter.ResetRuntime()
local tacticalAllowed = Arbiter.Reserve({
    streamKey = "awareness:player:p1:horde",
    now = 1000,
    cooldownMs = 12000,
    maxSpeakers = 1,
    speakerID = "npc-a",
    audienceKey = "player:p1",
    family = "horde_tactical_prompt",
    familyCooldownMs = 12000,
    priorityHoldMs = 5000,
    priority = tactical.priority,
    moment = tactical,
})
T.truthy(tacticalAllowed, "tactical prompt reserves the player chatter lane")

local killGate = T.truthy(Arbiter.Begin({
    streamKey = "player_kill:player:p1",
    now = 1100,
    cooldownMs = 5000,
    maxSpeakers = 2,
    priority = ordinary.priority,
    moment = ordinary,
}), "ordinary kill stream still coalesces before witness query")
local killAllowed, killReason = Arbiter.Consider(killGate, {
    now = 1100,
    speakerID = "npc-b",
    audienceKey = "player:p1",
    family = "combat_kill_witness",
    speakerCooldownMs = 5000,
    familyCooldownMs = 5000,
    priority = ordinary.priority,
    moment = ordinary,
})
T.falsy(killAllowed, "ordinary boast stays silent under active tactical prompt")
T.equal(killReason, "higher_priority_active",
    "silence has explainable higher-priority reason")

local laterGate = T.truthy(Arbiter.Begin({
    streamKey = "player_kill:player:p1",
    now = 7000,
    cooldownMs = 5000,
    maxSpeakers = 2,
    priority = ordinary.priority,
    moment = ordinary,
}), "kill stream opens after cooldown")
local laterAllowed = Arbiter.Consider(laterGate, {
    now = 7000,
    speakerID = "npc-b",
    audienceKey = "player:p1",
    family = "combat_kill_witness",
    speakerCooldownMs = 5000,
    familyCooldownMs = 5000,
    priority = ordinary.priority,
    moment = ordinary,
})
T.truthy(laterAllowed, "ordinary banter becomes eligible after urgent hold clears")

local budgetGate = T.truthy(Arbiter.Begin({
    streamKey = "budget:test",
    now = 13000,
    cooldownMs = 0,
    maxSpeakers = 2,
    priority = ordinary.priority,
    moment = ordinary,
}), "budget stream opens")
for _, speakerID in ipairs({ "npc-c", "npc-d" }) do
    local ok = Arbiter.Consider(budgetGate, {
        now = 13000,
        speakerID = speakerID,
        audienceKey = "player:p2",
        family = "combat_kill_witness",
        priority = ordinary.priority,
        moment = ordinary,
    })
    T.truthy(ok, "bounded speaker is accepted")
end
local third, thirdReason = Arbiter.Consider(budgetGate, {
    now = 13000,
    speakerID = "npc-e",
    audienceKey = "player:p2",
    family = "combat_kill_witness",
    priority = ordinary.priority,
    moment = ordinary,
})
T.falsy(third, "third simultaneous speaker is silenced")
T.equal(thirdReason, "team_budget", "fanout rejection is explainable")

local snapshot = Arbiter.Snapshot(12)
T.truthy(#snapshot.decisions > 0 and #snapshot.decisions <= 12,
    "arbiter exposes a bounded recent decision trace")
local foundPriority, foundBudget = false, false
for _, row in ipairs(snapshot.decisions) do
    if row.reason == "higher_priority_active" then foundPriority = true end
    if row.reason == "team_budget" then foundBudget = true end
end
T.truthy(foundPriority, "trace records priority silence")
T.truthy(foundBudget, "trace records fanout-budget silence")

T.finish("pnc_semantic_combat_banter_arbiter_smoke")
