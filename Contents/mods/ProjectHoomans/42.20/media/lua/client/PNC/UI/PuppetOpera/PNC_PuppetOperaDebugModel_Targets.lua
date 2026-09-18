-- Compatibility and load-order hub for animation target projection.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Targets_Catalog"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Targets_Selection"

return Model
