PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog context-question module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog context-question module requires RegisterPattern")
end

function Internal.RegisterWorldFactQuestions()
    Internal.RegisterWorldFactQuestions_Environment()
    Internal.RegisterWorldFactQuestions_Medical()
    Internal.RegisterWorldFactQuestions_Knowledge()
    Internal.RegisterWorldFactQuestions_FollowUps()
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Medical"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Knowledge"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps"

return Internal
