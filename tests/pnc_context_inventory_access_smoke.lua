local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

local function findOption(menu, name)
    for index = 1, #menu.options do
        if menu.options[index].name == name then return menu.options[index] end
    end
    return nil
end

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    return menu
end

local debugAuthorized = false
local registeredProvider
local openedCharacter
local openedInventory
local player = {
    getUsername = function() return "alice" end,
    getOnlineID = function() return 7 end,
}

PNC = {
    Const = { INVENTORY_INTERACTION_RADIUS = 3 },
    Client = {
        CanUseDebug = function() return debugAuthorized end,
    },
    CompanionCommands = {
        IsCompanion = function(record)
            return record and record.recruited == true
        end,
        IsOwnedByPlayer = function(record, targetPlayer)
            return record and targetPlayer
                and record.ownerUsername == targetPlayer:getUsername()
        end,
        CanPlayerCommand = function(record, targetPlayer)
            return record and record.recruited == true
                and record.ownerUsername == targetPlayer:getUsername()
        end,
    },
    ContextHub = {
        RegisterProvider = function(provider)
            registeredProvider = provider
        end,
    },
    CharacterWindow = {
        Toggle = function(id) openedCharacter = id end,
    },
    InventoryWindow = {
        Open = function(id) openedInventory = id end,
    },
}

getText = function(key) return key end

T.load(CLIENT_ROOT
    .. "PNC/UI/Context/Providers/PNC_ContextProvider_Inventory.lua")

local owned = {
    id = "owned",
    snapshot = {
        recruited = true,
        ownerUsername = "alice",
    },
}
local neutral = {
    id = "neutral",
    snapshot = {
        recruited = false,
        tacticalClass = "neutral",
    },
}

T.equal(registeredProvider.isEnabled(owned, player), true,
    "owned companion access hidden outside debug")
local menu = newMenu()
registeredProvider.addOptions(menu, owned, player)
local viewOption = findOption(menu, "View Character")
local inventoryOption = findOption(menu, "Inventory")
T.equal(viewOption ~= nil, true, "owned companion character option")
T.equal(inventoryOption ~= nil, true, "owned companion inventory option")
viewOption.callback()
inventoryOption.callback()
T.equal(openedCharacter, "owned", "owned character target")
T.equal(openedInventory, "owned", "owned inventory target")

T.equal(registeredProvider.isEnabled(neutral, player), false,
    "neutral inventory exposed without debug")
debugAuthorized = true
T.equal(registeredProvider.isEnabled(neutral, player), true,
    "debug neutral inventory access hidden")
menu = newMenu()
registeredProvider.addOptions(menu, neutral, player)
viewOption = findOption(menu, "View Character")
inventoryOption = findOption(menu, "Inventory")
T.equal(viewOption ~= nil, true, "debug neutral character option")
T.equal(inventoryOption ~= nil, true, "debug neutral inventory option")
viewOption.callback()
inventoryOption.callback()
T.equal(openedCharacter, "neutral", "debug character target")
T.equal(openedInventory, "neutral", "debug inventory target")
T.finish("pnc_context_inventory_access_smoke")

T.finish("pnc_context_inventory_access_smoke")
