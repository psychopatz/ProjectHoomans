local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local refreshCount = 0
local clothingVisuals = {}
PNC = {
    Core = { LogWarn = function() end },
    Visuals = {
        ClearAttachedItems = function(zombie)
            zombie.attached = {}
        end,
        RefreshModel = function()
            refreshCount = refreshCount + 1
        end,
        AddClothingVisual = function(_, fullType)
            clothingVisuals[#clothingVisuals + 1] = fullType
            return true, "visual_added"
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

ISHotbarAttachDefinition = {
    Back = {
        type = "Back",
        attachments = { BigWeapon = "Back" },
    },
}

dofile(ROOT .. "Equipment/PNC_Equipment_Items.lua")
dofile(ROOT .. "Equipment/PNC_Equipment_Slots.lua")
dofile(ROOT .. "Equipment/PNC_Equipment.lua")

local weapon = {
    IsWeapon = function() return true end,
    isRequiresEquippedBothHands = function() return false end,
    getAttachmentType = function() return "BigWeapon" end,
}
PNC.Equipment.CreateItem = function()
    return weapon, "test_item"
end

local primarySet = 0
local handModelsReset = 0
local zombie = {
    attached = {},
    setVariable = function() end,
    setPrimaryHandItem = function(self, item)
        self.primary = item
        primarySet = primarySet + 1
    end,
    setSecondaryHandItem = function(self, item)
        self.secondary = item
    end,
    setAttachedItem = function(self, location, item)
        self.attached[location] = item
    end,
    resetEquippedHandsModels = function()
        handModelsReset = handModelsReset + 1
    end,
    getWornItems = function()
        error("hands-only refresh touched worn items")
    end,
    getItemVisuals = function()
        error("hands-only refresh touched clothing visuals")
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
assertEqual(applied, true, "idle equipment apply")
assertEqual(zombie.primary, nil, "idle primary hand cleared")
assertEqual(zombie.attached.Back, weapon, "idle primary implicitly holstered")

record.runtime = { target = { kind = "zombie" } }
applied = PNC.Equipment.ApplyCombatState(zombie, record, true)
assertEqual(applied, true, "combat equipment apply")
assertEqual(zombie.primary, weapon, "combat primary hand")
assertEqual(zombie.attached.Back, nil, "combat holster cleared")

record.runtime.target = nil
applied = PNC.Equipment.ApplyCombatState(zombie, record, false)
assertEqual(applied, true, "idle combat-state equipment apply")
assertEqual(zombie.primary, nil, "idle primary leaves hand")
assertEqual(zombie.attached.Back, weapon, "idle primary returns to holster")
assert(primarySet >= 3, "primary hand state was not refreshed")
assert(handModelsReset > 0, "hand models were not refreshed")
assert(refreshCount > 0, "equipment presentation did not refresh the model")

local appliedCondition
local shirtBodyLocation = {}
local clothing = {
    setCondition = function(_, value) appliedCondition = value end,
    getConditionMax = function() return 10 end,
    getBodyLocation = function() return shirtBodyLocation end,
}
PNC.Equipment.CreateItem = function()
    return clothing, "test_clothing"
end
local worn = { clear = function() end }
local visuals = { clear = function() end }
local dressedZombie = {
    attached = {},
    getWornItems = function() return worn end,
    getItemVisuals = function() return visuals end,
    setWornItem = function(_, location, item)
        assertEqual(location, shirtBodyLocation, "typed worn item location")
        assertEqual(item, clothing, "worn item instance")
    end,
    getAttachedItems = function()
        return { size = function() return 0 end }
    end,
    setVariable = function() end,
    setPrimaryHandItem = function() end,
    setSecondaryHandItem = function() end,
    resetEquippedHandsModels = function() end,
}
local dressedRecord = {
    equipment = { worn = { Shirt = "Base.Shirt_FormalWhite" }, attached = {} },
    inventory = {
        worn = { Shirt = "shirt_1" },
        items = { shirt_1 = { id = "shirt_1", type = "Base.Shirt_FormalWhite", cond = 3 } },
    },
    runtime = {},
}
applied = PNC.Equipment.Apply(dressedZombie, dressedRecord)
assertEqual(applied, true, "full clothing apply")
assertEqual(appliedCondition, 3, "virtual condition copied to live worn item")
assertEqual(clothingVisuals[#clothingVisuals], "Base.Shirt_FormalWhite", "explicit clothing visual applied")

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
