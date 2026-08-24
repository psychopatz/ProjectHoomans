local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")
local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")

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

T.load(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryUI_Model.lua")
T.load(CLIENT_ROOT .. "PNC/UI/Communities/PNC_ColonyStorageViewModel.lua")
local storageRows = PNC.ColonyStorageViewModel.BuildInventoryRows({ rows = {
    { recordIndex = 1, fullType = "Base.Crisps", name = "Crisps",
        quantity = 3, totalWeight = 0.6 },
    { recordIndex = 2, fullType = "Base.Bandage", name = "Bandage",
        quantity = 2, totalWeight = 0.2 },
} }, "", "name", {})
T.equal(storageRows[1].groupHeader, true,
    "storage inventory category header missing")
T.equal(storageRows[2].texture ~= nil, true,
    "storage inventory row texture missing")
local collapsedStorageRows = PNC.ColonyStorageViewModel.BuildInventoryRows({ rows = {
    { recordIndex = 1, fullType = "Base.Crisps", name = "Crisps",
        quantity = 3, totalWeight = 0.6 },
} }, "", "name", { ["storage-category:item"] = true })
T.equal(#collapsedStorageRows, 1,
    "collapsed storage category still exposed child rows")
T.load(SHARED_ROOT .. "PNC/Conversation/PNC_ConversationGifts.lua")
T.equal(PNC.Gifts.IsValidItemType("Base.Crisps"), true,
    "crisps are valid food gifts")
local repeatedGiftEffect = PNC.Gifts.EvaluateEffect({
    "Base.Bandage", "Base.Bandage", "Base.Bandage", "Base.Bandage",
})
T.equal(repeatedGiftEffect.approval, 16,
    "repeated gifts are no longer reputation capped")
T.equal(repeatedGiftEffect.familiarity, 2,
    "repeated gift familiarity remains cumulative")

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
package.preload["PNC/UI/Communities/PNC_ColonyStorageViewModel"] = function()
    return PNC.ColonyStorageViewModel
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
T.equal(#playerContainers, 2, "player root and backpack selectors")
T.equal(playerContainers[1].id, "root", "player root selector first")
T.equal(playerContainers[2].label, "Duffel Bag", "player backpack selector")
T.equal(PNC.InventoryUIModel.FindContainer(playerContainers, "missing"), nil,
    "missing container does not masquerade as root")
local playerRows = PNC.InventoryUIModel.BuildPlayerRows(playerContainers[1], player)
local playerRowsByID = {}
for _, row in ipairs(playerRows) do playerRowsByID[row.id] = row end
T.equal(playerRowsByID["42"].favorite, true, "player favorite row state")
T.equal(playerRowsByID["42"].equipped, true, "player equipped row state")
T.equal(playerRowsByID["43"].equipped, true,
    "player worn item protected even when InventoryItem:isEquipped is false")
local giftRows = PNC.InventoryUIModel.BuildPlayerRows(
    playerContainers[1], player, nil, true
)
T.truthy(#giftRows > 0, "gift mode retains valid equipment gifts")
T.truthy(#giftRows < #playerRows, "gift mode removes ordinary non-gifts")
for _, row in ipairs(giftRows) do
    T.equal(row.giftValid, true, "gift mode filters invalid item rows")
end
local playerAmmoGroup
for _, row in ipairs(playerRows) do
    if row.fullType == "Base.Bullets9mm" then playerAmmoGroup = row end
end
T.equal(playerAmmoGroup.groupHeader, true, "matching player items collapse")
T.equal(playerAmmoGroup.stack, 2, "collapsed player quantity")
local playerAmmoSelection = PNC.InventoryUIModel.BuildTransferSelection(
    playerAmmoGroup,
    1
)
T.equal(#playerAmmoSelection.itemIDs, 1, "partial player selection")
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
T.equal(expandedAmmoCount, 3, "expanded group has header and members")

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
T.equal(#npcContainers, 2, "NPC root and backpack selectors")
T.equal(npcContainers[2].label, "Work Bag", "NPC backpack selector")
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
T.equal(npcRowsByID["npc_bag"].favorite, true, "NPC favorite row state")
T.equal(npcRowsByID["npc_bag"].equipped, true, "NPC equipped row state")
T.equal(npcNailsGroup.stack, 5, "compact NPC stacks combine")
local npcNailsSelection = PNC.InventoryUIModel.BuildTransferSelection(
    npcNailsGroup,
    4
)
T.equal(#npcNailsSelection.itemIDs, 2, "quantity spans compact stacks")
T.equal(npcRowsByID["identity_card"].restricted, true,
    "off-limits item model state")

T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryTransferEndpoint.lua")
package.preload["PNC/UI/Inventory/PNC_InventoryTransferEndpoint"] = function()
    return PNC.InventoryTransferEndpoint
end
T.load(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryWindow.lua")

local storageEndpoint = PNC.InventoryTransferEndpoint.Storage("storage_a")
PNC.Network.ClientState.colonyManagement = { storage = {
    storageId = "storage_a",
    inventoryRevision = 7,
    usedWeight = 4,
    capacity = 200,
    rows = {{
        recordIndex = 3,
        fullType = "Base.Nails",
        name = "Nails",
        quantity = 25,
        totalWeight = 0.25,
    }},
} }
T.equal(storageEndpoint:revision(), 7, "storage endpoint revision")
T.equal(#storageEndpoint:rows(), 2,
    "storage endpoint reuses category inventory rows")
local storageSelection = PNC.InventoryTransferEndpoint.SelectionForRow(
    storageEndpoint,
    storageEndpoint:rows()[2],
    10
)
T.equal(storageSelection.records[1].recordIndex, 3,
    "storage selection retains authoritative record index")
T.equal(storageSelection.records[1].quantity, 10,
    "storage selection retains requested quantity")
storageEndpoint.readOnly = true
local sent, readOnlyReason = storageEndpoint:send(
    "to_target", { itemIDs = { "1" } }, "root")
T.equal(sent, false, "read-only storage endpoint rejects transfer")
T.equal(readOnlyReason, "read_only", "read-only transfer reason")

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
T.equal(#eligibleIDs, 1, "bulk transfer protected-item filtering")
T.equal(eligibleIDs[1], "ordinary", "bulk transfer eligible item")
window:showItemContext("player", { id = "player_item_1" })
T.equal(contextPlayerID, 0, "context menu receives numeric player ID")
T.equal(#context.options, 1, "player transfer context option")

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
T.equal(quantityRequest.maximum, 2, "group transfer opens quantity modal")
quantityRequest.callback(quantityRequest.callbackTarget, 1)
T.equal(window.lastTransfer.quantity, 1, "modal quantity reaches transfer")
T.equal(window.lastTransfer.direction, "player_to_npc",
    "modal preserves transfer direction")

window.playerContainers = {
    { id = "root" },
    { id = "bag_1" },
}
window.selectedPlayerContainer = "root"
window.refreshInventory = function(self, force)
    self.refreshForced = force
end
T.equal(window:selectContainer("player", "bag_1"), true, "select player bag")
T.equal(window.selectedPlayerContainer, "bag_1", "selected player bag retained")
T.equal(window.refreshForced, true, "container selection refresh")
window:cycleContainer("player", 1)
T.equal(window.selectedPlayerContainer, "root", "container wheel cycles forward")
window:cycleContainer("player", -1)
T.equal(window.selectedPlayerContainer, "bag_1", "container wheel cycles backward")

local listSource = T.read(
    "ProjectHoomans", "client", "PNC/UI/Inventory/PNC_InventoryUI_List.lua"
)
T.truthy(string.find(listSource, "media/ui/icon.png", 1, true),
    "vanilla equipped circle texture missing")
T.truthy(string.find(
    listSource, "media/ui/inventoryPanes/FavouriteYes.png", 1, true
),
    "vanilla favorite star texture missing")
T.truthy(string.find(
    listSource,
    "media/ui/inventoryPanes/Button_TreeCollapsed.png",
    1,
    true
), "vanilla collapsed-group texture missing")
T.truthy(string.find(listSource, "row.restricted", 1, true),
    "off-limits row dimming missing")

local modalSource = T.read(
    "ProjectHoomans", "client", "PNC/UI/Inventory/PNC_InventoryQuantityModal.lua"
)
T.truthy(string.find(
    modalSource,
    'require "RadioCom/ISUIRadio/ISSliderPanel"',
    1,
    true
), "quantity modal slider missing")
T.finish("pnc_inventory_ui_smoke")

T.finish("pnc_inventory_ui_smoke")
