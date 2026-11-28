local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

local function assertEq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", tostring(msg), tostring(expected), tostring(actual)), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then
        error(tostring(msg or "expected truthy value"), 2)
    end
end

local nowMs = 10000
PNC = {
    Const = {
        RANGED_RANGE = 10,
        RANGED_AIM_BASE_MS = 460,
        RANGED_AIM_MIN_MS = 140,
        RANGED_AIM_MOVE_TOLERANCE = 0.35,
        COMBAT_STANCE_HOLD_MS = 6000,
    },
    Core = {
        Now = function() return nowMs end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = (x2 or 0) - (x1 or 0), (y2 or 0) - (y1 or 0)
            return dx * dx + dy * dy
        end,
    },
    Skills = { GetLevel = function() return 4 end },
    Firearms = {},
    Combat = { Internal = {} },
    CombatResolution = {},
    CombatTactics = {
        Internal = {
            AssessThreat = function() return { visiblePressureCount = 0 } end,
        },
        IsFriendlyFireSafe = function() return true, "clear" end,
    },
    Equipment = { Internal = {} },
    Visuals = {},
}

require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Descriptors"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_State"
require "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_RangedOutcome"
require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_RangedReadiness"
local Stance = require "PNC/Core/Combat/PNC_Combat_Stance"

local Firearms = PNC.Firearms
local Tactics = PNC.CombatTactics

local function makeGun(fullType, opts)
    opts = opts or {}
    return {
        getFullType = function() return fullType end,
        getFireMode = function() return opts.fireMode end,
        getFireModePossibilities = function() return opts.modes end,
        getRecoilDelay = function() return opts.recoilDelay end,
        getCyclicRateMultiplier = function() return opts.cyclic end,
        isRackAfterShoot = function() return opts.rack == true end,
        getMaxAmmo = function() return opts.cap or 10 end,
    }
end

local rec = { id = "npc_gunner", alive = true, x = 10, y = 10, z = 0, runtime = {} }

local dAuto = Firearms.Describe(rec, makeGun("Base.AssaultRifle", { fireMode = "Auto", recoilDelay = 12 }))
local dPistol = Firearms.Describe(rec, makeGun("Base.Pistol", { fireMode = "Single", recoilDelay = 18 }))
local dRevolver = Firearms.Describe(rec, makeGun("Base.Revolver", { fireMode = "Single", recoilDelay = 28 }))
local dDB = Firearms.Describe(rec, makeGun("Base.DoubleBarrelShotgun", { fireMode = "Single", recoilDelay = 45 }))
local dPump = Firearms.Describe(rec, makeGun("Base.Shotgun", { fireMode = "Single", recoilDelay = 50, rack = true }))
local dBolt = Firearms.Describe(rec, makeGun("Base.VarmintRifle", { fireMode = "Single", recoilDelay = 65, rack = true }))

assertEq(dAuto.cadenceClass, "auto", "M16 should classify as auto")
assertEq(dAuto.isAutomatic, true, "M16 should be marked automatic")
assertTruthy(dAuto.burstSize >= 3, "Automatic rifle should configure burst size")
assertEq(dPistol.cadenceClass, "semipistol", "M9 should classify as semipistol")
assertEq(dRevolver.cadenceClass, "revolver", "Revolver should classify as revolver")
assertEq(dDB.cadenceClass, "dbshotgun", "Double-barrel should classify as dbshotgun")
assertEq(dPump.cadenceClass, "pump_shotgun", "Pump shotgun should classify as pump_shotgun")
assertEq(dBolt.cadenceClass, "bolt_rifle", "Bolt-action rifle should classify as bolt_rifle")

assertTruthy(dAuto.fireCooldownMs < dPistol.fireCooldownMs, "Auto rifle must fire faster than semi pistol")
assertTruthy(dPistol.fireCooldownMs < dRevolver.fireCooldownMs, "Semi pistol must fire faster than revolver")
assertTruthy(dDB.fireCooldownMs < dPump.fireCooldownMs, "Double-barrel must tap faster than pump shotgun")
assertTruthy(dPump.fireCooldownMs < dBolt.fireCooldownMs, "Pump shotgun must cycle faster than bolt rifle")
assertTruthy(dAuto.shotDurationMs < 200, "Auto rifle action duration must stay short for rapid fire")

-- Follow-up shot aim settle should be much faster than initial aim settle.
local target = { kind = "zombie", zombieId = 99, x = 15, y = 10, distSq = 25 }
local okFirst = Tactics.CanTakeRangedShot(rec, target)
assertEq(okFirst, false, "Initial aim should require settle time")
local initialSettle = rec.runtime.combatAim.settleMs

Tactics.MarkRangedShot(rec, dAuto.followUpAimScale)
nowMs = nowMs + 100
local okFollow = Tactics.CanTakeRangedShot(rec, target)
local followSettle = rec.runtime.combatAim.settleMs
assertTruthy(followSettle < initialSettle * 0.4, "Follow-up auto shot settle should be much shorter than initial aim")
assertEq(okFollow, true, "Follow-up auto shot should be ready quickly without re-aiming from scratch")

-- Holster stability: ApplyCombatState must keep weapon drawn during active CombatStance
-- AND stay idempotent across fresh snapshot recordViews via body modData.
local refreshCount = 0
local presentCalls = 0
PNC.Visuals.RefreshModel = function() refreshCount = refreshCount + 1 end
PNC.Equipment.PRESENTATION_REVISION = 1
PNC.Equipment.EnsureRecordEquipment = function() return { primaryFullType = "Base.AssaultRifle" } end
PNC.Equipment.Internal.isNetworkedGame = function() return false end
PNC.Equipment.Internal.peekWeaponDescriptor = function(ft)
    return { fullType = ft, hasWeapon = true, isContainer = false }
end
PNC.Equipment.Internal.buildWeaponDescriptor = function(ft)
    return { fullType = ft, hasWeapon = true, isContainer = false }
end
PNC.Equipment.Internal.isPrimaryHandStateCurrent = function() return true end
PNC.Equipment.Internal.applyCombatPresentation = function(z, r, eq, desc, held)
    presentCalls = presentCalls + 1
    r.runtime = r.runtime or {}
    r.runtime.equipmentAttackModeApplied = held == true
    r.runtime.equipmentPresentationRevision = PNC.Equipment.PRESENTATION_REVISION
    return true, "ok", "ok"
end

require "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_CombatState"

local modData = {}
local fakeBody = { getModData = function() return modData end }
Stance.Maintain(rec, nowMs)

local ok1, reason1 = PNC.Equipment.ApplyCombatState(fakeBody, rec, true)
assertEq(ok1, true, "Initial armed ApplyCombatState should succeed")
assertEq(presentCalls, 1, "Initial presentation should apply once")

-- Stray call with attackMode=false while CombatStance is still armed must NOT holster!
local ok2, reason2 = PNC.Equipment.ApplyCombatState(fakeBody, rec, false)
assertEq(ok2, true, "ApplyCombatState(false) during active CombatStance should succeed")
assertEq(reason2, "unchanged", "Weapon must remain drawn (unchanged) while CombatStance is armed")
assertEq(presentCalls, 1, "Must not re-holster during active CombatStance")

-- Fresh temporary snapshot recordView with empty runtime must STILL be idempotent via body modData!
local freshRecordView = { id = rec.id, alive = true, runtime = {} }
local ok3, reason3 = PNC.Equipment.ApplyCombatState(fakeBody, freshRecordView, true)
assertEq(ok3, true, "Snapshot recordView ApplyCombatState should succeed")
assertEq(reason3, "unchanged", "Fresh snapshot recordView must not clear/re-equip hands")
assertEq(presentCalls, 1, "Body presentation must not thrash across presence snapshots")
assertEq(refreshCount, 1, "RefreshModel must not be spammed on unchanged presentation")

-- Continuous ranged aiming: armed firearm keeps PNCRangedAiming=true and upgrades Walk -> WalkAim.
require "PNC/Core/Visuals/PNC_Animation/PNC_Animation_LocomotionVariables"
local AnimInternal = PNC.Animation.Internal
local animVars = { PNCPrimaryType = "handgun" }
local animBody = {
    getVariableString = function(_, k) return animVars[k] end,
    setVariable = function(_, k, v) animVars[k] = v end,
}

local walkOut, aimingOut = AnimInternal.resolveContinuousRangedAim(animBody, rec, "Walk", false)
assertEq(aimingOut, true, "Armed handgun NPC should continuously aim")
assertEq(animVars.PNCRangedAiming, true, "PNCRangedAiming should be set true for IdleAimHandgun")
assertEq(walkOut, "WalkAim", "Walking while armed with handgun should use WalkAim")

local runOut, aimingRun = AnimInternal.resolveContinuousRangedAim(animBody, rec, "Run", false)
assertEq(aimingRun, true, "Running armed handgun NPC still keeps PNCRangedAiming flag")
assertEq(runOut, "Run", "Full sprint should preserve Run walkType")

Stance.Clear(rec)
local relaxedWalk, relaxedAim = AnimInternal.resolveContinuousRangedAim(animBody, rec, "Walk", false)
assertEq(relaxedAim, false, "Cleared combat stance should lower weapon aim")
assertEq(animVars.PNCRangedAiming, false, "PNCRangedAiming should reset to false out of combat")
assertEq(relaxedWalk, "Walk", "Out-of-combat walking should return normal Walk")

-- Regression: even if CombatStance is still armed, a body whose gun is holstered
-- (empty primary hand) must NEVER enter PNCRangedAiming / WalkAim.
Stance.Maintain(rec, 4000)
local holsteredVars = { PNCPrimaryType = "rifle", PNCRangedAiming = true }
local holsteredBody = {
    getVariableString = function(_, k) return holsteredVars[k] end,
    setVariable = function(_, k, v) holsteredVars[k] = v end,
    getPrimaryHandItem = function() return nil end,
}
local holsteredWalk, holsteredAim = AnimInternal.resolveContinuousRangedAim(
    holsteredBody, rec, "Walk", false
)
assertEq(holsteredAim, false, "Holstered rifle (empty primary hand) must not aim empty air")
assertEq(holsteredVars.PNCRangedAiming, false, "PNCRangedAiming must be false when primary hand is empty")
assertEq(holsteredWalk, "Walk", "Holstered rifle must walk normally instead of WalkAim")

-- Regression: NPC undergoing suicide keeps CombatStance (weapon in hand) during
-- forced holster checks, while resolveContinuousRangedAim keeps PNCRangedAiming=false
-- so WalkAim/IdleAim never fights the suicide animation scene.
local suicideRec = { id = "npc_suicide_guard", alive = true, runtime = { suicideState = { phase = "resolve" } } }
Stance.Maintain(suicideRec, 4000)
local suicideVars = { PNCPrimaryType = "handgun", PNCRangedAiming = true }
local suicideBody = {
    getVariableString = function(_, k) return suicideVars[k] end,
    setVariable = function(_, k, v) suicideVars[k] = v end,
    getPrimaryHandItem = function() return { getFullType = function() return "Base.Pistol" end } end,
}
local suicideWalk, suicideAim = AnimInternal.resolveContinuousRangedAim(
    suicideBody, suicideRec, "Walk", false
)
assertEq(suicideAim, false, "Suicide scene must not be overridden by continuous ranged aiming")
assertEq(suicideVars.PNCRangedAiming, false, "PNCRangedAiming must be false during suicide scene")
assertEq(suicideWalk, "Walk", "Suicide scene must not upgrade walkType to WalkAim")

print("PASS: pnc_firearm_cadence_and_holster_stability_smoke")
