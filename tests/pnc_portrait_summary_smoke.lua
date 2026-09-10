local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")

local function deepCopy(value)
    local output
    local key
    if type(value) ~= "table" then return value end
    output = {}
    for key, value in pairs(value) do
        output[key] = deepCopy(value)
    end
    return output
end

PNC = {
    Core = {
        DeepCopy = deepCopy,
    },
    Archetypes = {
        Get = function()
            return {
                id = "General",
                label = "General",
                visualProfile = "colonist",
                allowedJobs = {},
                looks = {
                    male = {
                        { "Base.Shirt_FormalWhite", "Base.Trousers" },
                    },
                    female = {
                        { "Base.Shirt_FormalWhite", "Base.Trousers" },
                    },
                    spawnOutfit = {
                        male = "PNCCompanionMale",
                        female = "PNCCompanionFemale",
                    },
                },
            }
        end,
        GetColonistDefaults = function() return { "General" } end,
        GetHostileDefaults = function() return { "General" } end,
    },
    Types = {
        NormalizeTacticalClass = function(value) return value or "colonist" end,
    },
}

T.load(ROOT .. "Identity/PNC_Identity.lua")
T.load(ROOT .. "Identity/PNC_Identity_Profile.lua")
T.load(ROOT .. "Identity/PNC_Identity_Portrait.lua")

local record = {
    id = "npc_portrait_summary",
    name = "Portrait NPC",
    identitySeed = 44,
    archetypeID = "General",
    tacticalClass = "colonist",
    isFemale = false,
    identity = {
        seed = 44,
        displayName = "Portrait NPC",
        archetypeID = "General",
        archetypeLabel = "General",
        isFemale = false,
        survivor = {
            skinTexture = "MaleBody03",
            hairModel = "Short",
            beardModel = "Goatee",
            hairColor = { r = 0.2, g = 0.1, b = 0.05 },
        },
    },
    equipment = {
        worn = {
            Hat = "Base.Hat_HardHat",
            Mask = "Base.Hat_DustMask",
            Jacket = "Base.Jacket_WhiteTINT",
            Shirt = "Base.Shirt_FormalWhite",
        },
        wornVisuals = {
            Jacket = {
                fullType = "Base.Jacket_WhiteTINT",
                textureChoice = 2,
                tint = { r = 0.7, g = 0.8, b = 0.9 },
            },
        },
    },
    runtime = {},
}

local portrait = T.truthy(PNC.Identity.BuildPortraitSummary(record))
T.truthy(PNC.Identity.BuildPortraitSummary(record) == portrait,
    "unchanged portrait summary was rebuilt instead of cached")
T.equal(portrait.faceOnly, true, "portrait summary face-only flag")
T.equal(portrait.identitySeed, 44, "portrait identity seed")
T.truthy((tonumber(portrait.revision) or 0) > 0,
    "portrait summary revision was not generated")
T.equal(portrait.appearance.hairModel, "Short",
    "portrait hair model")
T.equal(portrait.equipment.worn.Hat, "Base.Hat_HardHat",
    "portrait did not retain the current worn loadout")
T.equal(portrait.equipment.wornVisuals.Jacket.textureChoice, 2,
    "portrait did not retain the current clothing visual choice")
T.truthy(type(portrait.appearance.outfitItems) == "table",
    "portrait did not retain its bounded fallback outfit")

record.equipment.worn.Hat = "Base.Hat_Beret"
local changedPortrait = PNC.Identity.BuildPortraitSummary(record)
T.truthy(changedPortrait ~= portrait,
    "equipment-only change did not invalidate the portrait")
T.equal(changedPortrait.equipment.worn.Hat, "Base.Hat_Beret",
    "portrait cache kept the stale hat")

local normalized = PNC.Identity.NormalizePortraitSummary({
    id = "oversized",
    identitySeed = 9,
    appearance = {
        hairModel = string.rep("H", 200),
    },
    equipment = {
        worn = {
            Hat = "Base.Hat_HardHat",
            Mask = "Base.Hat_DustMask",
        },
    },
})
T.equal(normalized.equipment.worn.Hat, "Base.Hat_HardHat",
    "normalized portrait discarded clothing metadata")
T.truthy(#normalized.appearance.hairModel <= 128,
    "portrait appearance string was not bounded")
T.finish("pnc_portrait_summary_smoke")
