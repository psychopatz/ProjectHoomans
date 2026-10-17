PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry"

local definitions = {
    require "PNC/Semantics/PNC_SemanticDialogueFlow_Identity",
    require "PNC/Semantics/PNC_SemanticDialogueFlow_Wellbeing",
    require "PNC/Semantics/PNC_SemanticDialogueFlow_Greeting",
}

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
