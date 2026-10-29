local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {
    Semantics = {},
    Const = {
        ORDER_FOLLOW = "follow",
    },
}

local Intent = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCombatEncounterIntent.lua"
)

local first = {
    id = "npc-a",
    alive = true,
    ownerOnlineID = 7,
    ownerUsername = "owner",
    activeJob = "FollowOwner",
    attackType = "ranged",
    runtime = {},
}
local second = {
    id = "npc-b",
    alive = true,
    ownerOnlineID = 7,
    ownerUsername = "owner",
    activeJob = "FollowOwner",
    attackType = "melee",
    runtime = {},
}
local player = {
    getOnlineID = function() return 7 end,
    getUsername = function() return "owner" end,
}

local state, reason = Intent.OnHordeTransition(
    first, "started", "horde:one", 1000
)
T.equal(reason, "team_started", "first follower starts team encounter")
T.equal(state.intent, "undecided", "new encounter begins undecided")
T.equal(state.spokespersonID, "npc-a", "first eligible follower is spokesperson")
T.truthy(Intent.IsPromptSpeaker(first, "horde:one"),
    "spokesperson owns the active prompt")
T.falsy(Intent.IsPromptSpeaker(second, "horde:one"),
    "second follower is not a duplicate spokesperson")
T.truthy(Intent.MatchesOwner(first, player), "prompt can target actual owner")

local joined, joinReason = Intent.OnHordeTransition(
    second, "started", "horde:two", 1100
)
T.equal(joinReason, "member_joined", "second follower joins existing team episode")
T.equal(joined.spokespersonID, "npc-a", "spokesperson remains stable")
T.equal(Intent.Snapshot(first).memberCount, 2, "team state tracks bounded members")

local stale, staleReason = Intent.Resolve(
    first, "engage", "horde:stale", "semantic_command", 1200
)
T.falsy(stale, "stale prompt cannot change a newer encounter")
T.equal(staleReason, "encounter_prompt_stale", "stale prompt reason is explicit")

local accepted, resolved = Intent.Resolve(
    first, "avoid", "horde:one", "semantic_command", 1300
)
T.truthy(accepted, "valid owner prompt can resolve team intent")
T.equal(resolved, "avoid", "resolved intent is returned")
T.equal(Intent.IntentFor(first), "avoid", "spokesperson sees team intent")
T.equal(Intent.IntentFor(second), "avoid", "all followers share team intent")
T.equal(first.attackType, "ranged", "temporary intent never mutates attackType")
T.equal(second.attackType, "melee", "team intent never mutates peer attackType")

local _, memberClear = Intent.OnHordeTransition(
    first, "cleared", "horde:one", 2000
)
T.equal(memberClear, "member_cleared", "one clear keeps team episode active")
T.truthy(Intent.GetForRecord(second).active, "remaining follower keeps encounter alive")
local cleared, clearReason = Intent.OnHordeTransition(
    second, "cleared", "horde:two", 2100
)
T.equal(clearReason, "team_cleared", "last member clear ends team episode")
T.falsy(cleared.active, "team episode becomes inactive")
T.equal(cleared.intent, "undecided", "cleared encounter drops temporary intent")

Intent.ResetRuntime()
Intent.OnHordeTransition(first, "started", "horde:three", 3000)
local implicit, implicitReason = Intent.ObserveOwnerEngaged(first, true, 3100)
T.equal(implicit, "engage", "owner starting combat implicitly answers engage")
T.equal(implicitReason, "owner_combat", "implicit resolution source is explicit")
T.equal(Intent.IntentFor(first), "engage", "implicit engage updates team intent")

local hordeHandoff = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatHorde.lua"
)
local selfDefenseAt = string.find(
    hordeHandoff, "TryRespondToImmediateThreat(record, zombie)", 1, true
)
local intentGateAt = string.find(
    hordeHandoff, "local encounterIntent = EncounterIntent", 1, true
)
T.truthy(selfDefenseAt and intentGateAt and selfDefenseAt < intentGateAt,
    "immediate self-defense remains ahead of encounter-intent proactive gating")

T.finish("pnc_semantic_combat_encounter_intent_smoke")
