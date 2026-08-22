local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Relationships/PNC_RelationshipGraph.lua"
local MODEL =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "UI/Relationships/PNC_RelationshipDebugModel.lua"
local PRESENTATION =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Relationships/PNC_RelationshipPresentation.lua"

PNC = {}
T.load(FILE)
T.load(PRESENTATION)

local Graph = PNC.RelationshipGraph
local Presentation = PNC.RelationshipPresentation

local summary = Presentation.Summarize({
    approval = 25,
    respect = -30,
    familiarity = 7,
    state = "wary",
    revision = 4.9,
}, true)
T.equal(summary.approval, 25, "presentation retains approval")
T.equal(summary.respect, -30, "presentation retains respect")
T.equal(summary.revision, 4, "presentation normalizes revision")
T.equal(
    Presentation.BuildEvaluation(summary, "inspect").attitude,
    "pity",
    "presentation uses shared attitude graph"
)
local syntheticFear = Presentation.GetDebugStandingPreset("fear")
T.equal(syntheticFear.approval, -65, "fear baseline approval")
T.equal(syntheticFear.respect, 65, "fear baseline respect")

T.equal(Graph.ResolveAttitude(40, 40), "admire",
    "positive approval and respect")
T.equal(Graph.ResolveAttitude(40, -40), "pity",
    "positive approval and negative respect")
T.equal(Graph.ResolveAttitude(-40, 40), "fear",
    "negative approval and positive respect")
T.equal(Graph.ResolveAttitude(-40, -40), "despise",
    "negative approval and respect")
T.equal(Graph.ResolveAttitude(4, -4), "indifferent",
    "neutral dead zone")
T.equal(Graph.ResolveAttitude(20, 4), "sympathetic",
    "positive approval neutral respect")
T.equal(Graph.ResolveAttitude(4, 20), "impressed",
    "neutral approval positive respect")

local recruit = Graph.Evaluate(50, 50, "recruit")
T.truthy(recruit.insideSuccessRegion,
    "high approval and respect recruit")
T.equal(recruit.attitude, "admire", "evaluation attitude")

local feared = Graph.Evaluate(-30, 80, "challenge_extorter")
T.truthy(feared.insideSuccessRegion,
    "high respect can pass challenge while disliked")
T.equal(feared.attitude, "fear",
    "challenge does not turn fear into approval")

local mercyWithoutContext =
    Graph.Evaluate(20, -20, "request_mercy")
local mercyWithCompassion = Graph.Evaluate(
    20,
    -20,
    "request_mercy",
    {
        modifiers = {
            {
                id = "compassion",
                label = "Extorter compassion",
                value = 20,
            },
        },
    }
)
T.equal(mercyWithoutContext.insideSuccessRegion, false,
    "mercy initially outside region")
T.truthy(mercyWithCompassion.insideSuccessRegion,
    "context expands mercy region")
T.equal(mercyWithCompassion.contextBonus, 20,
    "context modifier included")

local x, y = Graph.RelationshipToScreen(
    100,
    -100,
    10,
    20,
    200,
    200
)
T.equal(x, 10, "minimum respect maps left")
T.equal(y, 20, "maximum approval maps top")

local first = Graph.Evaluate(25, 30, "recruit")
local second = Graph.Evaluate(25, 30, "recruit")
T.equal(first.finalScore, second.finalScore,
    "evaluation deterministic")
T.equal(first.insideSuccessRegion,
    second.insideSuccessRegion,
    "evaluation result deterministic")

T.load(MODEL)
local mercyDebug = PNC.RelationshipDebugModel.BuildGraph({
    relationship = {
        approval = 20,
        respect = -20,
    },
    observer = {
        personality = {
            compassion = 1,
            materialism = 0,
            aggression = 0,
        },
        faction = {
            policy = { caution = 0.5 },
        },
    },
}, "request_mercy", { bonus = 5 })
T.equal(mercyDebug.attitude, "pity",
    "debug model retains derived attitude")
T.equal(mercyDebug.contextBonus, 25,
    "debug model exposes personality and manual context")
T.truthy(mercyDebug.insideSuccessRegion,
    "debug context redraws success region")
T.finish("pnc_relationship_graph_smoke")

T.finish("pnc_relationship_graph_smoke")
