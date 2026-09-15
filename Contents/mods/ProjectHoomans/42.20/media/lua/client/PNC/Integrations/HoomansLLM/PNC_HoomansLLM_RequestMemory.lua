-- Optional first-meeting memory side effects for interactive requests.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Runtime = Internal.Runtime
local RequestMemory = Internal.RequestMemory or {}
Internal.RequestMemory = RequestMemory

local function memoryPipeline()
    if Integration.Memory then return Integration.Memory end
    local ok = pcall(require,
        "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Memory")
    return ok and Integration.Memory or nil
end

local function disclosureName(view, npcID)
    local context = view and view.spec and view.spec.context or {}
    local identity = PNC.NPCIdentityPresentation
    if identity and identity.GetDisclosureName and context.entry then
        local name = Runtime.Trim(identity.GetDisclosureName(context.entry))
        if name ~= "" and name ~= identity.UnknownName then return name end
    end
    local state = PNC.Network and PNC.Network.ClientState or {}
    local projection = state.npcPresentations
        and state.npcPresentations[tostring(npcID)] or nil
    local name = projection and (projection.displayName or projection.name)
    if name and Runtime.Trim(name) ~= "" then return Runtime.Trim(name) end
    return Runtime.Trim(context.npcFullName or context.npcName)
end

function RequestMemory.QueueNameQuestion(item, value, inputMessage)
    local memory = memoryPipeline()
    if not memory or not memory.IsNameQuestion
        or not memory.IsNameQuestion(value)
        or not memory.EnqueueFirstMeeting
    then return end
    local view = item and item.view
    local npcID = item and item.npcID or view and view.spec
        and view.spec.npcID or ""
    local context = view and view.spec and view.spec.context or {}
    local name = disclosureName(view, npcID)
    local playerID = context.characterUUID
    if playerID == "unbound" or playerID == "unbound-player" then
        playerID = nil
    end
    local queued, reason = memory.EnqueueFirstMeeting(
        npcID,
        name,
        inputMessage and inputMessage.messageID or item and item.requestID,
        playerID
    )
    Runtime.Log(
        "memory_name_question",
        "npc=" .. tostring(npcID)
            .. " name=" .. tostring(name)
            .. " queued=" .. tostring(queued == true)
            .. " reason=" .. tostring(reason or "")
    )
end

return RequestMemory
