-- Authority-side one-time unique NPC reservation and lifecycle state.
-- Provider composition root: helpers, diagnostics, lifecycle, maintenance.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.UniqueNPCRegistry = PNC.UniqueNPCRegistry or {}

require "PNC/Director/PNC_UniqueNPCRegistry_Core"
require "PNC/Director/PNC_UniqueNPCRegistry_Diagnostics"
require "PNC/Director/PNC_UniqueNPCRegistry_Lifecycle"
require "PNC/Director/PNC_UniqueNPCRegistry_Maintenance"

return PNC.UniqueNPCRegistry
