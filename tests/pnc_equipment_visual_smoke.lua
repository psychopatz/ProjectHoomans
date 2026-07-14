local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local refreshCount = 0
PNC = {
    Core = { LogWarn = function() end },
    Visuals = {
        RefreshModel = function()
            refreshCount = refreshCount + 1
        end,
    },
}

WeaponType = {
    FIREARM = {},
    HANDGUN = {},
    SPEAR = {},
    HEAVY = {},
    TWO_HANDED = {},
    ONE_HANDED = {},
}
WeaponType.getWeaponType = function()
    return WeaponType.ONE_HANDED
end

dofile(ROOT .. "Equipment/PNC_Equipment_Items.lua")
dofile(ROOT .. "Equipment/PNC_Equipment_Slots.lua")
dofile(ROOT .. "Equipment/PNC_Equipment.lua")

local weapon = {
    IsWeapon = function() return true end,
    isRequiresEquippedBothHands = function() return false end,
}
PNC.Equipment.CreateItem = function()
    return weapon, "test_item"
end

local primarySet = 0
local handModelsReset = 0
local zombie = {
    setVariable = function() end,
    setPrimaryHandItem = function(_, item)
        assertEqual(item, weapon, "primary hand item")
        primarySet = primarySet + 1
    end,
    setSecondaryHandItem = function() end,
    resetEquippedHandsModels = function()
        handModelsReset = handModelsReset + 1
    end,
    getWornItems = function()
        error("hands-only refresh touched worn items")
    end,
    getItemVisuals = function()
        error("hands-only refresh touched clothing visuals")
    end,
    getAttachedItems = function()
        error("hands-only refresh touched attached items")
    end,
}
local record = {
    equipment = {
        primaryFullType = "Base.Axe",
        worn = { Shirt = "Base.Shirt_FormalWhite" },
        attached = {},
    },
}

local applied = PNC.Equipment.ApplyHands(zombie, record)
assertEqual(applied, true, "hands-only apply")
assertEqual(primarySet, 1, "primary hand apply count")
assert(handModelsReset > 0, "hand models were not refreshed")
assertEqual(refreshCount, 0, "hands-only path performed a full model refresh")

local calls = {
    appearance = 0,
    fullEquipment = 0,
    hands = 0,
    broadcast = 0,
}
local apiRecord = {
    id = "npc_visual",
    runtime = {},
    equipment = { worn = { Shirt = "Base.Shirt_FormalWhite" }, attached = {} },
}
PNC = {
    API = {},
    Core = {
        LogRecordDebug = function() end,
    },
    Types = {},
    Registry = {
        Get = function() return apiRecord end,
        GetLiveZombie = function() return {} end,
    },
    OrderSystem = {},
    Presence = {},
    Health = {},
    Visuals = {
        ApplyHumanVisuals = function()
            calls.appearance = calls.appearance + 1
        end,
    },
    Equipment = {
        SetPrimary = function(target, fullType)
            target.equipment.primaryFullType = fullType
        end,
        ResolveWeaponMode = function() return "melee" end,
        Apply = function()
            calls.fullEquipment = calls.fullEquipment + 1
            return true, "full"
        end,
        ApplyHands = function()
            calls.hands = calls.hands + 1
            return true, "hands"
        end,
        Describe = function()
            return { combatModeResolved = "melee", weaponStatus = "melee_ready" }
        end,
    },
    Inventory = {
        SyncFromEquipment = function() end,
    },
    Network = {
        BroadcastRecord = function()
            calls.broadcast = calls.broadcast + 1
        end,
    },
}

dofile(ROOT .. "API/PNC_API.lua")
assert(PNC.API.DebugCommand("npc_visual", "copy_held_weapon", {
    weaponFullType = "Base.Axe",
}), "copy held weapon failed")
assertEqual(calls.hands, 1, "API hands-only apply count")
assertEqual(calls.appearance, 0, "API rebuilt appearance")
assertEqual(calls.fullEquipment, 0, "API rebuilt full equipment")
assertEqual(calls.broadcast, 1, "API equipment broadcast count")

print("pnc_equipment_visual_smoke: ok")
