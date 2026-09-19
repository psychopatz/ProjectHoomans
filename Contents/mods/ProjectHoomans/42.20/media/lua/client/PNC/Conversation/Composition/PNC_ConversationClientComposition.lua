-- Deterministic client Conversation composition root.
require "PNC/Conversation/PNC_Conversation"

if Events and Events.OnTick and PNC.Conversation
    and PNC.Conversation.Composer
    and not PNC.Conversation.Composer.LocalPumpRegistered
then
    Events.OnTick.Add(PNC.Conversation.Composer.PumpLocalRequests)
    Events.OnTick.Add(PNC.Conversation.Composer.PumpSettlementVisitExpiry)
    PNC.Conversation.Composer.LocalPumpRegistered = true
end

return PNC and PNC.Conversation
