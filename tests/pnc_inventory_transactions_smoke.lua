local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/server/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"
package.path = SERVER_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local record = {
    id = "npc-1",
    inventory = {
        revision = 3,
        items = {
            ["npc-item"] = {
                id = "npc-item",
                type = "Base.Axe",
                stack = 1,
                cond = 7,
                itemState = { customName = "Trusted Axe" },
            },
        },
    },
}
local nativeItem = {
    getID = function() return 55 end,
    getFullType = function() return "Base.Bandage" end,
}
local nativeCreated = {
    getContainer = function() return {} end,
}
local sent = {}
local deltaSince
local fullSyncs = 0
local addedSpecs
local removedIDs
local takenIDs
local granted
local actionExecuted
local equipmentRefreshes = 0
local canManage = true

sendServerCommand = function(_, module, command, payload)
    sent[#sent + 1] = { module = module, command = command, payload = payload }
end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_INVENTORY_RESULT = "InventoryResult",
        INVENTORY_INTERACTION_RADIUS = 3,
        INVENTORY_TRANSFER_MAX_ITEMS = 64,
    },
    Registry = {
        Get = function(id) return id == record.id and record or nil end,
        GetLiveZombie = function()
            return {
                getSquare = function() return {} end,
            }
        end,
    },
    CompanionCommands = {
        CanPlayerCommand = function()
            return canManage, canManage and "commandable" or "not_owner"
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(target) return target.inventory end,
        AddItems = function(_, specs)
            addedSpecs = specs
            record.inventory.revision = record.inventory.revision + 1
            return true, "added", { "npc-new" }
        end,
        RemoveItems = function(_, itemIDs)
            removedIDs = itemIDs
            record.inventory.revision = record.inventory.revision + 1
            return true, "removed"
        end,
    },
    InventoryActions = {
        Execute = function(actionID)
            actionExecuted = actionID
            record.inventory.revision = record.inventory.revision + 1
            return true, "equipped_primary"
        end,
    },
    Network = {
        SendInventoryDelta = function(_, _, since)
            deltaSince = since
            return true
        end,
        SendCharacterPayload = function()
            fullSyncs = fullSyncs + 1
        end,
    },
    Equipment = {
        Apply = function()
            equipmentRefreshes = equipmentRefreshes + 1
            return true
        end,
    },
}

package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload["PsychopatzCore/Inventory/PsychopatzItemTransfer"] = function()
    return {
        ResolvePlayerItems = function(_, itemIDs)
            assertEqual(itemIDs[1], "55", "authoritative player ID")
            return { nativeItem }
        end,
        DescribeItem = function()
            return {
                fullType = "Base.Bandage",
                state = { condition = 4, favorite = true },
            }
        end,
        TakeFromPlayer = function(_, itemIDs)
            takenIDs = itemIDs
            return { nativeItem }
        end,
        GiveToPlayerContainer = function(_, destination, fullType, count, state)
            granted = {
                destination = destination,
                fullType = fullType,
                count = count,
                state = state,
            }
            return javaList({ nativeCreated })
        end,
        RemoveItem = function() return true end,
        DropToSquare = function() return { {} } end,
    }
end

local Service = require "PNC/PNC_ServerInventory"
local player = {}

local ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "55" },
    npcContainer = "root",
    inventoryRevision = 3,
    requestId = "a",
})
assertEqual(ok, true, "player-to-NPC success")
assertEqual(reason, "transferred_to_npc", "player-to-NPC reason")
assertEqual(addedSpecs[1].type, "Base.Bandage", "compact item type")
assertEqual(addedSpecs[1].cond, 4, "compact condition")
assertEqual(takenIDs[1], "55", "native source removed")
assertEqual(deltaSince, 3, "delta starts at client revision")

record.inventory.revision = 8
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "bag-9",
    inventoryRevision = 8,
    requestId = "b",
})
assertEqual(ok, true, "NPC-to-player success")
assertEqual(reason, "transferred_to_player", "NPC-to-player reason")
assertEqual(granted.destination, "bag-9", "player bag destination")
assertEqual(granted.fullType, "Base.Axe", "native recreation type")
assertEqual(granted.state.condition, 7, "native recreation condition")
assertEqual(granted.state.customName, "Trusted Axe", "native recreation custom name")
assertEqual(removedIDs[1], "npc-item", "compact source removed")

record.inventory.revision = 12
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 12,
    requestId = "c",
})
assertEqual(ok, true, "item action success")
assertEqual(reason, "equipped_primary", "item action reason")
assertEqual(actionExecuted, "equip_primary", "modular action routed")
assertEqual(equipmentRefreshes > 0, true, "live equipment refreshed")

record.inventory.revision = 20
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    inventoryRevision = 19,
})
assertEqual(ok, false, "revision conflict rejected")
assertEqual(reason, "revision_conflict", "revision conflict reason")
assertEqual(fullSyncs, 1, "conflict sends full payload")

canManage = false
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 20,
})
assertEqual(ok, false, "non-owner rejected")
assertEqual(reason, "not_owner", "non-owner reason")

print("pnc_inventory_transactions_smoke: ok")
