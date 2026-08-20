if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityTriggers = PNC.NeedFacilityTriggers or {}

require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggerDefinitions"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_HomeRoute"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider"

return PNC.NeedFacilityTriggers
