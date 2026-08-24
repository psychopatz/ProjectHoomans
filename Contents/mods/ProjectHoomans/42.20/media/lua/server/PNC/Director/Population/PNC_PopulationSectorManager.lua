-- Stable population-sector manager entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationSectors = PNC.PopulationSectors or {}

require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Core"
require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Registry"
require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Queries"
require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Players"
require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Repair"
require "PNC/Director/Population/PopulationSectorManager/PNC_PopulationSectorManager_Generation"

return PNC.PopulationSectors
