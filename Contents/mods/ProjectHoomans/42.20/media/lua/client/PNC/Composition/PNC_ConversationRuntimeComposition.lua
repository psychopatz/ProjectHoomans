-- Compose client presentation dependencies before Conversation, then load
-- optional integrations after the runtime is ready.
-- Keep voice registration ahead of Conversation so every appended message
-- can enter Core's optional voice stream.
require "PNC/Integrations/PNC_VoiceGateway"
require "PNC/UI/PNC_NPCTypePalette"
require "PNC/UI/Factions/PNC_FactionPresentation"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"
require "PNC/UI/Context/PNC_ContextHub"
require "PNC/Conversation/Composition/PNC_ConversationClientComposition"
require "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Bridge"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_InlineChat"

return PNC and PNC.Conversation
