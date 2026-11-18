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
    local npcID = scenarioNpc and (scenarioNpc.npcID or scenarioNpc.id)
        or spec.npcID
    local visitService = PNC.MobileSettlementVisitService
    local activeSettlementVisit = npcID and visitService
        and type(visitService.GetNPCVisit) == "function"
        and visitService.GetNPCVisit(
            npcID,
            workerContext.player,
            Runtime.scenario and Runtime.scenario.world
                and Runtime.scenario.world.worldAgeHours or 0
        ) or nil
    if type(view.spec.context.conversationBlockContext) == "table"
        and (activeSettlementVisit ~= nil
            or (type(scenarioNpc) == "table"
                and type(scenarioNpc.ambientVisitPreview) == "table"))
    then
        if activeSettlementVisit ~= nil then
            view.spec.context.settlementVisit =
                workerContext.Values.copy(activeSettlementVisit)
            view.spec.context.conversationBlockContext.settlementVisit =
                workerContext.Values.copy(activeSettlementVisit)
        end
        if type(scenarioNpc) == "table"
            and type(scenarioNpc.ambientVisitPreview) == "table"
        then
            view.spec.context.conversationBlockContext.ambientVisitPreview =
                workerContext.Values.copy(scenarioNpc.ambientVisitPreview)
        end
        if composer and type(composer.BuildRootNode) == "function" then
            local ok, root = pcall(
                composer.BuildRootNode,
                view.spec.context.conversationBlockContext,
                view.spec.context.conversationMenuOptions
                    or view.spec.context.conversationBlockContext.conversationMenuOptions
                    or {}
            )
            if ok and type(root) == "table" then
                view.spec.nodes.greeting = root
                view.spec.nodes.menu = { choices = root.choices or {} }
                if session.currentNodeID == "greeting" then
                    session.currentNode = view.spec.nodes.greeting
                elseif session.currentNodeID == "menu" then
                    session.currentNode = view.spec.nodes.menu
                end
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
