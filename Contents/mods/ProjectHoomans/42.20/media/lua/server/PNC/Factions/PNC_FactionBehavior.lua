-- Server-authoritative bridge from persistent factions to tactical behavior.
-- Persistent faction identity remains canonical; tactical fields are derived.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}
PNC.FactionBehavior.ReconciliationQueue =
    PNC.FactionBehavior.ReconciliationQueue or {}
PNC.FactionBehavior.ReconciliationKeys =
    PNC.FactionBehavior.ReconciliationKeys or {}

require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_Context"
require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_Intent"
require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_OrderPlanning"
require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_Application"
require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_ReconciliationQueue"
require "PNC/Factions/FactionBehavior/PNC_FactionBehavior_ReconciliationPump"

return PNC.FactionBehavior
