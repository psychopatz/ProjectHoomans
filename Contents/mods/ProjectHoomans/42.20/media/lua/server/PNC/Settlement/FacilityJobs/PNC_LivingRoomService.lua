if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Compatibility name retained for existing pump callers and integrations.
PNC = PNC or {}
local Ambient = require "PNC/Settlement/FacilityJobs/PNC_AmbientFacilityService"
PNC.LivingRoomService = Ambient
return Ambient
