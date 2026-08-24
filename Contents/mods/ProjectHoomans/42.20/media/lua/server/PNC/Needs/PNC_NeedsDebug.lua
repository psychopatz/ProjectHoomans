-- Stable server-only Needs diagnostics entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsDebug = PNC.NeedsDebug or {
    groupHistory = {},
    individualHistory = {},
}
PNC.NeedsDebug.Internal = PNC.NeedsDebug.Internal or {}

local Debug = PNC.NeedsDebug
Debug.groupHistory = Debug.groupHistory or {}
Debug.individualHistory = Debug.individualHistory or {}
Debug.ProfilingEnabled = Debug.ProfilingEnabled == true
Debug.SupplyLoggingEnabled = Debug.SupplyLoggingEnabled == true

require "PNC/Needs/NeedsDebug/PNC_NeedsDebug_Summaries"
require "PNC/Needs/NeedsDebug/PNC_NeedsDebug_Snapshot"
require "PNC/Needs/NeedsDebug/PNC_NeedsDebug_Actions"

return Debug
