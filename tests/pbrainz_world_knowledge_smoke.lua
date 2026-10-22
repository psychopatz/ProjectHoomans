local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
local Facts = require
    "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload_DialogueFacts"
local result = Facts.Build(
    { id = "npc:alice", name = "Alice" },
    {
        language = "EN",
        npcGossip = {
            source = "world_knowledge",
            statements = { "I heard there is heavy zombie pressure nearby." },
            factRefs = { "fact:pressure:1" },
            candidates = {
                {
                    factID = "fact:pressure:1",
                    provenance = "told",
                    confidence = 0.85,
                },
            },
        },
    },
    nil,
    nil
)
T.truthy(result, "PBrainZ fact projection")
T.equal(#result, 1, "same authorized fact count")
T.equal(result[1].factID, "fact:pressure:1", "same fact ID")
T.equal(result[1].provenance, "told", "same provenance")
T.equal(result[1].source, "world_knowledge", "same source")
T.equal(result[1].content,
    "I heard there is heavy zombie pressure nearby.",
    "same realized statement")

print("pbrainz_world_knowledge_smoke: PASS")
