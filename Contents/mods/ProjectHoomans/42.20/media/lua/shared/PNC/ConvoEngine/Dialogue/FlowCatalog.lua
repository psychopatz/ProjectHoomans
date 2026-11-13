PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/ConvoEngine/Dialogue/FlowRegistry"
local ConversationRegistry = require
    "PNC/ConvoEngine/Registry"

local definitions = {
    require "PNC/ConvoEngine/Dialogue/Flow_Identity",
    require "PNC/ConvoEngine/Dialogue/Flow_Wellbeing",
    require "PNC/ConvoEngine/Dialogue/Flow_Needs",
    require "PNC/ConvoEngine/Dialogue/Flow_Weather",
    require "PNC/ConvoEngine/Dialogue/Flow_Greeting",
}

for index = 1, #(ConversationRegistry.FLOWS or {}) do
    definitions[#definitions + 1] = ConversationRegistry.FLOWS[index]
end

for index = 1, #definitions do
    local definition = definitions[index]
    if not Registry.Get(definition.id) then
        local registered, reason = Registry.Register(definition)
        if not registered then
            error("semantic dialogue flow registration failed: "
                .. tostring(definition.id) .. " (" .. tostring(reason) .. ")")
        end
    end
end

return Registry
