-- Compose client presentation dependencies before Conversation, then load
-- optional integrations after the runtime is ready.
-- Keep voice registration ahead of Conversation so every appended message
-- can enter Core's optional voice stream.
require "PNC/Integrations/PNC_VoiceGateway"
require "PNC/UI/PNC_NPCTypePalette"
require "PNC/Conversation/PNC_ConversationTalkParity"
require "PNC/UI/Factions/PNC_FactionPresentation"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"
require "PNC/UI/Context/PNC_ContextHub"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/Semantics/PNC_SemanticGiftLifecycle"
require "PNC/Semantics/PNC_SemanticGiftContext"
require "PNC/Conversation/Composition/PNC_ConversationClientComposition"
require "PNC/Conversation/Semantic/PNC_ConversationSemanticRuntime"
require "PNC/Semantics/PNC_SemanticCombatResponseSurface"
require "PNC/UI/Conversation/PNC_CombatResponseStrip"

local Conversation = PNC.Conversation
local SemanticRuntime = Conversation and Conversation.Semantic
local registrationReason = "semantic_runtime_unavailable"
if SemanticRuntime
    and type(SemanticRuntime.Register) == "function"
then
    local _, reason = SemanticRuntime.Register(
        Conversation, Conversation and Conversation.Group,
        Conversation and Conversation.Time)
    registrationReason = reason
end
if not PNC.Conversation
    or type(PNC.Conversation.CreateSemanticDialogueInput) ~= "function"
then
    local message = "conversation_input_registration_failed reason="
        .. tostring(registrationReason or "factory_unavailable")
    if PNC.Core and type(PNC.Core.LogWarn) == "function" then
        PNC.Core.LogWarn(message)
    elseif type(print) == "function" then
        print("[PNC][WARN] " .. message)
    end
end

require "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Bridge"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_InlineChat"

-- Inline integration loading can populate additional Conversation factories.
-- Re-register the semantic runtime after that boundary so any caller that
-- builds a definition immediately afterward sees the canonical input factory.
if SemanticRuntime
    and type(SemanticRuntime.Register) == "function"
then
    SemanticRuntime.Register(
        Conversation, Conversation and Conversation.Group,
        Conversation and Conversation.Time)
end

return PNC and PNC.Conversation
