-- Stable plan/validate/commit entry for roaming strategic groups.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.GroupGenerator = PNC.GroupGenerator or {}
PNC.GroupGenerator.Internal = PNC.GroupGenerator.Internal or {}

local Generator = PNC.GroupGenerator
Generator.Metrics = Generator.Metrics or {
    attempts = 0,
    successes = 0,
    failures = 0,
    npcRecordsCreated = 0,
}

require "PNC/Director/Population/GroupGenerator/PNC_GroupGenerator_Selection"
require "PNC/Director/Population/GroupGenerator/PNC_GroupGenerator_Planning"
require "PNC/Director/Population/GroupGenerator/PNC_GroupGenerator_Rollback"
require "PNC/Director/Population/GroupGenerator/PNC_GroupGenerator_Commit"

return Generator
