-- Deterministic server entry for persistent faction identity and membership.
-- Incident, behavior, toll, validation, and debug adapters remain at their
-- later composition positions because they consume other runtime domains.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

require "PNC/PNC_FactionTelemetry"
require "PNC/PNC_FactionService"
require "PNC/PNC_FactionLeadership"
require "PNC/PNC_FactionMembershipService"

return PNC and PNC.Factions
