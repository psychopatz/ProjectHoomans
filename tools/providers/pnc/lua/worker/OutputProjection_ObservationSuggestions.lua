-- Suggestion instrumentation projection for an observation.

local Suggestions = {}

function Suggestions.build(context, record, result, semanticContext)
    local Values = context.Values
    local runtime = context.Runtime
    local suggestionsModule = PNC
        and PNC.Semantics
        and PNC.Semantics.DialogueSuggestions
    local suppressInstrumentation = record.type == "preview"
    local previousSuppression = runtime.suppressTranslationInstrumentation
    if suppressInstrumentation then
        runtime.suppressTranslationInstrumentation = true
    end
    local suggestions
    if suggestionsModule and type(suggestionsModule.Build) == "function" then
        local suggestionContext = semanticContext
        local pendingIdentity = record.contextAfter
            and record.contextAfter.dialogue
            and record.contextAfter.dialogue.pendingIdentityExchange
        if pendingIdentity and type(suggestionContext) == "table" then
            suggestionContext = Values.copy(suggestionContext)
            suggestionContext.pendingIdentityExchange = pendingIdentity
            suggestionContext.semanticDialogueContext =
                suggestionContext.semanticDialogueContext
                or Values.copy(record.contextAfter.dialogue)
        end
        local ok, value = pcall(
            suggestionsModule.Build,
            result,
            suggestionContext or record.contextAfter,
            record.messages
        )
        suggestions = ok and value or nil
    end
    runtime.suppressTranslationInstrumentation = previousSuppression
    return suggestions or {
        schemaVersion = 1,
        kind = "semantic_dialogue_suggestions",
        revision = tonumber(result.sequence) or 0,
        turnID = "turn-" .. tostring(tonumber(result.sequence) or 0),
        candidates = {},
        sources = {},
        trace = {
            {
                source = "suggestions",
                status = "unavailable",
                reason = "production_module_unavailable",
                candidateCount = 0,
            },
        },
    }
end

return Suggestions
