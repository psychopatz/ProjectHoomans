--[[
    PNC Network Snapshots - Combat Debug State Payload
    Composes the stable combat diagnostics projection.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

if not Parts.BuildCombatDebugTacticalPayload then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_TacticalPayload"
end

if not Parts.BuildCombatDebugAttackPayload then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_AttackPayload"
end

function Parts.BuildCombatDebugPayload(context)
    local payload = {}
    local tacticalPayload = Parts.BuildCombatDebugTacticalPayload(context)
    local attackPayload = Parts.BuildCombatDebugAttackPayload(context)
    local key

    for key, value in pairs(tacticalPayload) do
        payload[key] = value
    end
    for key, value in pairs(attackPayload) do
        payload[key] = value
    end
    return payload
end

return Parts
