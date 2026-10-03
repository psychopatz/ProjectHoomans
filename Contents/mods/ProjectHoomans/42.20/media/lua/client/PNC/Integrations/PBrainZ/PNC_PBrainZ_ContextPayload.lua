-- Context payload assembly for the client-owned PBrainZ snapshot.
--
-- The public facade keeps the stable Context API while source selection, actor
-- identity, history, needs, and tool policy live in focused providers.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Context = PNC.PBrainZ.Context or {}

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Runtime"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ActorIdentity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextActors"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextHistory"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextNeeds"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextTools"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Identity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload_DialogueFacts"
require "PNC/Semantics/PNC_SemanticLLMResult"
require "PNC/Semantics/PNC_SemanticWorldContext"
require "PNC/Semantics/PNC_SemanticDialogueSituation"

local Internal = PNC.PBrainZ.Internal
local Payload = Internal.ContextPayload or {}
Internal.ContextPayload = Payload
local Runtime = Internal.Runtime
local Actors = Internal.ContextActors
local History = Internal.ContextHistory
local Needs = Internal.ContextNeeds
local Tools = Internal.ContextTools
local Message = PsychopatzCore.Conversation.Message
local ToolPolicy = PNC.ConversationLLMTools
local MemoryIdentity = PNC.PBrainZ.Identity
local DialogueFacts = PNC.PBrainZ.ContextPayloadDialogueFacts
local SemanticResult = PNC.Semantics and PNC.Semantics.LLMResult
local WorldContext = PNC.Semantics and PNC.Semantics.WorldContext
local DialogueSituation = PNC.Semantics
    and PNC.Semantics.DialogueSituation


require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload_Helpers"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload_Build"

return Payload
