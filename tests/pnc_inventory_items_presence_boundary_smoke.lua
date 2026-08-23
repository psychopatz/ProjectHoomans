local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items.lua"
)
local prefix =
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items/"
local providers = {
    "PNC_Inventory_Items_State",
    "PNC_Inventory_Items_Metadata",
    "PNC_Inventory_Items_Payloads",
    "PNC_Inventory_Items_Construction",
    "PNC_Inventory_Items_Weights",
}
local publicFunctions = {
    "SanitizeItemState",
    "GetContainerProfile",
    "GetEncumbranceState",
    "RebuildCaches",
}
local internalFunctions = {
    "sanitizeItemState",
    "getContainerProfile",
    "getItemWeight",
    "getItemCapacity",
    "itemToPayload",
    "itemToPersistencePayload",
    "createItem",
    "normalizeLegacyBagSlot",
    "ensureIdentityCard",
    "calculateWeights",
    "getContainerRawWeight",
    "findItemByTemplateKey",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = { Inventory = { Internal = {} } }
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Inventory[functionName]),
        "function",
        "entry point should preserve Inventory." .. functionName
    )
end
for i = 1, #internalFunctions do
    local functionName = internalFunctions[i]
    T.equal(
        type(PNC.Inventory.Internal[functionName]),
        "function",
        "entry point should preserve Internal." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_inventory_items_presence_boundary_smoke")
