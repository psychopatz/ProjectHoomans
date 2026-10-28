local T = require "tests/support/test"
T.addPackagePaths()
PNC = { Conversation = { Memory = { Events = { Internal = {
    CurrentWorldDay = function() return 10 end,
} } } } }
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local snapshot = { observedWorldDay = 10, observedWorldAgeHours = 48, rows = {} }
for _, tier in ipairs({ "TODAY", "DURABLE" }) do
    snapshot.rows[#snapshot.rows+1] = { sourceRef = tier .. ":fact", providerID = "owning.domain",
        sourceTier = tier, actorID = "a", targetID = "b", relations = { opens = { "repair" } },
        confidence = 0.9, retentionSalience = 150 }
end
local context = { npcID = "b", relationship = { semanticEvidence = snapshot },
    worldContext = { worldAgeHours = 48.5 } }
local result = Providers.QueryEvidence(context, { actorID = "a", targetID = "b" })
T.equal(#result.rows, 2, "MP clients consume bounded server tier projections")
T.equal(result.rows[1].ageHours, 0.5, "remote age advances ephemerally")
T.equal(#Providers.QueryEvidence(context, { actorID = "other" }).rows, 0, "other actor excluded")
snapshot.observedWorldDay = 9
T.equal(#Providers.QueryEvidence(context, {}).rows, 1, "previous-day TODAY snapshot excluded")
context.worldContext.worldAgeHours = 50
T.equal(#Providers.QueryEvidence(context, {}).rows, 0, "stale projections fail closed")
T.finish("pnc_semantic_evidence_remote_smoke")
