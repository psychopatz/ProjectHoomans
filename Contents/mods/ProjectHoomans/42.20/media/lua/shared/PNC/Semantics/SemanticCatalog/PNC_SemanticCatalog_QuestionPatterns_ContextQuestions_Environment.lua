-- Environment context-question registration hub.
--
-- Keep this public path stable; spokes own ordered world-fact families.
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

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment_Time"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment_Weather"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment_Identity"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment_Activity"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_Environment_Wellbeing"

function Internal.RegisterWorldFactQuestions_Environment()
    Internal.RegisterEnvironmentTimeQuestions()
    Internal.RegisterEnvironmentWeatherQuestions()
    Internal.RegisterEnvironmentIdentityQuestions()
    Internal.RegisterEnvironmentActivityQuestions()
    Internal.RegisterEnvironmentWellbeingQuestions()
end

return Internal
