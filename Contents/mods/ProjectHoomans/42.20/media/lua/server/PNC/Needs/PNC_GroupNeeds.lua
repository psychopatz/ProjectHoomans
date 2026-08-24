-- Stable mobile-group needs entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.GroupNeeds = PNC.GroupNeeds or {}
PNC.GroupNeeds.Internal = PNC.GroupNeeds.Internal or {}
PNC.GroupNeeds.Listeners = PNC.GroupNeeds.Listeners or {}

require "PNC/Needs/GroupNeeds/PNC_GroupNeeds_Listeners"
require "PNC/Needs/GroupNeeds/PNC_GroupNeeds_State"
require "PNC/Needs/GroupNeeds/PNC_GroupNeeds_Update"
require "PNC/Needs/GroupNeeds/PNC_GroupNeeds_Debug"

return PNC.GroupNeeds
