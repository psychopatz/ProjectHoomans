if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ScavengeService = PNC.ScavengeService or {}

require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Runtime"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Lifecycle"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Snapshots"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Diagnostics"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Search"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Queue"
require "PNC/Scavenge/ScavengeService/PNC_ScavengeService_Commands"

return PNC.ScavengeService
