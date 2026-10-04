local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local hammer = { id = "hammer", fullType = "Base.ClawHammer" }
local rod = { id = "rod", fullType = "Base.FishingRod", cond = 10 }
local body = {
    getPrimaryHandItem = function(self) return self.primary end,
}
body.primary = hammer

local record = {
    id = "npc:fishing-tool",
    equipment = { primaryFullType = "Base.ClawHammer" },
    inventory = {
        items = { hammer = hammer, rod = rod },
        equipped = { primary = "hammer" },
    },
}

PNC = {
    Registry = {
        GetLiveZombie = function() return body end,
    },
    FishingService = { Runtime = {}, Internal = {} },
}

T.load("ProjectHoomans", "server",
    "PNC/Fishing/PNC_FishingService_Job.lua")

local resolve = PNC.FishingService.Internal.ResolveFishingTool
local missing = resolve(record, "rod")
T.equal(missing.fullType, "Base.FishingRod", "rod is found in inventory")
T.equal(missing.reason, "fishing_tool_not_equipped",
    "hammer primary reports the real fishing handoff reason")
T.falsy(missing.ready, "hammer primary cannot start fishing")

record.inventory.equipped.primary = "rod"
body.primary = rod
local ready = resolve(record, "rod")
T.truthy(ready.ready, "equipped rod is accepted by the resolver")
T.equal(ready.nativePrimary, "Base.FishingRod",
    "native primary reports the presented rod")

T.finish("pnc_fishing_tool_handoff_smoke")
