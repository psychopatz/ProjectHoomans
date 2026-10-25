-- Survival and identity backstory question registrations.
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

function Internal.RegisterSurvivalAndIdentityQuestions()
    register("pnc.question.backstory.survival", {
        { kind = "literal", value = "how" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "concept", id = "SURVIVAL_ORIGIN" },
    }, "survival_origin", .92, 90)
    register("pnc.question.backstory.how_survive", {
        { kind = "literal", value = "how" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "survive" },
    }, "survival_origin", .96, 110)
    register("pnc.question.backstory.birthday", {
        { kind = "literal", value = "when" },
        { kind = "literal", value = "your" },
        { kind = "concept", id = "BIRTHDAY" },
    }, "date_of_birth", .94, 92)
    register("pnc.question.backstory.when_birthday", {
        { kind = "literal", value = "when" },
        { kind = "literal", value = "is" },
        { kind = "literal", value = "your" },
        { kind = "literal", value = "birthday" },
    }, "date_of_birth", .97, 110)
end

return Internal

