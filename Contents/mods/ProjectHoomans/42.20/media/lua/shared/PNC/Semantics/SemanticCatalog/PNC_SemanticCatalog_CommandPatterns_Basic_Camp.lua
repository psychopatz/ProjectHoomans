-- Camp command registration hub.
--
-- Keep this public path stable; spokes own shared construction and camp
-- command families while preserving the original registration order.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog command spoke requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog command spoke requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Camp_Core"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Camp_Campfire"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Camp_Room"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Camp_Here"

function Internal.RegisterCampCommands()
    Internal.RegisterCampfireCommand()
    Internal.RegisterCampRoomCommand()
    Internal.RegisterCampHereCommands()
end

return Internal
