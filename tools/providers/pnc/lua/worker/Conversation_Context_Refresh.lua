-- Reprojects the live conversation context after an action.

local Refresh = {}

function Refresh.apply(context, Conversation)
    local Runtime = context.Runtime
    if Runtime.view and Runtime.view.spec then
        local previousContext = Runtime.view.spec.context
        local refreshedContext = Conversation.buildContext(context)
        -- Production BuildDefinition installs menu options containing the
        -- identity/dossier choice closures. Preserve that session-local
        -- authored menu while rebuilding derived context after a rejected or
        -- accepted semantic frame; otherwise a failed click can silently
        -- remove a currently presented native row.
        if type(refreshedContext.conversationMenuOptions) ~= "table"
            and type(previousContext.conversationMenuOptions) == "table"
        then
            refreshedContext.conversationMenuOptions =
                previousContext.conversationMenuOptions
        end
        local previousBlockContext =
            type(previousContext.conversationBlockContext) == "table"
            and previousContext.conversationBlockContext or nil
        local refreshedBlockContext =
            type(refreshedContext.conversationBlockContext) == "table"
            and refreshedContext.conversationBlockContext or nil
        local menuOptions = refreshedContext.conversationMenuOptions
            or previousBlockContext and previousBlockContext.conversationMenuOptions
        if refreshedBlockContext and type(menuOptions) == "table" then
            refreshedBlockContext.conversationMenuOptions = menuOptions
        end
        Runtime.view.spec.context = refreshedContext
        local block = Conversation.blockProjection(Runtime.view)
        Runtime.view.spec.context.conversationBlock = block
        local composer = PNC.Conversation and PNC.Conversation.Composer
        if composer
            and type(composer.BuildSemanticConversationGraphProjection)
                == "function"
        then
            Runtime.view.spec.context.conversationGraph =
                composer.BuildSemanticConversationGraphProjection(Runtime.view)
        else
            Runtime.view.spec.context.conversationGraph = nil
        end
        if block then
            Runtime.view.spec.context.conversationTopic = block.topic
            Runtime.view.spec.context.currentTopic = block.topic
            if type(Runtime.view.spec.context.conversationBlockContext)
                == "table"
            then
                Runtime.view.spec.context.conversationBlockContext.conversationTopic =
                    block.topic
            end
        end
        if composer and type(composer.BuildCategoryDiagnostics) == "function"
            and type(Runtime.view.spec.context.conversationBlockContext) == "table"
        then
            local ok, diagnostics = pcall(
                composer.BuildCategoryDiagnostics,
                Runtime.view.spec.context.conversationBlockContext
            )
            if ok and type(diagnostics) == "table" then
                Runtime.view.spec.context.categoryDiagnostics = diagnostics
            end
        end
        if composer and type(composer.BuildRootNode) == "function"
            and type(Runtime.view.spec.context.conversationBlockContext)
                == "table"
        then
            local ok, root = pcall(
                composer.BuildRootNode,
                Runtime.view.spec.context.conversationBlockContext,
                Runtime.view.spec.context.conversationMenuOptions
                    or Runtime.view.spec.context.conversationBlockContext
                    and Runtime.view.spec.context.conversationBlockContext
                        .conversationMenuOptions
                    or {}
            )
            if ok and type(root) == "table" then
                Runtime.view.spec.nodes.menu = { choices = root.choices or {} }
                if composer
                    and type(composer.BuildSemanticRootProjection)
                        == "function"
                then
                    Runtime.view.spec.context.conversationRoot =
                        composer.BuildSemanticRootProjection(Runtime.view)
                end
                if Runtime.view.session.currentNodeID == "menu" then
                    Runtime.view.session.currentNode =
                        Runtime.view.spec.nodes.menu
                    Runtime.view.session:setChoices(
                        Runtime.view.session.currentNode.choices
                    )
                end
            end
        end
    end
end

return Refresh

