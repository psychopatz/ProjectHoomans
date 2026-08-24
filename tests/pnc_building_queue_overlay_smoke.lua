local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local events
events = {
    OnPreUIDraw = { Add = function(callback) events.render = callback end },
    OnMainMenuEnter = { Add = function(callback) events.reset = callback end },
}
package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return events
end

PNC = { BuildRecipeCatalog = {} }
local Overlay = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingQueueOverlay.lua")
Overlay.Reset()

local queue = {
    { id = "queued", status = "QUEUED", displayName = "Wall", percent = 0,
        blueprint = { objectInfoName = "Wall", x = 10, y = 11, z = 0 } },
    { id = "working", status = "WORKING", displayName = "Door", percent = 50,
        blueprint = { objectInfoName = "Door", x = 12, y = 11, z = 0 } },
    { id = "done", status = "COMPLETED", displayName = "Floor", percent = 100,
        blueprint = { objectInfoName = "Floor", x = 14, y = 11, z = 0 } },
}

Overlay.SetQueue(queue)
T.equal(#Overlay.queue, 2, "overlay excludes completed buildings")
T.falsy(Overlay.IsEnabled(), "queue overlay starts hidden")
T.truthy(Overlay.Toggle(queue), "queue overlay toggles on")
T.truthy(Overlay.IsEnabled(), "queue overlay reports visible")
T.falsy(Overlay.Toggle(queue), "queue overlay toggles off")
T.falsy(Overlay.IsEnabled(), "queue overlay reports hidden")

Overlay.SetQueue({ queue[1] })
T.equal(#Overlay.queue, 1, "queue overlay refreshes from latest snapshot")
T.equal(Overlay.queue[1].id, "queued", "queue overlay retains order identity")
T.truthy(events.render, "queue overlay registers a world draw callback")
T.truthy(events.reset, "queue overlay registers a reset callback")

T.finish("pnc_building_queue_overlay_smoke")
