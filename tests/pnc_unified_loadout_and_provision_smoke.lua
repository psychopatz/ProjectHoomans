local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")

-- 1. Unified ReconcileBestLoadout (bags + armor + skill-weighted weapons)
PNC = {
    Inventory = {
        Internal = {
            normalizeString = function(v) return type(v) == "string" and v ~= "" and v or nil end,
            normalizeItemWeightReduction = function(v)
                local n = tonumber(v) or 0
                if n > 1 then n = n / 100 end
                return math.max(0, math.min(0.95, n))
            end,
            getContainerRawWeight = function() return 0 end,
            shallowArrayCopy = function(t)
                local out = {}
                for i = 1, #(t or {}) do out[i] = t[i] end
                return out
            end,
            getItemWeight = function() return 0.5 end,
        },
        EnsureRecordInventory = function(rec) return rec.inventory end,
        ClearWorn = function(rec, id)
            local item = rec.inventory.items[id]
            if item and item.wornSlot then
                rec.inventory.worn[item.wornSlot] = nil
                item.wornSlot = nil
            end
            return true
        end,
        SetWorn = function(rec, id, slot)
            local item = rec.inventory.items[id]
            if not item then return false end
            rec.inventory.worn[slot] = id
            item.wornSlot = slot
            return true
        end,
        SetEquipped = function(rec, slot, id)
            rec.inventory.equipped[slot] = id
            return true
        end,
        ApplyDelta = function() return true end,
    },
}

package.loaded["PNC/Core/Identity/PNC_Identity_Appearance"] = {
    WornSlotsConflict = function(a, b) return a == b end,
}

T.load(SHARED .. "Inventory/PNC_Inventory/Model/PNC_Inventory_BagAdoption.lua")

local npc = {
    id = "npc_1",
    skills = { Axe = 6, Blunt = 0, Aiming = 0 },
    inventory = {
        worn = {
            Back = "bag_small",
            Jacket = "jacket_cloth",
        },
        equipped = {
            primary = "bat_old",
        },
        containers = {
            bag_small_c = { maxWeight = 12, items = {} },
            bag_mil_c = { maxWeight = 28, items = {} },
        },
        items = {
            bag_small = { id = "bag_small", type = "Base.Bag_Schoolbag", wornSlot = "Back", wearableSlot = "Back", bagContainer = "bag_small_c", maxWeight = 12, weightReduction = 60 },
            bag_mil = { id = "bag_mil", type = "Base.Bag_ALICEpack_Army", wearableSlot = "Back", bagContainer = "bag_mil_c", maxWeight = 28, weightReduction = 87 },
            jacket_cloth = { id = "jacket_cloth", type = "Base.Jacket_WhiteTINT", wornSlot = "Jacket", wearableSlot = "Jacket", biteDefense = 10, scratchDefense = 20, condition = 10, conditionMax = 10 },
            jacket_leather = { id = "jacket_leather", type = "Base.JacketLong_Random", wearableSlot = "Jacket", biteDefense = 30, scratchDefense = 50, bulletDefense = 10, condition = 10, conditionMax = 10 },
            bat_old = { id = "bat_old", type = "Base.BaseballBat", isWeapon = true, weaponSkill = "Blunt", minDamage = 0.8, maxDamage = 1.1, maxRange = 1.25, condition = 10, conditionMax = 10 },
            axe_fire = { id = "axe_fire", type = "Base.Axe", isWeapon = true, weaponSkill = "Axe", minDamage = 0.8, maxDamage = 1.4, maxRange = 1.25, condition = 10, conditionMax = 10 },
            pistol_empty = { id = "pistol_empty", type = "Base.Pistol", isWeapon = true, isRanged = true, hasAmmo = false, minDamage = 2.0, maxDamage = 3.0, maxRange = 10, condition = 10, conditionMax = 10 },
        },
    },
}

local changed, summary = PNC.Inventory.ReconcileBestLoadout(npc, "trade_upgrade")
T.truthy(changed, "ReconcileBestLoadout upgrades bag, armor, and skill-matched weapon")
T.equal(summary.bags, 1, "upgraded to military backpack")
T.equal(summary.armor, 1, "upgraded to leather jacket")
T.equal(summary.weapons, 1, "upgraded to fire axe matching Axe skill (ignoring empty pistol)")
T.equal(npc.inventory.worn.Back, "bag_mil", "military backpack is worn")
T.equal(npc.inventory.worn.Jacket, "jacket_leather", "leather jacket is worn")
T.equal(npc.inventory.equipped.primary, "axe_fire", "fire axe is equipped as primary")

-- 2. Provision rules register weapon_upgrade, armor_upgrade, and bag_upgrade
local registeredRules = {}
PNC.ProvisionRuleRegistry = {
    Register = function(def) registeredRules[def.id] = def end,
}
T.load(SHARED .. "Provision/Rules/PNC_WeaponProvisionRule.lua")
T.load(SHARED .. "Provision/Rules/PNC_ArmorProvisionRule.lua")
T.load(SHARED .. "Provision/Rules/PNC_BagProvisionRule.lua")
T.truthy(registeredRules["weapon_upgrade"], "weapon_upgrade rule registered")
T.truthy(registeredRules["armor_upgrade"], "armor_upgrade rule registered")
T.truthy(registeredRules["bag_upgrade"], "bag_upgrade rule registered")
T.equal(registeredRules["weapon_upgrade"].defaults.enabled, false, "weapon_upgrade has per-type enabled toggle")
T.equal(registeredRules["bag_upgrade"].defaults.enabled, true, "bag_upgrade defaults enabled")

T.finish("pnc_unified_loadout_and_provision_smoke")
