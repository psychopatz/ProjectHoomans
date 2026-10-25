-- Project Hoomans semantic concept registration hub.
--
-- Keep this public path stable; the spokes only own registration families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
local registerSpeechAct = Internal.RegisterSpeechAct
if type(registerConcept) ~= "function"
    or type(registerSpeechAct) ~= "function"
then
    error("semantic catalog concepts require registration adapters")
end

local CampSite = PNC.Semantics.CampSite
if type(CampSite) ~= "table" or type(CampSite.RoomTypesList) ~= "function" then
    error("semantic catalog concepts require camp-site room definitions")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_SpeechActs"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Actions"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Context"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Items"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Dialogue"

function Internal.RegisterVocabulary()
    Internal.RegisterSpeechActs()
    Internal.RegisterActionConcepts()
    Internal.RegisterContextConcepts()
    Internal.RegisterItemConcepts()
    Internal.RegisterDialogueConcepts()
end

return Internal
