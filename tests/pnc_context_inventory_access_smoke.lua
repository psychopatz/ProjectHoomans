local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

dofile(CLIENT_ROOT
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
        faction = "neutral",
    },
}

assertEqual(registeredProvider.isEnabled(owned, player), true,
    "owned companion access hidden outside debug")
local menu = newMenu()
registeredProvider.addOptions(menu, owned, player)
local viewOption = findOption(menu, "View Character")
local inventoryOption = findOption(menu, "Inventory")
assertEqual(viewOption ~= nil, true, "owned companion character option")
assertEqual(inventoryOption ~= nil, true, "owned companion inventory option")
viewOption.callback()
inventoryOption.callback()
assertEqual(openedCharacter, "owned", "owned character target")
assertEqual(openedInventory, "owned", "owned inventory target")

assertEqual(registeredProvider.isEnabled(neutral, player), false,
    "neutral inventory exposed without debug")
debugAuthorized = true
assertEqual(registeredProvider.isEnabled(neutral, player), true,
    "debug neutral inventory access hidden")
menu = newMenu()
registeredProvider.addOptions(menu, neutral, player)
viewOption = findOption(menu, "View Character")
inventoryOption = findOption(menu, "Inventory")
assertEqual(viewOption ~= nil, true, "debug neutral character option")
assertEqual(inventoryOption ~= nil, true, "debug neutral inventory option")
viewOption.callback()
inventoryOption.callback()
assertEqual(openedCharacter, "neutral", "debug character target")
assertEqual(openedInventory, "neutral", "debug inventory target")

print("pnc_context_inventory_access_smoke: ok")
