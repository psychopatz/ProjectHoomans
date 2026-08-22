local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
local sent
local registeredLayer
local gameSpeed = 0
local originalRightClicks = 0
local submenu

local map = {
    playerNum = 0,
    width = 800,
    height = 600,
    getAbsoluteX = function() return 0 end,
    getAbsoluteY = function() return 0 end,
    mapAPI = {
        uiToWorldX = function(_, x) return x + 1000 end,
        uiToWorldY = function(_, _, y) return y + 2000 end,
    },
}

package.preload["ISUI/Maps/ISWorldMap"] = function()
    ISWorldMap = {
        onRightMouseUp = function()
            originalRightClicks = originalRightClicks + 1
            return false
        end,
        close = function() return true end,
        ShowWorldMap = function()
            ISWorldMap_instance = map
        end,
        shouldPause = function() return true end,
    }
    return ISWorldMap
end

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = {
            name = name,
            target = target,
            callback = callback,
        }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(_, child)
        self.submenu = child
    end
    return menu
end

package.preload["ISUI/ISContextMenu"] = function()
    ISContextMenu = {
        get = function()
            local context = newMenu()
            submenu = newMenu()
            context.prebuiltSubmenu = submenu
            return context
        end,
        getNew = function(_, context)
            return context.prebuiltSubmenu
        end,
    }
    return ISContextMenu
end

getGameSpeed = function() return gameSpeed end
setGameSpeed = function(value) gameSpeed = value end

PNC = {
    Const = {
        MAP_COMMAND_MAX_SELECTION = 32,
    },
    Core = {
        Now = function() return 1000 end,
        LogWarn = function() end,
    },
    MapLayers = {
        Register = function(_, definition)
            registeredLayer = definition
            return true
        end,
    },
    Client = {
        CanUseDebug = function() return true end,
        SendMapCommand = function(commandID, npcIds, target, options)
            sent = {
                commandID = commandID,
                npcIds = npcIds,
                target = target,
                options = options,
            }
            return true
        end,
    },
}

T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(FILE .. "PNC_MapCommandRegistry.lua")
T.load(FILE .. "Commands/PNC_MapCommand_Travel.lua")

T.truthy(PNC.MapCommands.OpenForNPC({
    id = "npc:1",
    name = "Map Tester",
    x = 50,
    y = 60,
    z = 0,
}), "command map did not open")
T.truthy(gameSpeed == 1, "command map left single-player simulation paused")
T.truthy(PNC.MapCommands.IsSelected("npc:1"),
    "command map lost the selected NPC")
T.truthy(registeredLayer and registeredLayer.order == 1000,
    "command status did not register as an independent map layer")

setmetatable(map, { __index = ISWorldMap })
T.truthy(map:onRightMouseUp(25, 35) == true,
    "command mode did not consume right click")
T.truthy(originalRightClicks == 0,
    "vanilla debug map context replaced the NPC command context")
T.truthy(submenu and #submenu.options == 1,
    "travel provider did not populate the map context menu")
T.truthy(submenu.options[1].name == "Move Map Tester here",
    "travel context label lost the NPC name")
submenu.options[1].callback()
T.truthy(sent and sent.commandID == "travel"
    and sent.npcIds[1] == "npc:1"
    and sent.target.x == 1025
    and sent.target.y == 2035,
    "map travel provider dispatched the wrong command payload")

map:close()
T.truthy(not PNC.MapCommands.IsSelected("npc:1"),
    "closing the command map retained stale selection")
map:onRightMouseUp(1, 1)
T.truthy(originalRightClicks == 1,
    "normal map right click was not restored after command mode")
T.finish("pnc_map_command_registry_smoke")

T.finish("pnc_map_command_registry_smoke")
