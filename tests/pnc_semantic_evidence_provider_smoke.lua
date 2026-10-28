local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Context = require "PNC/Semantics/PNC_SemanticInteractionContext"
for _, tier in ipairs({ "SESSION", "TODAY", "DURABLE" }) do
    local sourceTier = tier
    T.truthy(Providers.RegisterEvidenceAdapter({ id = "fixture." .. tier,
        sourceTier = tier, Query = function(_, query)
            T.equal(query.limit, 16, "adapter receives a bounded query")
            return {{ sourceRef = sourceTier .. ":1", actorID = "player:a",
                targetID = "npc:b", classes = { "test" },
                relations = { opens = { "fixture_relation" } },
                retentionSalience = 240, confidence = 0.7, effectiveStrength = 0.4,
                ageHours = 12, rawText = "must not escape", arbitrary = {} }}
        end }))
end
local projection = Providers.ProjectDialogue({ evidenceQuery = {
    relation = "fixture_relation", targetID = "npc:b" } })
T.equal(#projection.evidence.rows, 3, "all lifetimes share one schema")
for index, tier in ipairs({ "SESSION", "TODAY", "DURABLE" }) do
    local row = projection.evidence.rows[index]
    T.equal(row.sourceTier, tier, "deterministic tier order")
    T.equal(row.retentionSalience, 240, "retention is separate")
    T.equal(row.confidence, 0.7, "confidence is separate")
    T.equal(row.effectiveStrength, 0.4, "strength is separate")
    T.equal(row.ageHours, 12, "recency is separate")
    T.falsy(row.rawText, "no transcript copied")
    T.falsy(row.arbitrary, "no arbitrary domain tables copied")
end
T.equal(#Providers.QueryEvidence({}, { targetID = "npc:other" }).rows, 0,
    "different target excluded")
T.equal(#Providers.QueryEvidence({}, { relation = "other" }).rows, 0,
    "different relation excluded")
T.equal(#Providers.QueryEvidence({}, { limit = 1 }).rows, 1, "result limit")
T.equal(#Context.Project({}, nil, { interactionProjection = projection }).evidence.rows,
    3, "InteractionContext carries evidence")
T.truthy(Providers.RegisterEvidenceAdapter({ id = "fixture.failure", sourceTier = "DURABLE",
    Query = function() error("external adapter unavailable") end }))
T.equal(#Providers.QueryEvidence({}, {}).rows, 3, "failed provider contributes nothing")
T.falsy(Providers.NormalizeEvidence({ sourceRef = "bad", sourceTier = "OTHER" }),
    "invalid lifetime rejected")
T.finish("pnc_semantic_evidence_provider_smoke")
