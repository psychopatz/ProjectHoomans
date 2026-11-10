-- Stable server-authoritative faction/community group generator entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDirector = PNC.CommunityDirector or {}
PNC.CommunityDirector.Internal = PNC.CommunityDirector.Internal or {}

require "PNC/Communities/CommunityDirector/PNC_CommunityDirector_Core"
require "PNC/Communities/CommunityDirector/PNC_CommunityDirector_SiteSelection"
require "PNC/Communities/CommunityDirector/PNC_CommunityDirector_NPCSpawner"
require "PNC/Communities/CommunityDirector/PNC_CommunityDirector_Generation"

return PNC.CommunityDirector
