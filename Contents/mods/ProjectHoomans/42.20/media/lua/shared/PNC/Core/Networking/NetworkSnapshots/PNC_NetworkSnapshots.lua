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
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_MotionContext"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_Context"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_Payload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PathDebugState"
Internal.CombatDebugTarget = {
    Core = PNC.Core,
    Registry = PNC.Registry,
}
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugTargetResolver"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugObservations"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Temporal"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Context"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_TacticalPayload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_AttackPayload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Payload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedDebugState"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_RosterPayloads"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CharacterPayload"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload"

return Network
