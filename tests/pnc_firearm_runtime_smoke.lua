local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/PNC_Combat_Firearms.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertContains(actual, expected, label)
    if not string.find(tostring(actual), tostring(expected), 1, true) then
        error((label or "assertContains") .. ": missing=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local realismEnabled = true
local mirroredAmmo
local reloadAction
local weapon = {
    getFullType = function() return "Base.TestPistol" end,
    getAmmoType = function() return "Base.Bullets9mm" end,
    getMaxAmmo = function() return 3 end,
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
            assertEqual(fullType, "Base.TestPistol", "script firearm type")
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
            assertEqual(anim, "LoadPistol", "pistol reload animation")
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

dofile(FILE)

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
fired, reason, magazine = PNC.Firearms.PrepareShot(record, weapon)
assertEqual(fired, true, "first companion shot")
assertEqual(reason, "round_consumed", "first companion shot reason")
assertEqual(record.inventory.items.gun.ammoCount, 2, "weapon-derived magazine decremented")
assertEqual(magazine.capacity, 3, "weapon script clip capacity")
assertEqual(mirroredAmmo, 2, "live firearm magazine mirror")

PNC.Firearms.PrepareShot(record, weapon)
PNC.Firearms.PrepareShot(record, weapon)
assertEqual(record.inventory.items.gun.ammoCount, 0, "magazine exhausted")

fired, reason = PNC.Firearms.PrepareShot(record, weapon)
assertEqual(fired, false, "empty companion firearm rejected")
assertEqual(reason, "reload_required", "inventory rounds request reload")

local started
started, reason = PNC.Firearms.StartReload(record, {}, { kind = "zombie" }, weapon)
assertEqual(started, true, "reload action started")
assertEqual(reason, "reload_started", "reload action reason")
assertEqual(reloadAction.attackType, "reload", "reload action type")
assertEqual(reloadAction.magazineCapacity, 3, "reload action capacity")
assertEqual(reloadAction.durationMs, 1000, "weapon reload time")

local completed
completed, reason = PNC.Firearms.CompleteReload(record, {}, reloadAction)
assertEqual(completed, true, "reload completed")
assertEqual(reason, "reload_complete", "full reload reason")
assertEqual(record.inventory.items.gun.ammoCount, 3, "magazine refilled to capacity")
assertEqual(record.inventory.items.rounds.stack, 1, "matching loose rounds consumed")

local autonomous = {
    id = "hostile_firearm",
    recruited = false,
    faction = "hostile",
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
assertEqual(fired, false, "empty autonomous magazine does not fire")
assertEqual(reason, "reload_required", "autonomous infinite reserve still reloads")
started, reason = PNC.Firearms.StartReload(autonomous, {}, { kind = "zombie" }, weapon)
assertEqual(started, true, "autonomous reload action started")
completed, reason = PNC.Firearms.CompleteReload(autonomous, {}, reloadAction)
assertEqual(completed, true, "autonomous reload completed")
assertEqual(reason, "reload_complete_unlimited_reserve", "autonomous reserve reason")
assertEqual(autonomous.inventory.items.gun.ammoCount, 3, "autonomous magazine refilled")
assertEqual(autonomous.inventory.items.rounds, nil, "autonomous reload did not require inventory rounds")

realismEnabled = false
record.runtime.attackAction = nil
record.inventory.items.gun.ammoCount = 0
record.inventory.items.rounds = nil
fired, reason = PNC.Firearms.PrepareShot(record, weapon)
assertEqual(fired, false, "disabled realism still honors magazine")
assertEqual(reason, "reload_required", "disabled realism uses infinite reserve reload")
started = PNC.Firearms.StartReload(record, {}, { kind = "zombie" }, weapon)
assertEqual(started, true, "disabled-realism companion reload started")
completed, reason = PNC.Firearms.CompleteReload(record, {}, reloadAction)
assertEqual(completed, true, "disabled-realism companion reload completed")
assertEqual(reason, "reload_complete_unlimited_reserve", "disabled realism reserve reason")
assertEqual(record.inventory.items.gun.ammoCount, 3, "disabled-realism magazine refilled")

local debugState = PNC.Firearms.BuildDebugState(record)
assertEqual(debugState.count, 3, "debug magazine count")
assertEqual(debugState.capacity, 3, "debug magazine capacity")
assertEqual(debugState.unlimitedReserve, true, "debug infinite reserve")

PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Core = { Now = function() return 0 end }
local NameplateDebug = dofile(
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/Nameplates/PNC_NameplateDebug.lua"
)
local overlay = NameplateDebug.BuildText({
    presenceState = "live",
    firearmState = debugState,
    debugState = {
        weaponStatus = "ranged_ready",
        combatModeResolved = "ranged",
    },
}, true, {})
assertContains(overlay, "Mag: 3/3", "debug overlay magazine")
assertContains(overlay, "Reserve: infinite", "debug overlay reserve")

print("pnc_firearm_runtime_smoke: ok")
