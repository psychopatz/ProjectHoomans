local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates.lua"
)

T.contains(source, "nativeWornSlot",
    "canonical Dynamic Trading clothing resolves native body locations")
T.contains(source, "created:getBodyLocation()",
    "canonical clothing probes the engine item body location")
T.contains(source, "wornSlot = nativeWornSlot",
    "canonical inventory does not forward compact slot aliases to live NPCs")

T.finish("pnc_dynamic_trading_canonical_slot_smoke")
