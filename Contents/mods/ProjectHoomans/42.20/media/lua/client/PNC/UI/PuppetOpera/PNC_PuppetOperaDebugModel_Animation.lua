-- Compatibility and load-order hub for animation assignment and summaries.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Animation_Assignment"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Animation_Summary"

return Model
