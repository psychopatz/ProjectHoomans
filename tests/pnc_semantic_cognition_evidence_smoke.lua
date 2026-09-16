local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

local remembered
local rememberCount = 0

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Semantics = {},
}

PNC.Semantics.CognitionService = {
    Remember = function(observerID, fact)
        rememberCount = rememberCount + 1
        remembered = { observerID = observerID, fact = fact }
        return true, fact, { revision = rememberCount }
    end,
}

local Evidence = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticCognitionEvidence.lua"
)

local observer = {
    id = "observer",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
}
local target = {
    id = "sarah",
    name = "Sarah",
    x = 5,
    y = 0,
    z = 0,
    alive = true,
}

local accepted, fact = Evidence.RecordVisibleNPC(observer, target, {
    observedAt = 10,
    visibilityKind = "clear",
})
T.equal(accepted, true, "line-of-sight evidence is recorded")
T.equal(remembered.observerID, "observer",
    "evidence is stored against the observing NPC")
T.equal(fact.subject, "SEEN", "visibility maps to the SEEN semantic subject")
T.equal(fact.targetID, "sarah", "visibility retains the target identity")
T.equal(fact.status, "known", "proven visibility is known, not guessed")
T.equal(fact.location.distanceBand, "nearby",
    "visibility stores a bounded location band")
T.equal(fact.location.observedX, 5,
    "observation retains server-side position evidence")
T.equal(fact.evidence.kind, "line_of_sight",
    "fact diagnostics identify the evidence source")

accepted = Evidence.RecordVisibleNPC(observer, target, {
    observedAt = 10.01,
    visibilityKind = "clear",
})
T.equal(accepted, false, "repeated observations are throttled")
T.equal(rememberCount, 1, "throttling avoids repeated persistence writes")

target.x = 30
accepted, fact = Evidence.RecordVisibleNPC(observer, target, {
    observedAt = 10.1,
    visibilityKind = "clearthroughwindow",
})
T.equal(accepted, true, "a later observation refreshes cognition")
T.equal(rememberCount, 2, "later evidence is persisted once")
T.equal(fact.location.distanceBand, "not_far",
    "later observations update the location band")

accepted = Evidence.RecordVisibleNPC(observer, observer, {
    observedAt = 11,
})
T.equal(accepted, false, "self-observation is rejected safely")

PNC.Core.IsAuthority = function() return false end
accepted = Evidence.RecordVisibleNPC(observer, target, {
    observedAt = 12,
})
T.equal(accepted, false, "clients cannot write cognition evidence")

T.finish("pnc_semantic_cognition_evidence_smoke")
