--[[
    PNC Network Snapshots - Visual State
    Serializes movement, animation, scene, and native traversal state.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Diagnostics = PNC.PerformanceScalingDiagnostics
if not Parts.BuildVisualStateContext then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_Context"
end
if not Parts.BuildVisualStatePayload then
    require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState_Payload"
end

function Parts.BuildVisualState(record)
    local timingName
    local timingStart
    if Diagnostics and Diagnostics.BeginTiming then
        timingName, timingStart = Diagnostics.BeginTiming(
            "Network.Snapshot.Part.VisualState"
        )
    end
    if type(Parts.BuildVisualStateContext) ~= "function" then
        if Diagnostics and Diagnostics.EndTiming then
            Diagnostics.EndTiming(timingName, timingStart)
        end
        return nil
    end
    if type(Parts.BuildVisualStatePayload) ~= "function" then
        if Diagnostics and Diagnostics.EndTiming then
            Diagnostics.EndTiming(timingName, timingStart)
        end
        return nil
    end
    local context = Parts.BuildVisualStateContext(record)

    local snapshot = Parts.BuildVisualStatePayload(context)
    if Diagnostics and Diagnostics.EndTiming then
        Diagnostics.EndTiming(timingName, timingStart)
    end
    return snapshot
end

return Parts
