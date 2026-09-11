local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local lastValue
local owner = { id = "npc-1" }
PNC = {
    NeedsDebug = {
        Internal = { Copy = function(value) return value end },
        BuildSnapshot = function(_, _, action) return action end,
    },
    Registry = {
        Get = function(id) return id == owner.id and owner or nil end,
    },
    IndividualNeeds = {
        Set = function(_, _, value) lastValue = value; return value end,
        Modify = function(_, _, value) lastValue = value; return value end,
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedsDebug/PNC_NeedsDebug_Actions.lua")

PNC.NeedsDebug.PerformAction({
    target = "individual", ownerID = owner.id,
    operation = "set", needType = "hunger", value = 25,
})
T.equal(lastValue, 0.25, "legacy percentage set value is normalized")

PNC.NeedsDebug.PerformAction({
    target = "individual", ownerID = owner.id,
    operation = "modify", needType = "thirst", amount = -10,
})
T.equal(lastValue, -0.10, "legacy percentage modify value is normalized")

PNC.NeedsDebug.PerformAction({
    target = "individual", ownerID = owner.id,
    operation = "set", needType = "fatigue", value = 0.5,
})
T.equal(lastValue, 0.5, "normalized need values remain unchanged")

T.finish("pnc_needs_debug_unit_normalization_smoke")
