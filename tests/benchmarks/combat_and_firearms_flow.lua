-- Repeatable CPU micro-benchmark and combat / firearms / conflict verifier.
-- Usage:
--   lua tests/benchmarks/combat_and_firearms_flow.lua
local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local failures = {}
local function check(cond, msg)
    if not cond then
        failures[#failures + 1] = tostring(msg)
        print("[FAIL] " .. tostring(msg))
    end
end

local function msSince(t0)
    return (os.clock() - t0) * 1000.0
end

local nowMs = 50000
local counts = {
    scriptGetItem = 0,
    weaponMethod = 0,
    createItem = 0,
    deepCopy = 0,
    refreshCanonical = 0,
    normalizeHydration = 0,
    syncEquipmentFromInv = 0,
    reconcileWater = 0,
    provisionDirty = 0,
    taskEvents = 0,
    tableSort = 0,
    haltMove = 0,
    moveRecord = 0,
    requestMove = 0,
    normalizeLoadout = 0,
    warnLogs = 0,
}

local realTableSort = table.sort
table.sort = function(list, comp)
    counts.tableSort = counts.tableSort + 1
    return realTableSort(list, comp)
end

isServer = function() return true end
isClient = function() return false end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
ZombRand = function() return 0 end
ZombRandFloat = function() return 0.1 end
getText = function(k) return k end
getCurrentSaveName = function() return "bench-combat-firearms" end
getCell = function()
    return {
        getFakeZombieForHit = function() return nil end,
    }
end

local scriptPistol = {
    getDisplayCategory = function() counts.weaponMethod = counts.weaponMethod + 1; return "Firearm" end,
    getClipSize = function() counts.weaponMethod = counts.weaponMethod + 1; return 15 end,
    getMaxAmmo = function() counts.weaponMethod = counts.weaponMethod + 1; return 15 end,
    getAmmoType = function() counts.weaponMethod = counts.weaponMethod + 1; return "Base.Bullets9mm" end,
    getAmmoPerShoot = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
    getReloadTime = function() counts.weaponMethod = counts.weaponMethod + 1; return 16 end,
    getSwingSound = function() counts.weaponMethod = counts.weaponMethod + 1; return "M9Shot" end,
    getSoundRadius = function() counts.weaponMethod = counts.weaponMethod + 1; return 40 end,
    getSoundVolume = function() counts.weaponMethod = counts.weaponMethod + 1; return 40 end,
    getSoundGain = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
    getProjectileCount = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
    getProjectileSpread = function() counts.weaponMethod = counts.weaponMethod + 1; return 0.2 end,
    getMaxRange = function() counts.weaponMethod = counts.weaponMethod + 1; return 11 end,
    isPiercingBullets = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
    getImpactSound = function() counts.weaponMethod = counts.weaponMethod + 1; return "BulletHit" end,
    getShellFallSound = function() counts.weaponMethod = counts.weaponMethod + 1; return "ShellFall" end,
    isManuallyRemoveSpentRounds = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
    isRackAfterShoot = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
    getActualWeight = function() return 1.0 end,
}
local scriptBlade = {
    getActualWeight = function() return 1.5 end,
}
local scriptLight = {
    getActualWeight = function() return 0.02 end,
}

getScriptManager = function()
    return {
        getItem = function(_, ft)
            counts.scriptGetItem = counts.scriptGetItem + 1
            local key = tostring(ft or "")
            if key == "Base.Machete" then return scriptBlade end
            if key == "Base.Pistol" then return scriptPistol end
            return scriptLight
        end,
    }
end

WeaponType = {
    FIREARM = "FIREARM",
    HANDGUN = "HANDGUN",
    SPEAR = "SPEAR",
    TWO_HANDED = "TWO_HANDED",
    HEAVY = "HEAVY",
    ONE_HANDED = "ONE_HANDED",
    getWeaponType = function(item)
        if item and item.isRanged and item:isRanged() then
            return "HANDGUN"
        end
        return "ONE_HANDED"
    end,
}

local function makeWeaponDouble(fullType, ranged)
    return {
        __class = "HandWeapon",
        isWeapon = true,
        IsWeapon = function() return true end,
        isRanged = function() return ranged == true end,
        getFullType = function() counts.weaponMethod = counts.weaponMethod + 1; return fullType end,
        getAmmoType = function() counts.weaponMethod = counts.weaponMethod + 1; return ranged and "Base.Bullets9mm" or nil end,
        getMaxAmmo = function() counts.weaponMethod = counts.weaponMethod + 1; return ranged and 15 or 0 end,
        getClipSize = function() counts.weaponMethod = counts.weaponMethod + 1; return ranged and 15 or 0 end,
        getAmmoPerShoot = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
        getSwingSound = function() counts.weaponMethod = counts.weaponMethod + 1; return ranged and "M9Shot" or "MacheteSwing" end,
        getSoundRadius = function() counts.weaponMethod = counts.weaponMethod + 1; return 40 end,
        getSoundVolume = function() counts.weaponMethod = counts.weaponMethod + 1; return 40 end,
        getSoundGain = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
        getProjectileCount = function() counts.weaponMethod = counts.weaponMethod + 1; return 1 end,
        getProjectileSpread = function() counts.weaponMethod = counts.weaponMethod + 1; return 0.2 end,
        getMaxRange = function() counts.weaponMethod = counts.weaponMethod + 1; return ranged and 11 or 1.4 end,
        isPiercingBullets = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
        getImpactSound = function() counts.weaponMethod = counts.weaponMethod + 1; return "BulletHit" end,
        getShellFallSound = function() counts.weaponMethod = counts.weaponMethod + 1; return "ShellFall" end,
        isManuallyRemoveSpentRounds = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
        isRackAfterShoot = function() counts.weaponMethod = counts.weaponMethod + 1; return false end,
        setCurrentAmmoCount = function() end,
        getConditionLowerChance = function() return 1 end,
        getCondition = function() return 10 end,
        getConditionMax = function() return 10 end,
        getSwingAnim = function() return ranged and "Handgun" or "1Handed" end,
    }
end

local weaponPistol = makeWeaponDouble("Base.Pistol", true)
local weaponBlade = makeWeaponDouble("Base.Machete", false)

instanceof = function(obj, className)
    return obj ~= nil and obj.__class == className
end
instanceItem = function(fullType)
    if tostring(fullType or "") == "Base.Pistol" then return weaponPistol end
    if tostring(fullType or "") == "Base.Machete" then return weaponBlade end
    return {
        getFullType = function() return fullType end,
        getActualWeight = function() return 0.1 end,
    }
end

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function deepCopyCounted(value)
    if type(value) ~= "table" then return value end
    counts.deepCopy = counts.deepCopy + 1
    local output = {}
    for k, v in pairs(value) do
        output[k] = deepCopyCounted(v)
    end
    return output
end

local spatialZombies = {}
local spatialNPCs = {}
local liveBodies = {}
local logMessages = {}

PNC = {
    Const = {
        GENERATOR_VERSION = 4,
        PRESENCE_LIVE = "LIVE",
        MELEE_RANGE = 1.3,
        MELEE_COMMIT_RANGE = 1.15,
        MELEE_HIT_TOLERANCE = 0.12,
        MELEE_APPROACH_STOP_DISTANCE = 0.92,
        RANGED_RANGE = 8.5,
        RANGED_PREFERRED_MIN_DISTANCE = 5.0,
        RANGED_MIN_STANDOFF = 2.2,
        RANGED_RETREAT_STEP = 3.2,
        RANGED_PRESSURE_COUNT = 2,
        RANGED_FIRE_LANE_STRAFE_DISTANCE = 1.6,
        RANGED_FIRE_LANE_LOCK_MS = 500,
        RANGED_FIRE_LANE_CORRIDOR = 0.62,
        RANGED_AIM_BASE_MS = 100,
        RANGED_AIM_MIN_MS = 100,
        RANGED_AIM_SKILL_REDUCTION_MS = 10,
        RANGED_AIM_DISTANCE_PENALTY_MS = 5,
        RANGED_AIM_PRESSURE_PENALTY_MS = 10,
        RANGED_AIM_MOVE_TOLERANCE = 0.35,
        COMBAT_HORDE_RADIUS = 5.5,
        COMBAT_HORDE_COUNT = 4,
        COMBAT_PRESSURE_RADIUS = 3.0,
        COMBAT_SURROUND_RADIUS = 1.8,
        COMBAT_SURROUND_COUNT = 3,
        COMBAT_TARGET_CROWD_RADIUS = 2.2,
        COMBAT_TARGET_CROWD_COUNT = 3,
        COMBAT_KITE_RETREAT_LOCK_MS = 450,
        COMBAT_KITE_DAMAGE_LOCK_MS = 700,
        COMBAT_KITE_DAMAGE_DISTANCE = 2.4,
        COMBAT_RETREAT_STAMINA_RATIO = 0.15,
        COMBAT_RETREAT_SAFETY_BUFFER = 0.25,
        COMBAT_RETREAT_STALL_MS = 900,
        COMBAT_RETREAT_RETRY_MS = 800,
        COMBAT_RETREAT_PROGRESS_DISTANCE = 0.18,
        COMBAT_TACTICAL_RETREAT_MIN_PRESSURE = 2,
        COMBAT_SHOVE_RANGE = 1.35,
        COMBAT_SHOVE_PRESSURE_COUNT = 2,
        COMBAT_BLOCK_LOG_REPEAT_MS = 5000,
        DEBUG_COMBAT_HOLD_MS = 1500,
        UNARMED_COOLDOWN_MS = 800,
        UNARMED_DAMAGE = 5,
        UNARMED_GROUND_DAMAGE = 9,
        NPC_ZOMBIE_DEFENSE_RADIUS = 2.2,
        NPC_ZOMBIE_DEFENSE_REFRESH_MS = 200,
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        ORDER_FOLLOW = "follow",
        MODULE = "PNC",
        CMD_FIREARM_SHOT = "FirearmShot",
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        DeepCopy = deepCopyCounted,
        Clamp = function(v, lo, hi) return math.max(lo, math.min(hi, v)) end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
            local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return dx * dx + dy * dy
        end,
        LogWarn = function() end,
        LogRecordDebug = function() end,
        Log = function(level, msg)
            if level == "WARN" then counts.warnLogs = counts.warnLogs + 1 end
            logMessages[#logMessages + 1] = tostring(level) .. ":" .. tostring(msg)
        end,
        IsManagedNPCBody = function() return false end,
    },
    Registry = {
        MarkDirty = function() end,
        Get = function() return nil end,
        GetLiveZombie = function(id) return liveBodies[id] end,
    },
    Skills = {
        GetLevel = function() return 4 end,
        AddXP = function() end,
        ResolveWeaponSkill = function() return "LongBlade" end,
    },
    Sandbox = {
        CompanionAmmoRealismEnabled = function() return true end,
        IsAmmoConsumptionEnabled = function() return true end,
        IsWeaponConditionEnabled = function() return true end,
    },
    Visuals = {
        RefreshModel = function() end,
        ClearAttachedItems = function() end,
    },
    Stamina = {
        GetRatio = function() return 0.9 end,
        CanSpendAttack = function() return true end,
        SpendAttack = function() end,
    },
    SpatialIndex = {
        QueryZombies = function() return spatialZombies end,
        QueryNPCs = function() return spatialNPCs end,
        QueryPlayers = function() return {} end,
    },
    Perception = {
        GetZombieCandidatesAt = function() return spatialZombies end,
        CanSeeWorldObject = function() return true, "los" end,
        CountEnemyZombies = function() return #spatialZombies end,
        FindZombieByID = function(id)
            for i = 1, #spatialZombies do
                local z = spatialZombies[i]
                local md = z.getModData and z:getModData() or nil
                if md and md.PNC_ZombieID == id then return z end
            end
            return nil
        end,
    },
    NeedsDefinitions = { SUPPLY = {} },
    IndividualNeeds = { RegisterListener = function() end },
    FacilityService = {},
    TaskEvents = {
        Emit = function() counts.taskEvents = counts.taskEvents + 1 end,
    },
    ProvisionScheduler = {
        MarkInventoryDirty = function() counts.provisionDirty = counts.provisionDirty + 1 end,
    },
    HomeDutyService = { GetBase = function() return { id = "b1" } end },
    NeedsScheduler = {},
    NeedFacilityEffects = { Tick = function() return false end },
    NeedSupplyBridge = {},
    NeedFacilityTriggers = { Internal = { RecordFor = function() return nil end } },
    NeedFacilityTriggerDefinitions = { List = function() return {} end },
    SupplyInventory = { EnsurePersonalInventory = function() end },
    FirearmEffects = { Emit = function() return true end },
    CombatResolution = {
        IsAmmoConsumptionEnabled = function() return true end,
        IsWeaponConditionEnabled = function() return true end,
        ApplyTargetDamage = function() return true, "hit_zombie" end,
        ResolveRangedShot = function() return true, "ranged_hit", { hitChance = 1 } end,
        ResolveMeleeStrike = function() return true, "melee_hit", { hitChance = 1 } end,
        ApplyWeaponConditionLoss = function(rec, wItem)
            local inv = PNC.Inventory.EnsureRecordInventory(rec)
            local itemID = inv and inv.equipped and inv.equipped.primary
            local item = itemID and inv.items[itemID]
            if not item then return false end
            local cond = math.max(0, (tonumber(item.cond) or 10) - 1)
            return PNC.Inventory.ApplyDelta(rec, {{ op = "update", itemID = itemID, cond = cond }}, "combat_condition") == true
        end,
        ConsumeAmmo = function(rec, wItem)
            return PNC.Firearms.PrepareShot(rec, wItem)
        end,
    },
    PathService = {
        IsTraversalActive = function() return false end,
        Reset = function() end,
        RequestCombatFacing = function() return true end,
    },
    BehaviorCommon = {
        SetCombatDebug = function(rec, _, reason) rec.runtime.combatBlockReason = reason end,
        HaltMovement = function(rec, _, reason)
            counts.haltMove = counts.haltMove + 1
            rec.runtime.lastHaltReason = reason
            if PNC.BehaviorMoveIntent and PNC.BehaviorMoveIntent.Hold then
                PNC.BehaviorMoveIntent.Hold(rec, reason)
            end
        end,
        MoveRecord = function(rec, _, x, y, z, mode, stopDist, reason)
            counts.moveRecord = counts.moveRecord + 1
            rec.runtime.lastMoveReason = reason
            return true
        end,
        ResolveCombatApproachMode = function(_, mode) return mode or "run" end,
    },
}
PNC.Tasking = { Commands = { RegisterProvider = function() end }, Events = PNC.TaskEvents }

T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Slots.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment.lua")
PNC.Equipment.CreateItem = function(ft)
    counts.createItem = counts.createItem + 1
    if tostring(ft or "") == "Base.Machete" then return weaponBlade, "mock" end
    return weaponPistol, "mock"
end

T.load("ProjectHoomans", "shared", "PNC/Core/Inventory/PNC_Inventory.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception_Frame.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Firearms.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/CombatTactics/PNC_Combat_Tactics.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Ranged.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Melee.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/AttackExecution/PNC_AttackExecution.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Engagement.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_MoveIntent.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Combat.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatRetreat.lua")
T.load("ProjectHoomans", "server", "PNC/Provision/PNC_Provision.lua")
T.load("ProjectHoomans", "server", "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_Provider_Lifecycle.lua")

-- Spy on the real Provision.Scheduler wired inside PNC_Provision.lua
if PNC.Provision and PNC.Provision.Scheduler then
    local origMarkInvDirty = PNC.Provision.Scheduler.MarkInventoryDirty
    PNC.Provision.Scheduler.MarkInventoryDirty = function(...)
        counts.provisionDirty = counts.provisionDirty + 1
        if origMarkInvDirty then return origMarkInvDirty(...) end
    end
end

-- Provide minimal FollowOwnerCombatRetreat binding since full AbstractFollowOwner loader wasn't needed
local origFollowRetreatLoader = PNC.BehaviorCompanion.Internal.FollowOwnerCombatRetreat
if not origFollowRetreatLoader or not origFollowRetreatLoader.TryHandle then
    PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
    PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}
    PNC.BehaviorCompanion.Internal.FollowOwnerCombatRetreat = {
        Const = PNC.Const,
        CombatTactics = PNC.CombatTactics,
        BehaviorCombat = PNC.BehaviorCombat,
        SetFollowMode = function(r, m) r.runtime.followMode = m end,
    }
    T.load("ProjectHoomans", "shared", "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner_CombatRetreat.lua")
end

-- Wrap internal counters to prove skips without mutating behavior
local origNormalize = PNC.Inventory.Internal.normalizeHydrationItems
PNC.Inventory.Internal.normalizeHydrationItems = function(...)
    counts.normalizeHydration = counts.normalizeHydration + 1
    return origNormalize(...)
end
local origSyncEquipInv = PNC.Inventory.SyncEquipmentFromInventory
PNC.Inventory.SyncEquipmentFromInventory = function(...)
    counts.syncEquipmentFromInv = counts.syncEquipmentFromInv + 1
    return origSyncEquipInv(...)
end
local origRefreshCanonical = PNC.Inventory.CoreBridge.refreshCanonical
PNC.Inventory.CoreBridge.refreshCanonical = function(...)
    counts.refreshCanonical = counts.refreshCanonical + 1
    return origRefreshCanonical(...)
end
local origReconcileWater = PNC.Inventory.ReconcileWaterContainer
PNC.Inventory.ReconcileWaterContainer = function(...)
    counts.reconcileWater = counts.reconcileWater + 1
    if origReconcileWater then return origReconcileWater(...) end
end
local origNormLoadout = PNC.Equipment.NormalizeLoadoutSpec
PNC.Equipment.NormalizeLoadoutSpec = function(...)
    counts.normalizeLoadout = counts.normalizeLoadout + 1
    return origNormLoadout(...)
end
local origLooseEntries = PNC.Combat.Internal.LooseAmmoEntries
counts.looseAmmoEntries = 0
PNC.Combat.Internal.LooseAmmoEntries = function(...)
    counts.looseAmmoEntries = counts.looseAmmoEntries + 1
    return origLooseEntries(...)
end

local origReqMove = PNC.BehaviorMoveIntent.RequestMove
PNC.BehaviorMoveIntent.RequestMove = function(rec, x, y, z, mode, stopDist, reason, ...)
    counts.requestMove = counts.requestMove + 1
    return origReqMove(rec, x, y, z, mode, stopDist, reason, ...)
end

local function makeGunnerRecord(id, x, y, multiAmmoStacks)
    local items = {
        gun = { id = "gun", type = "Base.Pistol", stack = 1, container = "root", equipSlot = "primary", ammoCount = 15, cond = 10 },
    }
    local rootList = { "gun" }
    for i = 1, 19 do
        local itemId = "item_" .. i
        local itemType
        local stackSize = 1
        if multiAmmoStacks then
            itemType = (i <= 3) and "Base.Bullets9mm" or ("Base.SupplyItem_" .. i)
            stackSize = (i <= 3) and 20 or 1
        else
            itemType = (i == 1) and "Base.Bullets9mm" or ("Base.SupplyItem_" .. i)
            stackSize = (i == 1) and 60 or 1
        end
        items[itemId] = {
            id = itemId,
            type = itemType,
            stack = stackSize,
            container = "root",
        }
        rootList[#rootList + 1] = itemId
    end
    local rec = {
        id = id,
        tacticalClass = "colonist",
        recruited = true,
        alive = true,
        presenceState = PNC.Const.PRESENCE_LIVE,
        weaponMode = "ranged",
        x = x or 10,
        y = y or 10,
        z = 0,
        stamina = { current = 90, max = 100 },
        equipment = {
            primaryFullType = "Base.Pistol",
            worn = { Torso = "Base.Shirt_Denim", Legs = "Base.Trousers", Feet = "Base.Shoes_Black", Back = "Base.Bag_NormalHikingBag" },
            wornVisuals = {},
            attached = { HolsterRight = "Base.Pistol" },
        },
        inventory = {
            revision = 1,
            cachedWeight = 5,
            maxWeight = 12,
            rootMaxWeight = 12,
            equipped = { primary = "gun" },
            worn = {},
            attached = {},
            items = items,
            containers = { root = { maxWeight = 12, items = rootList } },
            template = { generatorVersion = 4 },
        },
        runtime = { inventory = { nextItemSerial = 100, opLog = {} } },
    }
    local body = {
        _x = rec.x, _y = rec.y, _z = 0,
        getX = function(self) return self._x end,
        getY = function(self) return self._y end,
        getZ = function(self) return self._z end,
        getPrimaryHandItem = function() return weaponPistol end,
        getSecondaryHandItem = function() return nil end,
        setPrimaryHandItem = function() end,
        setSecondaryHandItem = function() end,
        setVariable = function() end,
        getAttachedItem = function() return nil end,
        setAttachedItem = function() end,
        faceThisObject = function() end,
        faceLocation = function() end,
    }
    liveBodies[id] = body
    return rec, body
end

-- Warmup hydration once
local gunner, gunnerBody = makeGunnerRecord("bench_gunner", 10, 10)
PNC.Inventory.EnsureRecordInventory(gunner)

print("=== 1. INVENTORY HYDRATION FAST-PATH (1000x, 20 ITEMS) ===")
counts.normalizeHydration = 0
counts.refreshCanonical = 0
counts.syncEquipmentFromInv = 0
counts.reconcileWater = 0
local t0 = os.clock()
for i = 1, 1000 do
    PNC.Inventory.EnsureRecordInventory(gunner)
end
local dtEnsure = msSince(t0)
print(string.format("  1000x EnsureRecordInventory: %.2fms (%.4f ms/call) | normalize=%d refreshCanonical=%d sync=%d",
    dtEnsure, dtEnsure / 1000, counts.normalizeHydration, counts.refreshCanonical, counts.syncEquipmentFromInv))
check(dtEnsure < 10.0, "1000x EnsureRecordInventory fast-path should be < 10ms (got " .. string.format("%.2fms", dtEnsure) .. ")")
check(counts.normalizeHydration == 0, "EnsureRecordInventory fast-path skipped normalizeHydrationItems")
check(counts.refreshCanonical == 0, "EnsureRecordInventory fast-path skipped refreshCanonical")
check(counts.syncEquipmentFromInv == 0, "EnsureRecordInventory fast-path skipped SyncEquipmentFromInventory")

-- Verify forceHydration and post-revision fallback still work
PNC.Inventory.EnsureRecordInventory(gunner, { forceHydration = true })
check(counts.normalizeHydration == 1, "forceHydration=true still runs full normalization")
check(counts.refreshCanonical == 1, "forceHydration=true still refreshes canonical store")

print("\n=== 2. LIGHTWEIGHT SCALAR APPLYDELTA (200x FIRE/WEAR) + SERIALIZE ROUNDTRIP ===")
counts.deepCopy = 0
counts.syncEquipmentFromInv = 0
counts.refreshCanonical = 0
counts.provisionDirty = 0
counts.taskEvents = 0
t0 = os.clock()
for i = 1, 200 do
    local ok = PNC.Inventory.ApplyDelta(gunner, {{ op = "update", itemID = "gun", ammoCount = (i % 15) + 1 }}, "combat_round_fired")
    check(ok == true, "scalar combat_round_fired ApplyDelta succeeded")
end
local dtDelta = msSince(t0)
print(string.format("  200x combat_round_fired ApplyDelta: %.2fms (%.4f ms/call) | deepCopy=%d sync=%d refreshCanonical=%d provisionDirty=%d taskEvents=%d",
    dtDelta, dtDelta / 200, counts.deepCopy, counts.syncEquipmentFromInv, counts.refreshCanonical, counts.provisionDirty, counts.taskEvents))
check(counts.deepCopy == 0, "scalar ApplyDelta executed 0 DeepCopy calls")
check(counts.syncEquipmentFromInv == 0, "scalar ApplyDelta skipped SyncEquipmentFromInventory")
check(counts.refreshCanonical == 0, "scalar ApplyDelta deferred CoreBridge.refreshCanonical")
check(counts.provisionDirty == 0, "combat_round_fired did not wake ProvisionScheduler")
check(counts.taskEvents == 0, "combat_round_fired did not emit TaskEvents")

-- Check EnsureRecordInventory still stays on fast path after scalar ApplyDelta!
counts.normalizeHydration = 0
counts.refreshCanonical = 0
PNC.Inventory.EnsureRecordInventory(gunner)
check(counts.normalizeHydration == 0 and counts.refreshCanonical == 0,
    "EnsureRecordInventory stayed on fast path after scalar ApplyDelta")

-- Check combat_condition also stays fast & triggers rollback cleanly on failure
local okCond = PNC.Inventory.ApplyDelta(gunner, {{ op = "update", itemID = "gun", cond = 7 }}, "combat_condition")
check(okCond == true, "combat_condition scalar ApplyDelta succeeded")
check(counts.provisionDirty == 0 and counts.taskEvents == 0, "combat_condition did not wake Provision/Tasking")
local okFail = PNC.Inventory.ApplyDelta(gunner, {
    { op = "update", itemID = "gun", ammoCount = 1, cond = 1 },
    { op = "update", itemID = "nonexistent_item", cond = 1 },
}, "combat_round_fired")
check(okFail == false, "failing scalar batch returned false")
check(gunner.inventory.items.gun.ammoCount == ((200 % 15) + 1) and gunner.inventory.items.gun.cond == 7,
    "scalar undo restored exact ammoCount and cond after failure")

-- Verify non-combat inventory change STILL wakes Provision & NeedFacilityTriggers
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
counts.provisionDirty = 0
counts.taskEvents = 0
EventBus.emit(EventTypes.NPC_INVENTORY_CHANGED, gunner, {}, "loot_pickup")
check(counts.provisionDirty == 1 and counts.taskEvents == 1,
    "non-combat inventory event still wakes Provision and NeedFacilityTriggers")

-- Check CoreBridge.serialize reflects updated scalar values
local encoded = PNC.Inventory.CoreBridge.serialize(gunner)
check(type(encoded) == "table", "CoreBridge.serialize succeeded after deferred scalar updates")
local decodedRec = { id = "decoded_check", runtime = {} }
local restoredInv = PNC.Inventory.CoreBridge.deserialize(decodedRec, encoded)
check(restoredInv and restoredInv.items.gun.ammoCount == ((200 % 15) + 1),
    "serialized Core inventory retained exact scalar ammoCount")
check(restoredInv and restoredInv.items.gun.cond == 7,
    "serialized Core inventory retained exact scalar cond")

print("\n=== 3. FIREARMS DESCRIBE CACHE, COUNTLOOSEAMMO & TRY-RANGED ===")
local r2, r2Body = makeGunnerRecord("bench_firearm_cache", 20, 20, true)
PNC.Inventory.EnsureRecordInventory(r2)
counts.scriptGetItem = 0
counts.weaponMethod = 0
counts.tableSort = 0
t0 = os.clock()
for i = 1, 1000 do
    local mag, mReason = PNC.Firearms.GetMagazineState(r2, weaponPistol, { skipLooseAmmoWhenLoaded = true })
    check(mag ~= nil and mReason == "magazine_ready", "GetMagazineState fast query succeeded")
end
local dtMag = msSince(t0)
print(string.format("  1000x GetMagazineState: %.2fms (%.4f ms/call) | scriptGetItem=%d weaponMethod=%d tableSort=%d",
    dtMag, dtMag / 1000, counts.scriptGetItem, counts.weaponMethod, counts.tableSort))
check(counts.scriptGetItem <= 2, "Firearms.Describe cache reduced scriptGetItem to <= 2 over 1000 calls (got " .. counts.scriptGetItem .. ")")
check(counts.weaponMethod <= 50, "Firearms.Describe cache cut Java weapon calls by >95% (got " .. counts.weaponMethod .. ")")
check(counts.tableSort == 0, "GetMagazineState skipped table.sort when magazine loaded")

-- Verify CountLooseAmmo (explicit call) also does zero table.sort calls
counts.tableSort = 0
local totalLoose = PNC.Combat.Internal.CountLooseAmmo(r2.inventory, "Base.Bullets9mm", "gun")
check(totalLoose == 60, "CountLooseAmmo summed all loose rounds accurately (expected 60, got " .. tostring(totalLoose) .. ")")
check(counts.tableSort == 0, "CountLooseAmmo skipped unnecessary table.sort")

print("\n=== 4. RANGED HALT/REPATH CONFLICT & STRAFE LOCK CHECK ===")
local r3, r3Body = makeGunnerRecord("bench_ranged_conflict", 10, 10)
PNC.Inventory.EnsureRecordInventory(r3)
local zombie1 = {
    isDead = function() return false end,
    getX = function() return 13.0 end,
    getY = function() return 10.0 end,
    getZ = function() return 0 end,
    getModData = function() return { PNC_ZombieID = "z_ranged_1" } end,
}
spatialZombies = { zombie1 }
spatialNPCs = {}
local targetZ = { kind = "zombie", zombieId = "z_ranged_1", x = 13.0, y = 10.0, z = 0, distSq = 9, visible = true, worldObject = zombie1 }

-- Part 4A: Cooldown active + within preferred min dist -> starts locked retreat, next 11 ticks must NOT call HaltMovement or reissue RequestMove every tick
nowMs = 100000
counts.haltMove = 0
counts.requestMove = 0
r3.runtime.lastAttackAt = nowMs -- force cooldown_active
for step = 1, 12 do
    nowMs = nowMs + 50
    PNC.CombatEngagement.Tick(r3, r3Body, targetZ)
end
check(counts.haltMove == 1,
    "active ranged_disengage retreat suppressed HaltMovement across all locked ticks (haltMove=" .. counts.haltMove .. ")")
check(counts.requestMove >= 1 and counts.requestMove <= 3,
    "locked ranged retreat throttled RequestMove over 600ms (requestMove=" .. counts.requestMove .. ")")

-- Verify MoveIntent.Hold deduplicates revision on identical holds
local holdTestRec = { id = "bench_hold_dedup", activeJob = "Combat", runtime = {} }
PNC.BehaviorMoveIntent.Hold(holdTestRec, "ranged_aim")
local holdRev1 = holdTestRec.runtime.moveIntent.revision
PNC.BehaviorMoveIntent.Hold(holdTestRec, "ranged_aim")
check(holdTestRec.runtime.moveIntent.revision == holdRev1,
    "repeated identical MoveIntent.Hold did not churn intent.revision")

-- Part 4B: Friendly fire risk -> starts phase='strafe', FollowOwnerCombatRetreat honors it, ContinueLockedRetreat holds 500ms lock
local r4, r4Body = makeGunnerRecord("bench_strafe_lock", 10, 10)
PNC.Inventory.EnsureRecordInventory(r4)
r4.runtime.lastAttackAt = 0 -- ready to fire
local blockerNpc = { id = "ally_1", tacticalClass = "colonist", alive = true, x = 13.0, y = 10.0, z = 0, orderSpec = { kind = "follow" } }
local zombieFar = {
    isDead = function() return false end,
    getX = function() return 16.0 end,
    getY = function() return 10.0 end,
    getZ = function() return 0 end,
    getModData = function() return { PNC_ZombieID = "z_far_1" } end,
}
spatialZombies = { zombieFar }
spatialNPCs = { blockerNpc }
PNC.SpatialIndex.IsFriendly = nil
PNC.Affiliation = nil
-- Add IsProtectedNPC friendly check by putting both in same faction
r4.affiliation = { factionID = "f1" }
blockerNpc.affiliation = { factionID = "f1" }
local farTarget = { kind = "zombie", zombieId = "z_far_1", x = 16.0, y = 10.0, z = 0, distSq = 36, visible = true, worldObject = zombieFar }
counts.haltMove = 0
counts.requestMove = 0
nowMs = 200000
for step = 1, 10 do
    nowMs = nowMs + 45
    PNC.CombatEngagement.Tick(r4, r4Body, farTarget)
end
check(r4.runtime.combatRetreat and r4.runtime.combatRetreat.phase == "strafe",
    "friendly_fire_risk initiated phase=strafe")
check(counts.haltMove <= 1,
    "strafe lock prevented repeated HaltMovement thrash (haltMove=" .. counts.haltMove .. ")")
check(counts.requestMove <= 3,
    "ContinueLockedRetreat honored strafe lock over 450ms instead of repathing all 10 ticks (requestMove=" .. counts.requestMove .. ")")
local followRetreatHandled = PNC.BehaviorCompanion.Internal.FollowOwnerCombatRetreat.TryHandle(r4, r4Body, nowMs)
check(followRetreatHandled == true, "FollowOwnerCombatRetreat honored phase='strafe'")
check(_G.maintainRangedSpacing == nil, "maintainRangedSpacing no longer leaks into _G")

print("\n=== 5. ATTACK EXECUTION: 0 THROWAWAY WEAPONS, DZ=0.35 HIT, ZOMBIE WARN THROTTLED ===")
local mRec, mBody = makeGunnerRecord("bench_melee", 5, 5)
mRec.weaponMode = "melee"
mRec.equipment.primaryFullType = "Base.Machete"
mRec.inventory.items.gun.type = "Base.Machete"
mRec.inventory.items.gun.ammoCount = nil
mBody.getPrimaryHandItem = function() return weaponBlade end
PNC.Inventory.EnsureRecordInventory(mRec)
local slopeZombie = {
    isDead = function() return false end,
    getX = function() return 5.4 end,
    getY = function() return 5.0 end,
    getZ = function() return 0.35 end,
    getModData = function() return { PNC_ZombieID = "z_slope_1" } end,
}
local outOfRangeZombie = {
    isDead = function() return false end,
    getX = function() return 8.0 end,
    getY = function() return 5.0 end,
    getZ = function() return 0 end,
    getModData = function() return { PNC_ZombieID = "z_miss_1" } end,
}
spatialZombies = { slopeZombie, outOfRangeZombie }
local slopeTarget = { kind = "zombie", zombieId = "z_slope_1", x = 5.4, y = 5.0, z = 0.35, worldObject = slopeZombie }
check(PNC.Combat.Internal.AttackExecution.isCommittedMeleeTargetInRange(mBody, slopeTarget) == true,
    "committed melee hit check accepts dz=0.35 matching commit distance")
counts.createItem = 0
local hitOk, hitReason = PNC.Combat.Internal.applyAttackActionHit(mRec, mBody, {
    attackType = "melee", attackKind = "melee", damage = 10, skillID = "LongBlade",
    weaponFullType = "Base.Machete",
}, slopeTarget)
check(hitOk == true, "applyAttackActionHit succeeded on slope zombie (reason=" .. tostring(hitReason) .. ")")
check(mRec.inventory.items.gun.cond == 9, "hit decremented weapon condition via lightweight scalar path (expected 9, got " .. tostring(mRec.inventory.items.gun.cond) .. ")")
check(counts.createItem == 0, "hit resolution used live primary hand item with 0 throwaway CreateItem calls")

-- Check zombie target_out_of_range_at_hit WARN log throttling over 10 misses in 1000ms
counts.warnLogs = 0
nowMs = 300000
for i = 1, 10 do
    nowMs = nowMs + 100
    mRec.runtime.attackAction = {
        attackType = "melee",
        attackKind = "melee",
        hitDone = false,
        hitAt = nowMs,
        finishAt = nowMs + 100,
        target = { kind = "zombie", zombieId = "z_miss_1", x = 8.0, y = 5.0, z = 0, worldObject = outOfRangeZombie },
    }
    PNC.Combat.PumpAttackAction(mRec, mBody)
end
check(counts.warnLogs == 1,
    "zombie target_out_of_range_at_hit WARN logs throttled cleanly (10 misses -> " .. counts.warnLogs .. " log)")

print("\n=== 6. EQUIPMENT APPLYCOMBATSTATE FAST-PATH (1000x UNCHANGED) ===")
local eqRec, eqBody = makeGunnerRecord("bench_equip", 0, 0)
PNC.Equipment.ApplyCombatState(eqBody, eqRec, true)
counts.normalizeLoadout = 0
t0 = os.clock()
for i = 1, 1000 do
    PNC.Equipment.ApplyCombatState(eqBody, eqRec, true)
end
local dtEquip = msSince(t0)
print(string.format("  1000x Equipment.ApplyCombatState (unchanged): %.2fms (%.4f ms/call) | normalizeLoadout=%d",
    dtEquip, dtEquip / 1000, counts.normalizeLoadout))
check(counts.normalizeLoadout == 0, "EnsureRecordEquipment skipped NormalizeLoadoutSpec on unchanged ticks")

print("\n=== 7. MIXED 10 GUNNERS + 10 MELEE COMBAT SIMULATION (50 TICKS = 1000 NPC-TICKS) ===")
local roster = {}
spatialZombies = {}
spatialNPCs = {}
for i = 1, 20 do
    local zx = (i % 5) * 3 + 2
    local zy = math.floor((i - 1) / 5) * 3 + 2
    local zObj = {
        isDead = function() return false end,
        getX = function() return zx + 4 end,
        getY = function() return zy end,
        getZ = function() return 0 end,
        getModData = function() return { PNC_ZombieID = "sim_z_" .. i } end,
    }
    spatialZombies[i] = zObj
    local isGunner = (i <= 10)
    local npcRec, npcBody = makeGunnerRecord("sim_npc_" .. i, zx, zy)
    if not isGunner then
        npcRec.weaponMode = "melee"
        npcRec.equipment.primaryFullType = "Base.Machete"
        npcRec.inventory.items.gun.type = "Base.Machete"
        npcRec.inventory.items.gun.ammoCount = nil
        npcBody.getPrimaryHandItem = function() return weaponBlade end
        zObj.getX = function() return zx + 0.8 end
    end
    PNC.Inventory.EnsureRecordInventory(npcRec)
    PNC.Equipment.ApplyCombatState(npcBody, npcRec, true)
    spatialNPCs[#spatialNPCs + 1] = npcRec
    roster[i] = {
        record = npcRec,
        body = npcBody,
        target = {
            kind = "zombie",
            zombieId = "sim_z_" .. i,
            x = zObj:getX(),
            y = zObj:getY(),
            z = 0,
            distSq = isGunner and 16 or 0.64,
            visible = true,
            worldObject = zObj,
        },
    }
end

counts.deepCopy = 0
counts.refreshCanonical = 0
counts.createItem = 0
counts.scriptGetItem = 0
counts.looseAmmoEntries = 0
nowMs = 500000
t0 = os.clock()
for tick = 1, 50 do
    nowMs = nowMs + 100
    for i = 1, #roster do
        local entry = roster[i]
        PNC.BehaviorCombat.TickEngage(entry.record, entry.body, entry.target)
    end
end
local dtSim = msSince(t0)
print(string.format("  1000 mixed combat NPC-ticks (10 gun + 10 melee): %.2fms (%.4f ms/npc-tick) | deepCopy=%d refreshCanonical=%d createItem=%d scriptGetItem=%d looseAmmoSorts=%d",
    dtSim, dtSim / 1000, counts.deepCopy, counts.refreshCanonical, counts.createItem, counts.scriptGetItem, counts.looseAmmoEntries))
check(counts.deepCopy == 0, "mixed gun+melee simulation performed 0 inventory deep copies")
check(counts.refreshCanonical == 0, "mixed gun+melee simulation performed 0 full canonical rebuilds")
check(counts.createItem == 0, "mixed gun+melee simulation instantiated 0 throwaway HandWeapons")
check(counts.looseAmmoEntries == 0, "mixed gun+melee simulation performed 0 CountLooseAmmo sorts")

if #failures > 0 then
    print(string.format("\nSUMMARY: %d failures", #failures))
    os.exit(1)
else
    print("\nSUMMARY: ALL COMBAT & FIREARMS BENCHMARK + CONFLICT CHECKS PASSED")
end
