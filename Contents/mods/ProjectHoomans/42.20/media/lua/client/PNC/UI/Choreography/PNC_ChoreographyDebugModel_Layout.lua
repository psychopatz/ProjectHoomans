-- Compatibility entry hub for Puppet Opera layout model responsibilities.
--
-- Keep the existing module path and public model namespace stable while
-- loading projection and editing spokes in their dependency order.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Layout_Projections"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Layout_Anchors"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Layout_ActorSlots"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Layout_LivePlacement"

return Model
