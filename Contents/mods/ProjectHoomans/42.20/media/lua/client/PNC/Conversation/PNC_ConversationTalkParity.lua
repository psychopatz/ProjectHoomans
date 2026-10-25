-- Public native Talk parity entry point.
--
-- The public module path is intentionally stable.  Cohesive target,
-- presentation, payload, and lifecycle concerns are loaded in dependency
-- order so native Talk and the Semantic Lab continue to share one contract.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local TalkParity = PNC.Conversation.TalkParity or {}
PNC.Conversation.TalkParity = TalkParity

local Conversation = PNC.Conversation
local TalkStart = Conversation.TalkStart
    or require "PNC/Conversation/PNC_ConversationTalkStart"
local SpeechDelivery = PNC.Semantics
    and PNC.Semantics.SemanticSpeechDelivery
    or require "PNC/Semantics/PNC_SemanticSpeechDelivery"

TalkParity.VERSION = 1
TalkParity.SCHEMA = "semantic.talk.parity.v1"
TalkParity.Internal = TalkParity.Internal or {}
TalkParity.Internal.TalkStart = TalkStart
TalkParity.Internal.SpeechDelivery = SpeechDelivery
TalkParity.Internal.Conversation = Conversation

require "PNC/Conversation/PNC_ConversationTalkParity_Targets"
require "PNC/Conversation/PNC_ConversationTalkParity_Presentation"
require "PNC/Conversation/PNC_ConversationTalkParity_Payloads"
require "PNC/Conversation/PNC_ConversationTalkParity_Lifecycle"

return TalkParity
