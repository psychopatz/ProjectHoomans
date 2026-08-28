local T = require "tests/support/test"

T.addPackagePaths({ { "PsychopatzCore", "common" } })
PsychopatzCore = { Events = { _listeners = {} } }
local Events = T.load("PsychopatzCore", "common",
    "PsychopatzCore/Events/PC_EventBus.lua")
local owner = {}
local calls, lateCalls = 0, 0
local listener
listener = function()
    calls = calls + 1
    Events.unsubscribe("test", listener)
    Events.subscribe("test", function() lateCalls = lateCalls + 1 end, owner)
end

T.truthy(Events.subscribe("test", listener, owner),
    "event listener registers")
T.truthy(Events.subscribe("test", listener, owner),
    "duplicate registration is idempotent")
T.equal(Events.getListenerCount("test"), 1,
    "duplicate registration does not multiply delivery")
T.equal(Events.emit("test"), 1,
    "stable snapshot delivers the original listener")
T.equal(calls, 1, "listener runs once")
T.equal(lateCalls, 0, "listeners added during emit wait for next emit")
T.equal(Events.emit("test"), 1, "new snapshot delivers the new listener")
T.equal(lateCalls, 1, "new listener runs on the next emit")
T.equal(Events.clearOwner(owner), 1, "owner cleanup removes subscriptions")

T.finish("pnc_event_bus_smoke")
