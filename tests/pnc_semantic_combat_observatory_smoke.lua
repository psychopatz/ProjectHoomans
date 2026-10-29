local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

PNC = {
    Semantics = {},
    Const = { ORDER_FOLLOW = "follow" },
}
local Catalog = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Moment = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatMoment.lua"
)
local Arbiter = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatBanterArbiter.lua"
)
local Encounter = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatEncounterIntent.lua"
)
local Observatory = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatObservatory.lua"
)

local record = {
    id = "npc-a",
    alive = true,
    ownerOnlineID = 7,
    activeJob = "FollowOwner",
    runtime = {
        zombieHordeAwareness = {
            active = true,
            sequence = 2,
            lastPhase = "escalated",
            episodeID = "horde:two",
            lastBand = "horde",
            lastCount = 14,
            startedAt = 900,
            lastObservedAt = 1000,
        },
    },
}
Encounter.OnHordeTransition(record, "started", "horde:two", 900)

Arbiter.ResetRuntime()
local tactical = Moment.Build({
    kind = "tactical_prompt",
    eventType = "zombie_horde_encounter",
    actorKind = "npc",
    actorID = "npc-a",
    targetKind = "zombie_group",
    pressureBand = "horde",
    nearbyCount = 14,
    encounterID = "horde:two",
    encounterIntent = "undecided",
    presentationClass = "TACTICAL_PROMPT",
    occurredAt = 1000,
})
local allowed = Arbiter.Reserve({
    streamKey = "awareness:player:p1:horde_tactical_prompt",
    now = 1000,
    cooldownMs = 12000,
    maxSpeakers = 1,
    speakerID = "npc-a",
    audienceKey = "player:p1",
    family = "horde_tactical_prompt",
    familyCooldownMs = 12000,
    priority = tactical.priority,
    moment = tactical,
})
T.truthy(allowed, "tactical prompt is admitted by production arbiter")

local offerRows = Catalog.OffersForSelection(
    "semantic.combat.horde.prompt",
    "semantic.combat.horde.prompt.default"
)
local offerIDs = {}
for _, offer in ipairs(offerRows or {}) do
    offerIDs[#offerIDs + 1] = offer.id
end
Arbiter.RecordPresentation({
    accepted = true,
    reason = "presentation_sent",
    at = 1001,
    speakerID = "npc-a",
    audienceKey = "player:p1",
    family = "horde_tactical_prompt",
    moment = tactical,
    eventRef = "horde:two",
    responsePlanID = "semantic.combat.horde.prompt",
    realizationID = "semantic.combat.horde.prompt.default",
    presentationClass = "TACTICAL_PROMPT",
    offerIDs = offerIDs,
})

local tacticalView = Observatory.Inspect(record, {
    eventRef = "horde:two",
    limit = 6,
})
T.equal(tacticalView.schema, "semantic.combat.observatory.v1",
    "combat observatory exposes stable bounded schema")
T.equal(tacticalView.hordeEpisode.phase, "escalated",
    "current horde transition comes from runtime episode state")
T.equal(tacticalView.hordeEpisode.nearbyCount, 14,
    "horde episode exposes bounded observed count")
T.equal(tacticalView.encounterIntent.intent, "undecided",
    "current tactical team intent comes from production encounter owner")
T.equal(tacticalView.combatMoment.kind, "tactical_prompt",
    "combat moment is recovered from arbiter decision evidence")
T.equal(tacticalView.presentation.class, "TACTICAL_PROMPT",
    "selected presentation class is explicit")
T.equal(tacticalView.presentation.offerCount, 3,
    "response-plan offers are bounded and inspectable")
local actions = {}
for _, offer in ipairs(tacticalView.presentation.offers) do
    actions[offer.action] = true
end
T.truthy(actions.COMBAT_ENGAGE and actions.COMBAT_AVOID
    and actions.COMBAT_HOLD,
    "tactical offer inspection exposes the three executable actions")
T.equal(tacticalView.explanation.outcome, "asked",
    "successful tactical presentation is explained as a question")
T.equal(tacticalView.explanation.reason, "presentation_sent",
    "successful tactical explanation retains terminal reason")
T.truthy(#tacticalView.arbiter.decisions <= 6,
    "combat decision evidence respects requested bound")

Arbiter.ResetRuntime()
local urgent = Moment.Build({
    kind = "tactical_prompt",
    eventType = "zombie_horde_encounter",
    actorKind = "npc",
    actorID = "npc-a",
    targetKind = "zombie_group",
    presentationClass = "TACTICAL_PROMPT",
    occurredAt = 2000,
})
T.truthy(Arbiter.Reserve({
    streamKey = "awareness:player:p1:horde",
    now = 2000,
    cooldownMs = 12000,
    maxSpeakers = 1,
    speakerID = "npc-a",
    audienceKey = "player:p1",
    family = "horde_tactical_prompt",
    familyCooldownMs = 12000,
    priorityHoldMs = 5000,
    priority = urgent.priority,
    moment = urgent,
}), "urgent team lane is occupied")

local kill = Moment.Build({
    kind = "kill",
    eventType = "zombie_kill_witnessed",
    actorKind = "player",
    actorID = "player:p1",
    targetKind = "zombie",
    outcome = "killed",
    attackType = "ranged",
    attackKind = "firearm",
    weaponDisplayName = "M9 Pistol",
    weaponFamily = "firearm",
    weaponSkill = "Aiming",
    weaponSkillLevel = 8,
    weaponSkillBand = "high",
    weaponNameEligible = true,
    hitZone = "head_neck",
    woundType = "gunshot",
    presentationClass = "BARK",
    occurredAt = 2100,
})
local gate = T.truthy(Arbiter.Begin({
    streamKey = "player_kill:player:p1",
    now = 2100,
    cooldownMs = 5000,
    maxSpeakers = 2,
    priority = kill.priority,
    moment = kill,
}), "ordinary kill stream opens")
local canSpeak, silenceReason = Arbiter.Consider(gate, {
    now = 2100,
    speakerID = "npc-b",
    audienceKey = "player:p1",
    family = "combat_kill_witness",
    priority = kill.priority,
    moment = kill,
})
T.falsy(canSpeak, "ordinary line is silenced under urgent team speech")
T.equal(silenceReason, "higher_priority_active",
    "production arbiter returns the silence reason")

local silentView = Observatory.Inspect({ id = "npc-b", runtime = {} }, {
    limit = 4,
})
T.equal(silentView.explanation.outcome, "silent",
    "rejected candidate is explained as silence")
T.equal(silentView.explanation.reason, "higher_priority_active",
    "silence explanation comes from arbiter rejection")
T.equal(silentView.weapon.family, "firearm",
    "weapon-family predicate comes from real combat moment")
T.equal(silentView.weapon.skill, "Aiming",
    "weapon skill predicate remains grounded")
T.truthy(silentView.weapon.highSkill,
    "bounded skill-band predicate is exposed")
T.truthy(silentView.weapon.nameAvailable,
    "safe actual weapon display-name predicate is explicit")
T.truthy(silentView.weapon.headNeckResult,
    "hit-zone predicate remains grounded")
T.equal(silentView.presentation.offerCount, 0,
    "ordinary bark has no invented tactical offers")

T.finish("pnc_semantic_combat_observatory_smoke")
