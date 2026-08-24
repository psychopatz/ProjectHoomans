-- Stable community-site resolver entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunitySiteResolver = PNC.CommunitySiteResolver or {}

require "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Core"
require "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Description"
require "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Candidates"
require "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_Finders"
require "PNC/Communities/CommunitySiteResolver/PNC_CommunitySiteResolver_SpawnPoints"

return PNC.CommunitySiteResolver
