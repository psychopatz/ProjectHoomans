local T = require "tests/support/test"
T.addPackagePaths()

local definitions = T.read(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua"
)
local categories = T.read(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/10_PNC_ConversationCategories.lua"
)
local topics = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTopicCatalog.lua"
)

T.falsy(string.find(
    definitions,
    "80_PNC_ConversationTrade",
    1,
    true
), "Project Hoomans must not register a duplicate trader graph")
T.falsy(string.find(
    categories,
    "category.trade",
    1,
    true
), "Project Hoomans must not own Dynamic Trading trade content")
T.falsy(string.find(
    topics,
    "projecthoomans:trade",
    1,
    true
), "Project Hoomans must not publish a duplicate trader topic")

T.finish("pnc_trader_conversation_ownership_smoke")
