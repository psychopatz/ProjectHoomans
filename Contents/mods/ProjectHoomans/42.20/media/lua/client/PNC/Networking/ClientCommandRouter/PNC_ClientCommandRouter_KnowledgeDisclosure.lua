-- Client delivery of knowledge disclosure results.

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Memory = Internal.KnowledgeMemory

local function logDisclosure(args, result, reason)
    if not print then return end
    local success = args and (args.success == true
        or tostring(args.success or "") == "true") or false
    print("[PNC][LLM] knowledge_disclosure_received npc="
        .. tostring(args and args.npcID or "")
        .. " topic=" .. tostring(args and (args.topicID or args.topicId) or "")
        .. " success=" .. tostring(success)
        .. " memory=" .. tostring(result == true)
        .. " reason=" .. tostring(reason or ""))
end

Internal.RegisterServerCommand(Const.CMD_KNOWLEDGE_DISCLOSURE, function(args)
    local npcID = args.npcID and tostring(args.npcID) or nil
    local clientState = PNC.Network.ClientState
    local pending = npcID and clientState.pendingDisclosure
        and clientState.pendingDisclosure[npcID] or nil
    if pending and args.requestID and pending ~= args.requestID then return end
    if pending and npcID then clientState.pendingDisclosure[npcID] = nil end
    if args.success and args.presentation then
        Internal.ApplyNPCPresentation(args.presentation)
    elseif args.npcID then
        Internal.ApplyNPCPresentation(args.presentation or {
            npcID = args.npcID, state = "error", reason = args.reason,
        })
    end
    local disclosureSuccess = args.success == true
        or tostring(args.success or "") == "true"
    local topicID = tostring(args.topicID or args.topicId or "")
    local memoryQueued = nil
    local memoryReason = nil
    if disclosureSuccess and topicID == "identity_name" then
        local presentation = args.presentation or {}
        memoryQueued, memoryReason = Memory.EnqueueFirstMeeting(
            args.npcID,
            presentation.displayName or presentation.name,
            args.requestID
        )
    end
    logDisclosure(args, memoryQueued, memoryReason)
    if PNC.Conversation and PNC.Conversation.ReceiveDisclosureResult then
        PNC.Conversation.ReceiveDisclosureResult(args)
    end
end)

return Internal
