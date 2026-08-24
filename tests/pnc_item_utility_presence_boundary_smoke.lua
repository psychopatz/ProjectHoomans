local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/") .. "Supply/"
local entry = T.read(ROOT .. "PNC_ItemUtility.lua")
local providers = ROOT .. "ItemUtility/"
local core = T.read(providers .. "PNC_ItemUtility_Core.lua")
local profiles = T.read(providers .. "PNC_ItemUtility_StaticProfiles.lua")
local descriptors = T.read(providers .. "PNC_ItemUtility_Descriptors.lua")

T.contains(entry, "PNC.ItemUtility.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.ProbeFor",
    "safe item probing stays behind the internal boundary")
T.contains(profiles, "function Utility.GetStatic",
    "static item profiles remain available")
T.contains(descriptors, "function Utility.DescribeCoreRecord",
    "runtime item descriptors remain available")
T.falsy(string.find(entry, "function Utility.GetStatic", 1, true),
    "entry contains wiring rather than implementation")
