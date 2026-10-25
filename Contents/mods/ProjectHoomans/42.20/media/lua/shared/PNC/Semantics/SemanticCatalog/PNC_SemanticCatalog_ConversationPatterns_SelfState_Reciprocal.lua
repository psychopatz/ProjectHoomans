-- Reciprocal self-state registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog self-state spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog self-state spoke requires RegisterPattern")
end

function Internal.RegisterSelfReciprocalPatterns()
    local reciprocalPatterns = {
        {
            id = "pnc.question.wellbeing_reciprocal_how_about_you",
            match = {
                { kind = "literal", value = "how" },
                { kind = "literal", value = "about" },
                { kind = "literal", value = "you" },
            },
        },
        {
            id = "pnc.question.wellbeing_reciprocal_what_about_yourself",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "about" },
                { kind = "literal", value = "yourself" },
            },
        },
    }
    local reciprocalIndex
    local reciprocal
    for reciprocalIndex = 1, #reciprocalPatterns do
        reciprocal = reciprocalPatterns[reciprocalIndex]
        registerPattern(
            reciprocal.id,
            reciprocal.match,
            {
                intent = "QUESTION",
                speechAct = "QUESTION",
                subject = "WELLBEING_RECIPROCAL",
                target = "SELF",
                socialContext = {
                    directed = true,
                    informationalQuestion = true,
                    target = "SELF",
                    reciprocal = true,
                },
                extensions = {
                    dialogueFollowUp = "WELLBEING",
                    topic = "wellbeing",
                    reciprocal = true,
                },
            },
            0.99,
            191
        )
    end
end

return Internal
