-- Autonomy executor for roaming eat, drink, and sleep ambient scenes.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamAmbient = PNC.AutonomyExecutors.RoamAmbient or {}

require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Policy"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Schedule"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Discovery"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Lifecycle"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_SleepStart"
require "PNC/Tasking/Autonomy/Executors/PNC_AutonomyExecutor_RoamAmbient_Tick"

return PNC.AutonomyExecutors.RoamAmbient
