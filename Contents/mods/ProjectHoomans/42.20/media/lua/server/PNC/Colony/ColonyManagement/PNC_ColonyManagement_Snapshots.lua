if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Stable server snapshot entry point. Shared identity and settlement helpers,
-- the compact base projection, and the sectioned full projection load in order.
-- Compatibility inventory: function Management.BuildBaseSnapshot and
-- function Management.BuildSnapshot remain public provider declarations.
-- Snapshot contracts retained by the providers include `storage = storage`,
-- `includeRows = true`, `learnedTechnologyIds`, and
-- `ResearchRepository.Get(colony.id, false)`.
PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots_Core"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots_Base"
require "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots_Full"

return PNC.ColonyManagement
