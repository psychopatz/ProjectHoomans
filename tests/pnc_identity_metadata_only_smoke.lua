local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

package.preload["PsychopatzCore/Inventory/PsychopatzPortableItemState"] =
    function()
        return {}
    end

local bumpCalls = 0
PNC = {
    Inventory = {
        Internal = {
            normalizeString = function(value)
                if value == nil or value == "" then return nil end
                return tostring(value)
            end,
            nextItemID = function() return "generated" end,
            removeItemByID = function(inv, itemID)
                if not inv.items[itemID] then return false end
                inv.items[itemID] = nil
                return true
            end,
            bumpRevision = function(record)
                bumpCalls = bumpCalls + 1
                record.inventory.revision =
                    (tonumber(record.inventory.revision) or 0) + 1
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/PNC_Inventory_Items_Construction.lua"
)
local Internal = PNC.Inventory.Internal

local record = {
    id = "npc:metadata",
    inventory = {
        revision = 0,
        persistenceMode = "SEED_ONLY",
        items = {
            legacyCard = {
                id = "legacyCard",
                type = "Base.IDcard",
                templateKey = "tmpl:identity_card:0",
            },
            legacyDogtag = {
                id = "legacyDogtag",
                type = "Base.Necklace_DogTag",
                interactionLockReason = "faction_dogtag",
            },
            vanillaCard = {
                id = "vanillaCard",
                type = "Base.IDcard",
                customName = "ID Card: A survivor",
            },
        },
    },
}

local removed, ids = Internal.removeLegacyIdentityItems(
    record,
    record.inventory,
    { reason = "test" }
)
T.truthy(removed, "legacy identity items are removed")
T.equal(#ids, 2, "only Project Hoomans identity items are selected")
T.falsy(record.inventory.items.legacyCard,
    "legacy identity card is not retained in logical inventory")
T.falsy(record.inventory.items.legacyDogtag,
    "legacy faction dogtag is not retained in logical inventory")
T.truthy(record.inventory.items.vanillaCard,
    "vanilla identity item is preserved")
T.equal(bumpCalls, 1, "metadata cleanup creates one bounded revision")
T.equal(record.inventory.persistenceMode, "BASELINE_DELTA",
    "cleanup remains representable in inventory persistence")

T.finish("pnc_identity_metadata_only_smoke")
