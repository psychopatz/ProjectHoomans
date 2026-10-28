local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Lifecycle = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionLifecycle.lua"
)
local Envelope = Lifecycle.Envelope

local function countKeys(value)
    local count = 0
    for _ in pairs(value or {}) do count = count + 1 end
    return count
end

local function transientSpeech(store, suffix)
    suffix = suffix or "one"
    return Lifecycle.RecordNPCSpeech(store, {
        npcID = "npc:mara",
        targetID = "player:one",
        playerUUID = "player-one",
        act = "REACT",
        topic = "combat",
        beatID = "beat:kill:" .. suffix,
        responsePlanID = "semantic.combat.kill.witness.supportive",
        eventType = "zombie_kill_witnessed",
        eventRef = "combat:kill:" .. suffix,
        flowID = "social:zombie_kill_witnessed",
        realizationID = "semantic.combat.reaction.kill_witness_supportive_01",
        offerIDs = {
            "semantic.followup.event.happened",
            "semantic.followup.event.quantity",
            "semantic.followup.event.health",
            "semantic.followup.event.next",
        },
        factRefs = { "combat:kill:" .. suffix },
        worldHour = 100,
        meaningful = false,
        transient = true,
        ttlHours = 15 / 3600,
    })
end

local store = Lifecycle.New({ worldHour = 100 })
local transient = transientSpeech(store, "one")
T.truthy(transient and transient.accepted,
    "transient NPC speech is accepted")
T.falsy(transient.persisted,
    "transient NPC speech is not persisted")
T.equal(transient.reason, "transient_state",
    "transient reason is explicit")

local projected = Lifecycle.Project(store, "player-one", "npc:mara")
T.truthy(projected.thread and projected.thread.activeBeat,
    "transient beat remains projectable for immediate follow-up")
T.equal(projected.thread.activeBeat.eventRef, "combat:kill:one",
    "transient projection retains event reference")
T.equal(#(projected.thread.activeBeat.offerIDs or {}), 4,
    "transient projection retains follow-up offers")

local exported = Lifecycle.Export(store)
T.equal(countKeys(exported.pairs), 0,
    "transient kill speech exports no pair capsule")
T.equal(countKeys(exported.sharedEvents), 0,
    "transient kill speech exports no shared event capsule")
T.equal(Lifecycle.Metrics(store).applied, 0,
    "transient kill speech does not increment exported applied metrics")

local closed = Lifecycle.Close(
    store, "player-one", "npc:mara", { worldHour = 100.001 }
)
T.equal(closed.reason, "transient_closed",
    "closing transient speech never promotes it")
exported = Lifecycle.Export(store)
T.equal(countKeys(exported.pairs), 0,
    "closed transient speech remains absent from persistence")

local promoteStore = Lifecycle.New({ worldHour = 100 })
transientSpeech(promoteStore, "two")
local followUp = Lifecycle.Apply(
    promoteStore,
    Envelope.TypedText({
        speechAct = "QUESTION",
        topic = "combat",
    }, {
        actorID = "player:one",
        targetID = "npc:mara",
        playerUUID = "player-one",
        topic = "combat",
        worldHour = 100.001,
    }),
    {
        meaningful = true,
        worldHour = 100.001,
    }
)
T.truthy(followUp and followUp.persisted,
    "real player follow-up may promote transient context")
local promoted = Lifecycle.Export(promoteStore)
T.equal(countKeys(promoted.pairs), 1,
    "only the real follow-up creates a durable pair capsule")
T.equal(countKeys(promoted.sharedEvents), 1,
    "promoted event reference is registered only after follow-up")
T.truthy(promoted.sharedEvents["combat:kill:two"],
    "promoted event identity remains grounded")

local expiryStore = Lifecycle.New({ worldHour = 100 })
transientSpeech(expiryStore, "three")
expiryStore.worldHour = 101
local maintenance = Lifecycle.Maintenance(expiryStore, 1)
T.equal(maintenance.expired, 1,
    "bounded maintenance expires transient state")
T.falsy(Lifecycle.Project(expiryStore, "player-one", "npc:mara").thread,
    "expired transient beat is gone")

T.finish("pnc_semantic_interaction_lifecycle_transient_smoke")
