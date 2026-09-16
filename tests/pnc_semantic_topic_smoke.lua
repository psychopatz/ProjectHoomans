local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Topics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTopicCatalog.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)

local weather = Semantic.Parser.Parse("Is it raining?")
Topics.Annotate(weather, "Is it raining?")
T.equal(weather.extensions.topic.id, "weather",
    "weather question receives a world topic")
T.equal(weather.diagnostics.topicSource, "keyword",
    "keyword topic records its source")

local greeting = Semantic.Parser.Parse("Hello there")
Topics.Annotate(greeting, "Hello there")
T.equal(greeting.extensions.topic.id, "greeting",
    "greeting receives a social topic")

local morning = Semantic.Parser.Parse("Good morning")
Topics.Annotate(morning, "Good morning")
T.equal(morning.extensions.topic.id, "greeting",
    "time-shaped greetings remain greeting topics")

local state = Semantic.DialogueState.New({ maxEvents = 2 })
local recorded, event = state:Record(weather, { timestamp = 100 })
T.equal(recorded, true, "annotated IR enters dialogue state")
T.equal(state.currentTopic, "weather",
    "state prefers the explicit topic extension")
T.equal(event.topic, "weather", "event keeps the compact topic")

local fetch = Semantic.Parser.Parse("Bring me water")
Topics.Annotate(fetch, "Bring me water")
state:Record(fetch, { timestamp = 200 })
T.equal(state.currentTopic, "resources",
    "resource requests continue a resource topic")
T.equal(state.previousTopic, "weather",
    "previous topic remains available")

local switched, switchedTopic = state:SetTopic("trade")
T.equal(switched, true, "authored topic changes do not create an event")
T.equal(switchedTopic, "trade", "authored topic setter returns the topic")
T.equal(state.currentTopic, "trade",
    "authored topic becomes the active semantic context")
T.equal(state.previousTopic, "resources",
    "authored topic changes preserve the previous topic")
local invalidTopic, invalidReason = state:SetTopic({})
T.equal(invalidTopic, false, "invalid authored topics are rejected")
T.equal(invalidReason, "invalid_topic",
    "invalid authored topics return a stable diagnostic")

local noTopic = Topics.Resolve(nil, "something entirely unrelated")
T.falsy(noTopic, "unknown text does not receive a false topic")

local customTopicOK = Topics.RegisterAuthoredTopic(
    "testmod:radio", "radio"
)
T.equal(customTopicOK, true, "authored categories can register topics")
T.equal(Topics.AuthoredTopic({ category = "testmod:radio" }), "radio",
    "authored category topic is resolved from data")
T.equal(
    Topics.AuthoredTopic({ category = "testmod:radio", topic = "briefing" }),
    "briefing", "an authored block can override its category topic"
)

T.finish("pnc_semantic_topic_smoke")
