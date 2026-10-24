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

return T.finish("pnc_semantic_interaction_persistence_smoke")
