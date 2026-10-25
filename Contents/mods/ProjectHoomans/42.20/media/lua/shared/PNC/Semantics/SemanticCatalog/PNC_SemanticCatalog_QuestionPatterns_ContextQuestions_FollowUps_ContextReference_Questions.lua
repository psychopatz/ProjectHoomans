-- Context-reference follow-up question registration hub.
--
-- Keep this public path stable; spokes own shared question construction,
-- reference-based fact questions, and causal questions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog follow-up spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog follow-up spoke requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference_Questions_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference_Questions_Facts"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_ContextQuestions_FollowUps_ContextReference_Questions_Causal"

function Internal.RegisterContextReferenceQuestionsFollowUps()
    Internal.RegisterContextReferenceFactQuestions()
    Internal.RegisterContextReferenceCausalQuestions()
end

return Internal
