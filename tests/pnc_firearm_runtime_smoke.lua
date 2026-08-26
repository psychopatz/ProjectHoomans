local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Firearms.lua")

local realismEnabled = true
local mirroredAmmo
local reloadAction
local weapon = {
    getFullType = function() return "Base.TestPistol" end,
    getAmmoType = function() return "Base.Bullets9mm" end,
    getMaxAmmo = function() return 3 end,
    getAmmoPerShoot = function() return 1 end,
    getSwingSound = function() return "TestPistolShot" end,
    getSoundRadius = function() return 72 end,
    getSoundVolume = function() return 40 end,
    getProjectileCount = function() return 1 end,
    getProjectileSpread = function() return 0.25 end,
    setCurrentAmmoCount = function(_, value) mirroredAmmo = value end,
}
local scriptItem = {
    getClipSize = function() return 3 end,
    getAmmoType = function() return "Base.Bullets9mm" end,
    getReloadTime = function() return 10 end,
    getDisplayCategory = function() return "Firearm" end,
}

getScriptManager = function()
    return {
        getItem = function(_, fullType)
            T.equal(fullType, "Base.TestPistol", "script firearm type")
            return scriptItem
        end,
    }
end

local function applyOps(record, ops)
    local inv = record.inventory
    local i
    local op
    local item
    for i = 1, #ops do
        op = ops[i]
        if op.op == "update" then
            item = inv.items[op.itemID]
            if not item then return false end
            if op.stack ~= nil then item.stack = op.stack end
            if op.ammoCount ~= nil then item.ammoCount = op.ammoCount end
        elseif op.op == "remove" then
            inv.items[op.itemID] = nil
        end
    end
    return true
end

PNC = {
    Sandbox = {
        CompanionAmmoRealismEnabled = function() return realismEnabled end,
    },
    Skills = {
        GetLevel = function() return 0 end,
        AddXP = function() end,
    },
    Inventory = {
        EnsureRecordInventory = function(record) return record.inventory end,
        ApplyDelta = function(record, ops) return applyOps(record, ops) end,
    },
    Animation = {
        PlayBump = function(_, _, anim)
            T.equal(anim, "LoadPistol", "pistol reload animation")
        end,
    },
    Combat = {
        Internal = {
            resolveWeaponItem = function() return weapon end,
            buildAttackAction = function(record, target, attackKind, attackType, anim, _, _, extra)
                reloadAction = extra
                reloadAction.target = target
                reloadAction.attackKind = attackKind
                reloadAction.attackType = attackType
                reloadAction.anim = anim
                record.runtime.attackAction = reloadAction
                return reloadAction
            end,
        },
    },
}

T.load(FILE)

local record = {
    id = "companion_firearm",
    recruited = true,
    equipment = { primaryFullType = "Base.TestPistol" },
    runtime = {},
    inventory = {
        equipped = { primary = "gun" },
        items = {
            gun = {
                id = "gun",
                type = "Base.TestPistol",
                equipSlot = "primary",
            },
            rounds = {
                id = "rounds",
                type = "Base.Bullets9mm",
                stack = 4,
            },
        },
    },
}

local fired
local reason
local magazine
local descriptor = PNC.Firearms.Describe(record, weapon)
T.equal(descriptor.ammoType, "Base.Bullets9mm", "weapon ammo type")
T.equal(descriptor.ammoPerShot, 1, "weapon ammo per shot")
T.equal(descriptor.shotSound, "TestPistolShot", "weapon shot sound")
T.equal(descriptor.soundRadius, 72, "weapon noise radius")
T.equal(descriptor.projectileCount, 1, "weapon projectile count")
T.equal(descriptor.projectileSpread, 0.25, "weapon projectile spread")
fired, reason, magazine = PNC.Firearms.PrepareShot(record, weapon)
T.equal(fired, true, "first companion shot")
T.equal(reason, "round_consumed", "first companion shot reason")
T.equal(record.inventory.items.gun.ammoCount, 2, "weapon-derived magazine decremented")
T.equal(magazine.capacity, 3, "weapon script clip capacity")
T.equal(mirroredAmmo, 2, "live firearm magazine mirror")

PNC.Firearms.PrepareShot(record, weapon)
PNC.Firearms.PrepareShot(record, weapon)
T.equal(record.inventory.items.gun.ammoCount, 0, "magazine exhausted")

fired, reason = PNC.Firearms.PrepareShot(record, weapon)
T.equal(fired, false, "empty companion firearm rejected")
T.equal(reason, "reload_required", "inventory rounds request reload")

local started
started, reason = PNC.Firearms.StartReload(record, {}, { kind = "zombie" }, weapon)
T.equal(started, true, "reload action started")
T.equal(reason, "reload_started", "reload action reason")
T.equal(reloadAction.attackType, "reload", "reload action type")
T.equal(reloadAction.magazineCapacity, 3, "reload action capacity")
T.equal(reloadAction.durationMs, 1000, "weapon reload time")

local completed
completed, reason = PNC.Firearms.CompleteReload(record, {}, reloadAction)
T.equal(completed, true, "reload completed")
T.equal(reason, "reload_complete", "full reload reason")
T.equal(record.inventory.items.gun.ammoCount, 3, "magazine refilled to capacity")
T.equal(record.inventory.items.rounds.stack, 1, "matching loose rounds consumed")

local autonomous = {
    id = "hostile_firearm",
    recruited = false,
    tacticalClass = "hostile",
    equipment = { primaryFullType = "Base.TestPistol" },
    runtime = {},
    inventory = {
        equipped = { primary = "gun" },
        items = {
            gun = {
                id = "gun",
                type = "Base.TestPistol",
                equipSlot = "primary",
                ammoCount = 0,
            },
        },
    },
}
fired, reason = PNC.Firearms.PrepareShot(autonomous, weapon)
T.equal(fired, false, "empty autonomous magazine does not fire")
T.equal(reason, "reload_required", "autonomous infinite reserve still reloads")
started, reason = PNC.Firearms.StartReload(autonomous, {}, { kind = "zombie" }, weapon)
T.equal(started, true, "autonomous reload action started")
completed, reason = PNC.Firearms.CompleteReload(autonomous, {}, reloadAction)
T.equal(completed, true, "autonomous reload completed")
T.equal(reason, "reload_complete_unlimited_reserve", "autonomous reserve reason")
T.equal(autonomous.inventory.items.gun.ammoCount, 3, "autonomous magazine refilled")
T.equal(autonomous.inventory.items.rounds, nil, "autonomous reload did not require inventory rounds")

realismEnabled = false
record.runtime.attackAction = nil
record.inventory.items.gun.ammoCount = 0
record.inventory.items.rounds = nil
fired, reason = PNC.Firearms.PrepareShot(record, weapon)
T.equal(fired, false, "disabled realism still honors magazine")
T.equal(reason, "reload_required", "disabled realism uses infinite reserve reload")
started = PNC.Firearms.StartReload(record, {}, { kind = "zombie" }, weapon)
T.equal(started, true, "disabled-realism companion reload started")
completed, reason = PNC.Firearms.CompleteReload(record, {}, reloadAction)
T.equal(completed, true, "disabled-realism companion reload completed")
T.equal(reason, "reload_complete_unlimited_reserve", "disabled realism reserve reason")
T.equal(record.inventory.items.gun.ammoCount, 3, "disabled-realism magazine refilled")

local debugState = PNC.Firearms.BuildDebugState(record)
T.equal(debugState.count, 3, "debug magazine count")
T.equal(debugState.capacity, 3, "debug magazine capacity")
T.equal(debugState.unlimitedReserve, true, "debug infinite reserve")

PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Core = { Now = function() return 0 end }
local NameplateDebug = T.load(
    T.path("ProjectHoomans", "client", "PNC/UI/Nameplates/PNC_NameplateDebug.lua")
)
local overlay = NameplateDebug.BuildText({
    presenceState = "live",
    firearmState = debugState,
    debugState = {
        weaponStatus = "ranged_ready",
        combatModeResolved = "ranged",
    },
}, true, {})
T.contains(overlay, "Mag: 3/3", "debug overlay magazine")
T.contains(overlay, "Reserve: infinite", "debug overlay reserve")
T.finish("pnc_firearm_runtime_smoke")

T.finish("pnc_firearm_runtime_smoke")
