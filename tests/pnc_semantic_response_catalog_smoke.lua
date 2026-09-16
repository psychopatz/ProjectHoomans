local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)

local default = Catalog.Select(
    "semantic.greeting",
    { npcID = "mara", worldContext = {} },
    "default"
)
T.equal(default.templateID, "semantic.greet.acknowledged",
    "response catalog exposes the stable greeting template id")
T.equal(default.fallback, "Hey there.",
    "response catalog uses the safe default greeting")

local friendly = Catalog.Select(
    "semantic.greeting",
    {
        npcID = "mara",
        dialogueSituation = { social = { style = "friendly" } },
    },
    "friendly"
)
T.equal(friendly.templateID, "semantic.greet.friendly",
    "response pools can branch on projected NPC social style")

local dawn = Catalog.Select(
    "semantic.greeting",
    {
        npcID = "mara",
        worldContext = { timeBand = "dawn" },
    },
    "dawn"
)
T.equal(dawn.templateID, "semantic.greet.morning",
    "response conditions can use the cached world time band")

local registered = Catalog.Register("test.topic_pool", {
    variants = {
        {
            id = "test.topic.default",
            fallback = "I hear you.",
        },
        {
            id = "test.topic.weather",
            fallback = "The weather is turning.",
            when = { topic = "weather" },
            priority = 1,
        },
    },
})
T.equal(registered, true,
    "domain modules can register a bounded response pool")

local weather = Catalog.Select(
    "test.topic_pool",
    { npcID = "mara", currentTopic = "weather" },
    "weather"
)
T.equal(weather.id, "test.topic.weather",
    "the most specific matching response variant wins")

local unrelated = Catalog.Select(
    "test.topic_pool",
    { npcID = "mara", currentTopic = "resources" },
    "resources"
)
T.equal(unrelated.id, "test.topic.default",
    "unmatched conditions fall back to the default variant")

T.falsy(Catalog.Select("missing_pool", {}, "missing"),
    "missing pools fail safely")

T.finish("pnc_semantic_response_catalog_smoke")
