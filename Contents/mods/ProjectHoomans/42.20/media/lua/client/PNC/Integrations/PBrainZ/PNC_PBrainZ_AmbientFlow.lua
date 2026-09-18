-- Best-effort ambient social flavor requests.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local State = Internal.State
local Runtime = Internal.Runtime
local AmbientPackets = Internal.AmbientPackets
local AmbientFlow = Internal.AmbientFlow or {}
Internal.AmbientFlow = AmbientFlow

function Integration.SubmitAmbientFlavor(item, callback)
    if not Runtime.IsBridgeEnabled() then return false, "bridge_disabled" end
    if State.Pending or #State.PendingQueue > 0 or State.AmbientPending then
        return false, "llm_request_pending"
    end
    if type(item) ~= "table" or type(callback) ~= "function" then
        return false, "ambient_request_invalid"
    end
    State.serial = State.serial + 1
    local requestID = "pnc_ambient_llm_" .. tostring(Runtime.Now()) .. "_"
        .. tostring(State.serial)
    State.AmbientPending = {
        requestID = requestID,
        eventID = tostring(item.eventID or ""),
        npcID = tostring(item.speakerID or ""),
        packet = AmbientPackets.Build(item, requestID),
        callback = callback,
        claimed = false,
    }
    Runtime.Log(
        "ambient_request_queued",
        "npc=" .. State.AmbientPending.npcID
            .. " event=" .. State.AmbientPending.eventID
            .. " request=" .. requestID
    )
    return true, requestID
end

function Integration.CancelAmbientFlavor(eventID)
    if State.AmbientPending
        and tostring(State.AmbientPending.eventID or "")
            == tostring(eventID or "")
    then
        Runtime.Log("ambient_request_cancelled", "event=" .. tostring(eventID))
        State.AmbientPending = nil
        return true
    end
    return false
end

function AmbientFlow.Poll()
    if not State.AmbientPending or State.AmbientPending.claimed then
        return { status = "idle" }
    end
    State.AmbientPending.claimed = true
    Runtime.Log(
        "ambient_task_polled",
        "npc=" .. tostring(State.AmbientPending.npcID)
            .. " request=" .. tostring(State.AmbientPending.requestID)
    )
    return State.AmbientPending.packet
end

function AmbientFlow.HandleDelivery(arguments)
    local ambient = State.AmbientPending
    local requestID = tostring(arguments and arguments.request_id or "")
    if not ambient or ambient.requestID ~= requestID or not ambient.claimed then
        return nil
    end
    State.AmbientPending = nil
    local response = Runtime.CleanResponseText(arguments.response_text)
    response = Runtime.EnforceAmbientNamePolicy(response, ambient.packet)
    if response ~= "" then
        ambient.callback(response, {
            ttsManaged = arguments.tts_managed == true,
        })
        Runtime.Log(
            "ambient_response_delivered",
            "npc=" .. tostring(ambient.npcID)
                .. " event=" .. tostring(ambient.eventID)
                .. " chars=" .. tostring(#response)
        )
        return { accepted = true, presentation = "social_flavor" }
    end
    Runtime.Log(
        "ambient_response_empty",
        "npc=" .. tostring(ambient.npcID)
            .. " event=" .. tostring(ambient.eventID)
    )
    return { accepted = false, reason = "ambient_response_empty" }
end

return AmbientFlow
