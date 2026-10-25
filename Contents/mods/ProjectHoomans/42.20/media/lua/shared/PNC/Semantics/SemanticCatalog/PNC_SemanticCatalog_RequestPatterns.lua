-- Explicit item assistance request registration hub.
--
-- Keep this public path stable; spokes own request families only.
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

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns_Basic"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns_World"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_RequestPatterns_Quest"

function Internal.RegisterRequests()
    Internal.RegisterBasicRequests()
    Internal.RegisterWorldRequests()
    Internal.RegisterQuestRequests()
end

return Internal
