-- Stable bounded abstract-combat resolver entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractCombatResolver = PNC.AbstractCombatResolver or {}
PNC.AbstractCombatResolver.Internal =
    PNC.AbstractCombatResolver.Internal or {}
PNC.AbstractCombatResolver.Metrics =
    PNC.AbstractCombatResolver.Metrics or {
        combats = 0, retreats = 0, casualties = 0, rounds = 0,
    }

require "PNC/Director/AbstractCombatResolver/PNC_AbstractCombatResolver_Math"
require "PNC/Director/AbstractCombatResolver/PNC_AbstractCombatResolver_Resources"
require "PNC/Director/AbstractCombatResolver/PNC_AbstractCombatResolver_Outcomes"
require "PNC/Director/AbstractCombatResolver/PNC_AbstractCombatResolver_Resolution"

return PNC.AbstractCombatResolver
