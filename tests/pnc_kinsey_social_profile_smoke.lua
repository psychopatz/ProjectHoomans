local T = require "tests/support/test"
T.addPackagePaths()

T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileTypes.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileMath.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_RelationshipProposalPolicy.lua"))

local Types = PNC.SocialProfileTypes
local Generator = PNC.SocialProfileGenerator
local Math = PNC.SocialProfileMath
local Policy = PNC.RelationshipProposalPolicy

-- Backward-compatible default mapping from legacy orientation without kinsey.
local straightProfile = Types.NormalizePlayerSocialProfile({ orientation = "straight" })
T.equal(straightProfile.kinsey, 0, "legacy straight normalizes to Kinsey 0")
local biProfile = Types.NormalizePlayerSocialProfile({ orientation = "bisexual" })
T.equal(biProfile.kinsey, 3, "legacy bisexual normalizes to Kinsey 3")
local gayProfile = Types.NormalizePlayerSocialProfile({ orientation = "gay" })
T.equal(gayProfile.kinsey, 6, "legacy gay normalizes to Kinsey 6")

-- Explicit Kinsey override derives matching coarse orientation.
local kinsey1 = Types.NormalizePlayerSocialProfile({ kinsey = 1 })
T.equal(kinsey1.kinsey, 1, "explicit Kinsey 1 preserved")
T.equal(kinsey1.orientation, "straight", "Kinsey 1 maps to straight coarse label")
local kinsey5 = Types.NormalizePlayerSocialProfile({ kinsey = 5 })
T.equal(kinsey5.kinsey, 5, "explicit Kinsey 5 preserved")
T.equal(kinsey5.orientation, "gay", "Kinsey 5 maps to gay coarse label")

-- Continuous attraction weights: 0 blocks same-gender, 6 blocks opposite-gender, 1..5 scale smoothly.
T.equal(Math.AttractionWeight(straightProfile, "female", "female"), 0,
    "Kinsey 0 has zero same-gender attraction")
T.equal(Math.AttractionWeight(straightProfile, "female", "male"), 1,
    "Kinsey 0 has full opposite-gender attraction")
T.equal(Math.AttractionWeight(gayProfile, "male", "male"), 1,
    "Kinsey 6 has full same-gender attraction")
T.equal(Math.AttractionWeight(gayProfile, "male", "female"), 0,
    "Kinsey 6 has zero opposite-gender attraction")
T.truthy(Math.AttractionWeight(kinsey1, "female", "female") > 0,
    "Kinsey 1 allows incidental same-gender attraction")
T.truthy(Math.AttractionWeight(kinsey1, "female", "female")
    < Math.AttractionWeight(biProfile, "female", "female"),
    "Kinsey 1 same-gender attraction is lower than Kinsey 3")
T.truthy(Math.AttractionWeight(kinsey5, "male", "female") > 0,
    "Kinsey 5 allows incidental opposite-gender attraction")

-- Mutual attraction weight requires both sides > 0.
T.equal(Math.MutualAttractionWeight(straightProfile, "female", gayProfile, "female"), 0,
    "mutual attraction is 0 when one side has 0 attraction")
T.truthy(Math.MutualAttractionWeight(kinsey1, "female", kinsey5, "female") > 0,
    "Kinsey 1 and Kinsey 5 have non-zero mutual same-gender attraction")

-- AcceptanceProbability scales smoothly with attractionWeight.
local rel = { approval = 80, respect = 70, familiarity = 60 }
local npcProf = { romanceStyle = "neutral", socialStyle = "neutral" }
local pLow = Policy.AcceptanceProbability(rel, npcProf, 0.17)
local pHigh = Policy.AcceptanceProbability(rel, npcProf, 1.0)
T.equal(Policy.AcceptanceProbability(rel, npcProf, 0), 0,
    "zero attraction weight yields zero acceptance probability")
T.truthy(pLow > 0 and pLow < pHigh,
    "lower Kinsey attraction yields lower acceptance probability than full attraction")

-- Generator deterministically rolls Kinsey within 0..6 and respects overrides.
local gen = Generator.Generate(4242, "General")
T.truthy(gen.kinsey >= 0 and gen.kinsey <= 6, "generated Kinsey is bounded 0..6")
local genOverride = Generator.Generate(4242, "General", { kinsey = 4 })
T.equal(genOverride.kinsey, 4, "generator respects Kinsey override")
T.equal(genOverride.orientation, "bisexual", "generator syncs orientation from Kinsey override")

-- PersonalityChemistry returns bounded [-1, 1] and rewards compatible sociable pairs.
local warmA = { compassion = 0.8, sociability = 0.8, aggression = 0.2, loyalty = 0.8, socialStyle = "friendly" }
local warmB = { compassion = 0.75, sociability = 0.8, aggression = 0.2, loyalty = 0.75, socialStyle = "friendly" }
local harsh = { compassion = 0.1, sociability = 0.2, aggression = 0.9, loyalty = 0.2, socialStyle = "withdrawn" }
local chemGood = Math.PersonalityChemistry(warmA, warmB)
local chemBad = Math.PersonalityChemistry(warmA, harsh)
T.truthy(chemGood > chemBad, "compatible friendly personalities have higher chemistry than mismatched aggressive ones")

T.finish("pnc_kinsey_social_profile_smoke")
