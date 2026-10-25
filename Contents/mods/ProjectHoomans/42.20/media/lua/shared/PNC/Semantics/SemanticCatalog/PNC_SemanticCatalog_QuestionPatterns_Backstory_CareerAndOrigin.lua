-- Career and origin backstory question registrations.
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

function Internal.RegisterCareerAndOriginQuestions()
    register("pnc.question.backstory.former_job", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "do" },
        { kind = "literal", value = "before" },
    }, "former_job", .96, 94)
    register("pnc.question.backstory.work", {
        { kind = "literal", value = "what" },
        { kind = "concept", id = "FORMER_JOB" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "do" },
    }, "former_job", .95, 93)
    register("pnc.question.backstory.what_was_your_job", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "was" },
        { kind = "literal", value = "your" },
        { kind = "literal", value = "job" },
    }, "former_job", .97, 110)
    register("pnc.question.backstory.hometown", {
        { kind = "literal", value = "where" },
        { kind = "literal", value = "are" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "from" },
    }, "hometown", .96, 94)
    register("pnc.question.backstory.where_grow_up", {
        { kind = "literal", value = "where" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "grow" },
        { kind = "literal", value = "up" },
    }, "hometown", .96, 110)
    register("pnc.question.backstory.education", {
        { kind = "literal", value = "what" },
        { kind = "literal", value = "did" },
        { kind = "literal", value = "you" },
        { kind = "literal", value = "study" },
    }, "education", .93, 92)
end

return Internal

