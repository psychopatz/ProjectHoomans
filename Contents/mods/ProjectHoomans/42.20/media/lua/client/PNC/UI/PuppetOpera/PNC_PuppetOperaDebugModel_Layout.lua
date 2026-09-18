-- Compatibility entry hub for Puppet Opera layout model responsibilities.
--
-- Keep the existing module path and public model namespace stable while
-- loading projection and editing spokes in their dependency order.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Layout_Projections"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Layout_Anchors"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Layout_ActorSlots"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Layout_LivePlacement"

return Model
