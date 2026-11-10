-- Conversation view session activation and derived projections.

local Finalize = {}

function Finalize.apply(workerContext, Conversation, view, session, spec)
    local Runtime = workerContext.Runtime
    session.view = view
    session.spec = spec
    -- Enter the same production opening node that native Talk enters. The
    -- headless adapter keeps its lightweight session, while the greeting
    -- payload and landing choices still come from the production composer.
    session:enterNode("greeting")
    view.spec.context.conversationBlock = Conversation.blockProjection(view)
    view.spec.context.conversationGraph = Conversation.graphProjection(view)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildSemanticRootProjection) == "function" then
        view.spec.context.conversationRoot =
            composer.BuildSemanticRootProjection(view)
    end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal and type(internal.RefreshRootSuggestions) == "function" then
        local projection = internal.RefreshRootSuggestions(view)
        if projection then
            Runtime.lastSuggestionRevision = tonumber(projection.revision)
                or Runtime.lastSuggestionRevision
        end
    end
    return view
end

return Finalize
