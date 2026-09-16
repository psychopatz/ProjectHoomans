local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

PNC = {
    Core = { Now = function() return 100 end },
    Network = { ClientState = {} },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)
local Cognition = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCognitionClient.lua"
)

Cognition.Reset()
local accepted
local reason
accepted, reason = Cognition.ApplyPayload({
    requestID = "request:1",
    projection = {
        npcID = "observer",
        revision = 2,
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                targetName = "Sarah",
                status = "known",
                value = true,
                source = "witnessed",
                observedAt = 10,
            },
        },
    },
})
T.equal(accepted, true, "client accepts a valid cognition projection")
T.equal(reason, "updated", "client reports a fresh projection")
T.equal(
    Cognition.GetFact("observer", "SEEN", "sarah").value,
    true,
    "client cache exposes the received fact"
)

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "observer",
        revision = 1,
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                status = "known",
                value = false,
                observedAt = 1,
            },
        },
    },
})
T.equal(accepted, true, "stale packets are harmlessly acknowledged")
T.equal(reason, "stale_projection", "client identifies stale packets")
T.equal(
    Cognition.GetFact("observer", "SEEN", "sarah").value,
    true,
    "stale packets cannot overwrite the current fact"
)

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "observer",
        revision = 3,
        replace = true,
        scope = { subject = "SEEN", targetID = "sarah" },
        facts = {},
    },
})
T.equal(accepted, true, "client accepts an empty scoped replacement")
T.equal(reason, "updated", "client reports the cache removal")
T.falsy(Cognition.GetFact("observer", "SEEN", "sarah"),
    "client removes facts absent from an authoritative replacement")

accepted, reason = Cognition.ApplyPayload({
    projection = {
        npcID = "other_observer",
        revision = 1,
        facts = {},
    },
})
T.equal(accepted, true, "a distinct NPC receives an isolated cache entry")
T.falsy(Cognition.GetFact("other_observer", "SEEN", "sarah"),
    "NPC cognition caches remain isolated by observer")

accepted, reason = Cognition.ApplyPayload({
    npcID = "observer",
    reason = "invalid_lease",
    requestID = "request:2",
})
T.equal(accepted, false, "failed server projection does not create facts")
T.equal(reason, "invalid_lease", "client preserves server rejection reason")

T.finish("pnc_semantic_cognition_client_smoke")
