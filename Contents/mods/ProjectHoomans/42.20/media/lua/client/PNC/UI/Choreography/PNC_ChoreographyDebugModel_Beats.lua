-- Compatibility and load-order hub for Puppet Opera beat editing.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
Model.Internal = Model.Internal or {}

-- Helpers load first because Layout and Animation consume their contracts.
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Beats_Contracts"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Beats_Catalog"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Beats_Mutations"

return Model
