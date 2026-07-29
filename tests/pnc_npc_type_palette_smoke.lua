local FILE =
    "Contents/mods/ProjectHoomans/common/media/lua/client/PNC/UI/"
    .. "PNC_NPCTypePalette.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

PNC = {
    Const = { ORDER_FOLLOW = "follow" },
}

dofile(FILE)

local Palette = PNC.NPCTypePalette
assertEqual(Palette.ResolveType({ faction = "neutral" }), "neutral",
    "neutral type")
assertEqual(Palette.ResolveType({ faction = "hostile" }), "hostile",
    "hostile type")
assertEqual(Palette.ResolveType({
    record = {
        recruited = true,
        faction = "colonist",
        orderSpec = { kind = "follow" },
    },
}), "follower", "nested follower type")
assertEqual(Palette.ResolveType({
    snapshot = {
        recruited = true,
        faction = "colonist",
    },
}), "colonist", "snapshot colonist type")
assertEqual(Palette.ResolveType({
    deathMarker = true,
    colonist = true,
}), "deadColonist", "dead colonist type")

local hostile = Palette.Resolve({ faction = "hostile" })
local theme = Palette.BuildConversationTheme({ faction = "hostile" })
assertEqual(hostile.r, 1, "map hostile red")
assertEqual(theme.accent.r, hostile.r, "conversation uses map red")
assertEqual(theme.accent.g, hostile.g, "conversation uses map green")
assertEqual(theme.accent.b, hostile.b, "conversation uses map blue")

print("pnc_npc_type_palette_smoke: ok")
