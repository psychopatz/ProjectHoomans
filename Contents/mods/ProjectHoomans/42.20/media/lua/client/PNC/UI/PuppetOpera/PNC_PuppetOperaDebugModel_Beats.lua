-- Compatibility and load-order hub for Puppet Opera beat editing.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
Model.Internal = Model.Internal or {}

-- Helpers load first because Layout and Animation consume their contracts.
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Beats_Contracts"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Beats_Catalog"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Beats_Mutations"

return Model
