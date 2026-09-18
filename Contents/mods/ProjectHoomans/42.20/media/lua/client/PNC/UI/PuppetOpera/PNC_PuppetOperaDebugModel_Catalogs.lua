-- Compatibility and load-order hub for animation catalog access.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Catalogs_Contracts"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Catalogs_State"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Catalogs_Entries"

return Model
