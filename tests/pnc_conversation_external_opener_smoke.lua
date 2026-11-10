local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    ContextHub = {
        RegisterProvider = function(provider)
            PNC.ContextHub.provider = provider
            return true
        end,
    },
    Conversation = {
        Open = function()
            return { fallback = true }
        end,
    },
    Semantics = {
        SemanticDialogueRuntime = {
            IsEnabled = function() return true end,
        },
    },
}
PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(value) return value.key or "Talk" end,
        },
    },
}

local Openers = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationOpeners.lua"
)
local opened
Openers.Register({
    id = "DT.trader",
    priority = 100,
    canOpen = function(entry) return entry.id == "trader-npc" end,
    open = function(entry, player)
        opened = { entry = entry, player = player }
        return true, "access_requested"
    end,
})

local captured
local menu = {
    addOption = function(_, title, target, callback)
        captured = { title = title, target = target, callback = callback }
        return captured
    end,
}
local Provider = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation.lua"
)
local entry = { id = "trader-npc" }
local player = {}
Provider.addOptions(menu, entry, player)
T.truthy(captured and type(captured.callback) == "function",
    "Talk option was not created")
local result, reason = captured.callback()
T.truthy(result, reason)
T.truthy(opened, "Talk did not try the registered trader opener")
T.equal(opened.entry, entry, "external opener lost the selected NPC")
T.equal(opened.player, player, "external opener lost the player")

T.finish("pnc_conversation_external_opener_smoke")
