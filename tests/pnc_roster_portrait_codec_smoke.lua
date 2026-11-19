local T = require "tests/support/test"
T.addPackagePaths()
PNC = { Core = {} }
require "PNC/Core/Identity/PNC_Identity"
local identity = require "PNC/Core/Identity/PNC_Identity_Portrait"
local codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = copy(child) end
    return output
end
PNC.Core.DeepCopy = copy

local function compare(expected, actual, path)
    T.equal(type(actual), type(expected), path .. " type")
    if type(expected) == "table" then
        for key, value in pairs(expected) do
            compare(value, actual[key], path .. "." .. tostring(key))
        end
        for key, _ in pairs(actual) do
            T.truthy(expected[key] ~= nil, path .. " unexpected key " .. tostring(key))
        end
    else
        T.equal(actual, expected, path)
    end
end

local itemType = "RadioTraders.RTAlienSkinny_Costume"
local source = {
    identitySeed = 1376740512,
    isFemale = false,
    appearance = {
        outfitMode = "none", skinTexture = "MaleBody03", hairStubble = false,
        chestHair = false, hairModel = "Short",
        outfitItemSpecs = {
            { type = itemType, wornSlot = "fixture:costume",
                itemState = { metadata = { customColor = false, enabled = true,
                    values = { 0, 1.1234567890123457, "variant-id" } } } },
        },
    },
    equipment = {
        worn = { ["fixture:costume"] = itemType },
        wornVisuals = {
            ["fixture:costume"] = {
                fullType = itemType, baseTexture = 0, textureChoice = 2,
                hue = 0.12345678901234566, decal = "fixture:decal", modelIndex = 3,
                customColor = true,
                tint = { r = 0.23456789012345678, g = 0.6, b = 0.9, a = 1 },
                color = { r = 0.71234567890123456, g = 0.2, b = 0.4, a = 0.8 },
            },
        },
    },
}
local populated = identity.NormalizePortraitSummary(source)
local packed = assert(codec.Pack(populated))
compare(populated, codec.Unpack(packed), "resolved projection")
T.equal(source.identitySeed, 1376740512, "identity input still immutable")

source.equipment.worn["fixture:costume"] = nil
source.equipment.wornVisuals["fixture:costume"] = nil
source.appearance.outfitItemSpecs = {}
local cleared = identity.NormalizePortraitSummary(source)
compare(cleared, codec.Unpack(assert(codec.Pack(cleared))), "explicit empty clothing")
T.equal(codec.Unpack(packed).equipment.worn["fixture:costume"], itemType, "prior output isolated")

local oldCodec = copy(packed)
oldCodec.a.future = "unsupported"
T.equal(codec.Unpack(oldCodec), nil, "unknown wire fields trigger resolved repair")
local futureProjection = copy(populated)
futureProjection.appearance.future = "unsupported"
T.equal(codec.Pack(futureProjection), nil, "unknown projection field uses full transport")

-- A fixed-field transform preserves the authoritative ID and ordinal even
-- without local definitions. A real renderer must still load the asset and
-- validate the mapping before claiming native visual parity.
local localVariants = { "VariantC", "VariantB", "VariantA" }
local serverVariants = { "VariantA", "VariantB", "VariantC" }
T.truthy(localVariants[3] ~= serverVariants[3], "fixture changes visual meaning at same index")
T.equal(codec.Unpack(packed).equipment.wornVisuals["fixture:costume"].textureChoice,
    2, "representation cannot rewrite ordinal for mismatched catalog")
T.equal(codec.Unpack(packed).equipment.worn["fixture:costume"], itemType,
    "missing client asset leaves authoritative type intact")
T.finish("pnc_roster_portrait_codec_smoke")
