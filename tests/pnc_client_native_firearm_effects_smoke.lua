local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

local muzzleCalls = 0
local ballisticsUpdates = 0
local weaponStateCalls = 0
local tracerCalls = {}
local currentUseWeapon
local animationReady = true

local nativeManager = {
    startMuzzleFlash = function(_, body, lightMode)
        T.truthy(body, "native muzzle flash lost the firing body")
        T.equal(lightMode, 1, "native muzzle flash used the wrong mode")
        muzzleCalls = muzzleCalls + 1
    end,
}

local nativeTracer = {
    addEffect = function(_, body, range, x, y, z)
        T.truthy(body, "native tracer lost the firing body")
        T.truthy(range > 0, "native tracer range was not resolved")
        tracerCalls[#tracerCalls + 1] = { x = x, y = y, z = z }
        return {}
    end,
}

zombie = {
    EffectsManager = {
        getInstance = function() return nativeManager end,
    },
    iso = {
        objects = {
            IsoBulletTracerEffects = {
                getInstance = function() return nativeTracer end,
            },
        },
    },
}

local weapon = {
    isAimedFirearm = function() return true end,
    getFullType = function() return "ExampleMod.CustomCarbine" end,
    getMuzzleFlashModelKey = function() return "MuzzleFlash" end,
    getAmmoType = function() return "Base.Bullet" end,
    getMaxRange = function(_, body)
        T.truthy(body, "weapon range was not evaluated against the firing body")
        return 18
    end,
    getProjectileCount = function() return 3 end,
    getProjectileSpread = function() return 2 end,
    getSwingSound = function() return nil end,
    getSoundGain = function() return 1 end,
}

local controller
local body = {
    getPrimaryHandItem = function() return weapon end,
    getUseHandWeapon = function() return currentUseWeapon end,
    setUseHandWeapon = function(_, value)
        currentUseWeapon = value
        weaponStateCalls = weaponStateCalls + 1
    end,
    getAttackingWeapon = function() return currentUseWeapon end,
    updateBallistics = function()
        ballisticsUpdates = ballisticsUpdates + 1
        controller = {}
    end,
    getBallisticsController = function() return controller end,
    getAnimationPlayer = function()
        return { isReady = function() return animationReady end }
    end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getEmitter = function() return nil end,
}

PNC = {
    Core = {
        Now = function() return 100 end,
        Log = function() end,
    },
    Network = {
        FindZombieByOnlineID = function() return body end,
    },
}

local Effects = T.load(
    "ProjectHoomans",
    "client",
    "PNC/PNC_ClientFirearmEffects.lua"
)

local payload = {
    shotId = "custom-weapon-shot-1",
    shooterOnlineID = 22,
    weaponFullType = "ExampleMod.CustomCarbine",
    sx = 10,
    sy = 10,
    sz = 0,
    tx = 20,
    ty = 10,
    tz = 1,
    maxRange = 18,
    projectileCount = 3,
    projectileSpread = 2,
}

T.truthy(Effects.Play(payload), "weapon-agnostic native effects did not play")
T.equal(muzzleCalls, 1, "native muzzle flash was not used")
T.equal(ballisticsUpdates, 1, "native ballistics was not refreshed")
T.equal(#tracerCalls, 3, "weapon projectile count was not honored")
T.equal(currentUseWeapon, nil, "temporary native weapon state was not restored")
T.equal(weaponStateCalls, 2, "native weapon state was not scoped")
T.equal(#Effects.ActiveLights, 0, "fallback light was spawned beside native flash")
T.equal(#Effects.ActiveTracers, 0, "fallback tracer was spawned beside native tracer")

local capabilities = Effects.GetNativeCapabilities(body, payload)
T.truthy(capabilities.effectsManager, "native effects manager was not detected")
T.truthy(capabilities.bulletTracerEffects, "native tracer service was not detected")
T.truthy(capabilities.aimedFirearm, "custom firearm was rejected as a firearm")
T.truthy(capabilities.animationReady, "ready animation player was not detected")

animationReady = false
capabilities = Effects.GetNativeCapabilities(body, payload)
T.falsy(capabilities.animationReady, "unready animation player was accepted")
T.truthy(Effects.Play({
    shotId = "custom-weapon-shot-unready",
    shooterOnlineID = 22,
    weaponFullType = "ExampleMod.CustomCarbine",
    sx = 10, sy = 10, sz = 0,
    tx = 20, ty = 10, tz = 1,
    maxRange = 18,
    projectileCount = 3,
    projectileSpread = 2,
}), "unready weapon effect did not fail safely")
T.equal(muzzleCalls, 1, "unready body invoked native muzzle flash")
T.equal(#tracerCalls, 3, "unready body invoked native tracer")

T.falsy(Effects.Play(payload), "duplicate firearm shot was replayed")
T.equal(#tracerCalls, 3, "duplicate shot created additional native tracers")
T.finish("pnc_client_native_firearm_effects_smoke")
