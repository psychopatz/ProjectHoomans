-- Stable production research service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
PNC.ResearchService.Commands = PNC.ResearchService.Commands or {}
PNC.ResearchService.Queries = PNC.ResearchService.Queries or {}

require "PNC/Production/PNC_WorkInputService"
require "PNC/Production/ResearchService/PNC_ResearchService_Context"
require "PNC/Production/ResearchService/PNC_ResearchService_Knowledge"
require "PNC/Production/ResearchService/PNC_ResearchService_Queueing"
require "PNC/Production/ResearchService/PNC_ResearchService_Artifacts"
require "PNC/Production/ResearchService/PNC_ResearchService_Lifecycle"
require "PNC/Production/ResearchService/PNC_ResearchService_Snapshot"

return PNC.ResearchService
