-- Context-reference follow-up registration hub.
--
-- Keep this public path stable; spokes own reference and wellbeing families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog follow-up module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog follow-up module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference_Questions"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference_Wellbeing"

function Internal.RegisterContextReferenceFollowUps()
    Internal.RegisterContextReferenceQuestionsFollowUps()
    Internal.RegisterWellbeingFollowUps()
end

return Internal
