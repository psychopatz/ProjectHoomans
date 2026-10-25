-- Base conversation view specification and production diagnostics.

local Spec = {}

local function choicePresentation(view, authoredChoices)
    local input = PNC.Semantics
        and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal
        and type(internal.PresentSemanticChoices) == "function"
    then
        return internal.PresentSemanticChoices(view, authoredChoices)
    end
    return nil
end

local function choiceInteractionGuard(view)
    local context = view and view.spec and view.spec.context or nil
    return type(context) ~= "table"
        or context.pendingConversationRequest == nil
end

local function attachAuthorityContext(workerContext, spec, scenario, npc)
    local authority = PNC.Conversation and PNC.Conversation.Authority
    if authority and type(authority.BuildContext) == "function" then
        local ok, blockContext = pcall(
            authority.BuildContext,
            workerContext.player,
            npc,
            scenario.conversation and scenario.conversation.token
        )
        if ok and type(blockContext) == "table" then
            spec.context.conversationBlockContext = blockContext
        end
    end
end

local function attachCategoryDiagnostics(spec)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildCategoryDiagnostics) == "function"
        and type(spec.context.conversationBlockContext) == "table"
    then
        local ok, diagnostics = pcall(
            composer.BuildCategoryDiagnostics,
            spec.context.conversationBlockContext
        )
        if ok and type(diagnostics) == "table" then
            spec.context.categoryDiagnostics = diagnostics
        end
    end
end

function Spec.build(workerContext, Conversation, scenario, npc)
    local builtContext = Conversation.buildContext(workerContext)
    if type(scenario.campSiteCandidates) == "table" then
        builtContext.campSiteCandidates = scenario.campSiteCandidates
    end
    if type(scenario.campfireCandidates) == "table" then
        builtContext.campfireCandidates = scenario.campfireCandidates
    end
    if type(scenario.locationObservation) == "table" then
        builtContext.locationObservation = scenario.locationObservation
    end
    local spec = {
        npcID = npc.npcID,
        context = builtContext,
        nodes = { greeting = { choices = {} }, menu = { choices = {} } },
        choicePresentation = choicePresentation,
        choiceInteractionGuard = choiceInteractionGuard,
    }
    attachAuthorityContext(workerContext, spec, scenario, npc)
    attachCategoryDiagnostics(spec)
    return spec
end

return Spec
