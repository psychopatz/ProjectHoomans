local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local WindowBase = {}
function WindowBase:derive()
    local derived = {}
    setmetatable(derived, { __index = self })
    derived.__index = derived
    return derived
end

PsychopatzCore = {
    UI = {
        Window = WindowBase,
        Layout = {},
    },
}

PNC = {
    Network = {
        ClientState = {
            characterPayloads = {},
            snapshots = {},
        },
    },
    InventoryActions = {
        List = function() return {} end,
        IsAvailable = function() return false end,
    },
    Equipment = {
        CreateItem = function(fullType)
            return {
                getDisplayName = function() return fullType end,
                getDisplayCategory = function() return "Item" end,
                getTex = function() return "texture:" .. fullType end,
                getActualWeight = function() return 1 end,
            }
        end,
    },
}

getTexture = function(path) return path end
package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload["ISUI/ISButton"] = function()
    ISButton = {}
    return ISButton
end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

dofile(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryUI_Model.lua")

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return PNC.InventoryUIModel
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_List"] = function()
    ISPNCInventoryList = {}
    return ISPNCInventoryList
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_ContainerList"] = function()
    ISPNCInventoryContainerList = {}
    return ISPNCInventoryContainerList
end

local contextPlayerID
local context = { options = {} }
function context:addOption(label, target, callback)
    self.options[#self.options + 1] = {
        label = label,
        target = target,
        callback = callback,
    }
end

ISContextMenu = {
    get = function(playerID)
        contextPlayerID = playerID
        return context
    end,
}
getMouseX = function() return 120 end
getMouseY = function() return 240 end

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local nestedContainer = {
    getItems = function() return javaList({}) end,
    getCapacityWeight = function() return 0 end,
    getEffectiveCapacity = function() return 18 end,
}
local playerBag = {
    getID = function() return 42 end,
    getFullType = function() return "Base.Bag_DuffelBag" end,
    getDisplayName = function() return "Duffel Bag" end,
    getItemContainer = function() return nestedContainer end,
}
local rootContainer = {
    getItems = function() return javaList({ playerBag }) end,
    getCapacityWeight = function() return 4.5 end,
}
local player = {
    getInventory = function() return rootContainer end,
    getMaxWeight = function() return 12 end,
}
local playerContainers = PNC.InventoryUIModel.BuildPlayerContainers(player)
assertEqual(#playerContainers, 2, "player root and backpack selectors")
assertEqual(playerContainers[1].id, "root", "player root selector first")
assertEqual(playerContainers[2].label, "Duffel Bag", "player backpack selector")
assertEqual(PNC.InventoryUIModel.FindContainer(playerContainers, "missing"), nil,
    "missing container does not masquerade as root")

local npcContainers = PNC.InventoryUIModel.BuildNPCContainers({
    items = {
        npc_bag = {
            id = "npc_bag",
            type = "Base.Bag_DuffelBag",
            customName = "Work Bag",
            bagContainer = "bag_npc_bag",
        },
    },
    containers = {
        root = { items = {} },
        bag_npc_bag = { items = {}, maxWeight = 18 },
    },
})
assertEqual(#npcContainers, 2, "NPC root and backpack selectors")
assertEqual(npcContainers[2].label, "Work Bag", "NPC backpack selector")

dofile(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryWindow.lua")

local window = setmetatable({}, { __index = ISPNCInventoryWindow })
window:showItemContext("player", { id = "player_item_1" })
assertEqual(contextPlayerID, 0, "context menu receives numeric player ID")
assertEqual(#context.options, 1, "player transfer context option")

window.playerContainers = {
    { id = "root" },
    { id = "bag_1" },
}
window.selectedPlayerContainer = "root"
window.refreshInventory = function(self, force)
    self.refreshForced = force
end
assertEqual(window:selectContainer("player", "bag_1"), true, "select player bag")
assertEqual(window.selectedPlayerContainer, "bag_1", "selected player bag retained")
assertEqual(window.refreshForced, true, "container selection refresh")
window:cycleContainer("player", 1)
assertEqual(window.selectedPlayerContainer, "root", "container wheel cycles forward")
window:cycleContainer("player", -1)
assertEqual(window.selectedPlayerContainer, "bag_1", "container wheel cycles backward")

print("pnc_inventory_ui_smoke: ok")
