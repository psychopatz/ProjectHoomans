local T = require "tests/support/test"

local composition = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
T.falsy(string.find(composition, "PNC/UI/Orders/", 1, true),
    "legacy Orders UI is still in the client composition")
local commandHub = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")
T.falsy(string.find(commandHub, "PNC.OrdersUI", 1, true),
    "command hub still routes through the removed Orders UI")
T.contains(commandHub, 'openZone("lumber")',
    "chop wood is not routed through the zone editor")
T.contains(commandHub, "corpse_haul",
    "corpse haul is missing from the command hub")
T.contains(commandHub, 'openZone("fishing")',
    "fishing is not routed through the zone editor")

T.finish("pnc_orders_registry_smoke")
