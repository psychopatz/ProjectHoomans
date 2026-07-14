local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/CharacterWindow/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertNear(actual, expected, label)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error((label or "assertNear") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local itemData = {
    ["Base.Jacket"] = { name = "Leather Jacket", bite = 30, scratch = 50, insulation = 0.8, wind = 0.7 },
    ["Base.Trousers"] = { name = "Trousers", bite = 10, scratch = 20, insulation = 0.4, wind = 0.3 },
}

PNC = {
    Equipment = {
        CreateItem = function(fullType)
            local data = itemData[fullType]
            if not data then return nil end
            return {
                getDisplayName = function() return data.name end,
                getBiteDefense = function() return data.bite end,
                getScratchDefense = function() return data.scratch end,
                getInsulation = function() return data.insulation end,
                getWindresist = function() return data.wind end,
            }
        end,
    },
}

dofile(ROOT .. "PNC_CharacterWindow_Shared.lua")

local snapshot = {
    id = "npc_ui",
    identitySeed = 42,
    presenceRevision = 7,
    isFemale = true,
    appearance = {
        hairModel = "Long",
        outfitItems = { "Base.Trousers" },
    },
    equipmentSummary = {
        primaryFullType = "Base.Axe",
        worn = {
            Jacket = "Base.Jacket",
            Pants = "Base.Trousers",
        },
    },
}

local rows = PNC.CharacterWindowShared.BuildClothingRows(snapshot, nil)
assertEqual(#rows, 2, "clothing row count")
assertEqual(rows[1].location, "Jacket", "stable clothing sort")
assertEqual(rows[1].name, "Leather Jacket", "display name")

local summary = PNC.CharacterWindowShared.SummarizeClothing(rows)
assertEqual(summary.biteAverage, 20, "average bite defense")
assertEqual(summary.scratchAverage, 35, "average scratch defense")
assertNear(summary.insulationAverage, 0.6, "average insulation")
assertNear(summary.windAverage, 0.5, "average wind resistance")

local spec = PNC.CharacterWindowShared.BuildPortraitSpec("npc_ui", snapshot, nil)
assertEqual(spec.id, "npc_ui", "portrait id")
assertEqual(spec.identitySeed, 42, "portrait seed")
assertEqual(spec.isFemale, true, "portrait gender")
assertEqual(spec.equipment.worn.Jacket, "Base.Jacket", "portrait equipment")

print("pnc_character_window_data_smoke: ok")
