local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")

local function trueValue(value, label)
    T.equal(value == true, true, label)
end

local function deepEqual(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, value in pairs(left) do
        if not deepEqual(value, right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function saveSafe(value, seen)
    local valueType = type(value)
    if valueType == "nil" or valueType == "boolean"
        or valueType == "number" or valueType == "string"
    then
        return true
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "number" and type(key) ~= "string" then
            return false
        end
        if not saveSafe(item, seen) then return false end
    end
    seen[value] = nil
    return true
end

PNC = {}
T.load(ROOT .. "Factions/PNC_FactionEmblems.lua")

local Emblems = PNC.FactionEmblems
local first = Emblems.Generate("looter", "faction_alpha")
local second = Emblems.Generate("looter", "faction_alpha")
trueValue(deepEqual(first, second), "generator deterministic")
T.equal(first.schemaVersion, 1, "emblem schema")
trueValue(#first.layers >= 1 and #first.layers <= 3,
    "generated layer bounds")
trueValue(saveSafe(first), "generated emblem save safe")

local normalized = Emblems.Normalize({
    backgroundColorID = "invalid",
    layers = {
        {
            symbolID = "Skull",
            colorID = "red",
            scale = 99,
            offsetX = -99,
            offsetY = 99,
        },
        { symbolID = "not_a_symbol" },
        { symbolID = "Star", colorID = "gold" },
        { symbolID = "Heart", colorID = "green" },
    },
    revision = -10,
}, "looter", "faction_test")

T.equal(normalized.backgroundColorID,
    Emblems.Generate("looter", "faction_test").backgroundColorID,
    "invalid background repaired")
T.equal(#normalized.layers, 2, "invalid and overflow layers removed")
T.equal(normalized.layers[1].scale, 1, "scale clamped")
T.equal(normalized.layers[1].offsetX, -0.35, "x clamped")
T.equal(normalized.layers[1].offsetY, 0.35, "y clamped")
T.equal(normalized.revision, 0, "revision clamped")
trueValue(
    deepEqual(
        normalized,
        Emblems.Normalize(
            normalized,
            "looter",
            "faction_test"
        )
    ),
    "normalization idempotent"
)

local fallback = Emblems.Normalize(
    { layers = { { symbolID = "invalid" } } },
    "trader",
    "faction_fallback"
)
trueValue(#fallback.layers > 0, "empty emblem gets failsafe")
trueValue(saveSafe(fallback), "normalized emblem save safe")
T.finish("pnc_faction_emblems_smoke")

T.finish("pnc_faction_emblems_smoke")
