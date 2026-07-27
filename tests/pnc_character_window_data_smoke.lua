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
    ["Base.Jacket"] = { name = "Leather Jacket", bite = 30, scratch = 50, insulation = 0.8, wind = 0.7, covered = { "Torso_Upper", "Torso_Lower" } },
    ["Base.Trousers"] = { name = "Trousers", bite = 10, scratch = 20, insulation = 0.4, wind = 0.3, covered = { "Groin", "UpperLeg_L", "UpperLeg_R" } },
}

PNC = {
    Equipment = {
        CreateItem = function(fullType)
            local data = itemData[fullType]
            if not data then return nil end
            local condition = 10
            local covered = {
                size = function() return #data.covered end,
                get = function(_, index) return data.covered[index + 1] end,
            }
            return {
                getDisplayName = function() return data.name end,
                getBiteDefense = function() return data.bite end,
                getScratchDefense = function() return data.scratch end,
                getInsulation = function() return data.insulation end,
                getWindresist = function() return data.wind end,
                getConditionMax = function() return 10 end,
                getCondition = function() return condition end,
                setCondition = function(_, value) condition = value end,
                getWetness = function() return 0 end,
                getHolesNumber = function() return 0 end,
                getCoveredParts = function() return covered end,
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

-- The Build 42 Kahlua environment used by the game may not expose the global
-- next() function. Keep this nil while building rows so direct use regresses.
local savedNext = next
next = nil
local rows = PNC.CharacterWindowShared.BuildClothingRows(snapshot, nil)
next = savedNext
assertEqual(#rows, 2, "clothing row count")
assertEqual(rows[1].location, "Jacket", "stable clothing sort")
assertEqual(rows[1].name, "Leather Jacket", "display name")

local summary = PNC.CharacterWindowShared.SummarizeClothing(rows)
assertEqual(summary.biteAverage, 20, "average bite defense")
assertEqual(summary.scratchAverage, 35, "average scratch defense")
assertNear(summary.insulationAverage, 0.6, "average insulation")
assertNear(summary.windAverage, 0.5, "average wind resistance")

local payload = {
    snapshot = snapshot,
    equipment = {
        worn = {
            Jacket = "Base.Trousers",
            Pants = "Base.Jacket",
        },
    },
    inventory = {
        worn = { Jacket = "jacket_1", Pants = "pants_1" },
        items = {
            jacket_1 = { id = "jacket_1", type = "Base.Jacket", cond = 4 },
            pants_1 = { id = "pants_1", type = "Base.Trousers", cond = 10 },
        },
    },
}
local stateRows = PNC.CharacterWindowShared.BuildClothingRows(snapshot, payload, "npc_ui")
assertEqual(stateRows[1].condition, 4, "virtual clothing condition")
assertNear(stateRows[1].conditionRatio, 0.4, "virtual condition ratio")
assertEqual(stateRows[1].fullType, "Base.Jacket",
    "inventory worn map overrides stale equipment summary")
local protection = PNC.CharacterWindowShared.BuildBodyProtection("npc_ui", snapshot, payload, stateRows)
assertNear(protection.Torso_Upper.bite, 12, "condition-adjusted covered bite defense")
assertNear(protection.Torso_Upper.scratch, 20, "condition-adjusted covered scratch defense")
local insulation = PNC.CharacterWindowShared.BuildBodyInsulation("npc_ui", snapshot, payload, stateRows)
assertNear(insulation.Torso_Upper.insulation, 0.32, "condition-adjusted covered insulation")

PNC.ClientPresenceSync = {
    BodyByID = {
        npc_ui = {
            getBodyPartClothingDefense = function(_, index, bite)
                return (bite and 20 or 10) + index
            end,
        },
    },
}
protection = PNC.CharacterWindowShared.BuildBodyProtection("npc_ui", snapshot, nil, stateRows)
assertEqual(protection.Head.bite, 28, "live per-part bite defense")
assertEqual(protection.Head.scratch, 18, "live per-part scratch defense")

local liveJacket = itemData["Base.Jacket"]
local wornEntry = {
    getLocation = function() return "Jacket" end,
    getItem = function() return liveJacket end,
}
PNC.ClientPresenceSync.BodyByID.npc_ui = {
    getWornItems = function()
        return {
            size = function() return 1 end,
            get = function(_, index) return index == 0 and wornEntry or nil end,
            getItem = function()
                error("Build 42 getItem must not receive a legacy string location")
            end,
        }
    end,
}
local liveRows = PNC.CharacterWindowShared.BuildClothingRows(snapshot, payload, "npc_ui")
assertEqual(liveRows[1].item, liveJacket, "Build 42 worn-item lookup uses typed-safe iteration")

local spec = PNC.CharacterWindowShared.BuildPortraitSpec("npc_ui", snapshot, nil)
assertEqual(spec.id, "npc_ui", "portrait id")
assertEqual(spec.identitySeed, 42, "portrait seed")
assertEqual(spec.isFemale, true, "portrait gender")
assertEqual(spec.equipment.worn.Jacket, "Base.Jacket", "portrait equipment")

print("pnc_character_window_data_smoke: ok")
