local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua"
)
local providers = {
    "PNC_ConversationRegistry_Utilities",
    "PNC_ConversationRegistry_NodeValidation",
    "PNC_ConversationRegistry_Validation",
    "PNC_ConversationRegistry_Mutations",
    "PNC_ConversationRegistry_Queries",
    "PNC_ConversationRegistry_Handlers",
    "PNC_ConversationRegistry_Fingerprint",
}
local publicFunctions = {
    "ValidateCategory",
    "ValidateBlock",
    "RegisterCategory",
    "UnregisterCategory",
    "RegisterBlock",
    "UnregisterBlock",
    "GetCategory",
    "GetBlock",
    "ListCategories",
    "ListBlocks",
    "RegisterConditionHandler",
    "UnregisterConditionHandler",
    "RegisterEffectHandler",
    "UnregisterEffectHandler",
    "GetFingerprint",
    "CollectTextKeys",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Conversation/Blocks/PNC_ConversationRegistry/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Conversation.Registry[functionName]),
        "function",
        "entry point should preserve Registry." .. functionName
    )
end

T.finish("pnc_conversation_registry_presence_boundary_smoke")
