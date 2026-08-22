local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local equipCalls = {}
PNC = {
    Core = {
        LogWarn = function() end,
    },
    Visuals = {
        RefreshModel = function() end,
    },
    Inventory = {
        EnsureRecordInventory = function(record)
            return record and record.inventory or nil
        end,
        EquipPrimary = function(record, itemID, reason)
            local inv = record.inventory
            local previousID = inv.equipped.primary
            if previousID and inv.items[previousID] then
                inv.items[previousID].equipSlot = nil
            end
            inv.equipped.primary = itemID
            if itemID and inv.items[itemID] then
                inv.items[itemID].equipSlot = "primary"
            end
            record.equipment = record.equipment or {}
            record.equipment.primaryFullType = itemID
                and inv.items[itemID].type
                or nil
            equipCalls[#equipCalls + 1] = {
                itemID = itemID,
                reason = reason,
            }
            return true, itemID and "equipped_primary" or "primary_cleared"
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
WeaponType.getWeaponType = function(item)
    return item.weaponType
end

T.load(ROOT .. "Equipment/PNC_Equipment_Items.lua")
T.load(ROOT .. "Equipment/PNC_Equipment_Slots.lua")
T.load(ROOT .. "Equipment/PNC_Equipment.lua")

PNC.Equipment.CreateItem = function(fullType)
    local weaponType = string.find(fullType, "Pistol", 1, true)
        and WeaponType.HANDGUN
        or WeaponType.ONE_HANDED
    return {
        weaponType = weaponType,
        IsWeapon = function() return true end,
    }, "test_item"
end

local record = {
    weaponMode = "ranged",
    equipment = {
        primaryFullType = "Base.Pistol",
        worn = {},
        attached = {},
    },
    inventory = {
        equipped = { primary = "gun" },
        items = {
            gun = {
                id = "gun",
                type = "Base.Pistol",
                equipSlot = "primary",
                ammoCount = 0,
            },
            ordinary = {
                id = "ordinary",
                type = "Base.Hammer",
            },
            reserve = {
                id = "reserve",
                type = "Base.HuntingKnife",
                templateKey = "tmpl:weapon:reserve",
            },
        },
    },
    runtime = {},
}

local switched, reason = PNC.Equipment.ActivateMeleeFallback(record, nil)
T.equal(switched, true, "melee fallback switch")
T.equal(reason, "switched_to_melee", "melee fallback reason")
T.equal(record.inventory.equipped.primary, "reserve", "reserved melee weapon priority")
T.equal(record.inventory.items.gun.equipSlot, nil, "empty firearm unequipped")
T.equal(record.inventory.items.reserve.equipSlot, "primary", "melee weapon equipped")
T.equal(record.equipment.primaryFullType, "Base.HuntingKnife", "legacy equipment synchronized")
T.equal(record.weaponMode, "melee", "combat mode switched")
T.equal(record.runtime.forceSyncEvent, "weapon_fallback_melee", "multiplayer sync requested")
T.equal(equipCalls[1].reason, "combat_melee_fallback", "melee mutation reason")

local shoveRecord = {
    weaponMode = "ranged",
    equipment = {
        primaryFullType = "Base.Pistol",
        worn = {},
        attached = {},
    },
    inventory = {
        equipped = { primary = "gun" },
        items = {
            gun = {
                id = "gun",
                type = "Base.Pistol",
                equipSlot = "primary",
                ammoCount = 0,
            },
        },
    },
    runtime = {},
}

switched, reason = PNC.Equipment.ActivateMeleeFallback(shoveRecord, nil)
T.equal(switched, true, "shove fallback switch")
T.equal(reason, "switched_to_shove", "shove fallback reason")
T.equal(shoveRecord.inventory.equipped.primary, nil, "firearm cleared for shove")
T.equal(shoveRecord.equipment.primaryFullType, nil, "barehand equipment synchronized")
T.equal(shoveRecord.weaponMode, "melee", "shove mode is melee")
T.equal(shoveRecord.runtime.forceSyncEvent, "weapon_fallback_shove", "shove sync requested")
T.equal(equipCalls[2].reason, "combat_shove_fallback", "shove mutation reason")
T.finish("pnc_ranged_fallback_smoke")

T.finish("pnc_ranged_fallback_smoke")
