-- First-person item-related need-state concepts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
if type(registerConcept) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end

function Internal.RegisterNeedsConcepts()
    registerConcept("HUNGER", {
        "hungry", "starving", "famished",
    }, 5)
    registerConcept("THIRST", { "thirsty", "parched" }, 5)
    registerConcept("FATIGUE", {
        "tired", "exhausted", "sleepy", "worn out",
    }, 5)
end

return Internal

