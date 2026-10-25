-- Shared backstory question registration adapter.
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

function Internal.RegisterBackstoryQuestion(id, match, kind, confidence, priority)
    registerPattern(id, match, {
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_BACKSTORY",
        slots = { backstoryKind = kind },
        socialContext = { directed = true, personalQuestion = true },
    }, confidence, priority)
end

return Internal

