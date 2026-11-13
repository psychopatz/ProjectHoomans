-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Suggestions = PNC.ConvoEngine.DialogueSuggestions
local Internal = Suggestions.Internal
local DialogueRuntime = Internal.DialogueRuntime

require "PNC/ConvoEngine/Dialogue/Suggestions_Build_Inputs"
require "PNC/ConvoEngine/Dialogue/Suggestions_Build_Sources"
require "PNC/ConvoEngine/Dialogue/Suggestions_Build_Result"

function Suggestions.Build(result, context, messages)
    if not DialogueRuntime.IsEnabled() then
        return Internal.DisabledSuggestionProjection()
    end

    local state = Internal.PrepareSuggestionBuild(result, context, messages)
    if state.private then
        return Internal.PrivateSuggestionProjection(state)
    end
    Internal.CollectSuggestionBuildSources(state)
    return Internal.FinalizeSuggestionBuild(state)
end

return Suggestions
