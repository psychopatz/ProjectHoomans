local T = require "tests/support/test"

local CORE_DIR = T.path("ProjectHoomans", "shared", "PNC/Core/")
local CLIENT_DIR = T.path("ProjectHoomans", "client", "PNC/")

T.addPackagePaths()

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

SandboxVars = {
    ProjectHoomans = {
        NPCCarryCapacityMultiplier = 1.0,
    },
}

ZomboidGlobals = {
    EquippedOrWornEncumbranceMultiplier = 0.3,
}

PNC = {
    Const = {
        INVENTORY_OPLOG_MAX = 32,
        GENERATOR_VERSION = 2,
        INVENTORY_HARD_CAPACITY_MULTIPLIER = 3,
        INVENTORY_HARD_CAPACITY = 50,
    },
    Core = {
        DeepCopy = deepCopy,
        LogWarn = function() end,
        LogDebug = function() end,
        Now = function() return 1000 end,
    },
    Registry = {
        MarkDirty = function() end,
    },
    Skills = {
        GetLevel = function() return 2 end,
    },
    Visuals = {
        RefreshModel = function() end,
        ClearAttachedItems = function() end,
    },
}

local ITEM_DEFS = {
    ["Base.Shirt"] = { weight = 1.0, wearable = "Shirt" },
    ["Base.Bag_DuffelBag"] = { weight = 1.0, capacity = 18, reduction = 65, wearable = "Back" },
    ["Base.Bag_BigHikingBag"] = { weight = 1.5, capacity = 28, reduction = 85, wearable = "Back" },
    ["Base.Bag_FannyPackFront"] = { weight = 0.2, capacity = 4, reduction = 50, wearable = "FannyPackFront" },
    ["Base.Garbagebag"] = { weight = 0.2, capacity = 20, reduction = 25 },
    ["Base.Axe"] = { weight = 3.0, weapon = true, twoHand = true, minDmg = 1.0, maxDmg = 1.0 },
    ["Base.Hammer"] = { weight = 1.0, weapon = true, twoHand = false, minDmg = 1.0, maxDmg = 1.0 },
    ["Base.Shotgun"] = { weight = 4.0, weapon = true, twoHand = true, bothHands = true, minDmg = 2.0, maxDmg = 2.0 },
    ["Base.CannedBeans"] = { weight = 2.0 },
}

local function makeNativeItem(fullType)
    local def = ITEM_DEFS[fullType] or { weight = 1.0 }
    return {
        getFullType = function() return fullType end,
        getActualWeight = function() return def.weight or 1.0 end,
        getCapacity = function() return def.capacity or 0 end,
        getMaxCapacity = function() return -1 end,
        getWeightReduction = function() return def.reduction or 0 end,
        canBeEquipped = function() return def.wearable end,
        getBodyLocation = function() return def.wearable end,
        IsWeapon = function() return def.weapon == true end,
        isTwoHandWeapon = function() return def.twoHand == true end,
        isRequiresEquippedBothHands = function() return def.bothHands == true end,
        getMinDamage = function() return def.minDmg or 0.5 end,
        getMaxDamage = function() return def.maxDmg or 0.5 end,
    }
end

function instanceItem(fullType)
    return makeNativeItem(fullType)
end

T.load(CORE_DIR .. "Base/PNC_Sandbox.lua")
T.load(CORE_DIR .. "Equipment/PNC_Equipment_Slots.lua")
T.load(CORE_DIR .. "Equipment/PNC_Equipment.lua")
PNC.Equipment.CreateItem = function(fullType)
    return makeNativeItem(fullType), "mock"
end
T.load(CORE_DIR .. "Inventory/PNC_Inventory.lua")
T.load(CORE_DIR .. "Inventory/InventoryActions/PNC_InventoryActions.lua")

local record = {
    id = "npc_bag_test_1",
    name = "Courier",
    archetypeID = "General",
    identitySeed = 42,
    inventory = PNC.Inventory.Internal.createBaseInventory({ id = "npc_bag_test_1" }),
}
PNC.Inventory.EnsureRecordInventory(record)

-- 1. Worn clothing uses 0.3 encumbrance multiplier
local okShirt, _, shirtIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Shirt", stack = 1 },
}, "root", "test_shirt")
T.equal(okShirt, true, "shirt added")
T.equal(PNC.Inventory.SetWorn(record, shirtIDs[1], "Shirt", "wear_shirt"), true, "shirt worn")
T.near(record.inventory.cachedWeight, 0.3, 0.0001, "worn shirt weighs 30%")

-- 2. Auto-equip best backpack & fanny pack on AddItems
local okDuffel, _, duffelIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Bag_DuffelBag", stack = 1 },
    { type = "Base.Bag_FannyPackFront", stack = 1 },
}, "root", "test_bags")
T.equal(okDuffel, true, "bags added")
local duffel = record.inventory.items[duffelIDs[1]]
local fanny = record.inventory.items[duffelIDs[2]]
T.equal(duffel.wornSlot, "Back", "duffel auto-equipped on Back")
T.equal(fanny.wornSlot, "FannyPackFront", "fanny pack auto-equipped simultaneously")
T.near(record.inventory.equippedBagCapacity, 22, 0.0001, "equipped bag capacity sums backpack + fanny")

-- 3. Default AddItems routes loose items into highest-reduction bag first, then spills to fanny pack
local okBeans, _, beanIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.CannedBeans", stack = 9 }, -- 18.0 fills duffel completely
    { type = "Base.CannedBeans", stack = 1 }, -- 2.0 spills into fanny pack
}, "root", "test_autopack")
T.equal(okBeans, true, "beans auto-packed")
T.equal(record.inventory.items[beanIDs[1]].container, duffel.bagContainer, "first stack packed into duffel")
T.equal(record.inventory.items[beanIDs[2]].container, fanny.bagContainer, "overflow packed into fanny pack")

-- 4. Receiving a better backpack auto-upgrades and migrates contents
local okBig, _, bigIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Bag_BigHikingBag", stack = 1 },
}, "root", "test_upgrade")
T.equal(okBig, true, "big hiking bag added")
local bigBag = record.inventory.items[bigIDs[1]]
T.equal(bigBag.wornSlot, "Back", "big hiking bag replaced duffel on Back")
T.equal(duffel.wornSlot, nil, "duffel unequipped on upgrade")
T.equal(record.inventory.items[beanIDs[1]].container, bigBag.bagContainer, "contents migrated to better bag")

-- 5. Equipping an item that is inside a backpack transfers it to root (PZ parity)
local okAxe, _, axeIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Axe", stack = 1 },
}, "root", "test_axe")
T.equal(okAxe, true, "axe added")
local axe = record.inventory.items[axeIDs[1]]
T.equal(axe.container, bigBag.bagContainer, "axe initially packed in backpack")
T.equal(PNC.Inventory.SetEquipped(record, "primary", axe.id, "equip_axe"), true, "axe equipped primary")
T.equal(axe.container, "root", "equipping primary moved axe from backpack to root")

-- 6. Hand-held Garbage Bag in primary: reduces weight, renders in hand outside combat, blocks weapon swap (shove-only)
local okTrash, _, trashIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Garbagebag", stack = 1 },
}, "root", "test_garbagebag")
T.equal(okTrash, true, "garbage bag added")
local trashBag = record.inventory.items[trashIDs[1]]
T.equal(
    PNC.InventoryActions.Execute("equip_primary", nil, record, trashBag.id, {}),
    true,
    "garbage bag equippable in primary"
)
T.equal(trashBag.equipSlot, "primary", "garbage bag equipped in primary")
local heldPrimary = nil
local fakeZombie = {
    setPrimaryHandItem = function(_, it) heldPrimary = it end,
    getPrimaryHandItem = function() return heldPrimary end,
    setSecondaryHandItem = function() end,
    getSecondaryHandItem = function() return nil end,
    resetEquippedHandsModels = function() end,
    setVariable = function() end,
}
PNC.Equipment.ApplyCombatState(fakeZombie, record, false, true)
T.truthy(heldPrimary ~= nil and heldPrimary:getFullType() == "Base.Garbagebag", "garbage bag rendered in hand when idle")
local fallbackOK, fallbackReason = PNC.Equipment.ActivateMeleeFallback(record, fakeZombie, "out_of_ammo")
T.equal(fallbackOK, false, "combat fallback does not replace hand-held bag")
T.equal(fallbackReason, "carrying_container_shove_only", "shove-only reason returned")

-- 7. Optional bonus + Sandbox multiplier
record.carryCapacityBonus = 10
SandboxVars.ProjectHoomans.NPCCarryCapacityMultiplier = 2.0
PNC.Inventory.RebuildCaches(record)
-- base = 6 + 2 + 1 = 9; (9 + 10) * 2 = 38
T.near(record.inventory.maxWeight, 38, 0.0001, "optional bonus + sandbox multiplier applied to maxWeight")
T.near(record.inventory.totalCapacity, 38 + 28 + 4 + 20, 0.0001, "totalCapacity sums boosted root + all equipped bags")

-- 8. UI Deposit All to Storage detects items inside bags even when root has no loose items
PNC.InventoryWindow = PNC.InventoryWindow or {}
ISPNCInventoryWindow = ISPNCInventoryWindow or {}
PNC.InventoryTransferEndpoint = PNC.InventoryTransferEndpoint or {}
T.load(CLIENT_DIR .. "UI/Inventory/InventoryWindow/_BulkTransfers.lua")
T.equal(
    PNC.InventoryWindow.HasAnyNPCBulkTransferItems(record.inventory),
    true,
    "HasAnyNPCBulkTransferItems finds items inside equipped bags"
)

-- 9. Vanilla parity: one-handed vs two-handed weapon with secondary bag
PNC.Const.STAMINA_MELEE_COST = 20
PNC.Const.STAMINA_RANGED_COST = 10
PNC.Const.STAMINA_DOWNED_SHOVE_COST = 8
PNC.Const.STAMINA_ATTACK_MIN_RESERVE = 10
PNC.CombatResolution = PNC.CombatResolution or {}
PNC.CombatResolution.IsWeaponDamageEnabled = function() return true end
T.load(CORE_DIR .. "Combat/CombatResolution/PNC_CombatResolution_Weapon.lua")
T.load(CORE_DIR .. "Combat/CombatResolution/PNC_CombatResolution_MeleeOutcome.lua")
T.load(CORE_DIR .. "Stamina/PNC_Stamina.lua")

local okWeap, _, weapIDs = PNC.Inventory.AddItems(record, {
    { type = "Base.Hammer", stack = 1 },
    { type = "Base.Shotgun", stack = 1 },
}, "root", "test_weapons")
T.equal(okWeap, true, "test weapons added")
local hammer = record.inventory.items[weapIDs[1]]
local shotgun = record.inventory.items[weapIDs[2]]

-- Secondary garbage bag + one-handed hammer: NO penalty
T.equal(PNC.Inventory.SetEquipped(record, "secondary", trashBag.id, "sec_bag"), true, "bag in secondary")
T.equal(PNC.Inventory.SetEquipped(record, "primary", hammer.id, "pri_hammer"), true, "hammer in primary")
T.equal(PNC.Equipment.IsUsingTwoHandedOneHanded(record, makeNativeItem("Base.Hammer")), false, "one-handed weapon has no two-handed penalty")
local hammerDmg = PNC.CombatResolution.GetAttackDamage(record, "melee", makeNativeItem("Base.Hammer"), 1, 2)
local hammerCd = PNC.CombatResolution.GetMeleeCooldown(record, 1000, {}, {})
local hammerDrain = PNC.Stamina.GetAttackDrain(record, "melee", "Strength")

-- Secondary garbage bag + two-handed axe: usable, 0.5x damage, 1.25x cooldown, 1.75x stamina
T.equal(PNC.Inventory.SetEquipped(record, "primary", axe.id, "pri_axe"), true, "axe in primary with secondary bag")
T.equal(record.inventory.equipped.secondary, trashBag.id, "secondary bag kept with two-handed melee")
T.equal(PNC.Equipment.IsUsingTwoHandedOneHanded(record, makeNativeItem("Base.Axe")), true, "two-handed axe used one-handed detected")
local axeDmg = PNC.CombatResolution.GetAttackDamage(record, "melee", makeNativeItem("Base.Axe"), 1, 2)
local axeCd = PNC.CombatResolution.GetMeleeCooldown(record, 1000, {}, {})
local axeDrain = PNC.Stamina.GetAttackDrain(record, "melee", "Strength")
T.near(axeDmg, hammerDmg * 0.5, 0.0001, "two-handed weapon with secondary bag deals 50% damage")
T.near(axeCd, hammerCd * 1.25, 0.0001, "two-handed weapon with secondary bag has 1.25x cooldown")
T.near(axeDrain, hammerDrain * 1.75, 0.0001, "two-handed weapon with secondary bag drains 1.75x stamina")

-- Both-hands-required shotgun clears secondary bag (and vice-versa)
T.equal(PNC.Inventory.SetEquipped(record, "primary", shotgun.id, "pri_shotgun"), true, "shotgun equipped")
T.equal(record.inventory.equipped.secondary, nil, "both-hands-required weapon cleared secondary bag")
T.equal(PNC.Inventory.SetEquipped(record, "secondary", trashBag.id, "sec_bag_again"), true, "bag re-equipped in secondary")
T.equal(record.inventory.equipped.primary, nil, "secondary bag cleared both-hands-required primary")

T.finish("pnc_inventory_backpack_utilization_smoke")
