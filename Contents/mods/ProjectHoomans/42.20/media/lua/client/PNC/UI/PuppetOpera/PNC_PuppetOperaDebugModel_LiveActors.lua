-- Compatibility entry hub for live-actor model responsibilities.
--
-- Keep this legacy module path stable.  The implementation is split by
-- cohesion so existing root-model callers and Project Zomboid load order do
-- not need to know about the internal migration.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_LiveActors_Contracts"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_LiveActors_Discovery"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_LiveActors_Bindings"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_LiveActors_Selection"

return Model
