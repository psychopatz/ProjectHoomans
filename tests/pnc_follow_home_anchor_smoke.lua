local T = require "tests/support/test"

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
    },
    Core = {
        Now = function() return 1234 end,
    },
}

T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Orders/PNC_OrderSystem_Base.lua"))

local normalized = PNC.OrderSystem.Normalize(
    { id = "npc-anchor", z = 0, ownerUsername = "alice" },
    {
        kind = "follow",
        ownerUsername = "alice",
        homeAnchor = {
            baseId = "base-1",
            x = 15,
            y = 16,
            z = 0,
            radius = 2,
            homeZoneId = "zone-1",
            stockpileNodeId = "stockpile-1",
        },
    }
)

T.equal(normalized.kind, "follow", "follow order remains normalized")
T.equal(normalized.homeAnchor.baseId, "base-1",
    "follow order retains the home base identity")
T.equal(normalized.homeAnchor.x, 15,
    "follow order retains the home anchor x")
T.equal(normalized.homeAnchor.y, 16,
    "follow order retains the home anchor y")
T.equal(normalized.homeAnchor.stockpileNodeId, "stockpile-1",
    "follow order retains the stockpile access identity")

T.finish("pnc_follow_home_anchor_smoke")
