local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local Resolver = require "PNC/Semantics/PNC_SemanticPragmaticResolver"
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Relations = require "PNC/Semantics/PNC_SemanticInteractionRelations"
local function stimulus(act)
    return { source = { actorID = "player:a" }, targets = { "npc:b" },
        semantic = { speechAct = act, intent = act } }
end
local function evidence(relation, kind, sequence, actor, target)
    return Providers.NormalizeEvidence({ sourceRef = "fixture:" .. tostring(sequence),
        actorID = actor or "player:a", targetID = target or "npc:b",
        sourceTier = "SESSION", relations = { [kind or "opens"] = { relation } },
        sequence = sequence or 1, ageHours = 0, confidence = 0.9,
        effectiveStrength = 1, retentionSalience = 200 }, "fixture")
end
T.equal(Resolver.ResolveEvidence(stimulus("APOLOGIZE"), {rows={}}).status, "unresolved",
    "no grievance does not ground repair")
for act, relation in pairs({ APOLOGIZE = "repair", THANK = "gratitude", ACCEPT = "response" }) do
    local reverse = Relations.Direction(relation) == "reverse"
    local result = Resolver.ResolveEvidence(stimulus(act), { rows = {
        evidence(relation, "opens", 1, reverse and "npc:b" or nil, reverse and "player:a" or nil) } })
    T.equal(result.status, "grounded", "shared relation algorithm grounds " .. act)
    T.equal(result.selected.relation, relation, "registered relation selected")
    T.equal(result.selected.retentionSalience, 200, "retention signal exposed separately")
    T.equal(result.selected.confidence, 0.9, "confidence signal exposed separately")
    T.truthy(result.selected.contextualRelevance > 0, "derived score exposed")
end
T.equal(Resolver.ResolveEvidence(stimulus("ACCEPT"), { rows = {
    evidence("response", "opens", 1, "npc:b", "player:a") } }).status,
    "grounded", "reply can address an offer in the reverse direction")
T.equal(Resolver.ResolveEvidence(stimulus("APOLOGIZE"), { rows = {
    evidence("repair", "opens", 1, "player:other", "npc:b") } }).status,
    "unresolved", "another actor's grievance excluded")
local rows = { evidence("repair", "opens", 1), evidence("repair", "addresses", 2) }
T.equal(Resolver.ResolveEvidence(stimulus("APOLOGIZE"), { rows = rows }).reason,
    "relation_already_addressed", "repair does not reopen old evidence")
rows[#rows+1] = evidence("repair", "opens", 3)
T.equal(Resolver.ResolveEvidence(stimulus("APOLOGIZE"), { rows = rows }).status,
    "grounded", "new evidence can reopen repair")
local weak = evidence("repair", "opens", 1)
weak.effectiveStrength = 0
T.falsy(Resolver.ResolveEvidence(stimulus("APOLOGIZE"), { rows = { weak } }).admitted,
    "expired evidence cannot ground an act")
T.truthy(Relations.RegisterAct("FIXTURE_MULTI", { relations = { addresses = { "r1", "r2" } } }))
T.equal(Resolver.ResolveEvidence(stimulus("FIXTURE_MULTI"), { rows = {
    evidence("r1", "opens", 1), evidence("r2", "opens", 1) } }).status,
    "ambiguous", "competing relation interpretations remain explicit")
T.finish("pnc_semantic_evidence_relations_smoke")
