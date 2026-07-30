local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function near(actual, expected, epsilon, label)
    if math.abs(actual - expected) > epsilon then
        error((label or "near") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PNC = {}
dofile(ROOT .. "Relationships/PNC_EntityRef.lua")
dofile(ROOT .. "Conduct/PNC_ConductConstants.lua")
dofile(ROOT .. "Conduct/PNC_ConductTypes.lua")
dofile(ROOT .. "Conduct/PNC_ConductMath.lua")
dofile(ROOT .. "Conduct/PNC_ConductDefinitions.lua")

local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants
local actor = "player:Patrick:char_test"
local subject = "npc:npc_test"

local neutral = Types.NewConductRecord()
equal(neutral.schemaVersion, 1, "conduct schema")
for _, dimension in ipairs(Constants.DIMENSIONS) do
    equal(neutral.scores[dimension], 0, "neutral " .. dimension)
end

local repaired = Types.NormalizeConductRecord({
    scores = {
        reliability = 500,
        generosity = -500,
        compassion = 0 / 0,
        courage = math.huge,
    },
    baseline = {
        reliability = 500,
        generosity = -500,
        compassion = 0 / 0,
        courage = math.huge,
    },
})
equal(repaired.scores.reliability, 100, "upper clamp")
equal(repaired.scores.generosity, -100, "lower clamp")
equal(repaired.scores.compassion, 0, "NaN repair")
equal(repaired.scores.courage, 0, "infinity repair")

local evidence = Types.NewConductEvidence({
    id = "conduct:social:test:" .. actor,
    eventID = "social:test",
    eventType = "saved_from_incapacitation",
    actorKey = actor,
    subjectKey = subject,
    createdAt = 0,
    effects = { compassion = 8, courage = 5, ignored = 99 },
    strength = 1,
    decayPerDay = 0.25,
    visibility = "direct",
    shareable = true,
    tags = { rescue = true, invalid = false },
})
assert(evidence, "valid evidence")
equal(evidence.effects.ignored, nil, "unknown effect ignored")
equal(evidence.tags.rescue, true, "map tag")
equal(Types.NewConductEvidence({
    id = "bad",
    eventID = "not_social",
    actorKey = actor,
    subjectKey = subject,
    effects = { courage = 1 },
}), nil, "invalid evidence rejected")
near(Math.CalculateEvidenceStrengthAtTime(evidence, 48),
    0.5, 0.00001, "deterministic decay")
evidence.permanent = true
near(Math.CalculateEvidenceStrengthAtTime(evidence, 480),
    1, 0.00001, "permanent evidence")

local many = Types.NewConductRecord()
for index = 1, 66 do
    many.evidence[#many.evidence + 1] =
        Types.NewConductEvidence({
            id = "conduct:social:limit:" .. index .. ":" .. actor,
            eventID = "social:limit:" .. index,
            eventType = "test",
            actorKey = actor,
            subjectKey = subject,
            createdAt = index,
            effects = { reliability = 1 },
            strength = index == 1 and 1 or index / 100,
            decayPerDay = 0,
            permanent = index == 1,
            visibility = "private",
        })
end
many, _, within = Math.PruneEvidence(many, 66, 64)
equal(within, true, "evidence limit")
equal(#many.evidence, 64, "evidence count")
local permanentFound = false
local weakestFound = false
for _, item in ipairs(many.evidence) do
    permanentFound = permanentFound or item.permanent
    weakestFound = weakestFound
        or item.id == "conduct:social:limit:2:" .. actor
end
equal(permanentFound, true, "permanent preserved")
equal(weakestFound, false, "weakest temporary removed")

local calculated = Types.NewConductRecord({
    evidence = {
        Types.NewConductEvidence({
            id = "conduct:social:score:" .. actor,
            eventID = "social:score",
            eventType = "test",
            actorKey = actor,
            subjectKey = subject,
            createdAt = 0,
            effects = { compassion = 8 },
            strength = 1,
            decayPerDay = 0.25,
            visibility = "direct",
        }),
    },
})
calculated = Math.Recalculate(calculated, 48)
near(calculated.scores.compassion, 4, 0.00001,
    "derived score")

equal(PNC.ConductDefinitions.treated_wound.effects.compassion,
    2, "treatment mapping")
equal(PNC.ConductDefinitions.abandoned_in_combat
    .effects.groupLoyalty, -8, "abandonment mapping")

print("pnc_conduct_smoke: ok")
