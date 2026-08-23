local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua"
)
local prefix = "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations/"
local providers = {
    "PNC_Inventory_Mutations_Delta",
    "PNC_Inventory_Mutations_Items",
    "PNC_Inventory_Mutations_Flags",
    "PNC_Inventory_Mutations_Equipment",
}
local providerFunctions = {
    Delta = { "ApplyDelta" },
    Items = { "CanAccept", "AddItems", "RemoveItems" },
    Flags = { "SetFavorite", "SetInteractionLocked" },
    Equipment = { "SetEquipped", "EquipPrimary", "SetWorn", "ClearWorn" },
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

for provider, functions in pairs(providerFunctions) do
    local providerSource = T.read(
        "ProjectHoomans",
        "shared",
        prefix .. "PNC_Inventory_Mutations_" .. provider .. ".lua"
    )
    for i = 1, #functions do
        T.contains(
            providerSource,
            "function Inventory." .. functions[i],
            provider .. " should own Inventory." .. functions[i]
        )
    end
end

T.finish("pnc_inventory_mutations_presence_boundary_smoke")
