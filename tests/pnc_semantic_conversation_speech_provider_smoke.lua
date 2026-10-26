local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Provider = T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticConversationSpeechProvider.lua")

T.falsy(Provider.IsBound(), "speech provider starts unbound")
local accepted, reason = Provider.Receive({}, {}, {})
T.falsy(accepted, "unbound speech fails closed")
T.equal(reason, "conversation_speech_presentation_unavailable",
    "unbound speech reports a bounded reason")

local received
local implementation = {
    Receive = function(ambientFlavor, summary, networkArgs)
        received = { ambientFlavor, summary, networkArgs }
        return true, "queued"
    end,
}
local bound, bindReason = Provider.Bind(implementation)
T.truthy(bound, bindReason)
local queued, queueReason = Provider.Receive("ambient", "summary", "network")
T.truthy(queued, "bound speech delegates to Conversation")
T.equal(queueReason, "queued", "bound speech preserves the result")
T.equal(received[1], "ambient", "speech preserves the payload")

T.finish("pnc_semantic_conversation_speech_provider_smoke")
