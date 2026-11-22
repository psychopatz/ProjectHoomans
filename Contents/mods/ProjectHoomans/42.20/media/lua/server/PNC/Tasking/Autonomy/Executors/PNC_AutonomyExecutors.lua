-- Autonomy action executors owned exclusively by PNC.Tasking (U3+ consolidated).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}

require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_FacilitySeat"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamingSeat"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient"

return PNC.AutonomyExecutors
