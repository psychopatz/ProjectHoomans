-- Composition hub for the hybrid semantic dialogue input lifecycle.
--
-- Ordered implementation spokes own presentation, navigation, validation,
-- routing, context recording, optional LLM fallback, action dispatch, and
-- response scheduling. The public Input.Internal contract remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Conversation/Memory/PNC_ConversationMemory"
require "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local CampSiteHints = require "PNC/Semantics/PNC_SemanticCampSiteHints"
local LocationObservation = PNC.Semantics.LocationObservation
    or require "PNC/Semantics/PNC_SemanticLocationObservation"

local Internal = Input.Internal or {}
Input.Internal = Internal
local DialogueInputTrace = PNC.Semantics.DialogueInputTrace
local audit = DialogueInputTrace.Audit
local traceTurn = DialogueInputTrace.RecordTurn
local Suggestions = PNC.Semantics.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/Semantics/PNC_SemanticDialogueSuggestions"
    Suggestions = PNC.Semantics.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}
local InteractionLifecycle = PNC.Semantics.InteractionLifecycle
if type(InteractionLifecycle) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticInteractionLifecycle"
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

require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Navigation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission"

return Internal
