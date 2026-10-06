local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local items = {}
local function item(fullType, modData)
    return {
        getFullType = function() return fullType end,
        getModData = function() return modData end,
    }
end

local managedCard = item("Base.IDcard", {
    PNC_IDCard = true,
    PNC_IDCardNPCId = "npc:one",
})
local managedDogtag = item("Base.Necklace_DogTag", {
    PsychopatzCore_CorpseItemKey = "ProjectHoomans:faction-dogtag:npc:one",
})
local vanillaCard = item("Base.IDcard", {})
items[1], items[2], items[3] = managedCard, managedDogtag, vanillaCard

local container = {
    getItems = function() return javaList(items) end,
    Remove = function(_, target)
        for index = #items, 1, -1 do
            if items[index] == target then table.remove(items, index) end
        end
    end,
}

package.preload["PsychopatzCore/Inventory/PsychopatzCorpseItems"] =
    function()
        return { INJECTION_KEY_FIELD = "PsychopatzCore_CorpseItemKey" }
    end

PNC = {
    BodyLifecycle = {
        Internal = {
            itemFullType = function(value)
                return value and value.getFullType and value:getFullType() or ""
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems_Identity.lua"
)
local Internal = PNC.BodyLifecycle.Internal
local target = { getInventory = function() return container end }
T.equal(Internal.removeManagedIdentityItems(target), 2,
    "managed identity artifacts are removed from the target")
T.equal(#items, 1, "cleanup leaves one unrelated item")
T.equal(items[1], vanillaCard, "vanilla ID card is preserved")

T.finish("pnc_corpse_identity_cleanup_smoke")
