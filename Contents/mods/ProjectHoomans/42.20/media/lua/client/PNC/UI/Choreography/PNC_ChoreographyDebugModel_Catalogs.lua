-- Compatibility and load-order hub for animation catalog access.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Catalogs_Contracts"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Catalogs_State"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Catalogs_Entries"

return Model
