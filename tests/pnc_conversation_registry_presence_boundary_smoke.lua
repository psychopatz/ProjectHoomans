local T = require "tests/support/test"

local source = T.read(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry.lua"
)
local providers = {
    "Utilities",
    "NodeValidation",
    "Validation",
    "Mutations",
    "Queries",
    "Handlers",
    "Fingerprint",
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
    "RegisterCategoryEligibilityProvider",
    "UnregisterCategoryEligibilityProvider",
    "EvaluateCategoryEligibility",
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
        'require "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Conversation/Registry/PsychopatzConversationRegistry.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PsychopatzCore.Conversation.Registry[functionName]),
        "function",
        "entry point should preserve Registry." .. functionName
    )
end

T.finish("pnc_conversation_registry_presence_boundary_smoke")
