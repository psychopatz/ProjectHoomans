local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {}
local received = {}

PNC = {
    Const = {
        CMD_CONVERSATION_CATEGORY_REQUEST = "ConversationCategoryRequest",
        CMD_CONVERSATION_CHOICE_REQUEST = "ConversationChoiceRequest",
        CMD_CONVERSATION_RECRUIT_REQUEST = "ConversationRecruitRequest",
    },
    ConversationScene = {
        CMD_BEGIN = "conversationBegin",
        CMD_END = "conversationEnd",
        CMD_CEASEFIRE = "conversationCeasefire",
        HandleClientCommand = function(receivedPlayer, command, args)
            received.scene = {
                player = receivedPlayer,
                command = command,
                args = args,
            }
        end,
    },
    Conversation = {
        Authority = {
            HandleCategory = function(receivedPlayer, args)
                received.category = { player = receivedPlayer, args = args }
            end,
            HandleChoice = function(receivedPlayer, args)
                received.choice = { player = receivedPlayer, args = args }
            end,
            HandleRecruit = function(receivedPlayer, args)
                received.recruit = { player = receivedPlayer, args = args }
            end,
        },
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerConversationCommandHandler"

local sceneArgs = { npcID = "npc-1", token = "lease-1" }
T.equal(Router.Handle("conversationBegin", player, sceneArgs), true,
    "scene begin handled")
T.equal(received.scene.command, "conversationBegin", "scene command")
T.equal(received.scene.args, sceneArgs, "scene payload")

T.equal(Router.Handle("conversationEnd", player, nil), true,
    "scene end handled")
T.equal(type(received.scene.args), "table", "scene nil payload normalized")

local categoryArgs = { categoryID = "projecthoomans:whats_up" }
T.equal(Router.Handle(
    "ConversationCategoryRequest",
    player,
    categoryArgs
), true, "category handled")
T.equal(received.category.args, categoryArgs, "category payload")

local choiceArgs = { choiceID = "detail" }
T.equal(Router.Handle(
    "ConversationChoiceRequest",
    player,
    choiceArgs
), true, "choice handled")
T.equal(received.choice.args, choiceArgs, "choice payload")

local recruitArgs = { npcID = "npc-1" }
T.equal(Router.Handle(
    "ConversationRecruitRequest",
    player,
    recruitArgs
), true, "recruit handled")
T.equal(received.recruit.args, recruitArgs, "recruit payload")

PNC.Conversation = nil
T.equal(Router.Handle(
    "ConversationCategoryRequest",
    player,
    {}
), true, "missing optional Authority still consumes command")
T.finish("pnc_server_conversation_command_handler_smoke")

T.finish("pnc_server_conversation_command_handler_smoke")
