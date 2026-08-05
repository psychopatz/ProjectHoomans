local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
        NormalizeFaction = function(value) return value or "colonist" end,
    },
}

dofile(ROOT .. "Identity/PNC_Identity.lua")
dofile(ROOT .. "Identity/PNC_Identity_Profile.lua")
dofile(ROOT .. "Identity/PNC_Identity_Portrait.lua")

local record = {
    id = "npc_portrait_summary",
    name = "Portrait NPC",
    identitySeed = 44,
    archetypeID = "General",
    faction = "colonist",
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

local portrait = assert(PNC.Identity.BuildPortraitSummary(record))
assert(PNC.Identity.BuildPortraitSummary(record) == portrait,
    "unchanged portrait summary was rebuilt instead of cached")
assertEqual(portrait.faceOnly, true, "portrait summary face-only flag")
assertEqual(portrait.identitySeed, 44, "portrait identity seed")
assert((tonumber(portrait.revision) or 0) > 0,
    "portrait summary revision was not generated")
assertEqual(portrait.appearance.hairModel, "Short",
    "portrait hair model")
assertEqual(portrait.equipment, nil,
    "portrait retained clothing metadata")
assertEqual(portrait.appearance.outfitItems, nil,
    "portrait leaked the full outfit list")

record.equipment.worn.Hat = "Base.Hat_Beret"
assert(PNC.Identity.BuildPortraitSummary(record) == portrait,
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
assertEqual(normalized.equipment, nil,
    "normalized portrait accepted clothing metadata")
assert(#normalized.appearance.hairModel <= 128,
    "portrait appearance string was not bounded")

print("pnc_portrait_summary_smoke: ok")
