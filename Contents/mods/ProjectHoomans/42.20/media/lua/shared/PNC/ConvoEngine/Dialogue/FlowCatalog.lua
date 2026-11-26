PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/ConvoEngine/Dialogue/FlowRegistry"
local ConversationRegistry = require
    "PNC/ConvoEngine/Registry"

local definitions = {
    require "PNC/ConvoEngine/Dialogue/Flow_Wellbeing",
    require "PNC/ConvoEngine/Dialogue/Flow_Weather",
}

-- Register core single-segment flows (e.g. greeting, identity, needs) before
-- dotted thematic flows so core flows take precedence on shared triggers.
local coreFlows = {}
local thematicFlows = {}
for index = 1, #(ConversationRegistry.FLOWS or {}) do
    local flow = ConversationRegistry.FLOWS[index]
    if type(flow) == "table" and type(flow.id) == "string"
        and not string.find(flow.id, ".", 1, true)
    then
        coreFlows[#coreFlows + 1] = flow
    else
        thematicFlows[#thematicFlows + 1] = flow
    end
end
for index = 1, #coreFlows do
    definitions[#definitions + 1] = coreFlows[index]
end
for index = 1, #thematicFlows do
    definitions[#definitions + 1] = thematicFlows[index]
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
