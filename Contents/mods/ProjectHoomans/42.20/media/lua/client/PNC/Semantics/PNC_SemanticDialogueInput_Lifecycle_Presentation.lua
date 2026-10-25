-- Internal implementation spoke for semantic dialogue input lifecycle.
-- The public entry point remains PNC_SemanticDialogueInput_Lifecycle.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal

local CampSiteHints = Internal.CampSiteHints
local LocationObservation = Internal.LocationObservation
local DialogueInputTrace = Internal.DialogueInputTrace
local audit = Internal.audit
local traceTurn = Internal.traceTurn
local Suggestions = Internal.Suggestions
local InteractionLifecycle = Internal.InteractionLifecycle

require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation_Interaction"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation_Choices"

return Internal
