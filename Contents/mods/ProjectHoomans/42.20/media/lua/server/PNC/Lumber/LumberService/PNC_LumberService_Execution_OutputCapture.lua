-- Durable lumber output-effect creation and world-item capture.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Production/PNC_WorkOutputService"

local Service = PNC.LumberService
local Internal = Service.Internal
local OutputService = PNC.WorkOutputService
local markDirty = Internal.MarkDirty
local LUMBER_OUTPUT_MARKER_VERSION = Internal.LumberOutputMarkerVersion

Internal.OutputEffectFor = function(output)
    if type(output) ~= "table" or not output.treeKey then return nil end
    local tree = Service.GetTree(output.treeKey)
    return tree and tree.outputEffect or nil
end

Internal.SetOutputEffectState = function(effect, state, reason)
    OutputService.SetOutputEffectState(effect, state, reason, {
        markDirty = markDirty,
    })
end

---Creates or returns the durable LUMBER_OUTPUT effect attached to tree.
Internal.EnsureLumberOutputEffect = function(tree, mode, items, phase, reason,
    workerID)
    if type(tree) ~= "table" then return nil end
    local sourceMode = tostring(mode or "ABSTRACT")
    return OutputService.EnsureOutputEffect(tree, sourceMode, items, {
        id = PNC.Core and PNC.Core.GenerateID
            and PNC.Core.GenerateID("lumber_output")
            or ("lumber_output:" .. tostring(tree.key)),
        kind = "LUMBER_OUTPUT",
        operation = "LUMBER_OUTPUT",
        ownerKey = tree.key,
        treeKey = tree.key,
        x = tree.x, y = tree.y, z = tree.z,
        phase = phase or "OUTPUT_PENDING",
        reason = reason,
        workerId = workerID,
        quantity = tree.logYield,
        expectedQuantity = tree.logYield,
        lootSource = sourceMode == "LIVE" and "vanilla_tree_loot"
            or "abstract_log_yield",
        identity = { treeKey = tree.key, sourceMode = sourceMode },
        markDirty = markDirty,
    })
end

---Snapshots or captures newly spawned lumber floor items via WorkOutputService.
Internal.CaptureOutputItems = function(square, before, effect, snapshotOnly)
    return OutputService.CaptureGroundOutput(square, before, effect, {
        snapshotOnly = snapshotOnly == true,
        markerKey = "PNC_LumberOutputEffectID",
        markerVersionKey = "PNC_LumberOutputEffectVersion",
        markerVersion = LUMBER_OUTPUT_MARKER_VERSION,
        markDirty = markDirty,
    })
end

return Service
