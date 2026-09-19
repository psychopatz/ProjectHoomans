local T = require "tests/support/test"
T.addPackagePaths()

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local record = {
    id = "npc-rollback",
    inventory = {
        revision = 4,
        items = {},
        containers = { root = { items = {} } },
    },
    runtime = {},
}
local nativePlayerItem = {
    getID = function() return 55 end,
    getFullType = function() return "Base.Bandage" end,
    isFavorite = function() return false end,
    isEquipped = function() return false end,
}
local nativeCreatedItem = {}
local failCompactRemove = false
local addedItemIDs = {}
local removedItemIDs = {}
local sourceRemovalCalls = 0
local nativeRollbackCalls = 0
local deltaSyncs = 0

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_INVENTORY_RESULT = "InventoryResult",
        INVENTORY_INTERACTION_RADIUS = 3,
        INVENTORY_TRANSFER_MAX_ITEMS = 64,
        INVENTORY_TRANSFER_MAX_QUANTITY = 1024,
        TACTICAL_CLASS_HOSTILE = "hostile",
    },
    Core = { LogWarn = function() end },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
        GetLiveZombie = function() return nil end,
    },
    CompanionCommands = {
        CanPlayerCommand = function() return true, "commandable" end,
    },
    Inventory = {
        EnsureRecordInventory = function(target) return target.inventory end,
        AddItems = function(_, specs)
            local item = specs[1]
            item.id = "npc-added"
            record.inventory.items[item.id] = item
            record.inventory.containers.root.items[1] = item.id
            record.inventory.revision = record.inventory.revision + 1
            addedItemIDs[1] = item.id
            return true, "added", { item.id }
        end,
        RemoveItems = function(_, itemIDs)
            if failCompactRemove then return false, "remove_failed" end
            removedItemIDs = itemIDs
            for _, itemID in ipairs(itemIDs) do
                record.inventory.items[itemID] = nil
                for index = #record.inventory.containers.root.items, 1, -1 do
                    if record.inventory.containers.root.items[index] == itemID then
                        table.remove(record.inventory.containers.root.items, index)
                    end
                end
            end
            record.inventory.revision = record.inventory.revision + 1
            return true, "removed"
        end,
    },
    Network = {
        SendInventoryDelta = function() deltaSyncs = deltaSyncs + 1 end,
        SendCharacterPayload = function() end,
    },
}

PsychopatzCore = {
    Debug = { CanUse = function() return false end },
    RuntimeRole = { AllowsServerCode = function() return true end },
}
sendServerCommand = function() end

package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload["PsychopatzCore/Inventory/PsychopatzItemTransfer"] = function()
    return {
        ResolvePlayerItems = function() return { nativePlayerItem } end,
        DescribeItem = function()
            return {
                fullType = "Base.Bandage",
                state = { condition = 8 },
            }
        end,
        TakeFromPlayer = function()
            sourceRemovalCalls = sourceRemovalCalls + 1
            return false, "source_remove_failed"
        end,
        GiveToPlayerContainer = function()
            return javaList({ nativeCreatedItem })
        end,
        RemoveItem = function(item)
            T.equal(item, nativeCreatedItem, "rollback removes created native item")
            nativeRollbackCalls = nativeRollbackCalls + 1
            return true
        end,
    }
end

local Service = require "PNC/Server/PNC_ServerInventory"
local player = {}

local ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "55" },
    npcContainer = "root",
    inventoryRevision = 4,
    requestId = "source-removal-failure",
})
T.equal(ok, false, "player source-removal failure rejects transfer")
T.equal(reason, "source_remove_failed", "player source-removal failure reason")
T.equal(sourceRemovalCalls, 1, "player source removal was attempted")
T.equal(addedItemIDs[1], "npc-added", "compact item was created before failure")
T.equal(removedItemIDs[1], "npc-added", "rollback removes the added item ID")
T.equal(record.inventory.items["npc-added"], nil,
    "compact item was removed by rollback")
T.equal(#record.inventory.containers.root.items, 0,
    "container membership was restored after rollback")

record.inventory.revision = 9
record.inventory.items["npc-existing"] = {
    id = "npc-existing",
    type = "Base.Axe",
    stack = 1,
    container = "root",
}
record.inventory.containers.root.items[1] = "npc-existing"
failCompactRemove = true
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-existing" },
    playerContainer = "root",
    inventoryRevision = 9,
    requestId = "compact-removal-failure",
})
T.equal(ok, false, "compact-removal failure rejects transfer")
T.equal(reason, "remove_failed", "compact-removal failure reason")
T.equal(nativeRollbackCalls, 1, "created native item was rolled back")
T.equal(record.inventory.items["npc-existing"] ~= nil, true,
    "compact source remains after failed removal")
T.equal(record.inventory.containers.root.items[1], "npc-existing",
    "compact source membership remains after failed removal")
T.equal(deltaSyncs, 0, "failed transfers do not publish inventory deltas")

T.finish("pnc_inventory_transfer_rollback_smoke")
