local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

PNC = {}
local Projection = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)

local projection = Projection.Normalize({
    npcID = "observer",
    revision = 4,
    facts = {
        {
            subject = "SEEN",
            targetID = "sarah",
            targetName = "Sarah",
            status = "known",
            value = true,
            source = "witnessed",
            confidence = 0.94,
            observedAt = 12,
            recordedAt = 12,
        },
        {
            subject = "LOCATION",
            targetID = "john",
            status = "known",
            location = { label = "church", precision = "named" },
            source = "witnessed",
            observedAt = 10,
        },
        {
            subject = "SECRET",
            targetID = "sarah",
            status = "known",
            value = "not for the client",
            clientVisible = false,
            observedAt = 20,
        },
    },
}, "observer")

T.equal(projection.npcID, "observer", "projection keeps observer identity")
T.equal(projection.revision, 4, "projection keeps authoritative revision")
T.equal(
    projection.facts[Projection.Key("SEEN", "sarah")].value,
    true,
    "projection normalizes a boolean cognition fact"
)
T.equal(
    projection.facts[Projection.Key("LOCATION", "john")].location.label,
    "church",
    "projection preserves bounded structured fact values"
)

local filtered = Projection.BuildClientProjection(projection, "observer", {
    subject = "SEEN",
    targetID = "sarah",
})
T.truthy(filtered.facts[Projection.Key("SEEN", "sarah")],
    "client projection includes the requested fact")
T.equal(filtered.replace, true,
    "client projection is an authoritative scoped replacement")
T.equal(filtered.scope.subject, "SEEN",
    "client projection records its subject scope")
T.falsy(filtered.facts[Projection.Key("LOCATION", "john")],
    "client projection does not send unrelated facts")
T.falsy(filtered.facts[Projection.Key("SECRET", "sarah")],
    "client projection excludes non-visible facts")

local privateObservation = Projection.BuildClientProjection(
    Projection.Normalize({
        npcID = "observer",
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                status = "known",
                value = true,
                source = "witnessed",
                sourceID = "server-only-observer",
                location = {
                    distanceBand = "nearby",
                    precision = "band",
                    observedX = 100,
                    observedY = 200,
                },
                evidence = { kind = "line_of_sight" },
                observedAt = 22,
            },
        },
    }, "observer"),
    "observer",
    { subject = "SEEN", targetID = "sarah" }
)
T.falsy(privateObservation.facts[Projection.Key("SEEN", "sarah")]
    .location.observedX,
    "client projection redacts exact observation coordinates")
T.falsy(privateObservation.facts[Projection.Key("SEEN", "sarah")].sourceID,
    "client projection redacts private source identity")
T.falsy(privateObservation.facts[Projection.Key("SEEN", "sarah")].evidence,
    "client projection redacts private observation evidence")

local accepted
local updated
accepted, updated, projection = Projection.Upsert(projection, {
    subject = "SEEN",
    targetID = "sarah",
    targetName = "Sarah",
    status = "known",
    value = false,
    source = "heard",
    confidence = 0.60,
    observedAt = 13,
}, "observer")
T.equal(accepted, true, "newer cognition evidence is accepted")
T.equal(updated.value, false, "newer cognition replaces an older belief")
T.equal(projection.revision, 5, "accepted cognition increments revision")

accepted = Projection.Upsert(projection, {
    subject = "SEEN",
    targetID = "sarah",
    status = "known",
    value = true,
    source = "witnessed",
    confidence = 1,
    observedAt = 11,
}, "observer")
T.equal(accepted, false, "older cognition evidence is rejected")

local merged
local changed
merged, changed = Projection.Merge(nil, {
    npcID = "observer",
    revision = 8,
    facts = {
        {
            subject = "SEEN",
            targetID = "sarah",
            status = "known",
            value = true,
            observedAt = 15,
        },
    },
}, "observer")
T.truthy(merged, "client merge accepts a matching observer projection")
T.equal(changed, true, "client merge reports fact changes")
T.equal(
    Projection.Get(merged, "SEEN", "sarah").value,
    true,
    "client merge exposes the received cognition fact"
)

merged, changed = Projection.Merge(merged, {
    npcID = "observer",
    revision = 9,
    replace = true,
    scope = { subject = "SEEN", targetID = "sarah" },
    facts = {},
}, "observer")
T.equal(changed, true,
    "scoped replacement removes facts forgotten by the authority")
T.falsy(Projection.Get(merged, "SEEN", "sarah"),
    "forgotten scoped facts do not remain in the client cache")

local stale
local staleChanged
stale, staleChanged = Projection.Merge(merged, {
    npcID = "observer",
    revision = 7,
    facts = {},
}, "observer")
T.truthy(stale, "stale merge keeps the current projection")
T.equal(staleChanged, false, "client merge rejects stale projection revisions")

local expired = Projection.Normalize({
    npcID = "observer",
    facts = {
        {
            subject = "SEEN",
            targetID = "sarah",
            status = "known",
            value = true,
            observedAt = 1,
            expiresAt = 2,
        },
    },
}, "observer")
T.falsy(Projection.Get(expired, "SEEN", "sarah", 2),
    "expired cognition does not become a deterministic fact")

T.finish("pnc_semantic_cognition_projection_smoke")
