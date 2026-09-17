-- Presentation-model hub for Hoomans Perception Debug.
-- Providers return primitive snapshots; these spokes format them for the
-- window, overlay labels, and hover tooltips.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Model = PNC.PerceptionDebug.Model or {}
PNC.PerceptionDebug.Model = Model

require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_ModelInternal"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_ModelObjects"
require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_ModelSummary"

return Model
