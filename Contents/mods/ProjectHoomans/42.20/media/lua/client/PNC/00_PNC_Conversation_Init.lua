-- Build 42.20 conversation runtime bootstrap.
require "PNC/Conversation/PNC_Conversation"
require "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation"

if Events and Events.OnTick and PNC.Conversation
    and PNC.Conversation.Composer
    and not PNC.Conversation.Composer.LocalPumpRegistered
then
    Events.OnTick.Add(PNC.Conversation.Composer.PumpLocalRequests)
    PNC.Conversation.Composer.LocalPumpRegistered = true
end
