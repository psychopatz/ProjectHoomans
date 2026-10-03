local T = require "tests/support/test"

local source = T.read("ProjectHoomans", "server",
    "PNC/Conversation/PNC_ConversationAuthority.lua")
local recruitSource = T.read("ProjectHoomans", "server",
    "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Recruit.lua")
local choiceSource = T.read("ProjectHoomans", "server",
    "PNC/Conversation/ConversationAuthority/PNC_ConversationAuthority_Choice.lua")
local prefix = "PNC/Conversation/ConversationAuthority/"
local providers = {
    "PNC_ConversationAuthority_Context",
    "PNC_ConversationAuthority_BuildContext",
    "PNC_ConversationAuthority_Validation",
    "PNC_ConversationAuthority_Category",
    "PNC_ConversationAuthority_Recruit",
    "PNC_ConversationAuthority_AmbientVisit",
    "PNC_ConversationAuthority_Choice",
    "PNC_ConversationAuthority_Choice_Handle_Context",
    "PNC_ConversationAuthority_Choice_Handle_Effects",
    "PNC_ConversationAuthority_Choice_Handle_Response",
    "PNC_ConversationAuthority_Choice_Handle",
    "PNC_ConversationAuthority_Recruit_Handle_Context",
    "PNC_ConversationAuthority_Recruit_Handle_Effects",
    "PNC_ConversationAuthority_Recruit_Handle_Response",
    "PNC_ConversationAuthority_Recruit_Handle",
}

local previousByRoot = {}
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local providerRoot = source
    if provider:find("Recruit_Handle", 1, true) then
        providerRoot = recruitSource
    elseif provider:find("Choice_Handle", 1, true) then
        providerRoot = choiceSource
    end
    local position = assert(providerRoot:find(needle, 1, true), needle)
    local previous = previousByRoot[providerRoot] or 0
    T.truthy(position > previous, provider .. " load order")
    previousByRoot[providerRoot] = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for name in providerSource:gmatch(
        "function%s+Authority%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = { Conversation = {} }
package.preload["PNC/Conversation/PNC_ConversationHistory"] = function()
    PNC.Conversation.History = {}
    return PNC.Conversation.History
end
package.preload[
    "PNC/Conversation/Blocks/PNC_ConversationTextLoader"
] = function()
    PNC.Conversation.TextLoader = {}
    return PNC.Conversation.TextLoader
end
T.load("ProjectHoomans", "server",
    "PNC/Conversation/PNC_ConversationAuthority.lua")

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.Conversation.Authority[name]), "function",
        "entry point preserves Conversation.Authority." .. name)
end
T.equal(publicCount, 5, "conversation-authority function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.preload["PNC/Conversation/PNC_ConversationHistory"] = nil
package.preload[
    "PNC/Conversation/Blocks/PNC_ConversationTextLoader"
] = nil

T.finish("pnc_conversation_authority_presence_boundary_smoke")
