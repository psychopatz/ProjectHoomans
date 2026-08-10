--[[
    PNC Networking - Network Snapshots
    Canonical entry point for serialized NPC state views.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal

Internal.SnapshotParts = Internal.SnapshotParts or {}

require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_Presentation"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_RuntimeSummaries"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PathDebugState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugObservations"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_RosterPayloads"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CharacterPayload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload"

return Network
