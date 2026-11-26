-- C0A characterization of the production conduct evidence boundary.
-- All records live in this disposable in-memory registry only.
local T = require "tests/support/test"
local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

PNC = {}
T.load(ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(ROOT .. "Conduct/PNC_ConductConstants.lua")
T.load(ROOT .. "Conduct/PNC_ConductTypes.lua")
T.load(ROOT .. "Conduct/PNC_ConductMath.lua")

local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants
local entityKey = "npc:c0a_saturation"
local subjectKey = "player:Patrick:char_c0a"

PNC.Core = {
    IsAuthority = function() return true end,
}
PNC.Registry = {
    records = {},
    Get = function(id) return PNC.Registry.records[id] end,
    MarkDirty = function() end,
}

local record = {
    id = "c0a_saturation",
    social = { conduct = Types.NewConductRecord() },
}
PNC.Registry.records[record.id] = record

local function makeEvidence(id, strength, permanent, ownerKey)
    return Types.NewConductEvidence({
        id = "conduct:c0a:" .. tostring(id),
        eventID = "social:c0a_saturation",
        eventType = "c0a_saturation_baseline",
        actorKey = ownerKey or entityKey,
        subjectKey = subjectKey,
        createdAt = tonumber(id) or 0,
        effects = { compassion = 1 },
        strength = strength,
        decayPerDay = 0,
        permanent = permanent == true,
        visibility = "direct",
    })
end

-- One permanent plus 63 strong temporary records fills the current limit.
record.social.conduct.evidence[1] = makeEvidence(1, 1, true)
for index = 2, Constants.EVIDENCE_LIMIT do
    record.social.conduct.evidence[index] = makeEvidence(index, 1, false)
end

T.equal(#record.social.conduct.evidence, Constants.EVIDENCE_LIMIT,
    "saturation fixture reaches current evidence limit")

T.load(
    T.path("ProjectHoomans", "server", "PNC/Social/PNC_ConductService.lua")
)
local accepted, reason = PNC.Conduct.AddEvidence(entityKey, {
    id = "conduct:c0a:new_weak",
    eventID = "social:c0a_saturation",
    eventType = "c0a_saturation_baseline",
    actorKey = entityKey,
    subjectKey = subjectKey,
    createdAt = 100,
    effects = { compassion = 1 },
    strength = 0.01,
    decayPerDay = 0,
    visibility = "direct",
})
T.equal(accepted, false, "weak new evidence is not accepted at capacity")
T.equal(reason, "evidence_pruned_by_limit",
    "current worker reports evidence_pruned_by_limit")
T.equal(#record.social.conduct.evidence, Constants.EVIDENCE_LIMIT,
    "rejected evidence does not mutate disposable owner")

local pruned, removed, withinLimit = Math.PruneEvidence(
    record.social.conduct, 100, Constants.EVIDENCE_LIMIT
)
T.equal(removed, 0, "already bounded record has no additional removals")
T.equal(withinLimit, true, "bounded record remains within limit")
T.truthy(pruned.evidence[1].permanent,
    "permanent evidence is retained by pruning")

local permanentEntityKey = "npc:c0a_permanent"
local permanentRecord = {
    id = "c0a_permanent",
    social = { conduct = Types.NewConductRecord() },
}
PNC.Registry.records[permanentRecord.id] = permanentRecord
for index = 1, Constants.EVIDENCE_LIMIT do
    permanentRecord.social.conduct.evidence[index] =
        makeEvidence(index, 1, true, permanentEntityKey)
end

local permanentAccepted, permanentReason = PNC.Conduct.AddEvidence(permanentEntityKey, {
    id = "conduct:c0a:new_permanent",
    eventID = "social:c0a_saturation",
    eventType = "c0a_saturation_baseline",
    actorKey = permanentEntityKey,
    subjectKey = subjectKey,
    createdAt = 101,
    effects = { compassion = 1 },
    strength = 1,
    decayPerDay = 0,
    permanent = true,
    visibility = "direct",
})
T.equal(permanentAccepted, false, "permanent overflow is not accepted")
T.equal(permanentReason, "permanent_evidence_limit",
    "permanent overflow has a distinct current rejection")

T.finish("pnc_c0a_conduct_saturation_baseline_smoke")
