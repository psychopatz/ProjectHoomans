-- Stable detailed snapshot diagnostics entry point.
local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState_Core"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState_Seating"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState_Camp"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState_Detailed"

return Parts
