local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/UI/")
    .. "PNC_NPCTypePalette.lua"

PNC = {
    Const = { ORDER_FOLLOW = "follow" },
}

T.load(FILE)

local Palette = PNC.NPCTypePalette
T.equal(Palette.ResolveType({ faction = "neutral" }), "neutral",
    "neutral type")
T.equal(Palette.ResolveType({ faction = "hostile" }), "hostile",
    "hostile type")
T.equal(Palette.ResolveType({
    record = {
        recruited = true,
        faction = "colonist",
        orderSpec = { kind = "follow" },
    },
}), "follower", "nested follower type")
T.equal(Palette.ResolveType({
    snapshot = {
        recruited = true,
        faction = "colonist",
    },
}), "colonist", "snapshot colonist type")
T.equal(Palette.ResolveType({
    deathMarker = true,
    colonist = true,
}), "deadColonist", "dead colonist type")

local hostile = Palette.Resolve({ faction = "hostile" })
local theme = Palette.BuildConversationTheme({ faction = "hostile" })
T.equal(hostile.r, 1, "map hostile red")
T.equal(theme.accent.r, hostile.r, "conversation uses map red")
T.equal(theme.accent.g, hostile.g, "conversation uses map green")
T.equal(theme.accent.b, hostile.b, "conversation uses map blue")
T.finish("pnc_npc_type_palette_smoke")

T.finish("pnc_npc_type_palette_smoke")
