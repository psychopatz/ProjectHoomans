local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Lifecycle = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticInteractionLifecycle.lua"
)
local Envelope = Lifecycle.Envelope

local context = {
    actorID = "player:one",
    targetID = "npc:mara",
    playerUUID = "player-one",
    topic = "camp",
    worldHour = 100,
}
local typed = Envelope.TypedText(
    { speechAct = "greeting", topic = "camp" }, context
)
local button = Envelope.SemanticChoice({
    semantic = { act = "GREET", topic = "camp" },
}, context)
local emote = Envelope.Emote({ id = "wavehi" }, context)

T.truthy(typed, "typed input creates an envelope")
T.truthy(button, "semantic choice creates an envelope")
T.truthy(emote, "emote creates an envelope")
T.equal(typed.source, "typed_text", "typed source is preserved")
T.equal(button.source, "semantic_choice", "button source is preserved")
T.equal(emote.source, "emote", "emote source is preserved")
T.equal(typed.act, "GREET", "typed greeting is canonical")
T.truthy(Envelope.Equivalent(typed, button),
    "typed and button meaning converges")
T.truthy(Envelope.Equivalent(button, emote),
    "button and emote meaning converges")

local bounded = Envelope.Build({
    source = "world_event",
    event = { id = "event:one", type = "combat", factRefs = {
        "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9",
    } },
    actorID = "npc:mara",
    targetID = "player-one",
})
T.equal(#bounded.factRefs, Lifecycle.LIMITS.factRefs,
    "event references are bounded")
T.equal(bounded.act, "REACT", "known events bypass NLU")
T.falsy(Envelope.Build({ source = "typed_text" }),
    "malformed envelope without an act is rejected")

local nonAuthoritative = Lifecycle.New({ authoritative = false })
local rejected, rejectedReason = Lifecycle.Apply(
    nonAuthoritative,
    typed,
    { meaningful = true }
)
T.falsy(rejected, "non-authoritative stores cannot mutate lifecycle state")
T.equal(rejectedReason, "lifecycle_not_authoritative",
    "non-authoritative mutation is rejected explicitly")
local rejectedEvent, rejectedEventReason = Lifecycle.RegisterSharedEvent(
    nonAuthoritative,
    { id = "world:client-only:1", type = "test" }
)
T.falsy(rejectedEvent, "non-authoritative stores cannot register events")
T.equal(rejectedEventReason, "lifecycle_not_authoritative",
    "event registration requires lifecycle authority")

local store = Lifecycle.New({ worldHour = 100 })
local npcSpeech = Lifecycle.RecordNPCSpeech(store, {
    npcID = "npc:mara",
    targetID = "player:one",
    playerUUID = "player-one",
    act = "REQUEST",
    topic = "water",
    beatID = "beat:water",
    responsePlanID = "plan:water",
    expectedReplies = { "yes", "no" },
    worldHour = 100,
})
T.truthy(npcSpeech and npcSpeech.persisted,
    "NPC speech creates durable semantic beat state")
T.truthy(npcSpeech.thread.activeBeat,
    "NPC speech retains active beat provenance")
T.falsy(npcSpeech.thread.activeBeat.renderedText,
    "NPC provenance does not persist rendered prose")

local interrupted = Lifecycle.Apply(store, Envelope.TypedText({
    speechAct = "REACT", topic = "danger",
}, context), {
    beatID = "beat:danger",
    meaningful = true,
})
T.equal(#interrupted.thread.topicStack, 1,
    "new topic suspends the previous beat")
T.equal(interrupted.thread.activeBeat.id, "beat:danger",
    "interruption installs the new active beat")
local resolvedDanger = Lifecycle.Apply(store, Envelope.TypedText({
    speechAct = "ACK", topic = "danger",
}, context), {
    resolveBeat = true,
    meaningful = true,
    worldHour = 101,
})
local resumedTopic = Lifecycle.Apply(store, Envelope.TypedText({
    speechAct = "ACK", topic = "water",
}, context), {
    resumeTopic = true,
    meaningful = true,
    worldHour = 101,
})
T.truthy(resolvedDanger, "interrupted topic can resolve")
T.equal(resumedTopic.thread.activeBeat.id, "beat:water",
    "resolved interruption resumes the suspended beat")

local closed = Lifecycle.Close(store, "player-one", "npc:mara", {
    worldHour = 102,
})
T.equal(closed.reason, "suspended", "UI close suspends meaningful context")
local resumed = Lifecycle.Resume(store, "player-one", "npc:mara", {
    worldHour = 120,
})
T.equal(resumed.thread.status, "ACTIVE", "suspended context rehydrates")

local sharedID = Lifecycle.RegisterSharedEvent(store, {
    id = "world:helicopter:1", type = "aircraft", occurredAt = 120,
})
local sharedAgain = Lifecycle.RegisterSharedEvent(store, {
    id = "world:helicopter:1", type = "aircraft", occurredAt = 120,
})
T.equal(sharedID, sharedAgain, "shared event payload is canonicalized once")

for index = 1, 200 do
    Lifecycle.Apply(store, Envelope.TypedText({
        speechAct = "ACK", topic = "danger",
    }, context), { meaningful = true, worldHour = 120 + index / 24 })
end
local metrics = Lifecycle.Metrics(store)
T.equal(metrics.maxRecentTurns, Lifecycle.LIMITS.turns,
    "long conversations retain only bounded recent turns")
T.equal(metrics.pairRecords, 1,
    "one meaningful player/NPC pair remains materialized")
T.truthy(metrics.pairCapsuleBytes < 12000,
    "compacted pair capsule remains bounded")

local otherPlayer = Lifecycle.New({ worldHour = 100 })
local trivial = Lifecycle.Apply(otherPlayer, Envelope.Emote({
    id = "wavehi",
}, {
    actorID = "player:two",
    targetID = "npc:mara",
    playerUUID = "player-two",
}), {})
T.falsy(trivial.persisted, "trivial interaction leaves no pair capsule")
T.equal(Lifecycle.Metrics(otherPlayer).pairRecords, 0,
    "absence remains the default for trivial interaction")

local private = Lifecycle.Project(store, "player-one", "npc:mara")
local unrelated = Lifecycle.Project(store, "player-two", "npc:mara")
T.truthy(private.thread, "owner receives the private thread projection")
T.falsy(unrelated.thread, "unrelated player receives no private context")
T.equal(metrics.dormantTickWork, 0,
    "dormant actors perform no lifecycle tick work")

return T.finish("pnc_semantic_interaction_lifecycle_smoke")
