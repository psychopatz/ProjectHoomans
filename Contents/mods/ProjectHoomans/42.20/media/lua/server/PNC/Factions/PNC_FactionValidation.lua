-- Stable faction invariant validation entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}

require "PNC/Factions/FactionValidation/PNC_FactionValidation_Context"
require "PNC/Factions/FactionValidation/PNC_FactionValidation_Relations"
require "PNC/Factions/FactionValidation/PNC_FactionValidation_Factions"
require "PNC/Factions/FactionValidation/PNC_FactionValidation_Registry"
require "PNC/Factions/FactionValidation/PNC_FactionValidation_Repair"
require "PNC/Factions/FactionValidation/PNC_FactionValidation_Scenarios"

return PNC.FactionValidation
