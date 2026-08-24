-- Stable community-debug entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}

require "PNC/Communities/CommunityDebug/PNC_CommunityDebug_Core"
require "PNC/Communities/CommunityDebug/PNC_CommunityDebug_Summaries"
require "PNC/Communities/CommunityDebug/PNC_CommunityDebug_Snapshot"
require "PNC/Communities/CommunityDebug/PNC_CommunityDebug_Actions"
require "PNC/Communities/CommunityDebug/PNC_CommunityDebug_Format"

return PNC.CommunityDebug
