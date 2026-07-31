local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local CLIENT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"

PNC = {}
dofile(SHARED .. "Factions/PNC_FactionEmblems.lua")

local textureLoads = 0
function getTexture(path)
    textureLoads = textureLoads + 1
    return path
end

dofile(
    CLIENT
        .. "UI/Factions/PNC_FactionEmblemRenderer.lua"
)

local rectangles = 0
local borders = 0
local layers = {}
local target = {}
function target:drawRect()
    rectangles = rectangles + 1
end
function target:drawRectBorder()
    borders = borders + 1
end
function target:drawTextureScaledAspect(
    texture,
    x,
    y,
    width,
    height,
    alpha,
    r,
    g,
    b
)
    layers[#layers + 1] = {
        texture = texture,
        x = x,
        y = y,
        width = width,
        height = height,
        alpha = alpha,
        r = r,
        g = g,
        b = b,
    }
end

local emblem = PNC.FactionEmblems.Normalize({
    backgroundColorID = "blue",
    layers = {
        {
            symbolID = "House",
            colorID = "white",
            scale = 0.95,
        },
        {
            symbolID = "Star",
            colorID = "gold",
            scale = 0.45,
            offsetX = 0.08,
            offsetY = -0.08,
        },
    },
}, "settler", "renderer")

assert(PNC.FactionEmblemRenderer.Draw(
    target,
    emblem,
    10,
    20,
    40
), "renderer rejected valid emblem")
assert(rectangles == 1 and borders == 1,
    "renderer did not draw bounded background")
assert(#layers == 2,
    "renderer did not overlap all emblem layers")
assert(layers[1].texture
    == "media/ui/LootableMaps/map_house.png",
    "renderer did not resolve vanilla symbol texture")

PNC.FactionEmblemRenderer.Draw(
    target,
    emblem,
    10,
    20,
    40
)
assert(textureLoads == 2,
    "symbol textures were not cached by stable ID")

print("pnc_faction_emblem_renderer_smoke: PASS")
