if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
Triggers.Internal = Triggers.Internal or {}
local Internal = Triggers.Internal

-- Stable contract markers: function Triggers.GetRecoveryState and
-- `return stopped == true` remain implemented by the recovery/lifecycle
-- providers below while this path stays the composition boundary.
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider_Helpers"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider_Main"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider_Recovery"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider_Lifecycle"

return Triggers
