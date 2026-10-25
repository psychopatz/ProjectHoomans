-- Values and difficult events backstory question registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog question spoke requires Catalog.Internal")
end

local register = Internal.RegisterBackstoryQuestion
if type(register) ~= "function" then
    error("semantic catalog question spoke requires RegisterBackstoryQuestion")
end

function Internal.RegisterValuesAndEventsQuestions()
    register("pnc.question.backstory.values", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "do" },
        { kind = "literal", value = "you" },
        { kind = "concept", id = "PERSONAL_VALUE" },
    }, "value", .94, 92)
    register("pnc.question.backstory.what_value", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "do" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "value" },
    }, "value", .96, 110)
    register("pnc.question.backstory.fear", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "are" },
        { kind = "literal", value = "you" },
        { kind = "concept", id = "PERSONAL_FEAR" },
        { kind = "literal", value = "of" },
    }, "fear", .94, 92)
    register("pnc.question.backstory.tragedy", {
        { kind = "literal", value = "what" },
        { kind = "concept", id = "PERSONAL_TRAGEDY" },
        { kind = "literal", value = "to" },
        { kind = "literal", value = "you" },
    }, "tragedy", .92, 90)
    register("pnc.question.backstory.what_happened", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "happened" },
        { kind = "literal", value = "to" },
        { kind = "literal", value = "you" },
    }, "tragedy", .96, 110)
    register("pnc.question.backstory.tragedy_concept", {
        { kind = "concept", id = "PERSONAL_TRAGEDY" },
        { kind = "literal", value = "to" },
        { kind = "literal", value = "you" },
    }, "tragedy", .96, 110)
end

return Internal

