-- Follow, stop, wait, and camp command registration hub.
--
-- Keep this public path stable; spokes own command families.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog command module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog command module requires RegisterPattern")
end

require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_FollowStop"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Wait"
require "PNC/Semantics/SemanticCatalog/PNC_SemanticCatalog_CommandPatterns_Basic_Camp"

function Internal.RegisterBasicCommands()
    Internal.RegisterFollowStopCommands()
    Internal.RegisterWaitCommands()
    Internal.RegisterCampCommands()
end

return Internal
