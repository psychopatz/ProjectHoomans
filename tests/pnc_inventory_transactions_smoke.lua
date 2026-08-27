local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

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
local nativeFavorite = false
local nativeEquipped = false
local nativeItem = {
    getID = function() return 55 end,
    getFullType = function() return "Base.Bandage" end,
    isFavorite = function() return nativeFavorite end,
    isEquipped = function() return nativeEquipped end,
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
local materializedIDs = {}

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
        MaterializeItem = function(_, _, itemID)
            materializedIDs[#materializedIDs + 1] = itemID
            return true, "materialized", function() end
        end,
        ApplyDelta = function(_, ops)
            for _, op in ipairs(ops or {}) do
                if op.op == "update" and record.inventory.items[op.itemID] then
                    if op.stack ~= nil then
                        record.inventory.items[op.itemID].stack = op.stack
                    end
                elseif op.op == "remove" then
                    record.inventory.items[op.itemID] = nil
                end
            end
            record.inventory.revision = record.inventory.revision + 1
            return true, "applied"
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
            T.equal(itemIDs[1], "55", "authoritative player ID")
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

local Service = require "PNC/Server/PNC_ServerInventory"
local player = {}

local ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "55" },
    npcContainer = "root",
    inventoryRevision = 3,
    requestId = "a",
})
T.equal(ok, true, "player-to-NPC success")
T.equal(reason, "transferred_to_npc", "player-to-NPC reason")
T.equal(addedSpecs[1].type, "Base.Bandage", "compact item type")
T.equal(addedSpecs[1].cond, 4, "compact condition")
T.equal(addedSpecs[1].fav, true, "compact favorite state")
T.equal(materializedIDs[1], "npc-new", "live NPC receives native projection")
T.equal(takenIDs[1], "55", "native source removed")
T.equal(deltaSince, 3, "delta starts at client revision")

record.inventory.revision = 8
record.inventory.items["npc-item"].fav = true
record.inventory.items["npc-item"].wornSlot = "Shirt"
record.equipment = {
    wornVisuals = {
        Shirt = {
            fullType = "Base.Axe",
            baseTexture = 2,
            textureChoice = 7,
            decal = "SpiffoLogo",
            tint = { r = 0.9, g = 0.8, b = 0.1 },
        },
    },
}
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "bag-9",
    inventoryRevision = 8,
    requestId = "b",
})
T.equal(ok, true, "NPC-to-player success")
T.equal(reason, "transferred_to_player", "NPC-to-player reason")
T.equal(granted.destination, "bag-9", "player bag destination")
T.equal(granted.fullType, "Base.Axe", "native recreation type")
T.equal(granted.state.condition, 7, "native recreation condition")
T.equal(granted.state.customName, "Trusted Axe", "native recreation custom name")
T.equal(granted.state.favorite, true, "explicit favorite transfer allowed")
T.equal(granted.state.visualFullType, "Base.Axe",
    "native recreation lost visual item identity")
T.equal(granted.state.visualTextureChoice, 7,
    "native recreation lost visual texture")
T.equal(granted.state.visualDecal, "SpiffoLogo",
    "native recreation lost shirt decal")
T.equal(granted.state.visualTintG, 0.8,
    "native recreation lost visual tint")
T.equal(removedIDs[1], "npc-item", "compact source removed")
record.inventory.items["npc-item"].wornSlot = nil

record.inventory.revision = 10
record.inventory.items["npc-item"].stack = 5
record.inventory.items["npc-item"].fav = false
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "root",
    quantity = 2,
    inventoryRevision = 10,
    requestId = "partial",
})
T.equal(ok, true, "partial NPC stack transfer success")
T.equal(reason, "transferred_to_player", "partial NPC stack reason")
T.equal(granted.count, 2, "partial native quantity")
T.equal(record.inventory.items["npc-item"].stack, 3,
    "partial compact stack remainder")

record.inventory.revision = 11
record.inventory.items["npc-item"].interactionLocked = true
record.inventory.items["npc-item"].interactionLockReason = "quest_item"
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "root",
    quantity = 1,
    inventoryRevision = 11,
})
T.equal(ok, false, "off-limits NPC transfer rejected")
T.equal(reason, "item_off_limits", "off-limits transfer reason")
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "drop",
    itemID = "npc-item",
    inventoryRevision = 11,
})
T.equal(ok, false, "off-limits NPC action rejected")
T.equal(reason, "item_off_limits", "off-limits action reason")
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "root",
    inventoryRevision = 11,
    bulk = true,
})
T.equal(ok, false, "off-limits NPC bulk transfer skipped")
T.equal(reason, "no_transferable_items", "off-limits NPC bulk reason")
record.inventory.items["npc-item"].interactionLocked = false
record.inventory.items["npc-item"].interactionLockReason = nil

record.inventory.revision = 12
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 12,
    requestId = "c",
})
T.equal(ok, true, "item action success")
T.equal(reason, "equipped_primary", "item action reason")
T.equal(actionExecuted, "equip_primary", "modular action routed")
T.equal(equipmentRefreshes > 0, true, "live equipment refreshed")

record.inventory.revision = 20
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    inventoryRevision = 19,
})
T.equal(ok, false, "revision conflict rejected")
T.equal(reason, "revision_conflict", "revision conflict reason")
T.equal(fullSyncs, 1, "conflict sends full payload")

canManage = true
nativeFavorite = true
record.inventory.revision = 30
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "55" },
    npcContainer = "root",
    inventoryRevision = 30,
    bulk = true,
})
T.equal(ok, false, "favorite player bulk transfer skipped")
T.equal(reason, "no_transferable_items", "favorite player bulk reason")

nativeFavorite = false
nativeEquipped = false
player.getWornItems = function()
    return javaList({
        { getItem = function() return nativeItem end },
    })
end
record.inventory.revision = 30
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "55" },
    npcContainer = "root",
    inventoryRevision = 30,
    bulk = true,
})
T.equal(ok, false, "worn player bulk transfer skipped")
T.equal(reason, "no_transferable_items", "worn player bulk reason")
player.getWornItems = nil

record.inventory.revision = 31
record.inventory.items["npc-item"].fav = false
record.inventory.items["npc-item"].equipSlot = "primary"
ok, reason = Service.Transfer(player, {
    id = record.id,
    direction = "npc_to_player",
    itemIDs = { "npc-item" },
    playerContainer = "root",
    inventoryRevision = 31,
    bulk = true,
})
T.equal(ok, false, "equipped NPC bulk transfer skipped")
T.equal(reason, "no_transferable_items", "equipped NPC bulk reason")

canManage = false
isServer = function() return true end
player.getAccessLevel = function() return "admin" end
record.inventory.revision = 40
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = 40,
})
T.equal(ok, true, "admin debug inventory edit rejected")
T.equal(reason, "equipped_primary", "admin debug inventory action reason")

player.getAccessLevel = function() return "" end
ok, reason = Service.Action(player, {
    id = record.id,
    actionID = "equip_primary",
    itemID = "npc-item",
    inventoryRevision = record.inventory.revision,
})
T.equal(ok, false, "non-owner rejected")
T.equal(reason, "not_owner", "non-owner reason")
T.finish("pnc_inventory_transactions_smoke")

T.finish("pnc_inventory_transactions_smoke")
