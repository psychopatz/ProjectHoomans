-- Client-side conversation root-menu coordinator.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local Choices = Internal.MenuRootChoices

if not Choices then return Composer end

function Composer.BuildRootNode(context, options)
    options = type(options) == "table" and options or {}
    context.categoryDiagnostics = Composer.BuildCategoryDiagnostics(context)
    local greeting, greetingBlock = Composer.BuildGreeting(context)
    local choices = Choices.Build(context, options, greetingBlock)
    local greetingNode = greetingBlock
        and greetingBlock.nodes
        and greetingBlock.nodes[greetingBlock.entryNode or "opening"]
        or nil
    return {
        npc = greeting,
        portraitAnimation = greetingNode
            and greetingNode.portraitAnimation or nil,
        choices = choices,
    }
end

return Composer
