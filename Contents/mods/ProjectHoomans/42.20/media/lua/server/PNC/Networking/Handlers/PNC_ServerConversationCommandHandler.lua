-- Conversation network adapter. Conversation services retain all authority.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Scene = PNC.ConversationScene

local function handleScene(player, args, command)
    Scene.HandleClientCommand(player, command, args)
end

if Scene then
    Router.Register(Scene.CMD_BEGIN, function(player, args)
        handleScene(player, args, Scene.CMD_BEGIN)
    end)
    Router.Register(Scene.CMD_END, function(player, args)
        handleScene(player, args, Scene.CMD_END)
    end)
    Router.Register(Scene.CMD_CEASEFIRE, function(player, args)
        handleScene(player, args, Scene.CMD_CEASEFIRE)
    end)
end

Router.Register(Const.CMD_CONVERSATION_CATEGORY_REQUEST, function(player, args)
    local conversation = PNC.Conversation
    if conversation and conversation.Authority then
        conversation.Authority.HandleCategory(player, args)
    end
end)

Router.Register(Const.CMD_CONVERSATION_CHOICE_REQUEST, function(player, args)
    local conversation = PNC.Conversation
    if conversation and conversation.Authority then
        conversation.Authority.HandleChoice(player, args)
    end
end)

Router.Register(Const.CMD_CONVERSATION_RECRUIT_REQUEST, function(player, args)
    local conversation = PNC.Conversation
    if conversation and conversation.Authority then
        conversation.Authority.HandleRecruit(player, args)
    end
end)
