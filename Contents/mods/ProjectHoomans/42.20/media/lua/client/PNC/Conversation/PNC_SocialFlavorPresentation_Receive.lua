-- Client-side ambient social flavor receiver coordinator.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}
PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}

local Presentation = PNC.SocialFlavorPresentation
local H = PNC.SocialFlavorPresentationInternal
local InteractionPresentationRegistry = require
    "PNC/Conversation/PNC_SemanticInteractionPresentationRegistry"
if not H.Clean then return Presentation end

local Client = PsychopatzCore.SocialFlavorClient
local currentTime = H.CurrentTime

require "PNC/Conversation/PNC_SocialFlavorPresentation_Receive_Context"
require "PNC/Conversation/PNC_SocialFlavorPresentation_Receive_Payload"

function Presentation.Receive(ambientFlavor, summary, networkArgs)
    local receive, reason = H.BuildReceiveContext(
        ambientFlavor,
        summary,
        networkArgs
    )
    if not receive then return false, reason end
    H.EnrichReceiveContext(receive)
    InteractionPresentationRegistry.Remember(
        receive.eventID,
        receive.ambientFlavor.interaction
            or receive.context and receive.context.interaction
    )
    local accepted, enqueueReason = Client.Enqueue(
        H.BuildReceivePayload(receive)
    )
    reason = enqueueReason
    if accepted == true and ambientFlavor.pumpImmediately == true
        and type(Client.Pump) == "function"
    then
        local delivered, deliveryReason = Client.Pump(currentTime())
        if delivered == true then
            reason = deliveryReason or reason
        end
    end
    H.Log("received", "event=" .. receive.eventID
        .. " npc=" .. receive.npcID
        .. " role=" .. receive.role
        .. " accepted=" .. tostring(accepted == true)
        .. " reason=" .. tostring(reason or ""))
    return accepted, reason
end

return Presentation
