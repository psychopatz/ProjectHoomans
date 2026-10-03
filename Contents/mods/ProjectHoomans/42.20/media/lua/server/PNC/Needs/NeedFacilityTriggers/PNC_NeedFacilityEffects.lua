-- Need-facility effects composition root.
-- Shared reporting/refill helpers load before world-water and need effects.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects_Core"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects_Water"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects_Needs"

return PNC.NeedFacilityEffects
