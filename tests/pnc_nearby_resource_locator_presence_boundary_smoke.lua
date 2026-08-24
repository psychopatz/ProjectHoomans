local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "World/"
local entry = T.read(ROOT .. "PNC_NearbyResourceLocator.lua")
local providers = ROOT .. "NearbyResourceLocator/"
local core = T.read(providers .. "PNC_NearbyResourceLocator_Core.lua")
local items = T.read(providers .. "PNC_NearbyResourceLocator_Items.lua")
local objects = T.read(providers .. "PNC_NearbyResourceLocator_Objects.lua")

T.contains(entry, "PNC.NearbyResourceLocator.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.Call",
    "safe engine interop stays behind the internal boundary")
T.contains(items, "function Locator.Find",
    "public nearby-item query remains available")
T.contains(objects, "function Locator.FindObject",
    "public nearby-object query remains available")
T.contains(core, "function Locator.Invalidate",
    "public cache invalidation remains available")
T.falsy(string.find(entry, "function Locator.Find(", 1, true),
    "entry contains wiring rather than implementation")
