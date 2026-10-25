-- NPC personal-history question pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog question module requires RegisterPattern")
end

function Internal.RegisterBackstoryQuestions()
    local registerPattern = Internal.RegisterPattern
    local function register(id, match, kind, confidence, priority)
        registerPattern(id, match, {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "NPC_BACKSTORY",
            slots = { backstoryKind = kind },
            socialContext = { directed = true, personalQuestion = true },
        }, confidence, priority)
    end

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
