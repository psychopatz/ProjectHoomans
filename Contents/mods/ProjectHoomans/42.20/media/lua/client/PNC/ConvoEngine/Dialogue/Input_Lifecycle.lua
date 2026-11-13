-- Composition hub for the hybrid semantic dialogue input lifecycle.
--
-- Ordered implementation spokes own presentation, navigation, validation,
-- routing, context recording, optional LLM fallback, action dispatch, and
-- response scheduling. The public Input.Internal contract remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Input = PNC.ConvoEngine.DialogueInput or {}
PNC.ConvoEngine.DialogueInput = Input
local ConversationMemory = PNC.ConvoEngine.ConversationMemoryProvider
if type(ConversationMemory) ~= "table" then
    ConversationMemory = require
        "PNC/ConvoEngine/MemoryProvider"
end
if type(ConversationMemory) ~= "table" then
    ConversationMemory = nil
end
local CampSiteHints = require "PNC/Semantics/PNC_SemanticCampSiteHints"
local LocationObservation = PNC.Semantics.LocationObservation
    or require "PNC/Semantics/PNC_SemanticLocationObservation"

local Internal = Input.Internal or {}
Input.Internal = Internal
local DialogueInputTrace = PNC.ConvoEngine.DialogueInputTrace
local audit = DialogueInputTrace.Audit
local traceTurn = DialogueInputTrace.RecordTurn
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/ConvoEngine/Dialogue/Suggestions"
    Suggestions = PNC.ConvoEngine.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}
local InteractionLifecycle = PNC.ConvoEngine.InteractionLifecycle
if type(InteractionLifecycle) ~= "table" then
    local loaded = require
        "PNC/ConvoEngine/Interaction/Lifecycle"
    InteractionLifecycle = type(loaded) == "table" and loaded or nil
end
local Internal = Input.Internal or {}
Input.Internal = Internal
Internal.CampSiteHints = CampSiteHints
Internal.LocationObservation = LocationObservation
Internal.DialogueInputTrace = DialogueInputTrace
Internal.audit = audit
Internal.traceTurn = traceTurn
Internal.Suggestions = Suggestions
Internal.InteractionLifecycle = InteractionLifecycle
Internal.ConversationMemory = ConversationMemory

require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Presentation"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Navigation"
require "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission"

return Internal
