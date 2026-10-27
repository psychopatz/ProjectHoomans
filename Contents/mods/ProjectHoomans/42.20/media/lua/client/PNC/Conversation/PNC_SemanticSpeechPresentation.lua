-- Project Hoomans adapter for the reusable PsychopatzCore social-flavor hub.
-- Provider composition root: shared context, speech/safety, delivery lifecycle.

PNC = PNC or {}
PNC.SemanticSpeechPresentation = PNC.SemanticSpeechPresentation or {}

require "PNC/Conversation/PNC_SemanticSpeechPresentation_Core"
require "PNC/Conversation/PNC_SemanticSpeechPresentation_Speech"
require "PNC/Conversation/PNC_SemanticSpeechPresentation_Delivery"

local SpeechProvider = require
    "PNC/Semantics/PNC_SemanticConversationSpeechProvider"
SpeechProvider.Bind(PNC.SemanticSpeechPresentation)

return PNC.SemanticSpeechPresentation
