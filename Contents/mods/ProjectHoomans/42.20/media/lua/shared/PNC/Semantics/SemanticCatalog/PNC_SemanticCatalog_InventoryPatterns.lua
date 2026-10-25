-- Inventory question registration hub.
--
-- Keep this public path stable; spokes own query phrasing families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog pattern module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_InventoryPatterns_Have"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_InventoryPatterns_Got"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_InventoryPatterns_Open"

function Internal.RegisterInventoryQueries()
    Internal.RegisterInventoryHaveQueries()
    Internal.RegisterInventoryGotQueries()
    Internal.RegisterInventoryOpenQueries()
end

return Internal
