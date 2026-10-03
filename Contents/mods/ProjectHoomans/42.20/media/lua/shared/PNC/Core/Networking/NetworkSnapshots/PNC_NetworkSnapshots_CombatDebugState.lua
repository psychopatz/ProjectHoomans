--[[
    PNC Network Snapshots - Combat Debug State
    Serializes tactical, defensive, aiming, and attack diagnostics.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Diagnostics = PNC.PerformanceScalingDiagnostics
if not Parts.BuildCombatDebugContext then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Context"
end
if not Parts.BuildCombatDebugPayload then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_Payload"
end
local buildCombatDebugContext = Parts.BuildCombatDebugContext
local buildCombatDebugPayload = Parts.BuildCombatDebugPayload

function Parts.BuildCombatDebugState(record, combat, firearmState)
    local timingName
    local timingStart
    if Diagnostics and Diagnostics.BeginTiming then
        timingName, timingStart = Diagnostics.BeginTiming(
            "Network.Snapshot.Part.CombatDebugState"
        )
    end
    local context = buildCombatDebugContext(record, combat, firearmState)
    local snapshot = buildCombatDebugPayload(context)
    if Diagnostics and Diagnostics.EndTiming then
        Diagnostics.EndTiming(timingName, timingStart)
    end
    return snapshot
end

return Parts
