local T = require "tests/support/test"

local CLIENT =
    T.path("ProjectHoomans", "client", "PNC/")

local function derive(base)
    local child = {}
    child.__index = child
    setmetatable(child, { __index = base })
    return child
end

PsychopatzWindow = {
    derive = function(self)
        return derive(self)
    end,
    initialise = function() end,
    createChildren = function() end,
    prerender = function() end,
    render = function() end,
    new = function(self)
        return setmetatable({}, { __index = self })
    end,
}

local modalOptions
PNC = {
    Network = {
        ClientState = {},
    },
    Core = {
        Now = function() return 100 end,
    },
    FactionEmblemRenderer = {
        Draw = function() return true end,
    },
    FactionMemberModal = {
        Open = function(options)
            modalOptions = options
            return options
        end,
    },
}
PsychopatzCore = {
    UI = {
        Theme = {
            colors = {
                text = { r = 1, g = 1, b = 1, a = 1 },
                textMuted = {
                    r = 0.5, g = 0.5, b = 0.5, a = 1,
                },
            },
        },
        Layout = {
            Pixels = function(value) return value end,
            Ellipsize = function(value) return value end,
        },
    },
}
UIFont = {
    Small = "small",
    Medium = "medium",
}
getText = function(key) return key end

package.preload["PsychopatzCore/UI/PsychopatzUI"] =
    function() return PsychopatzCore.UI end
package.preload[
    "PNC/UI/Factions/PNC_FactionEmblemRenderer"
] = function() return PNC.FactionEmblemRenderer end
package.preload[
    "PNC/UI/Factions/PNC_FactionMemberModal"
] = function() return PNC.FactionMemberModal end

T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(
    CLIENT
        .. "UI/Factions/PNC_FactionMemberWindow.lua"
)

local memberAction
local companionCommand
PNC.Client = {
    SendFactionMemberAction = function(action, playerKey)
        memberAction = {
            action = action,
            playerKey = playerKey,
        }
        return true
    end,
    SendCompanionCommand = function(command, npcID, scope)
        companionCommand = {
            command = command,
            npcID = npcID,
            scope = scope,
        }
        return true
    end,
}

local available = {
    item = {
        id = "player:Alex:char_alex",
        key = "player:Alex:char_alex",
        label = "Alex",
    },
}
local npc = {
    item = {
        id = "npc_1",
        label = "Morgan",
    },
}
local window = {
    availablePlayers = {
        getItem = function() return available end,
    },
    playerMembers = {
        getItem = function() return nil end,
    },
    npcMembers = {
        getItem = function() return npc end,
    },
}
setmetatable(
    window,
    { __index = ISPNCFactionMemberWindow }
)

window:onAction({ internal = "add_player" })
T.equal(modalOptions ~= nil, true, "add opens confirmation modal")
T.equal(
    modalOptions.context.playerKey,
    "player:Alex:char_alex",
    "modal keeps stable player key"
)
modalOptions.onConfirm(modalOptions.context)
T.equal(memberAction.action, "add_player",
    "confirmed add uses membership channel")
T.equal(memberAction.playerKey,
    "player:Alex:char_alex",
    "confirmed add target")

window:onAction({ internal = "follow" })
T.equal(companionCommand.command, "follow",
    "selected NPC quick follow")
T.equal(companionCommand.npcID, "npc_1",
    "selected NPC command target")

window:onAction({ internal = "all_stay" })
T.equal(companionCommand.command, "stay",
    "group quick stay")
T.equal(companionCommand.npcID, nil,
    "group command has no single target")
T.equal(companionCommand.scope, "group",
    "group command scope")
T.finish("pnc_faction_member_ui_smoke")

T.finish("pnc_faction_member_ui_smoke")
