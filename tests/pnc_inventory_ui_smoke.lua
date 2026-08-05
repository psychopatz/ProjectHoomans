local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"

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
local quantityRequest
package.preload["PNC/UI/Inventory/PNC_InventoryQuantityModal"] = function()
    PNC.InventoryQuantityModal = {
        Open = function(maximum, itemLabel, callbackTarget, callback)
            quantityRequest = {
                maximum = maximum,
                itemLabel = itemLabel,
                callbackTarget = callbackTarget,
                callback = callback,
            }
            return quantityRequest
        end,
    }
    return PNC.InventoryQuantityModal
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
    isFavorite = function() return true end,
    isEquipped = function() return true end,
}
local wornShirt = {
    getID = function() return 43 end,
    getFullType = function() return "Base.Shirt_Denim" end,
    getDisplayName = function() return "Denim Shirt" end,
    isFavorite = function() return false end,
    isEquipped = function() return false end,
}
local ammoOne = {
    getID = function() return 44 end,
    getFullType = function() return "Base.Bullets9mm" end,
    getDisplayName = function() return "9mm Round" end,
    isFavorite = function() return false end,
    isEquipped = function() return false end,
}
local ammoTwo = {
    getID = function() return 45 end,
    getFullType = function() return "Base.Bullets9mm" end,
    getDisplayName = function() return "9mm Round" end,
    isFavorite = function() return false end,
    isEquipped = function() return false end,
}
local rootContainer = {
    getItems = function()
        return javaList({ playerBag, wornShirt, ammoOne, ammoTwo })
    end,
    getCapacityWeight = function() return 4.5 end,
}
local player = {
    getInventory = function() return rootContainer end,
    getMaxWeight = function() return 12 end,
    getWornItems = function()
        return javaList({
            { getItem = function() return wornShirt end },
        })
    end,
}
local playerContainers = PNC.InventoryUIModel.BuildPlayerContainers(player)
assertEqual(#playerContainers, 2, "player root and backpack selectors")
assertEqual(playerContainers[1].id, "root", "player root selector first")
assertEqual(playerContainers[2].label, "Duffel Bag", "player backpack selector")
assertEqual(PNC.InventoryUIModel.FindContainer(playerContainers, "missing"), nil,
    "missing container does not masquerade as root")
local playerRows = PNC.InventoryUIModel.BuildPlayerRows(playerContainers[1], player)
local playerRowsByID = {}
for _, row in ipairs(playerRows) do playerRowsByID[row.id] = row end
assertEqual(playerRowsByID["42"].favorite, true, "player favorite row state")
assertEqual(playerRowsByID["42"].equipped, true, "player equipped row state")
assertEqual(playerRowsByID["43"].equipped, true,
    "player worn item protected even when InventoryItem:isEquipped is false")
local playerAmmoGroup
for _, row in ipairs(playerRows) do
    if row.fullType == "Base.Bullets9mm" then playerAmmoGroup = row end
end
assertEqual(playerAmmoGroup.groupHeader, true, "matching player items collapse")
assertEqual(playerAmmoGroup.stack, 2, "collapsed player quantity")
local playerAmmoSelection = PNC.InventoryUIModel.BuildTransferSelection(
    playerAmmoGroup,
    1
)
assertEqual(#playerAmmoSelection.itemIDs, 1, "partial player selection")
local expandedPlayerRows = PNC.InventoryUIModel.BuildPlayerRows(
    playerContainers[1],
    player,
    { [playerAmmoGroup.groupKey] = true }
)
local expandedAmmoCount = 0
for _, row in ipairs(expandedPlayerRows) do
    if row.fullType == "Base.Bullets9mm" then
        expandedAmmoCount = expandedAmmoCount + 1
    end
end
assertEqual(expandedAmmoCount, 3, "expanded group has header and members")

local npcContainers = PNC.InventoryUIModel.BuildNPCContainers({
    items = {
        npc_bag = {
            id = "npc_bag",
            type = "Base.Bag_DuffelBag",
            customName = "Work Bag",
            bagContainer = "bag_npc_bag",
            fav = true,
            wornSlot = "base:back",
        },
    },
    containers = {
        root = { items = {} },
        bag_npc_bag = { items = {}, maxWeight = 18 },
    },
})
assertEqual(#npcContainers, 2, "NPC root and backpack selectors")
assertEqual(npcContainers[2].label, "Work Bag", "NPC backpack selector")
local npcRows = PNC.InventoryUIModel.BuildNPCRows({
    items = {
        npc_bag = {
            id = "npc_bag",
            type = "Base.Bag_DuffelBag",
            container = "root",
            fav = true,
            wornSlot = "base:back",
        },
        nails_a = {
            id = "nails_a",
            type = "Base.Nails",
            container = "root",
            stack = 2,
        },
        nails_b = {
            id = "nails_b",
            type = "Base.Nails",
            container = "root",
            stack = 3,
        },
        identity_card = {
            id = "identity_card",
            type = "Base.IDcard",
            container = "root",
            interactionLocked = true,
            interactionLockReason = "identity_card",
        },
    },
    containers = {
        root = {
            items = { "npc_bag", "nails_a", "nails_b", "identity_card" },
        },
    },
}, "root")
local npcRowsByID = {}
local npcNailsGroup
for _, row in ipairs(npcRows) do
    npcRowsByID[row.id] = row
    if row.fullType == "Base.Nails" then npcNailsGroup = row end
end
assertEqual(npcRowsByID["npc_bag"].favorite, true, "NPC favorite row state")
assertEqual(npcRowsByID["npc_bag"].equipped, true, "NPC equipped row state")
assertEqual(npcNailsGroup.stack, 5, "compact NPC stacks combine")
local npcNailsSelection = PNC.InventoryUIModel.BuildTransferSelection(
    npcNailsGroup,
    4
)
assertEqual(#npcNailsSelection.itemIDs, 2, "quantity spans compact stacks")
assertEqual(npcRowsByID["identity_card"].restricted, true,
    "off-limits item model state")

dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
dofile(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryWindow.lua")

local window = setmetatable({}, { __index = ISPNCInventoryWindow })
local eligibleIDs = PNC.InventoryWindow.CollectBulkTransferIDs({
    items = {
        { item = { id = "ordinary" } },
        { item = { id = "favorite", favorite = true } },
        { item = { id = "equipped", equipped = true } },
        { item = { id = "locked", restricted = true } },
        { item = playerRowsByID["43"] },
    },
})
assertEqual(#eligibleIDs, 1, "bulk transfer protected-item filtering")
assertEqual(eligibleIDs[1], "ordinary", "bulk transfer eligible item")
window:showItemContext("player", { id = "player_item_1" })
assertEqual(contextPlayerID, 0, "context menu receives numeric player ID")
assertEqual(#context.options, 1, "player transfer context option")

window.npcID = "npc_1"
window.selectedNPCContainer = "root"
window.sendTransfer = function(self, direction, row, destination, quantity)
    self.lastTransfer = {
        direction = direction,
        row = row,
        destination = destination,
        quantity = quantity,
    }
end
window:requestTransfer("player_to_npc", playerAmmoGroup, nil)
assertEqual(quantityRequest.maximum, 2, "group transfer opens quantity modal")
quantityRequest.callback(quantityRequest.callbackTarget, 1)
assertEqual(window.lastTransfer.quantity, 1, "modal quantity reaches transfer")
assertEqual(window.lastTransfer.direction, "player_to_npc",
    "modal preserves transfer direction")

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

local listSource = assert(io.open(
    CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryUI_List.lua",
    "r"
)):read("*a")
assert(string.find(listSource, "media/ui/icon.png", 1, true),
    "vanilla equipped circle texture missing")
assert(string.find(listSource, "media/ui/FavoriteStar.png", 1, true),
    "vanilla favorite star texture missing")
assert(string.find(
    listSource,
    "media/ui/inventoryPanes/Button_TreeCollapsed.png",
    1,
    true
), "vanilla collapsed-group texture missing")
assert(string.find(listSource, "row.restricted", 1, true),
    "off-limits row dimming missing")

local modalSource = assert(io.open(
    CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryQuantityModal.lua",
    "r"
)):read("*a")
assert(string.find(
    modalSource,
    'require "RadioCom/ISUIRadio/ISSliderPanel"',
    1,
    true
), "quantity modal slider missing")

print("pnc_inventory_ui_smoke: ok")
