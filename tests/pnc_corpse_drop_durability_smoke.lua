local T = require "tests/support/test"

SandboxVars = {
    ProjectHoomans = {},
}

local function makeItem(kind, maxCond, cond)
    local obj = {
        _kind = kind,
        _max = maxCond,
        _cond = cond,
    }
    function obj:getCategory() return self._kind end
    function obj:IsWeapon() return self._kind == "Weapon" end
    function obj:IsClothing() return self._kind == "Clothing" end
    function obj:getConditionMax() return self._max end
    function obj:getCondition() return self._cond end
    function obj:setCondition(v) self._cond = v end
    return obj
end

T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems_Durability.lua")

local apply = PNC.BodyLifecycle.ApplyCorpseDropDurability

-- 1. Default behavior: enabled = true, maxPct = 5 -> unowned NPC weapons & clothing drop at condition 1; food untouched.
local wildRecord = { id = "npc_wild_1" }
local rifle = makeItem("Weapon", 10, 10)
local jacket = makeItem("Clothing", 10, 10)
local brokenBat = makeItem("Weapon", 15, 0)
local cannedFood = makeItem("Food", 10, 10)
local adjusted = apply(wildRecord, { rifle, jacket, brokenBat, cannedFood })
T.equal(adjusted, 3, "Only weapons and clothing should be adjusted")
T.equal(rifle._cond, 1, "Default 5% cap on maxCond=10 weapon should drop at condition 1")
T.equal(jacket._cond, 1, "Default 5% cap on maxCond=10 clothing should drop at condition 1")
T.equal(brokenBat._cond, 0, "Already-broken weapon must never be repaired up to 1 on death")
T.equal(cannedFood._cond, 10, "Food / non-gear items must remain untouched")

-- 2. Recruited / player-owned NPCs are exempt: what they have is what they drop.
local companion = { id = "npc_comp_1", recruited = true, ownerUsername = "player1" }
local compShotgun = makeItem("Weapon", 12, 11)
local compVest = makeItem("Clothing", 10, 9)
local compAdjusted = apply(companion, { compShotgun, compVest })
T.equal(compAdjusted, 0, "Recruited companion should be exempt from corpse durability cap")
T.equal(compShotgun._cond, 11, "Companion weapon should retain exact condition")
T.equal(compVest._cond, 9, "Companion clothing should retain exact condition")

-- 3. Sandbox toggle OFF disables the policy for unowned NPCs too.
SandboxVars.ProjectHoomans.NPCCorpseLowDurabilityLoot = false
local axe = makeItem("Weapon", 15, 15)
T.equal(apply(wildRecord, { axe }), 0, "Disabling sandbox toggle should skip durability reduction")
T.equal(axe._cond, 15, "Weapon should remain full durability when disabled")

-- 4. Max durability = 100 still rolls per item per death within [1, maxCond].
SandboxVars.ProjectHoomans.NPCCorpseLowDurabilityLoot = true
SandboxVars.ProjectHoomans.NPCCorpseLootMaxDurabilityPercent = 100
local rolls = { 0, 5, 9 }
local rollIdx = 0
ZombRand = function(n)
    rollIdx = rollIdx + 1
    return rolls[rollIdx] % n
end
local w1 = makeItem("Weapon", 10, 10)
local w2 = makeItem("Weapon", 10, 10)
local w3 = makeItem("Weapon", 10, 10)
apply(wildRecord, { w1, w2, w3 })
T.equal(w1._cond, 1, "Roll 0 at 100% max should produce condition 1")
T.equal(w2._cond, 6, "Roll 5 at 100% max should produce condition 6")
T.equal(w3._cond, 10, "Roll 9 at 100% max should produce condition 10")

-- 5. Mid-range cap (e.g., 50% of maxCond=10 -> cap 5) rolls within [1, 5].
SandboxVars.ProjectHoomans.NPCCorpseLootMaxDurabilityPercent = 50
ZombRand = function(n) return n - 1 end
local crowbar = makeItem("Weapon", 10, 10)
apply(wildRecord, { crowbar })
T.equal(crowbar._cond, 5, "50% cap on maxCond=10 should cap highest roll at 5")

-- 6. End-to-end PrepareCorpseItems: equipped/worn/attached gear gets capped to 1,
--    while carried unequipped inventory / trader stock stays pristine (10/10).
SandboxVars.ProjectHoomans.NPCCorpseLowDurabilityLoot = true
SandboxVars.ProjectHoomans.NPCCorpseLootMaxDurabilityPercent = 5
local createdByType = {}
local function makeTypedItem(fullType, kind, maxCond, cond)
    local item = makeItem(kind, maxCond, cond)
    function item:getFullType() return fullType end
    return item
end
package.loaded["PsychopatzCore/Inventory/PsychopatzCorpseItems"] = {
    IsAuthority = function() return true end,
    ApplyState = function() end,
    AddExisting = function() end,
}
PNC.BodyLifecycle.Internal.itemFullType = function(it)
    return it and it.getFullType and it:getFullType() or ""
end
PNC.Equipment = {
    CreateItem = function(fullType)
        local kind = fullType:find("Jacket") and "Clothing" or "Weapon"
        local item = makeTypedItem(fullType, kind, 10, 10)
        createdByType[fullType] = createdByType[fullType] or {}
        createdByType[fullType][#createdByType[fullType] + 1] = item
        return item
    end,
}
T.load("ProjectHoomans", "shared", "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems_Materialize.lua")

local traderRecord = {
    id = "npc_trader_1",
    inventory = {
        items = {
            eq_gun = { type = "Base.Pistol", cond = 10, equipSlot = "primary" },
            worn_jkt = { type = "Base.Jacket_ArmyCamo", cond = 10, wornSlot = "Jacket" },
            holster_knife = { type = "Base.HuntingKnife", cond = 10, attachedSlot = "Belt Left" },
            stock_rifle = { type = "Base.AssaultRifle", cond = 10 },
            stock_jacket = { type = "Base.Jacket_Leather", cond = 10 },
        },
    },
}
local mockZombie = {
    getInventory = function() return { getItems = function() return { size = function() return 0 end } end } end,
    setWornItem = function() end,
    setPrimaryHandItem = function() end,
    setSecondaryHandItem = function() end,
}
local okMat = PNC.BodyLifecycle.PrepareCorpseItems(traderRecord, mockZombie)
T.equal(okMat, true, "PrepareCorpseItems should succeed")
T.equal(createdByType["Base.Pistol"][1]._cond, 1, "Equipped primary weapon should drop at condition 1")
T.equal(createdByType["Base.Jacket_ArmyCamo"][1]._cond, 1, "Worn jacket should drop at condition 1")
T.equal(createdByType["Base.HuntingKnife"][1]._cond, 1, "Attached/holstered weapon should drop at condition 1")
T.equal(createdByType["Base.AssaultRifle"][1]._cond, 10, "Carried unequipped trader rifle should remain pristine")
T.equal(createdByType["Base.Jacket_Leather"][1]._cond, 10, "Carried unequipped trader jacket should remain pristine")

print("PASS: pnc_corpse_drop_durability_smoke")
