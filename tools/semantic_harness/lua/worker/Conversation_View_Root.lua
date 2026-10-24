-- Production conversation root resolution with guarded fallback behavior.

local Root = {}

local function productionRoot(workerContext, spec, scenario, player)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    local talkParity = PNC.Conversation
        and PNC.Conversation.TalkParity or nil
    local targetID = scenario.runtime
        and scenario.runtime.semanticLabTalkTarget or "current"
    local entry
    local talkProjection
    if talkParity and type(talkParity.BuildEntry) == "function"
        and type(talkParity.Resolve) == "function"
    then
        entry = select(1, talkParity.BuildEntry(scenario, targetID))
        talkProjection = select(
            1, talkParity.Resolve(scenario, targetID, player)
        )
    end

    local definitionBuilder = PNC.Conversation
        and PNC.Conversation.BuildDefinition or nil
    if type(definitionBuilder) == "function" and type(entry) == "table" then
        local ok, definition = pcall(
            definitionBuilder, entry, player, nil, talkProjection
        )
        if ok and type(definition) == "table"
            and type(definition.nodes) == "table"
            and type(definition.nodes.greeting) == "table"
        then
            -- Keep the production definition's presentation metadata beside
            -- the headless spec. The projection is later built from the live
            -- session rows, while these fields preserve native Talk/opening
            -- and TYPE TO TALK availability without Python reconstruction.
            spec.productionDefinition = definition
            spec.talkStartProjection = definition.talkStartProjection
            spec.extensionParts = definition.extensionParts
            return definition.nodes.greeting
        end
    end
    return nil
end

local function fallbackRoot(workerContext, spec, scenario, npc, player)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if not composer or type(composer.BuildRootNode) ~= "function"
        or type(spec.context.conversationBlockContext) ~= "table"
    then
        return nil
    end
    local menuOptions = spec.context.conversationMenuOptions
    if type(menuOptions) ~= "table" then
        menuOptions = {}
        spec.context.conversationMenuOptions = menuOptions
    end
    local identityChoice = PNC.Conversation
        and PNC.Conversation.IdentityChoice or nil
    local presentation = PNC.Network
        and PNC.Network.ClientState
        and PNC.Network.ClientState.npcPresentations
        and PNC.Network.ClientState.npcPresentations[npc.npcID]
        or nil
    if not menuOptions.askNameChoice
        and identityChoice
        and type(identityChoice.Build) == "function"
        and presentation and presentation.canAskName == true
    then
        menuOptions.askNameChoice = identityChoice.Build(
            npc.npcID,
            presentation,
            {
                playerName = player.displayName or player.forename,
                npcName = npc.forename or npc.displayName,
            }
        )
    end
    local ok, root = pcall(
        composer.BuildRootNode,
        spec.context.conversationBlockContext,
        menuOptions
    )
    return ok and type(root) == "table" and root or nil
end

function Root.resolve(workerContext, spec, scenario, npc, player)
    return productionRoot(workerContext, spec, scenario, player)
        or fallbackRoot(workerContext, spec, scenario, npc, player)
end

return Root
