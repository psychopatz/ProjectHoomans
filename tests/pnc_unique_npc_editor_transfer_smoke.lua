local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "shared" },
})

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function nativeItem(id, fullType, options)
    options = options or {}
    local nested = options.nested
    return {
        getID = function() return id end,
        getFullType = function() return fullType end,
        getDisplayName = function() return fullType end,
        isFavorite = function() return options.favorite == true end,
        isEquipped = function() return options.equipped == true end,
        getItemContainer = function() return nested end,
        getModData = function() return options.modData end,
    }
end

local ordinary = nativeItem("ordinary", "Base.Hotdog")
local favorite = nativeItem("favorite", "Base.Magazine", { favorite = true })
local equipped = nativeItem("equipped", "Base.Katana", { equipped = true })
local identityCard = nativeItem("card", "Base.IDcard")
local bagContents = javaList({ ordinary })
local bag = nativeItem("bag", "Base.Bag", {
    nested = { getItems = function() return bagContents end },
})
local playerItems = { ordinary, favorite, equipped, identityCard, bag }
local player = {
    getInventory = function()
        return { getItems = function() return javaList(playerItems) end }
    end,
    isEquipped = function(_, item) return item == equipped end,
    getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end,
    getWornItems = function() return javaList({}) end,
    getAttachedItems = function() return javaList({}) end,
}

local addedSpecs = {}
local removed = false
local draftRecord = {
    inventory = {
        revision = 0,
        items = {},
        containers = { root = { items = {} } },
    },
}

PNC = {
    Inventory = {
        Internal = {},
        CaptureNativeItem = function(item)
            return {
                type = item:getFullType(),
                stack = 1,
                itemState = { visualTextureChoice = 2 },
            }
        end,
        AddItems = function(_, specs)
            for _, spec in ipairs(specs or {}) do
                addedSpecs[#addedSpecs + 1] = spec
                local id = "copy-" .. tostring(#addedSpecs)
                draftRecord.inventory.items[id] = {
                    id = id,
                    type = spec.type,
                    stack = spec.stack or 1,
                    itemState = spec.itemState,
                    templateKey = spec.templateKey,
                }
                draftRecord.inventory.containers.root.items[#draftRecord
                    .inventory.containers.root.items + 1] = id
            end
            return true, "added", { "copy-" .. tostring(#addedSpecs) }
        end,
        RemoveItems = function()
            removed = true
            return false, "unexpected_player_remove"
        end,
    },
    Equipment = {
        CreateItem = function(fullType)
            return {
                getDisplayName = function() return fullType end,
                getDisplayCategory = function() return "Item" end,
                getTex = function() return nil end,
                getActualWeight = function() return 1 end,
            }
        end,
    },
}

package.preload["PNC/00_PNC_Init"] = function() return PNC end
package.preload["PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"] =
    function()
        return {
            EnsureRuntimeRecord = function() return draftRecord end,
            SyncFromRuntime = function() return true end,
        }
    end
package.preload["PNC/UI/Communities/PNC_ColonyStorageViewModel"] =
    function() return {} end

getSpecificPlayer = function() return player end

T.load("ProjectHoomans", "client", "PNC/UI/Inventory/PNC_InventoryUI_Model.lua")
T.load("ProjectHoomans", "client",
    "PNC/UI/Inventory/PNC_InventoryTransferEndpoint.lua")

local model = PNC.InventoryUIModel
T.equal(model.GetPlayerItemTransferBlockReason(ordinary, player), nil,
    "ordinary item remains transferable")
T.equal(model.GetPlayerItemTransferBlockReason(favorite, player), "favorite",
    "favorite item is protected")
T.equal(model.GetPlayerItemTransferBlockReason(equipped, player), "equipped",
    "equipped item is protected")
T.equal(model.GetPlayerItemTransferBlockReason(bag, player),
    "container_not_empty", "non-empty bag is protected")

local endpoint = PNC.InventoryTransferEndpoint.LocalDraft({})
local ok, reason, details = endpoint:send("to_target", {
    itemIDs = { "ordinary", "favorite", "equipped", "card", "bag" },
}, "root")
T.equal(ok, true, "bulk copy succeeds with valid items present")
T.equal(reason, "added", "bulk copy reports success")
T.equal(#addedSpecs, 1, "bulk copy skips protected items")
T.equal(addedSpecs[1].type, "Base.Hotdog",
    "bulk copy retains the valid item type")
T.equal(details.skippedReasons.favorite, 1,
    "bulk copy reports favorite skip")
T.equal(details.skippedReasons.equipped, 1,
    "bulk copy reports equipped skip")
T.equal(details.skippedReasons.item_off_limits, 1,
    "bulk copy reports forbidden skip")
T.equal(details.skippedReasons.container_not_empty, 1,
    "bulk copy reports container skip")
T.falsy(removed, "local editor copy never removes player items")

for _ = 1, 4 do
    local copied, copiedReason = endpoint:send("to_target", {
        itemIDs = { "ordinary" },
    }, "root")
    T.equal(copied, true, "repeated copy succeeds")
    T.equal(copiedReason, "added", "repeated copy reports success")
end
T.equal(#addedSpecs, 5, "repeated copies increment the NPC quantity")
T.equal(addedSpecs[5].itemState.visualTextureChoice, 2,
    "repeated copies preserve item metadata")
local npcRows = model.BuildNPCRows(
    draftRecord.inventory, "root", {})
T.equal(npcRows[1].groupHeader, true,
    "identical repeated copies are grouped in the NPC list")
T.equal(npcRows[1].stack, 5,
    "NPC list displays repeated copies as quantity five")

T.finish("pnc_unique_npc_editor_transfer_smoke")
