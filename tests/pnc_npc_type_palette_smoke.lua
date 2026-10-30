local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/UI/")
    .. "PNC_NPCTypePalette.lua"

PNC = {
    Const = { ORDER_FOLLOW = "follow" },
}

local legacy = T.load(FILE)

local Palette = require "PNC/Presentation/PNC_NPCTypePalette"
T.equal(legacy, Palette, "legacy UI path returns the canonical presentation query")
T.equal(Palette, PNC.NPCTypePalette, "both paths retain the one public palette object")
T.equal(Palette.ResolveType({ tacticalClass = "neutral" }), "neutral",
    "neutral type")
T.equal(Palette.ResolveType({ tacticalClass = "hostile" }), "hostile",
    "hostile type")
T.equal(Palette.ResolveType({
    record = {
        recruited = true,
        tacticalClass = "colonist",
        orderSpec = { kind = "follow" },
    },
}), "follower", "nested follower type")
T.equal(Palette.ResolveType({
    snapshot = {
        recruited = true,
        tacticalClass = "colonist",
    },
}), "colonist", "snapshot colonist type")
T.equal(Palette.ResolveType({
    deathMarker = true,
    colonyOwned = true,
    colonist = true,
}), "deadColonist", "dead colonist type")

local hostile = Palette.Resolve({ tacticalClass = "hostile" })
local theme = Palette.BuildConversationTheme({ tacticalClass = "hostile" })
T.equal(hostile.r, 1, "map hostile red")
T.equal(theme.accent.r, hostile.r, "conversation uses map red")
T.equal(theme.accent.g, hostile.g, "conversation uses map green")
T.equal(theme.accent.b, hostile.b, "conversation uses map blue")
T.finish("pnc_npc_type_palette_smoke")
