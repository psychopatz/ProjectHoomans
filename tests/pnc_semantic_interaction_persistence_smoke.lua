local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local modData = {}
ModData = {
    get = function(key) return modData[key] end,
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
}

local Lifecycle = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticInteractionLifecycle.lua"
)
local Persistence = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Conversation/PNC_InteractionLifecyclePersistence.lua"
)
Persistence.Load(true)

local transient = Persistence.RecordNPCSpeech({
    npcID = "npc-transient",
    targetID = "player-one",
    playerUUID = "player-one",
    act = "REACT",
    topic = "combat",
    beatID = "beat:kill:transient",
    responsePlanID = "semantic.combat.kill.witness.practical",
    eventType = "zombie_kill_witnessed",
    eventRef = "combat:kill:transient",
    factRefs = { "combat:kill:transient" },
    offerIDs = { "semantic.followup.event.happened" },
    worldHour = 99,
    meaningful = false,
    transient = true,
    ttlHours = 15 / 3600,
})
T.truthy(transient and transient.accepted and not transient.persisted,
    "transient NPC speech remains live without persistence")
T.falsy(Persistence.Dirty,
    "transient NPC speech does not dirty ModData")
local transientSaved, transientSaveReason = Persistence.Save(false)
T.falsy(transientSaved,
    "transient-only lifecycle has nothing to save")
T.equal(transientSaveReason, "not_dirty",
    "transient-only save remains clean")
T.falsy(modData[Persistence.MODDATA_KEY],
    "transient-only lifecycle creates no ModData payload")
T.truthy(Persistence.Project("player-one", "npc-transient").thread,
    "transient lifecycle remains projectable for follow-up")
T.equal(
    Persistence.Close("player-one", "npc-transient", {
        worldHour = 99.001,
    }).reason,
    "transient_closed",
    "closing transient lifecycle does not promote it"
)

local envelope = Lifecycle.Envelope.TypedText({
    speechAct = "REQUEST",
    topic = "water",
}, {
    actorID = "player-one",
    targetID = "npc-mara",
    playerUUID = "player-one",
    worldHour = 100,
})
local applied = Persistence.Apply(envelope, {
    meaningful = true,
    beatID = "beat:water",
    worldHour = 100,
})
T.truthy(applied and applied.persisted,
    "server lifecycle persistence accepts meaningful state")
T.truthy(Persistence.Dirty, "meaningful lifecycle state marks ModData dirty")

local saved = Persistence.Save(false)
T.truthy(saved, "lifecycle persistence writes its ModData root")
T.equal(modData[Persistence.MODDATA_KEY].schema,
    Lifecycle.SCHEMA,
    "saved lifecycle root carries the lifecycle schema")

Persistence.Loaded = false
Persistence.Load(true)
local projection = Persistence.Project("player-one", "npc-mara")
T.truthy(projection.thread,
    "server lifecycle rehydrates a meaningful pair capsule")
T.equal(projection.thread.activeBeat.id, "beat:water",
    "rehydration preserves semantic beat provenance")

local closed = Persistence.Close("player-one", "npc-mara", {
    worldHour = 101,
})
T.equal(closed.reason, "suspended",
    "closing a meaningful pair suspends its semantic capsule")
Persistence.Save(false)
Persistence.Loaded = false
Persistence.Load(true)
projection = Persistence.Project("player-one", "npc-mara")
T.equal(projection.thread.status, "SUSPENDED",
    "save-backed rehydration preserves suspension status")

local resumed = Persistence.Resume("player-one", "npc-mara", {
    worldHour = 120,
})
T.equal(resumed.reason, "resumed",
    "server persistence resumes a non-expired semantic capsule")
Persistence.Save(false)
Persistence.Loaded = false
Persistence.Load(true)
projection = Persistence.Project("player-one", "npc-mara")
T.equal(projection.thread.status, "ACTIVE",
    "resume status is written to the authoritative pair capsule")

return T.finish("pnc_semantic_interaction_persistence_smoke")
