PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
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
    local scenarioNpc = Runtime.scenario and Runtime.scenario.npc or nil
    if type(scenarioNpc) == "table"
        and type(scenarioNpc.ambientVisitPreview) == "table"
        and type(view.spec.context.conversationBlockContext) == "table"
    then
        view.spec.context.conversationBlockContext.ambientVisitPreview =
            workerContext.Values.copy(scenarioNpc.ambientVisitPreview)
        if composer and type(composer.BuildRootNode) == "function" then
            local ok, root = pcall(
                composer.BuildRootNode,
                view.spec.context.conversationBlockContext,
                view.spec.context.conversationMenuOptions
                    or view.spec.context.conversationBlockContext.conversationMenuOptions
                    or {}
            )
            if ok and type(root) == "table" then
                view.spec.nodes.menu = { choices = root.choices or {} }
            end
        end
    end
    if composer and type(composer.BuildSemanticRootProjection) == "function" then
        view.spec.context.conversationRoot =
            composer.BuildSemanticRootProjection(view)
    end
    local input = PNC.ConvoEngine and PNC.ConvoEngine.DialogueInput or nil
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
