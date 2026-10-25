-- Personal life backstory question registrations.
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

function Internal.RegisterPersonalLifeQuestions()
    register("pnc.question.backstory.hobby", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "is" },
        { kind = "literal", value = "your" },
        { kind = "concept", id = "HOBBY" },
    }, "hobby", .94, 92)
    register("pnc.question.backstory.fun", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "do" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "do" },
        { kind = "literal", value = "for" },
        { kind = "literal", value = "fun" },
    }, "hobby", .96, 110)
    register("pnc.question.backstory.family", {
        { kind = "literal", value = "tell" },
        { kind = "literal", value = "me" },
        { kind = "literal", value = "about" },
        { kind = "concept", id = "FAMILY" },
    }, "family_background", .94, 92)
    register("pnc.question.backstory.family_literal", {
        { kind = "literal", value = "tell" },
        { kind = "literal", value = "me" },
        { kind = "literal", value = "about" },
        { kind = "literal", value = "your" },
        { kind = "literal", value = "family" },
    }, "family_background", .97, 110)
end

return Internal

