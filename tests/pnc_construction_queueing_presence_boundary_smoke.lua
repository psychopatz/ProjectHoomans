local T = require "tests/support/test"
local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Production/ConstructionService/"
local entry = T.read(ROOT .. "PNC_ConstructionService_Queueing.lua")
local providers = ROOT .. "ConstructionService_Queueing/"
local build = T.read(providers .. "PNC_ConstructionService_Queueing_Build.lua")
local deconstruct = T.read(providers .. "PNC_ConstructionService_Queueing_Deconstruct.lua")
local reconstruct = T.read(providers .. "PNC_ConstructionService_Queueing_Reconstruct.lua")
T.contains(build, "function Service.QueueBuild", "build queue remains available")
T.contains(deconstruct, "function Service.QueueDeconstruct", "deconstruct queue remains available")
T.contains(reconstruct, "function Service.QueueReconstruct", "reconstruct queue remains available")
T.falsy(string.find(entry, "function Service.QueueBuild", 1, true),
    "entry contains wiring rather than implementation")
