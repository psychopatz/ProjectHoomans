-- Compose client presentation dependencies before Conversation, then load
-- optional integrations after the runtime is ready.
-- Keep voice registration ahead of Conversation so every appended message
-- can enter Core's optional voice stream.
require "PNC/Integrations/PNC_VoiceGateway"
require "PNC/UI/PNC_NPCTypePalette"
require "PNC/UI/Factions/PNC_FactionPresentation"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"
require "PNC/UI/Context/PNC_ContextHub"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/Semantics/PNC_SemanticGiftLifecycle"
require "PNC/Semantics/PNC_SemanticGiftContext"
require "PNC/Compatibility/Mods/Bandits/PNC_Bandits_HoomansFlavorDefinitions"
require "PNC/Compatibility/Mods/Necroa/PNC_Necroa_HoomansFlavorDefinitions"
require "PNC/Conversation/Composition/PNC_ConversationClientComposition"
require "PNC/PNC_ConversationSemantics"

local ConversationSemantics = PNC.ConversationSemantics
if ConversationSemantics
    and type(ConversationSemantics.RegisterConversation) == "function"
then
    ConversationSemantics.RegisterConversation(
        PNC.Conversation, PNC.Conversation.Group, PNC.Conversation.Time)
end

require "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Bridge"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_InlineChat"

return PNC and PNC.Conversation
