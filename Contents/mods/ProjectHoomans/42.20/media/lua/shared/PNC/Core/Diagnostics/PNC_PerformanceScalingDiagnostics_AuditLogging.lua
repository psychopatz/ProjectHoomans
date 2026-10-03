-- Opt-in diagnostics channels and bounded event snapshots.
PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}

require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_AuditChannels"
require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_AuditBuild"
require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_AuditState"

return PNC.PerformanceScalingDiagnostics
