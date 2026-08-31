local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/PNC_ConversationScene.lua"
)
local prefix = "PNC/Conversation/PNC_ConversationScene/"
local providers = {
    "PNC_ConversationScene_Core",
    "PNC_ConversationScene_Registration",
    "PNC_ConversationScene_Threat",
    "PNC_ConversationScene_Lease",
    "PNC_ConversationScene_Ceasefire",
    "PNC_ConversationScene_Commands",
}
local publicFunctions = {
    "EnsureRegistered",
    "HasThreat",
    "Begin",
    "End",
    "ReserveLLMRequest",
    "ClearLLMRequest",
    "ReleaseLLMRequest",
    "ValidateLLMRequest",
    "Pump",
    "HandleClientCommand",
}

local previous = 0
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
    "PNC/Conversation/PNC_ConversationScene.lua"
)
T.equal(PNC.ConversationScene.ID, "social.conversation", "scene ID")
T.equal(
    PNC.ConversationScene.CMD_CEASEFIRE,
    "conversationCeasefire",
    "ceasefire command"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.ConversationScene[functionName]),
        "function",
        "entry point should preserve ConversationScene." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_conversation_scene_presence_boundary_smoke")
