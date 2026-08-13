local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
assertEqual(Router.Handle("conversationBegin", player, sceneArgs), true,
    "scene begin handled")
assertEqual(received.scene.command, "conversationBegin", "scene command")
assertEqual(received.scene.args, sceneArgs, "scene payload")

assertEqual(Router.Handle("conversationEnd", player, nil), true,
    "scene end handled")
assertEqual(type(received.scene.args), "table", "scene nil payload normalized")

local categoryArgs = { categoryID = "projecthoomans:whats_up" }
assertEqual(Router.Handle(
    "ConversationCategoryRequest",
    player,
    categoryArgs
), true, "category handled")
assertEqual(received.category.args, categoryArgs, "category payload")

local choiceArgs = { choiceID = "detail" }
assertEqual(Router.Handle(
    "ConversationChoiceRequest",
    player,
    choiceArgs
), true, "choice handled")
assertEqual(received.choice.args, choiceArgs, "choice payload")

local recruitArgs = { npcID = "npc-1" }
assertEqual(Router.Handle(
    "ConversationRecruitRequest",
    player,
    recruitArgs
), true, "recruit handled")
assertEqual(received.recruit.args, recruitArgs, "recruit payload")

PNC.Conversation = nil
assertEqual(Router.Handle(
    "ConversationCategoryRequest",
    player,
    {}
), true, "missing optional Authority still consumes command")

print("pnc_server_conversation_command_handler_smoke: ok")
