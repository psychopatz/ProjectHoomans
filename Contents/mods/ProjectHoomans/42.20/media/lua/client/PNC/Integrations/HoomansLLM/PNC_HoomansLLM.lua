-- In-game NPC free-text chat over the bounded PsychopatzCore bridge.
-- This is the single Project Zomboid entry point for the HoomansLLM
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
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
Integration.Internal = Integration.Internal or {}

require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_State"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Layout"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Identity"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Outbox"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Memory"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ConversationMemorySync"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Context"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Packets"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_RequestMemory"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_RequestAdmission"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_RequestSession"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ActorIdentity"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_AmbientContext"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_AmbientPackets"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_RequestFlow"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_AmbientFlow"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ToolFlow"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_SemanticResult"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_SocialTool"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_KnowledgeTool"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_CommandTool"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ResponsePresentation"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ResponseFallback"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ResponseDelivery"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_SpeechFlow"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Transport"

return Integration
