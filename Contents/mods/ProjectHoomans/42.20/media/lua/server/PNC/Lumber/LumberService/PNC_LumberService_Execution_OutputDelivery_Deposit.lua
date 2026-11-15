-- Lumber live output delivery delegating to PNC.WorkOutputService.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Production/PNC_WorkOutputService"

local Service = PNC.LumberService
local Internal = Service.Internal
local OutputService = PNC.WorkOutputService
local now = Internal.Now
local markDirty = Internal.MarkDirty
local updateRuntime = Internal.UpdateRuntime

local function treeForOutput(job, pending)
    local key = pending and pending.treeKey or job and (job.outputTreeKey or job.targetKey)
    return key and Service.GetTree and Service.GetTree(key) or nil
end

---Drives live lumber output pickup and stockpile delivery via WorkOutputService.
Internal.TickLiveOutput = function(job, record, body, at)
    local output = job and job.pendingOutput
    local tree = output and Service.GetTree(output.treeKey) or nil
    local effect = tree and tree.outputEffect or nil
    if not effect then
        OutputService.ReleaseOutputCapacity(job, PNC.ColonyStorageService)
        job.state, job.phase = "FAILED", "FAILED"
        return false, false, "LUMBER_OUTPUT_EFFECT_MISSING"
    end
    if effect.waitReason == "LUMBER_LIVE_WORKER_REQUIRED" then
        effect.waitReason = nil
        effect.lastReason = "LUMBER_OUTPUT_RESUMED"
        effect.updatedAt = at
        markDirty()
    end
    local ok, complete, reason = OutputService.TickLiveDelivery(
        job, record, body, effect, at, {
            markerKey = "PNC_LumberOutputEffectID",
            markerVersionKey = "PNC_LumberOutputEffectVersion",
            markerVersion = Internal.LumberOutputMarkerVersion,
            grabSceneId = "lumber.grab",
            depositSceneId = "lumber.deposit",
            activityTag = "lumber",
            reservationPrefix = "lumber-output",
            storedReason = "LUMBER_OUTPUT_STORED",
            pickedReason = "LUMBER_OUTPUT_PICKED_UP",
            emptyReason = "LUMBER_OUTPUT_ITEMS_NOT_CAPTURED",
            missingReason = "LUMBER_OUTPUT_ITEM_MISSING",
            chunkWaitPhase = "WAITING_FOR_TREE_CHUNK",
            chunkWaitReason = "TREE_CHUNK_LOADING",
            chunkWaitReturnReason = "tree_chunk_loading_for_output",
            moveReason = "lumber_output",
            getSquare = Service.GetSquare,
            markDirty = markDirty,
            onUpdate = function(rec, currentJob)
                updateRuntime(rec, currentJob, treeForOutput(currentJob, output))
            end,
        })
    if complete then
        job.outputTreeKey = nil
        if reason == "work_output_already_delivered" then
            return true, true, "lumber_output_already_delivered"
        elseif reason == "work_output_deposited" then
            return true, true, "lumber_output_deposited"
        end
    end
    return ok, complete, reason
end

Internal.ReleaseOutputCapacity = function(job)
    OutputService.ReleaseOutputCapacity(job, PNC.ColonyStorageService)
end

return Service
