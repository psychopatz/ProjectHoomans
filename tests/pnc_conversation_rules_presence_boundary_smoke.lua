local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Blocks/PNC_ConversationRules.lua"
)
local prefix =
    "PNC/Conversation/Blocks/PNC_ConversationRules/"
local providers = {
    "PNC_ConversationRules_Conditions",
    "PNC_ConversationRules_RelationshipEffects",
    "PNC_ConversationRules_WorldEffects",
    "PNC_ConversationRules_Evaluation",
    "PNC_ConversationRules_Effects",
}
local publicFunctions = {
    "EvaluateGate",
    "EvaluateAll",
    "MatchesAudience",
    "CheckRepeat",
    "ValidateEffects",
    "ApplyEffects",
    "SimulateEffects",
}

local registryNeedle =
    'require "PNC/Conversation/Blocks/PNC_ConversationRegistry"'
local previous = assert(source:find(registryNeedle, 1, true))
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Blocks/PNC_ConversationRules.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Conversation.Rules[functionName]),
        "function",
        "entry point should preserve Rules." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_conversation_rules_presence_boundary_smoke")
