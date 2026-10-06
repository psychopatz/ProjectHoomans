local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

local function probe(fullType)
    return {
        name = fullType,
        category = "Identity",
        texture = "texture:" .. fullType,
        weight = 1,
        conditionMax = nil,
    }
end

package.preload[
    "PNC/UI/Inventory/PNC_InventoryUI_Model/_Native"
] = function()
    return {
        probe = probe,
        isNPCDepositForbidden = function() return false end,
        tooltipModel = { StateSignature = function() return "state" end },
        tooltipOptions = { modelOptions = {} },
        rootInventoryTexture = "root",
        currency = nil,
        newCurrencyRow = function() end,
        addCurrencyValue = function() end,
    }
end

PNC = { InventoryUIModel = {} }
PNC.InventoryUIModel.GroupRows = function(rows) return rows end

T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Inventory/PNC_InventoryUI_Model/_NPCRows.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Inventory/PNC_InventoryUI_Model/_Grouping.lua"
)

local rows = PNC.InventoryUIModel.BuildNPCRows({
    identityMetadata = {
        npcId = "npc:ui",
        displayName = "Curt patz",
        factionID = "faction:one",
        factionName = "Project Hoomans",
    },
    items = {},
    containers = { root = { items = {} } },
}, "root", {})

local byName = {}
for _, row in ipairs(rows) do byName[row.name] = row end
local card = byName["ID Card: Curt patz"]
local dogtag = byName["Dog Tags: Project Hoomans"]
T.truthy(card, "identity card is represented in the inventory UI")
T.truthy(dogtag, "faction dogtag is represented in the inventory UI")
T.truthy(card.virtual and card.restricted,
    "identity card row is virtual and non-transferable")
T.truthy(dogtag.virtual and dogtag.restricted,
    "dogtag row is virtual and non-transferable")
T.falsy(PNC.InventoryUIModel.BuildTransferSelection(card),
    "virtual identity row cannot create a transfer selection")

T.finish("pnc_inventory_identity_ui_smoke")
