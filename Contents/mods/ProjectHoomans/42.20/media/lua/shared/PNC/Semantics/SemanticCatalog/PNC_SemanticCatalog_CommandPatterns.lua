-- Direct movement, camp, wait, and local NPC command registration hub.
--
-- Keep this public path stable; command families own their registrations.
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

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Navigation"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Other"

return Internal
