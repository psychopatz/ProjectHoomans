local T = require "tests/support/test"

local Registry = T.load("ProjectHoomans", "client",
    "PNC/UI/Orders/PNC_OrdersRegistry.lua")

T.truthy(Registry.Get("fishing"), "fishing order was not registered")
T.equal(Registry.Get("fishing").mapCommand, "fishing_zone",
    "fishing order lost its map workflow")
T.equal(Registry.Get("lumber").job, "Lumber",
    "chop trees order was not mapped to the lumber job")
T.equal(Registry.Get("corpse_haul").mapCommand, nil,
    "corpse hauling should use its automatic workflow")

local future = Registry.Register({
    id = "future_task", order = 90, job = "FutureTask",
})
T.truthy(future, "future order definitions could not be registered")
T.equal(Registry.Get("future_task"), future,
    "registered future order could not be retrieved")
T.equal(Registry.All()[1].id, "fishing",
    "built-in order sort was not stable after extension")

local composition = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
T.contains(composition, "PNC/UI/Orders/PNC_OrdersWindow",
    "Orders window is not in the client composition")
T.contains(composition, "PNC/UI/Orders/PNC_OrdersButton",
    "Orders sidebar button is not in the client composition")

T.finish("pnc_orders_registry_smoke")
