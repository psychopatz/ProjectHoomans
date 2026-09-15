-- Interactive request admission: recipient expansion, packet creation, and leases.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local State = Internal.State
local Runtime = Internal.Runtime
local Packets = Internal.Packets
local Admission = Internal.RequestAdmission or {}
Internal.RequestAdmission = Admission

function Admission.RecipientViews(view, part)
    local inline = Integration.Inline
    if part and inline and part == inline.part
        and tostring(part.inputMode or "nearest") == "nearby"
        and type(inline.hosts) == "table"
        and #inline.hosts > 0
    then
        return inline.hosts
    end
    return { view }
end

function Admission.Create(view, value)
    State.serial = State.serial + 1
    local requestID = "pnc_llm_" .. tostring(Runtime.Now()) .. "_"
        .. tostring(State.serial)
    local packet = Packets.Build(view, requestID, value)
    local lifecycleState = view and view.spec and view.spec.context
        and view.spec.context.conversationLifecycleState
        or view and view.lifecycleState or nil
    if not packet then return nil end
    if lifecycleState then lifecycleState.llmRequestID = requestID end
    return {
        requestID = requestID,
        npcID = tostring(view.spec and view.spec.npcID or "unknown"),
        view = view,
        packet = packet,
        lifecycleState = lifecycleState,
        claimed = false,
    }
end

function Admission.Reserve(item)
    local client = PNC.Client
    local context = item and item.packet
        and item.packet.conversation_context or {}
    if not client or not client.ReserveLLMRequest then
        return true
    end
    local accepted, reason = client.ReserveLLMRequest(
        item.npcID,
        context.conversation_token,
        item.requestID
    )
    if accepted ~= true then
        Runtime.Log(
            "llm_request_reserve_failed",
            "npc=" .. tostring(item.npcID)
                .. " request=" .. tostring(item.requestID)
                .. " reason=" .. tostring(reason or "rejected")
        )
        return false, reason or "llm_request_reserve_failed"
    end
    Runtime.Log(
        "llm_request_reserved",
        "npc=" .. tostring(item.npcID)
            .. " request=" .. tostring(item.requestID)
            .. " reason=" .. tostring(reason or "reserved")
    )
    return true
end

return Admission
