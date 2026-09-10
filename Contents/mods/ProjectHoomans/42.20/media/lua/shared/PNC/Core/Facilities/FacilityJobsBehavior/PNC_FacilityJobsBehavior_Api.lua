PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Jobs = PNC.FacilityJobs
local Internal = PNC.FacilityJobsBehaviorInternal

Jobs.AbortForOrderChange = Internal.AbortForOrderChange
Jobs.Stop = Internal.Stop
Jobs.RecordProgress = Internal.RecordProgress
Jobs.OnSceneTick = Internal.OnSceneTick
Jobs.OnSceneStopped = Internal.OnSceneStopped
Jobs.Tick = Internal.Tick

-- Ambient roaming seats use the same live furniture validation and cleanup
-- as durable facility activities, but keep their owner order untouched. Keep
-- these seams narrow so the transient service cannot mutate facility state or
-- accidentally enter the persistence path.
Jobs.Seating = Jobs.Seating or {}
Jobs.Seating.ClearFurnitureSeat = Internal.ClearFurnitureSeat
Jobs.Seating.EnterFurnitureSeat = Internal.EnterFurnitureSeat
Jobs.Seating.RefreshLiveSeatTarget = Internal.RefreshLiveSeatTarget
Jobs.Seating.PositionAtSeatAnchor = Internal.PositionAtSeatAnchor
Jobs.Seating.ResetPath = Internal.ResetPath
Jobs.Seating.RestorePosition = Internal.RestorePosition
Jobs.Seating.RetryApproach = Internal.RetrySeatApproach

return Jobs
