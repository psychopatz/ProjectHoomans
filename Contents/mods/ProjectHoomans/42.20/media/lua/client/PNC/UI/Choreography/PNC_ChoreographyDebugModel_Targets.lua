-- Compatibility and load-order hub for animation target projection.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Targets_Catalog"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Targets_Selection"

return Model
