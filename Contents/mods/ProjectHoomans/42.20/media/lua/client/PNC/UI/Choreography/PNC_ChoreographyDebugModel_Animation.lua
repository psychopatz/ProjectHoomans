-- Compatibility and load-order hub for animation assignment and summaries.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Animation_Assignment"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Animation_Summary"

return Model
