-- Stable community-invariant validation entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityValidation = PNC.CommunityValidation or {}
PNC.CommunityValidation.Internal =
    PNC.CommunityValidation.Internal or {}

require "PNC/Communities/CommunityValidation/PNC_CommunityValidation_Core"
require "PNC/Communities/CommunityValidation/PNC_CommunityValidation_Registry"

return PNC.CommunityValidation
