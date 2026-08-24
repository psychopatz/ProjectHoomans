-- Stable sanitized abstract-director debug entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractDirectorDebug = PNC.AbstractDirectorDebug or {}
PNC.AbstractDirectorDebug.Internal =
    PNC.AbstractDirectorDebug.Internal or {}

require "PNC/Director/AbstractDirectorDebug/PNC_AbstractDirectorDebug_Summaries"
require "PNC/Director/AbstractDirectorDebug/PNC_AbstractDirectorDebug_Snapshot"
require "PNC/Director/AbstractDirectorDebug/PNC_AbstractDirectorDebug_Actions"

return PNC.AbstractDirectorDebug
