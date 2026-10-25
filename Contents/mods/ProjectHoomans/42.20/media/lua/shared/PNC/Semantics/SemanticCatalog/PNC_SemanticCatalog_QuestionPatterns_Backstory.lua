-- NPC personal-history question registration hub.
--
-- Keep this public path stable; spokes own the ordered backstory families.
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

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_Backstory_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_Backstory_CareerAndOrigin"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_Backstory_PersonalLife"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_Backstory_ValuesAndEvents"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_QuestionPatterns_Backstory_SurvivalAndIdentity"

function Internal.RegisterBackstoryQuestions()
    Internal.RegisterCareerAndOriginQuestions()
    Internal.RegisterPersonalLifeQuestions()
    Internal.RegisterValuesAndEventsQuestions()
    Internal.RegisterSurvivalAndIdentityQuestions()
end

return Internal
