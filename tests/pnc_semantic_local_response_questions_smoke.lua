local T = require "tests/support/test"
T.addPackagePaths()

local originalPsychopatzCore = PsychopatzCore
local originalPNC = PNC
PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans", "shared", "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local LocalResponse = PNC.Semantics.LocalResponse

local function question(subject)
    return Semantic.IR.New({
        rawText = "question",
        normalizedText = "question",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = subject,
        confidence = 0.95,
    })
end

local function decide(subject, worldContext)
    return Policy.Decide(question(subject), nil, {
        llmEnabled = false,
        worldContext = worldContext,
    })
end

local time = decide("TIME", { time = { hour = 21, minute = 5 } })
T.equal(time.branch, "QUESTION_RECEIVED",
    "time question stays on the deterministic response branch")
T.equal(time.response.templateID, "semantic.question.time",
    "time response keeps its catalog key")
T.equal(time.response.fallback, "It's 9:05 PM.",
    "time response formats the read-only world snapshot")
T.equal(time.response.args.hour, 21,
    "time response preserves the source hour for localization")

local date = decide("DATE", {
    calendar = { year = 1993, month = 10, day = 19 },
})
T.equal(date.response.templateID, "semantic.question.date",
    "date response keeps its catalog key")
T.equal(date.response.fallback, "It's October 19, 1993.",
    "date response formats the calendar snapshot")

local dayCount = decide("DATE", { gameDay = 41 })
T.equal(dayCount.response.fallback, "It's day 41.",
    "date response falls back to the game day when calendar fields are absent")

local weather = decide("WEATHER", {
    weather = { raining = true, foggy = true },
})
T.equal(weather.response.templateID, "semantic.question.weather",
    "weather response keeps its catalog key")
T.equal(weather.response.fallback, "It's raining and foggy out.",
    "weather response combines available observations")
T.equal(weather.response.args.weather.foggy, true,
    "weather response preserves the source snapshot for localization")

local unavailableTime = decide("TIME", {
    time = { available = false, hour = 21, minute = 5 },
})
T.equal(unavailableTime.response.templateID, "semantic.question.received",
    "an unavailable clock keeps the standard question fallback")

local malformedWeather = decide("WEATHER", { weather = "unknown" })
T.equal(malformedWeather.response.fallback,
    "I can't tell what the weather's doing right now.",
    "malformed weather data receives the explicit safe fallback")

T.equal(LocalResponse.Resolve(nil, nil, nil, "QUESTION_RECEIVED"), nil,
    "the public resolver rejects missing IR safely")

PNC = originalPNC
PsychopatzCore = originalPsychopatzCore
T.finish("pnc_semantic_local_response_questions_smoke")
