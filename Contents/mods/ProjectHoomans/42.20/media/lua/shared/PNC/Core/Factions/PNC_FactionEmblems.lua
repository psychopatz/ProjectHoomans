-- Pure, serialization-safe faction-emblem schema and deterministic generator.
--
-- Persistent emblems contain only stable vanilla map-symbol IDs, color IDs,
-- and bounded numeric transforms. Texture objects are resolved client-side.

PNC = PNC or {}
PNC.FactionEmblems = PNC.FactionEmblems or {}

local Emblems = PNC.FactionEmblems

Emblems.SCHEMA_VERSION = 1
Emblems.MAX_LAYERS = 3

Emblems.COLORS = {
    black = { r = 0.08, g = 0.08, b = 0.08 },
    gray = { r = 0.38, g = 0.38, b = 0.38 },
    white = { r = 0.92, g = 0.92, b = 0.88 },
    red = { r = 0.72, g = 0.10, b = 0.08 },
    blue = { r = 0.10, g = 0.24, b = 0.62 },
    green = { r = 0.08, g = 0.43, b = 0.16 },
    gold = { r = 0.86, g = 0.60, b = 0.08 },
    orange = { r = 0.88, g = 0.33, b = 0.06 },
    purple = { r = 0.42, g = 0.16, b = 0.56 },
}

Emblems.COLOR_IDS = {
    "black", "gray", "white", "red", "blue",
    "green", "gold", "orange", "purple",
}

-- These are stable IDs from Build 42's MapSymbolDefinitions. Paths are kept
-- here as primitives so the client renderer does not need Java definitions.
Emblems.SYMBOLS = {
    Asterisk = "media/ui/LootableMaps/map_asterisk.png",
    Checkmark = "media/ui/LootableMaps/map_checkmark.png",
    Club = "media/ui/LootableMaps/map_club.png",
    Diamond = "media/ui/LootableMaps/map_diamond.png",
    Heart = "media/ui/LootableMaps/map_heart.png",
    Spade = "media/ui/LootableMaps/map_spade.png",
    Cross = "media/ui/LootableMaps/map_cross.png",
    Exclamation = "media/ui/LootableMaps/map_exclamation.png",
    Fire = "media/ui/LootableMaps/map_firet.png",
    Leaf = "media/ui/LootableMaps/map_leaf.png",
    Lightning = "media/ui/LootableMaps/map_lightning.png",
    Moon = "media/ui/LootableMaps/map_moon.png",
    Circle = "media/ui/LootableMaps/map_o.png",
    Question = "media/ui/LootableMaps/map_question.png",
    Radiation = "media/ui/LootableMaps/map_radiation.png",
    Skull = "media/ui/LootableMaps/map_skull.png",
    Star = "media/ui/LootableMaps/map_star.png",
    Sun = "media/ui/LootableMaps/map_sun.png",
    Triangle = "media/ui/LootableMaps/map_triangle.png",
    Snowflake = "media/ui/LootableMaps/map_snowflake.png",
    Pawprint = "media/ui/LootableMaps/map_pawprint.png",
    Heartbroken = "media/ui/LootableMaps/map_heartbroken.png",
    Eye = "media/ui/LootableMaps/map_eye.png",
    CrossedSwords =
        "media/ui/LootableMaps/map_crossedswords.png",
}

Emblems.SYMBOL_IDS = {
    "Asterisk", "Checkmark", "Club", "Diamond", "Heart",
    "Spade", "Cross", "Exclamation", "Fire", "Leaf",
    "Lightning", "Moon", "Circle", "Question", "Radiation",
    "Skull", "Star", "Sun", "Triangle", "Snowflake",
    "Pawprint", "Heartbroken", "Eye", "CrossedSwords",
}

local ARCHETYPE_SYMBOLS = {
    settler = {
        "House", "Heart", "Sun", "Tree", "Star", "Checkmark",
    },
    looter = {
        "Skull", "CrossedSwords", "Fire", "Lightning",
        "Spade", "Exclamation",
    },
    trader = {
        "Diamond", "Star", "Checkmark", "Circle", "Sun",
    },
    refugee = {
        "Heart", "Moon", "Pawprint", "Leaf", "Sun", "Star",
    },
}

-- Location symbols used by the generator are also part of the vanilla set.
Emblems.SYMBOLS.House = "media/ui/LootableMaps/map_house.png"
Emblems.SYMBOLS.Tree = "media/ui/LootableMaps/map_tree.png"
Emblems.SYMBOL_IDS[#Emblems.SYMBOL_IDS + 1] = "House"
Emblems.SYMBOL_IDS[#Emblems.SYMBOL_IDS + 1] = "Tree"

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function clamp(value, minimum, maximum, fallback)
    return math.max(
        minimum,
        math.min(maximum, finite(value, fallback))
    )
end

local function revision(value)
    return math.max(0, math.floor(finite(value, 0)))
end

local function stableNumber(value)
    local hash = 5381
    local source = tostring(value or "")
    local index
    for index = 1, #source do
        hash = (
            hash * 33 + string.byte(source, index)
        ) % 2147483647
    end
    return hash
end

local function pick(values, seed, salt)
    return values[
        (stableNumber(tostring(seed) .. ":" .. tostring(salt))
            % #values) + 1
    ]
end

local function generatedLayer(symbolID, colorID, scale, x, y)
    return {
        symbolID = symbolID,
        colorID = colorID,
        scale = scale,
        offsetX = x,
        offsetY = y,
    }
end

function Emblems.Generate(archetypeID, seed)
    local symbols = ARCHETYPE_SYMBOLS[tostring(archetypeID or "")]
        or ARCHETYPE_SYMBOLS.settler
    local baseColors = {
        settler = { "green", "blue", "gold" },
        looter = { "red", "black", "orange" },
        trader = { "blue", "gold", "purple" },
        refugee = { "green", "blue", "purple" },
    }
    local colors = baseColors[tostring(archetypeID or "")]
        or baseColors.settler
    local primary = pick(symbols, seed, "primary")
    local accent = pick(
        { "Asterisk", "Circle", "Diamond", "Triangle", "Star" },
        seed,
        "accent"
    )
    local background = pick(colors, seed, "background")
    local foreground = background == "black" and "white"
        or pick({ "white", "black", "gold" }, seed, "foreground")
    return {
        schemaVersion = Emblems.SCHEMA_VERSION,
        backgroundColorID = background,
        layers = {
            generatedLayer(primary, foreground, 0.76, 0, 0),
            generatedLayer(
                accent,
                pick(colors, seed, "accent_color"),
                0.34,
                ((stableNumber(tostring(seed) .. ":x") % 17) - 8)
                    / 100,
                ((stableNumber(tostring(seed) .. ":y") % 17) - 8)
                    / 100
            ),
        },
        revision = 0,
    }
end

function Emblems.NormalizeLayer(value)
    local source = type(value) == "table" and value or {}
    if type(source.symbolID) ~= "string"
        or not Emblems.SYMBOLS[source.symbolID]
    then
        return nil
    end
    local colorID = Emblems.COLORS[source.colorID]
        and source.colorID or "white"
    return {
        symbolID = source.symbolID,
        colorID = colorID,
        scale = clamp(source.scale, 0.2, 1.0, 0.75),
        offsetX = clamp(source.offsetX, -0.35, 0.35, 0),
        offsetY = clamp(source.offsetY, -0.35, 0.35, 0),
    }
end

function Emblems.Normalize(value, archetypeID, seed)
    local source = type(value) == "table" and value or nil
    local fallback = Emblems.Generate(
        archetypeID,
        tostring(seed or archetypeID or "faction")
    )
    if not source then return fallback end
    local output = {
        schemaVersion = Emblems.SCHEMA_VERSION,
        backgroundColorID =
            Emblems.COLORS[source.backgroundColorID]
                and source.backgroundColorID
                or fallback.backgroundColorID,
        layers = {},
        revision = revision(source.revision),
    }
    local index
    for index = 1, math.min(
        #(
            type(source.layers) == "table"
                and source.layers or {}
        ),
        Emblems.MAX_LAYERS
    ) do
        local layer = Emblems.NormalizeLayer(source.layers[index])
        if layer then
            output.layers[#output.layers + 1] = layer
        end
    end
    if #output.layers == 0 then
        output.layers = fallback.layers
    end
    return output
end

function Emblems.GetColor(colorID)
    return Emblems.COLORS[tostring(colorID or "")]
        or Emblems.COLORS.white
end

function Emblems.GetTexturePath(symbolID)
    return Emblems.SYMBOLS[tostring(symbolID or "")]
end

return Emblems
