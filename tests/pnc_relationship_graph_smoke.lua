local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Relationships/PNC_RelationshipGraph.lua"
local MODEL =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "UI/Relationships/PNC_RelationshipDebugModel.lua"
local PRESENTATION =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Relationships/PNC_RelationshipPresentation.lua"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected="
            .. tostring(expected) .. " actual="
            .. tostring(actual))
    end
end

local function truthy(value, label)
    equal(value == true, true, label)
end

PNC = {}
dofile(FILE)
dofile(PRESENTATION)

local Graph = PNC.RelationshipGraph
local Presentation = PNC.RelationshipPresentation

local summary = Presentation.Summarize({
    approval = 25,
    respect = -30,
    familiarity = 7,
    state = "wary",
    revision = 4.9,
}, true)
equal(summary.approval, 25, "presentation retains approval")
equal(summary.respect, -30, "presentation retains respect")
equal(summary.revision, 4, "presentation normalizes revision")
equal(
    Presentation.BuildEvaluation(summary, "inspect").attitude,
    "pity",
    "presentation uses shared attitude graph"
)
local syntheticFear = Presentation.GetDebugStandingPreset("fear")
equal(syntheticFear.approval, -65, "fear baseline approval")
equal(syntheticFear.respect, 65, "fear baseline respect")

equal(Graph.ResolveAttitude(40, 40), "admire",
    "positive approval and respect")
equal(Graph.ResolveAttitude(40, -40), "pity",
    "positive approval and negative respect")
equal(Graph.ResolveAttitude(-40, 40), "fear",
    "negative approval and positive respect")
equal(Graph.ResolveAttitude(-40, -40), "despise",
    "negative approval and respect")
equal(Graph.ResolveAttitude(4, -4), "indifferent",
    "neutral dead zone")
equal(Graph.ResolveAttitude(20, 4), "sympathetic",
    "positive approval neutral respect")
equal(Graph.ResolveAttitude(4, 20), "impressed",
    "neutral approval positive respect")

local recruit = Graph.Evaluate(50, 50, "recruit")
truthy(recruit.insideSuccessRegion,
    "high approval and respect recruit")
equal(recruit.attitude, "admire", "evaluation attitude")

local feared = Graph.Evaluate(-30, 80, "challenge_extorter")
truthy(feared.insideSuccessRegion,
    "high respect can pass challenge while disliked")
equal(feared.attitude, "fear",
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
equal(mercyWithoutContext.insideSuccessRegion, false,
    "mercy initially outside region")
truthy(mercyWithCompassion.insideSuccessRegion,
    "context expands mercy region")
equal(mercyWithCompassion.contextBonus, 20,
    "context modifier included")

local x, y = Graph.RelationshipToScreen(
    100,
    -100,
    10,
    20,
    200,
    200
)
equal(x, 10, "minimum respect maps left")
equal(y, 20, "maximum approval maps top")

local first = Graph.Evaluate(25, 30, "recruit")
local second = Graph.Evaluate(25, 30, "recruit")
equal(first.finalScore, second.finalScore,
    "evaluation deterministic")
equal(first.insideSuccessRegion,
    second.insideSuccessRegion,
    "evaluation result deterministic")

dofile(MODEL)
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
equal(mercyDebug.attitude, "pity",
    "debug model retains derived attitude")
equal(mercyDebug.contextBonus, 25,
    "debug model exposes personality and manual context")
truthy(mercyDebug.insideSuccessRegion,
    "debug context redraws success region")

print("pnc_relationship_graph_smoke: ok")
