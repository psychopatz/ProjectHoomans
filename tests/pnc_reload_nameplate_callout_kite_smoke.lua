local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
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

isServer = function() return true end
isClient = function() return false end

local nowMs = 30000
local resolvedRoles = {}
local deliveredBarks = {}
local npcStore = {}

local playerObj = {
    _x = 14, _y = 10, _z = 0, _dead = false,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    getUsername = function() return "OwnerPlayer" end,
    getDescriptor = function() return { getForename = function() return "Alex" end } end,
}

PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }
PNC = {
    Const = {
        RANGED_PREFERRED_MIN_DISTANCE = 5.0,
        COMBAT_HORDE_RADIUS = 6,
    },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(fn) fn(playerObj) end,
    },
    Registry = { Data = npcStore },
    Perception = { AreWarningAllies = function() return true end },
    ZombieAggro = { ActiveSet = { order = {}, byID = {} }, State = { bites = {} } },
    CombatTactics = {
        Internal = {
            AssessThreat = function(rec, tgt)
                local d = math.sqrt(tonumber(tgt and tgt.distSq) or 0)
                return { pressureCount = d < 4 and 2 or 0 }
            end,
        },
    },
    Semantics = {},
}

local ActivityStatus = require "PNC/Core/Activities/PNC_ActivityStatus"
local S = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations"
local Tactics = require "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_RangedPositioning"

S.ResolveAllyWarnTone = function() return "shaken" end
S.BuildRichSpeechTokens = function(_, addr)
    return { ["addressee.name"] = addr and (addr.displayName or addr.name) or "partner" }
end
S.ResolveSemanticLine = function(speaker, _, _, _, _, _, toks, extra)
    local role = extra and extra.replyRole or "default"
    resolvedRoles[#resolvedRoles + 1] = {
        speakerId = speaker.id,
        role = role,
        addressee = toks and toks["addressee.name"],
    }
    return role, { realizationID = "test." .. role, presentationClass = "BARK" }
end
S.DeliverBark = function(speaker, _, opts)
    deliveredBarks[#deliveredBarks + 1] = {
        speakerId = speaker.id,
        interrupt = opts.interrupt,
        text = opts.text,
    }
    return 1
end

local gwen = {
    id = "npc_gwen",
    displayName = "Gwendolyn",
    alive = true,
    x = 10, y = 10, z = 0,
    health = { current = 90, max = 100 },
    runtime = {
        attackAction = {
            attackType = "reload",
            finishAt = nowMs + 2000,
            reloadCurrentCount = 2,
            reloadTargetCount = 6,
            magazineCapacity = 6,
            reloadIncremental = true,
            reloadProgress = 0.33,
        },
    },
}
local emma = { id = "npc_emma", displayName = "Emma", alive = true, x = 13, y = 10, z = 0, runtime = {} }
npcStore[gwen.id] = gwen
npcStore[emma.id] = emma

-- 1) Nameplate activity status reports Reloading with live bullet/mag count.
local act = ActivityStatus.Build(gwen)
assertTruthy(act, "ActivityStatus should resolve while reloading")
assertEq(act.activityId, "reloading", "Activity ID should be reloading")
assertEq(act.labelKey, "UI_PNC_Activity_Reloading", "Label key should be UI_PNC_Activity_Reloading")
assertEq(act.fallback, "Reloading", "Fallback label should be Reloading")
assertEq(act.reloadCurrent, 2, "Reload current count should be populated")
assertEq(act.reloadCapacity, 6, "Reload capacity should be populated")

PNC.NameplatePresentation = PNC.NameplatePresentation or {}
require "PNC/UI/Nameplates/PNC_NameplatePresentation_Actions"
local labelInc = PNC.NameplatePresentation.ActivityActionStatus({ actionInformation = act })
assertEq(labelInc, "Reloading (2/6)", "Incremental reload nameplate should display Reloading (2/6)")

local labelMag = PNC.NameplatePresentation.ActivityActionStatus({
    actionInformation = {
        kind = "activity",
        activityId = "reloading",
        fallback = "Reloading",
        reloadCurrent = 0,
        reloadCapacity = 15,
        reloadIncremental = false,
        reloadProgress = 0.5,
    },
})
assertEq(labelMag, "Reloading (0/15 50%)", "Magazine swap nameplate should display Reloading (0/15 50%)")

-- 2) Blindside warning is suppressed while speaker is actively reloading.
assertEq(S.TryEmitBlindsideWarning(gwen, emma, { semanticClass = "zombie", x = 12, y = 10 }, nowMs, "bs_1"), false,
    "Reloading NPC should not emit generic blindside warning for another ally")

-- 3) Reload callout scales with threat intensity: calm when target is far, panic when close!
local okCalm = S.TryEmitReloadCallout(gwen, { kind = "zombie", x = 18, y = 10, distSq = 64 }, nowMs, "rl_calm")
assertEq(okCalm, true, "Calm reload callout should emit")
assertEq(resolvedRoles[1].role, "reloading_cover", "Distant threat should use reloading_cover")
assertEq(deliveredBarks[1].interrupt, false, "Calm reload should not force interrupt")

nowMs = nowMs + 7000
local okPanic = S.TryEmitReloadCallout(gwen, { kind = "zombie", x = 12, y = 10, distSq = 4 }, nowMs, "rl_panic")
assertEq(okPanic, true, "High-pressure reload callout should emit")
assertEq(resolvedRoles[2].role, "reloading_panic", "Close threat should escalate to reloading_panic")
assertEq(deliveredBarks[2].interrupt, true, "Panicked reload should interrupt lower-priority barks")

-- 4) Reload kiting steps NPC away from close threat without changing action state.
local body = {
    _x = 10, _y = 10, _z = 0,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    setX = function(self, v) self._x = v end,
    setY = function(self, v) self._y = v end,
    setNextX = function() end,
    setNextY = function() end,
}
local kited, kReason = Tactics.StepReloadKite(gwen, body, { kind = "zombie", x = 12, y = 10, distSq = 4 }, nowMs)
assertEq(kited, true, "Reloading NPC should kite away from close zombie")
assertEq(kReason, "reloading_kiting", "Kite reason should be reloading_kiting")
assertTruthy(body._x < 10, "NPC should step away in -X direction from zombie at +X")
assertEq(gwen.x, body._x, "Record X should sync with body X")

-- Far threat does not trigger unnecessary reload kiting.
local kitedFar = Tactics.StepReloadKite(gwen, body, { kind = "zombie", x = 18, y = 10, distSq = 64 }, nowMs + 200)
assertEq(kitedFar, false, "Distant threat should not trigger reload kite step")

-- 5) Incremental round insertion & emergency partial-load fire interrupt.
PNC.Firearms = {}
PNC.Combat = { Internal = {} }
PNC.Sandbox = { CompanionAmmoRealismEnabled = function() return false end }
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Descriptors"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_State"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Actions"

local loadedShells = 0
local shotgunItem = {
    getFullType = function() return "Base.Shotgun" end,
    isRackAfterShoot = function() return true end,
    getMaxAmmo = function() return 6 end,
    getAmmoType = function() return "Base.ShotgunShells" end,
}
PNC.Combat.Internal.resolveWeaponItem = function() return shotgunItem end
PNC.Combat.Internal.EnsureMagazine = function()
    return { itemID = "sg_1", count = loadedShells, inventory = {} }, "ok"
end
PNC.Combat.Internal.UpdateMagazine = function(_, _, newCount)
    loadedShells = newCount
    return true
end

local reloadAction = {
    attackType = "reload",
    weaponFullType = "Base.Shotgun",
    startedAt = nowMs,
    finishAt = nowMs + 2800,
    ammoPerShot = 1,
    magazineCapacity = 6,
    reloadStartCount = 0,
    reloadCurrentCount = 0,
    reloadTargetCount = 6,
    reloadIncremental = true,
    reloadPerRoundMs = 450,
    reloadNextInsertAt = nowMs + 450,
    reloadProgress = 0,
}

-- At +500ms with distant target: inserts 1st shell, continues reloading!
local done1, r1 = PNC.Firearms.StepReload(gwen, body, reloadAction, { x = 18, y = 10, distSq = 64 }, nowMs + 500)
assertEq(done1, false, "Should keep reloading after 1st shell when threat is far")
assertEq(loadedShells, 1, "1st shell should be inserted into magazine")
assertEq(reloadAction.reloadCurrentCount, 1, "Action reloadCurrentCount should tick to 1")

-- At +950ms even with close zombie (2.0 tiles): still reloads normally when not exhausted!
local done2, r2 = PNC.Firearms.StepReload(gwen, body, reloadAction, { x = 12, y = 10, distSq = 4 }, nowMs + 950)
assertEq(done2, false, "Normal reload should continue even with nearby zombie when ammo/stamina available")
assertEq(loadedShells, 2, "2nd shell should be inserted cleanly")

-- Failsafe: if NPC becomes stamina-exhausted with shells already loaded, finishes early so they can fire!
PNC.Stamina = { GetRatio = function() return 0.05 end }
local done3, r3 = PNC.Firearms.StepReload(gwen, body, reloadAction, { x = 12, y = 10, distSq = 4 }, nowMs + 1000)
assertEq(done3, true, "Exhausted failsafe should end reload early once rounds are loaded")
assertEq(r3, "reload_partial_exhausted", "Reason should be reload_partial_exhausted")
assertEq(loadedShells, 2, "2 shells should remain loaded and ready to fire immediately")

print("PASS: pnc_reload_nameplate_callout_kite_smoke")
