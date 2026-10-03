-- Stable server facility interaction target resolver entry point.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityInteractionTargets = PNC.FacilityInteractionTargets or {}

require "PNC/Settlement/PNC_InteractionTargetResolver_Core"
require "PNC/Settlement/PNC_InteractionTargetResolver_Sleep"
require "PNC/Settlement/PNC_InteractionTargetResolver_Seat"

return PNC.FacilityInteractionTargets
