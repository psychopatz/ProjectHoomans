-- Optional knowledge-memory integration boundary.

local Internal = PNC.Client.Internal
local Memory = Internal.KnowledgeMemory or {}
Internal.KnowledgeMemory = Memory

function Memory.GetPipeline()
    if PNC.PBrainZ and PNC.PBrainZ.Memory then
        return PNC.PBrainZ.Memory
    end
    local ok = pcall(require,
        "PNC/Integrations/PBrainZ/PNC_PBrainZ_Memory")
    return ok and PNC.PBrainZ and PNC.PBrainZ.Memory or nil
end

function Memory.QueueSnapshotMemoryPrimitives(snapshot)
    local memory = Memory.GetPipeline()
    if memory and memory.EnqueueSnapshotPrimitives
        and snapshot and snapshot.memory_primitives
    then
        memory.EnqueueSnapshotPrimitives(snapshot.memory_primitives)
    end
end

function Memory.EnqueueFirstMeeting(npcID, displayName, requestID)
    local memory = Memory.GetPipeline()
    if memory and memory.EnqueueFirstMeeting then
        return memory.EnqueueFirstMeeting(npcID, displayName, requestID)
    end
    return nil, nil
end

return Memory
