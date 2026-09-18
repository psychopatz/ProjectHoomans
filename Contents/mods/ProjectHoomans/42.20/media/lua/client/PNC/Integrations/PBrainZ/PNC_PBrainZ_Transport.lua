-- Bridge-facing polling and delivery arbitration.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local State = Internal.State
local Runtime = Internal.Runtime
local AmbientFlow = Internal.AmbientFlow
local RequestFlow = Internal.RequestFlow
local ResponseDelivery = Internal.ResponseDelivery
local Transport = Internal.Transport or {}
Internal.Transport = Transport

function Integration.Poll()
    if not State.Pending then
        if not State.AmbientPending or State.AmbientPending.claimed then
            return { status = "idle" }
        end
        return AmbientFlow.Poll()
    end
    if State.Pending.claimed then return { status = "idle" } end
    State.Pending.claimed = true
    Runtime.Log(
        "task_polled",
        "npc=" .. tostring(State.Pending.npcID)
            .. " request=" .. tostring(State.Pending.requestID)
    )
    if Runtime.TraceEnabled() then
        local Trace = PsychopatzCore and PsychopatzCore.DebugTrace
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.request_polled",
            requestID = State.Pending.requestID,
            data = {
                npcID = State.Pending.npcID,
                sessionID = State.Pending.packet
                    and State.Pending.packet.session_id,
            },
        })
    end
    return State.Pending.packet
end

function Integration.Deliver(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local requestID = tostring(arguments.request_id or "")
    local ambientResult = AmbientFlow.HandleDelivery(arguments)
    if ambientResult then return ambientResult end
    if not State.Pending
        or State.Pending.requestID ~= requestID
        or not State.Pending.claimed
    then
        return nil, "NOT_AVAILABLE", "LLM request is no longer active."
    end
    return ResponseDelivery.Deliver(
        State.Pending, arguments
    )
end

return Transport
