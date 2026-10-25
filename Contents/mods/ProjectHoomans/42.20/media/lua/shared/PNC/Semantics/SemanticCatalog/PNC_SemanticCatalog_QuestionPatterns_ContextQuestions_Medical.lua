-- Context-question registration hub for personal-state question families.
--
-- Keep this public path stable; spokes own the ordered question families.
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

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_MedicalBite"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Residence"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Health"

function Internal.RegisterWorldFactQuestions_Medical()
    Internal.RegisterMedicalBiteQuestions()
    Internal.RegisterResidenceQuestions()
    Internal.RegisterHealthQuestions()
end

return Internal
