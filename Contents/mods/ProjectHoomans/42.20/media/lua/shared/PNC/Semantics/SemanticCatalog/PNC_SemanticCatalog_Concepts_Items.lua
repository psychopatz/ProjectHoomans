-- Item concept registration hub.
--
-- Keep this public path stable; spokes own contiguous taxonomy families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
if type(registerConcept) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_BasicFood"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Equipment"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Resources"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Consumables"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_SpecializedSupplies"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Utilities"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_Concepts_Needs"

function Internal.RegisterItemConcepts()
    Internal.RegisterBasicFoodConcepts()
    Internal.RegisterEquipmentConcepts()
    Internal.RegisterResourcesConcepts()
    Internal.RegisterConsumablesConcepts()
    Internal.RegisterSpecializedSuppliesConcepts()
    Internal.RegisterUtilitiesConcepts()
    Internal.RegisterNeedsConcepts()
end

return Internal
