local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/WorldKnowledge/PNC_WorldKnowledgeDebugModel.lua")
local snapshot = {
    actorID = "alice",
    facts = {
        { factID = "fact-1", kind = "faction.status",
            producer = "hoomans:faction", payload = { status = "destroyed" } },
    },
    actors = { { actorID = "alice", referenceCount = 1 } },
    actor = {
        actorID = "alice", known = true, references = {
            { factID = "fact-1", provenance = "told", confidence = 0.8,
                source = "conversation", acquisitionPath = "conversation" },
        },
    },
    context = {
        worldKnowledge = { candidates = {
            { factID = "fact-1", kind = "faction.status", producer = "hoomans:faction",
                provenance = "told", confidence = 0.8, score = 50 },
        } },
        npcGossip = { statements = { "I heard news." }, factRefs = { "fact-1" } },
    },
    explanation = {
        factID = "fact-1", provenance = "told", confidence = 0.8,
        acquisitionPath = "conversation", ranking = {},
    },
    trace = { { factID = "fact-1", fromActorID = "alice",
        toActorID = "bob", provenance = "told", reason = "opportunistic_share" } },
}

local actorItems = Model.ActorItems(snapshot, {
    { id = "runtime-alice", coreActorID = "alice" },
})
T.equal(actorItems[1].actorID, "alice", "actor model row")
T.equal(actorItems[1].referenceCount, 1, "snapshot references overlay roster")
T.equal(Model.Rows(snapshot, "facts")[1].factID, "fact-1",
    "fact model row")
T.equal(Model.Rows(snapshot, "knowledge")[1].reference.provenance, "told",
    "knowledge provenance model row")
T.equal(Model.Rows(snapshot, "context")[1].candidate.factID, "fact-1",
    "candidate model row")
T.equal(Model.Rows(snapshot, "why")[1].factID, "fact-1",
    "explanation model row")
T.equal(Model.Rows(snapshot, "trace")[1].trace.toActorID, "bob",
    "propagation trace model row")
local detailRows = Model.DetailRows(snapshot, Model.Rows(snapshot, "facts")[1], "facts")
local kindDetail
for _, detail in ipairs(detailRows) do
    if detail.label == "Kind" then kindDetail = detail.value end
end
T.equal(kindDetail, "faction.status", "fact detail projection")
T.finish("pnc_world_knowledge_debug_model_smoke")
