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
T.equal(portrait.equipment, nil,
    "portrait retained clothing metadata")
T.equal(portrait.appearance.outfitItems, nil,
    "portrait leaked the full outfit list")

record.equipment.worn.Hat = "Base.Hat_Beret"
T.truthy(PNC.Identity.BuildPortraitSummary(record) == portrait,
    "equipment-only change rebuilt the clothing-free portrait")

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
T.equal(normalized.equipment, nil,
    "normalized portrait accepted clothing metadata")
T.truthy(#normalized.appearance.hairModel <= 128,
    "portrait appearance string was not bounded")
T.finish("pnc_portrait_summary_smoke")

T.finish("pnc_portrait_summary_smoke")
