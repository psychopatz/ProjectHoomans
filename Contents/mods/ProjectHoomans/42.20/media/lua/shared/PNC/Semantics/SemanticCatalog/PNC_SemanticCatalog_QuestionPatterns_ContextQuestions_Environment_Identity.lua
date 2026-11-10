-- Identity context-question registrations.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog context-question spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog context-question spoke requires RegisterPattern")
end

function Internal.RegisterEnvironmentIdentityQuestions()
    registerPattern(
        "pnc.question.identity",
        { "@IDENTITY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY",
        },
        0.96,
        85
    )
    registerPattern(
        "pnc.question.identity.nickname",
        { "@NICKNAME" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY_NICKNAME",
            socialContext = { directed = true, identityFacet = "nickname" },
        },
        0.98,
        92
    )
    registerPattern(
        "pnc.question.identity.surname",
        { "@SURNAME" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY_SURNAME",
            socialContext = { directed = true, identityFacet = "surname" },
        },
        0.98,
        92
    )
    registerPattern(
        "pnc.question.identity.faction",
        { "@FACTION_IDENTITY" },
        {
            intent = "QUESTION",
            speechAct = "QUESTION",
            subject = "IDENTITY_FACTION",
            socialContext = { directed = true, identityFacet = "faction" },
        },
        0.98,
        92
    )
end

return Internal

