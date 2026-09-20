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
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Needs/PNC_NeedsDefinitions.lua"
)
local Situation = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueSituation.lua"
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

local function decideWellbeing(needs, ir)
    local context = {
        llmEnabled = false,
        entry = {
            id = "npc-needs-test",
            snapshot = { needs = needs },
        },
        npcRecord = {},
    }
    context.dialogueSituation = Situation.Build(context)
    return Policy.Decide(ir or question("WELLBEING"), nil, context), context
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

local areYouOkay = Semantic.Parser.Parse("Are you okay?")
T.equal(areYouOkay.intent, "QUESTION",
    "the player's direct wellbeing check parses as a question")
T.equal(areYouOkay.subject, "WELLBEING",
    "the player's direct wellbeing check uses the wellbeing subject")
local thirsty, thirstyContext = decideWellbeing({
    thirst = 0.30, hunger = 0.02, fatigue = 0.10,
}, areYouOkay)
T.equal(thirsty.branch, "QUESTION_RECEIVED",
    "wellbeing questions still use the existing question branch")
T.equal(thirstyContext.dialogueSituation.npc.needs.highest, "thirst",
    "the conversation snapshot projects thirst into the dialogue situation")
T.equal(thirstyContext.dialogueSituation.npc.needs.urgency, "moderate",
    "the projected thirst retains its need urgency")
T.truthy(string.find(thirsty.response.templateID, "thirst", 1, true),
    "the projected NPC thirst selects a thirst response")
T.truthy(string.find(string.lower(thirsty.response.fallback), "water", 1, true),
    "the thirst response names water the player can offer")
T.truthy(string.find(thirsty.response.fallback, "?", 1, true),
    "the thirst response invites a player reply")

local hungry = decideWellbeing({ hunger = 0.50, thirst = 0.02, fatigue = 0.10 })
T.truthy(string.find(hungry.response.templateID, "hunger", 1, true),
    "the projected NPC hunger selects a hunger response")
local hungerReply = string.lower(hungry.response.fallback)
T.truthy(string.find(hungerReply, "food", 1, true)
    or string.find(hungerReply, "eat", 1, true),
    "the hunger response asks about something edible")
T.truthy(string.find(hungry.response.fallback, "?", 1, true),
    "the hunger response invites a player reply")

local tired = decideWellbeing({ hunger = 0.02, thirst = 0.02, fatigue = 0.75 })
T.truthy(string.find(tired.response.templateID, "fatigue", 1, true),
    "the projected NPC fatigue selects a fatigue response")

local comfortable = decideWellbeing({
    hunger = 0.05, thirst = 0.04, fatigue = 0.10,
})
T.equal(comfortable.response.templateID,
    "semantic.question.wellbeing.default",
    "normal need levels keep the neutral wellbeing response")

T.equal(LocalResponse.Resolve(nil, nil, nil, "QUESTION_RECEIVED"), nil,
    "the public resolver rejects missing IR safely")

PNC = originalPNC
PsychopatzCore = originalPsychopatzCore
T.finish("pnc_semantic_local_response_questions_smoke")
