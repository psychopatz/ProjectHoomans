-- Stable server-authoritative social-profile entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialProfiles = PNC.SocialProfiles or {}
PNC.SocialProfiles.Internal = PNC.SocialProfiles.Internal or {}

local SocialProfiles = PNC.SocialProfiles
SocialProfiles.RuntimePlayers = SocialProfiles.RuntimePlayers
    or setmetatable({}, { __mode = "k" })

require "PNC/Social/SocialProfileService/PNC_SocialProfileService_Core"
require "PNC/Social/SocialProfileService/PNC_SocialProfileService_Players"
require "PNC/Social/SocialProfileService/PNC_SocialProfileService_NPCs"
require "PNC/Social/SocialProfileService/PNC_SocialProfileService_Math"

return SocialProfiles
