if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ScavengeExecutor = PNC.ScavengeExecutor or {}

require "PNC/Core/Behaviors/PNC_Behavior_Common"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Runtime"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Claims"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Transfers"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_State"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Actions"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Worker"
require "PNC/Scavenge/ScavengeExecutor/PNC_ScavengeExecutor_Provider"

return PNC.ScavengeExecutor
