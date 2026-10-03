-- Lumber execution composition root.
--
-- Tree work, world output capture, output delivery, and tick diagnostics are
-- loaded in dependency order while the original Service.TickJob entry point
-- remains the public handoff to the Lumber executor and WorkAdapter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
Internal.WorldEffects = PNC.WorldEffectService
Internal.FatigueGate = PNC.WorkFatigueGate
    or require "PNC/Core/Needs/PNC_WorkFatigueGate"
Internal.LumberOutputMarkerVersion = 1

require "PNC/Lumber/LumberService/PNC_LumberService_Execution_OutputCapture"
require "PNC/Lumber/LumberService/PNC_LumberService_Execution_OutputDelivery"
require "PNC/Lumber/LumberService/PNC_LumberService_Execution_TreeWork"
require "PNC/Lumber/LumberService/PNC_LumberService_Execution_Dispatch"

return Service
