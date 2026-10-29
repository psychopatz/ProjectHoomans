local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
local Intent = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticCombatEncounterIntent.lua"
)

local notifications = {}
Intent.SetNotifier(function(record, state, reason)
    notifications[#notifications + 1] = {
        npcID = record.id,
        active = state.active,
        intent = state.intent,
        promptEventRef = state.promptEventRef,
        lastPromptEventRef = state.lastPromptEventRef,
        reason = reason,
    }
end)

local record = {
    id = "npc-a",
    ownerOnlineID = 42,
    alive = true,
    activeJob = "FollowOwner",
    runtime = {},
}
local eventRef = "social:zombie_horde_encounter:npc-a:1000:1"
local state = Intent.OnHordeTransition(record, "started", eventRef, 1000)
T.truthy(state and state.active, "encounter starts")
T.equal(#notifications, 0,
    "initial prompt packet remains the start-state presentation authority")

local ok = Intent.Resolve(record, "engage", eventRef, "owner_combat", 1100)
T.truthy(ok, "implicit owner combat resolves encounter intent")
T.equal(#notifications, 1, "intent resolution emits one compact state change")
T.equal(notifications[1].intent, "engage",
    "state change carries authoritative resolved intent")
T.equal(notifications[1].promptEventRef, eventRef,
    "resolution state change retains prompt event identity")
T.equal(notifications[1].reason, "intent_resolved",
    "resolution notification has stable reason")

Intent.OnHordeTransition(record, "cleared", eventRef, 1200)
T.equal(#notifications, 2, "episode clear emits one compact state change")
T.falsy(notifications[2].active, "clear state is inactive")
T.equal(notifications[2].lastPromptEventRef, eventRef,
    "clear notification preserves the prompt identity for client invalidation")
T.equal(notifications[2].reason, "team_cleared",
    "clear notification has stable reason")

Intent.ResetRuntime()
local secondRef = "social:zombie_horde_encounter:npc-a:2000:2"
Intent.OnHordeTransition(record, "started", secondRef, 2000)
Intent.Resolve(record, "hold", secondRef, "semantic", 2100)
T.equal(#notifications, 3,
    "runtime reset clears teams without silently removing notifier wiring")
T.equal(notifications[3].intent, "hold",
    "notifier remains configuration rather than persisted encounter state")

T.finish("pnc_semantic_combat_encounter_state_sync_smoke")
