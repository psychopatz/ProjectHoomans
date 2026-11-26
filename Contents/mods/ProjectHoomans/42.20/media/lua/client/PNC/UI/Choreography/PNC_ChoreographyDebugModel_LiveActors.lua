-- Compatibility entry hub for live-actor model responsibilities.
--
-- Keep this legacy module path stable.  The implementation is split by
-- cohesion so existing root-model callers and Project Zomboid load order do
-- not need to know about the internal migration.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_LiveActors_Contracts"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_LiveActors_Discovery"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_LiveActors_Bindings"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_LiveActors_Selection"

return Model
