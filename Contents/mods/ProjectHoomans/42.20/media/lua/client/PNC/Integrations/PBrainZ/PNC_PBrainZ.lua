-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
-- This is the single Project Zomboid entry point for the PBrainZ
-- integration. The implementation is split into ordered, role-based spokes.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PsychopatzCore/Conversation/PsychopatzNameParts"
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Conversation/PNC_ConversationLLMTools"
require "PNC/Conversation/PNC_ConversationToolReplies"
require "PNC/Integrations/PNC_VoiceGateway"
require "PNC/UI/Nameplates/PNC_NameplateSpeech"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.PBrainZ = PNC.PBrainZ or {}

local Integration = PNC.PBrainZ
Integration.Internal = Integration.Internal or {}

require "PNC/Integrations/PBrainZ/PNC_PBrainZ_State"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Layout"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Runtime"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Identity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Outbox"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Memory"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ConversationMemorySync"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Context"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Packets"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_RequestMemory"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_RequestAdmission"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_RequestSession"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ActorIdentity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_AmbientContext"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_AmbientPackets"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_RequestFlow"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_AmbientFlow"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ToolFlow"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_SemanticResult"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_SocialTool"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_KnowledgeTool"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_CommandTool"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ResponsePresentation"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ResponseFallback"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ResponseDelivery"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_SpeechFlow"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Transport"

return Integration
