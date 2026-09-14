local T = require "tests/support/test"

local SHARED_FILE = T.path("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_FirearmEffects.lua")
local CLIENT_FILE = T.path("ProjectHoomans", "client", "PNC/PNC_ClientFirearmEffects.lua")

local now = 1000
local published
local worldNoise
local auditEvents = {}
local ammoKey = {
    getItemKey = function() return "ModdedAmmo.556Tracer" end,
}
local weapon = {
    getFullType = function() return "ModdedGuns.TestRifle" end,
    getAmmoType = function() return ammoKey end,
    getClipSize = function() return 30 end,
    getAmmoPerShoot = function() return 2 end,
    getSwingSound = function() return "ModdedRifleShot" end,
    getSoundRadius = function() return 95 end,
    getSoundVolume = function() return 48 end,
    getSoundGain = function() return 0.8 end,
    getProjectileCount = function() return 3 end,
    getProjectileSpread = function() return 1.5 end,
    getMaxRange = function() return 18 end,
    isPiercingBullets = function() return true end,
    getImpactSound = function() return "ModdedBulletImpact" end,
    getShellFallSound = function() return "ModdedShellFall" end,
    isManuallyRemoveSpentRounds = function() return false end,
    isRackAfterShoot = function() return false end,
}
local shooter = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    isOutside = function() return true end,
    addWorldSoundUnlessInvisible = function(_, radius, volume, stress)
        worldNoise = { radius = radius, volume = volume, stress = stress }
    end,
}

getScriptManager = function()
    return {
        getItem = function() return nil end,
    }
end
getSandboxOptions = nil
isServer = function() return true end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_FIREARM_SHOT = "FirearmShot",
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
    },
    PerformanceScalingDiagnostics = {
        FirearmAuditEnabled = true,
        LogFirearmAudit = function(eventName)
            auditEvents[eventName] = (auditEvents[eventName] or 0) + 1
            return true
        end,
    },
    Firearms = {},
    Network = {
        GetZombieOnlineID = function() return 77 end,
        BroadcastFirearmShot = function(payload)
            published = payload
            return true
        end,
    },
}

T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Combat/PNC_Combat_Firearms.lua"))
T.load(SHARED_FILE)

local record = {
    id = "npc_modded_rifle",
    x = 10,
    y = 20,
    z = 0,
    equipment = { primaryFullType = "ModdedGuns.TestRifle" },
    runtime = {},
}
local emitted, payload = PNC.FirearmEffects.Emit(record, shooter, {
    kind = "zombie",
    x = 16,
    y = 22,
    z = 0,
}, weapon)
T.equal(emitted, true, "authoritative shot emitted")
T.equal(payload, published, "published payload identity")
T.equal(payload.shotId, "npc_modded_rifle:body:1:1000", "shot sequence")
T.equal(payload.weaponFullType, "ModdedGuns.TestRifle", "modded weapon type")
T.equal(payload.ammoType, "ModdedAmmo.556Tracer", "ItemKey ammo type")
T.equal(payload.ammoPerShot, 2, "modded ammo consumption metadata")
T.equal(payload.shotSound, "ModdedRifleShot", "modded weapon sound")
T.equal(payload.projectileCount, 3, "modded projectile count")
T.equal(payload.projectileSpread, 1.5, "modded projectile spread")
T.equal(payload.shellFallSound, "ModdedShellFall", "modded shell sound")
T.equal(worldNoise.radius, 95, "weapon-driven world noise radius")
T.equal(worldNoise.volume, 48, "weapon-driven world noise volume")
T.truthy(auditEvents.emit_start, "firearm audit recorded authority entry")
T.truthy(auditEvents.payload_built, "firearm audit recorded payload build")
T.truthy(auditEvents.emit_complete, "firearm audit recorded authority dispatch")

local played = {}
local rendered = 0
local renderLines = {}
local muzzleFlash = 0
local nativeTracerCalls = 0
local anchorAvailable = false
local currentUseWeapon
local controller
local removedLights = 0
local lightCreated = 0
local lastLight
local impactSound
local freeEmitterSound
local liveWeapon = {
    getFullType = function() return "ModdedGuns.TestRifle" end,
    isAimedFirearm = function() return true end,
    getMuzzleFlashModelKey = function() return "MuzzleFlash" end,
    getAmmoType = function() return ammoKey end,
    getMaxRange = function() return 18 end,
    getProjectileCount = function() return 3 end,
    getProjectileSpread = function() return 1.5 end,
    getSwingSound = function() return "LiveModdedRifleShot" end,
    getShellFallSound = function() return "LiveModdedShellFall" end,
    isTwoHandWeapon = function() return true end,
    getStaticModel = function() return nil end,
}
local emitter = {
    playSound = function(_, sound)
        played[#played + 1] = sound
    end,
}
local body = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getAnimAngleRadians = function() return 0 end,
    getPrimaryHandItem = function() return liveWeapon end,
    getUseHandWeapon = function() return currentUseWeapon end,
    setUseHandWeapon = function(_, value) currentUseWeapon = value end,
    getAttackingWeapon = function() return currentUseWeapon end,
    updateBallistics = function() controller = {} end,
    getBallisticsController = function() return controller end,
    getAnimationPlayer = function()
        return { isReady = function() return true end }
    end,
    getEmitter = function() return emitter end,
}
local cell = {
    addLamppost = function(_, light)
        lightCreated = lightCreated + 1
        lastLight = light
    end,
    removeLamppost = function() removedLights = removedLights + 1 end,
    getGridSquare = function()
        return {
            getX = function() return 10 end,
            getY = function() return 20 end,
            getZ = function() return 0 end,
            playSound = function(_, sound) impactSound = sound end,
        }
    end,
}

PNC.Network.FindZombieByOnlineID = function() return body end
PNC.ClientPresenceSync = { BodyByID = {} }
getTexture = function() return {} end
getCell = function() return cell end
getCore = function()
    return {
        getZoom = function() return 1 end,
    }
end
getRenderer = function()
    return {
        render = function()
            rendered = rendered + 1
        end,
        renderline = function(_, _, x1, y1, x2, y2)
            rendered = rendered + 1
            renderLines[#renderLines + 1] = {
                x1 = x1,
                y1 = y1,
                x2 = x2,
                y2 = y2,
            }
        end,
    }
end
getWorld = function()
    return {
        getFreeEmitter = function()
            return {
                playSound = function(_, sound)
                    freeEmitterSound = sound
                    return 91
                end,
                setVolume = function() end,
            }
        end,
    }
end
ISCoordConversion = {
    ToScreen = function(x, y, z)
        return (x * 10) - (y * 10), ((x + y) * 5) - (z * 10)
    end,
}
IsoLightSource = {
    new = function(...) return { args = { ... } } end,
}
Events = {
    OnTick = { Add = function() end },
    OnPreUIDraw = { Add = function() end },
    OnResetLua = { Add = function() end },
}
local nativeEffectsManager = {
    startMuzzleFlash = function() muzzleFlash = muzzleFlash + 1 end,
}
local nativeBulletTracerEffects = {
    addEffect = function()
        nativeTracerCalls = nativeTracerCalls + 1
        return {}
    end,
}
zombie = {
    EffectsManager = {
        getInstance = function() return nativeEffectsManager end,
    },
    iso = {
        objects = {
            IsoBulletTracerEffects = {
                getInstance = function() return nativeBulletTracerEffects end,
            },
        },
    },
}

PNC.NameplateFirearmAnchor = {
    GetRenderMuzzle = function()
        if not anchorAvailable then return nil, nil, nil end
        return 1234, 5678, {}
    end,
    GetScreenDirection = function()
        return 0.6, 0.8
    end,
}
isServer = function() return false end
isIngameState = function() return true end
T.load(CLIENT_FILE)

T.equal(PNC.ClientFirearmEffects.Play(payload), true, "client shot rendered")
T.equal(played[1], "LiveModdedRifleShot", "live equipped gun sound preferred")
T.equal(played[2], "LiveModdedShellFall", "live equipped shell sound preferred")
T.equal(muzzleFlash, 1, "native muzzle flash used")
T.equal(nativeTracerCalls, 3, "native projectile count rendered")
T.equal(currentUseWeapon, nil, "temporary native weapon state restored")
T.equal(#PNC.ClientFirearmEffects.ActiveLights, 0, "fallback light avoided beside native flash")
T.equal(#PNC.ClientFirearmEffects.ActiveTracers, 0, "fallback tracer avoided beside native tracer")
T.equal(impactSound, "ModdedBulletImpact", "weapon impact sound")
T.equal(PNC.ClientFirearmEffects.Play(payload), false, "duplicate shot ignored")
PNC.ClientFirearmEffects.OnPreUIDraw()
T.equal(rendered, 0, "native tracers bypass screen-space renderer")
PNC.ClientFirearmEffects.OnPreUIDraw()
T.equal(rendered, 0, "native tracers remain outside fallback renderer")
PNC.ClientFirearmEffects.OnTick()
PNC.ClientFirearmEffects.OnTick()
T.equal(#PNC.ClientFirearmEffects.ActiveLights, 0, "muzzle light cleaned")
T.equal(removedLights, 0, "native muzzle light is engine-owned")

-- A tracked shooter must prefer the same relative nameplate anchor used by
-- the coordinate probe, instead of emitting another body-centred native line.
anchorAvailable = true
PNC.Network.FindZombieByOnlineID = function() return body end
local anchoredPayload = {}
for key, value in pairs(payload) do anchoredPayload[key] = value end
anchoredPayload.shotId = "npc_modded_rifle:anchored:1:1100"
T.equal(PNC.ClientFirearmEffects.Play(anchoredPayload), true,
    "tracked anchored shot rendered")
T.equal(muzzleFlash, 1, "tracked anchored shot bypasses native muzzle flash")
T.equal(nativeTracerCalls, 3, "tracked anchored shot bypasses native tracer")
T.equal(PNC.ClientFirearmEffects.ActiveMuzzleFlashes[1].x, 1234,
    "tracked muzzle flash uses the relative anchor")
T.equal(PNC.ClientFirearmEffects.ActiveTracers[1].anchorSource,
    "nameplate_relative", "tracked tracer records the relative anchor source")
PNC.ClientFirearmEffects.Reset()
local selfPayload = {}
for key, value in pairs(anchoredPayload) do selfPayload[key] = value end
selfPayload.shotId = "npc_modded_rifle:self:1:1100"
selfPayload.tx = 10
selfPayload.ty = 20
selfPayload.tz = 0
selfPayload.projectileCount = 1
selfPayload.projectileSpread = 0
T.equal(PNC.ClientFirearmEffects.Play(selfPayload), true,
    "self-targeted anchored shot rendered")
T.truthy(math.abs(PNC.ClientFirearmEffects.ActiveTracers[1].dx - 0.6) < 0.001,
    "self-targeted tracer follows the NPC forward screen X")
T.truthy(math.abs(PNC.ClientFirearmEffects.ActiveTracers[1].dy - 0.8) < 0.001,
    "self-targeted tracer follows the NPC forward screen Y")
PNC.ClientFirearmEffects.Reset()
lightCreated = 0

PNC.Network.FindZombieByOnlineID = function() return nil end
local remotePayload = {}
for key, value in pairs(payload) do remotePayload[key] = value end
remotePayload.shotId = "npc_modded_rifle:remote:2:1100"
remotePayload.shellFallSound = nil
T.equal(PNC.ClientFirearmEffects.Play(remotePayload), true, "unresolved remote shot rendered")
T.equal(freeEmitterSound, "ModdedRifleShot", "remote positional emitter uses packet weapon sound")
T.equal(lightCreated, 1, "Bandits-compatible muzzle light created")
T.equal(lastLight.args[8], 1, "muzzle light uses one-tick lifetime")
T.equal(lastLight.args[4], 0.78, "muzzle light uses softened red channel")
T.equal(lastLight.args[5], 0.68, "muzzle light uses softened green channel")
T.equal(lastLight.args[6], 0.52, "muzzle light uses softened blue channel")
T.equal(lastLight.args[7], 9, "muzzle light uses reduced radius")
T.equal(#PNC.ClientFirearmEffects.ActiveMuzzleFlashes, 1,
    "fallback muzzle flash queued at the weapon-forward point")
T.equal(#PNC.ClientFirearmEffects.ActiveTracers, 3, "fallback tracers queued")
T.equal(PNC.ClientFirearmEffects.ActiveMuzzleFlashes[1].x, 1234,
    "fallback muzzle flash uses cached nameplate anchor")
T.equal(PNC.ClientFirearmEffects.ActiveMuzzleFlashes[1].y, 5678,
    "fallback muzzle flash uses cached nameplate shoulder offset")
T.equal(PNC.ClientFirearmEffects.ActiveTracers[1].x, 1234,
    "fallback tracer uses cached nameplate anchor")
T.equal(PNC.ClientFirearmEffects.ActiveTracers[1].y, 5678,
    "fallback tracer uses cached nameplate shoulder offset")
PNC.ClientFirearmEffects.OnPreUIDraw()
T.equal(rendered > 0, true, "fallback firearm effects rendered")
T.truthy(renderLines[1], "fallback muzzle/tracer renderline submitted")
T.truthy(renderLines[1].x1 ~= renderLines[1].x2
    or renderLines[1].y1 ~= renderLines[1].y2,
    "fallback renderline has visible trajectory")
local cappedPayload = {}
for key, value in pairs(remotePayload) do cappedPayload[key] = value end
cappedPayload.shotId = "npc_modded_rifle:remote:3:1100"
cappedPayload.projectileCount = 16
T.equal(PNC.ClientFirearmEffects.Play(cappedPayload), true,
    "high-count fallback shot rendered")
T.equal(#PNC.ClientFirearmEffects.ActiveTracers, 8,
    "fallback visual projectile budget caps a high-count shot")
T.equal(lightCreated, 2,
    "fallback light budget limits world lights in a burst")
T.truthy(auditEvents.play_start, "firearm audit recorded client entry")
T.truthy(auditEvents.muzzle_light_complete, "firearm audit recorded muzzle light")
T.truthy(auditEvents.tracer_screen_queue_complete, "firearm audit recorded tracer queue")
T.truthy(auditEvents.draw_begin, "firearm audit recorded draw entry")
T.truthy(auditEvents.draw_renderline_complete, "firearm audit recorded renderline")

PNC.ClientFirearmEffects.Reset()
T.equal(
    PNC.ClientFirearmEffects.SimulateShot(body, "debug_npc", 0),
    true,
    "debug firearm simulation renders without authority or weapon state"
)
T.equal(PNC.ClientFirearmEffects.ActiveMuzzleFlashes[1].x, 1234,
    "debug simulation uses cached muzzle anchor")
T.equal(PNC.ClientFirearmEffects.ActiveMuzzleFlashes[1].anchorSource,
    "nameplate_relative",
    "debug simulation records the nameplate anchor source")
T.equal(PNC.ClientFirearmEffects.ActiveTracers[1].x, 1234,
    "debug simulation starts tracer at cached muzzle anchor")
PNC.ClientFirearmEffects.Reset()
now = 1000
T.equal(
    PNC.ClientFirearmEffects.ToggleSimulation(body, "debug_npc", 0),
    true,
    "debug firearm simulation toggles on"
)
T.truthy(
    PNC.ClientFirearmEffects.IsSimulationActive(body, "debug_npc"),
    "debug firearm simulation remains active"
)
now = 1500
PNC.ClientFirearmEffects.OnTick()
T.equal(#PNC.ClientFirearmEffects.ActiveTracers, 2,
    "active firearm simulation emits a repeated tracer")
T.equal(
    PNC.ClientFirearmEffects.ToggleSimulation(body, "debug_npc", 0),
    false,
    "debug firearm simulation toggles off"
)
T.falsy(
    PNC.ClientFirearmEffects.IsSimulationActive(body, "debug_npc"),
    "debug firearm simulation stops emitting"
)
T.finish("pnc_firearm_effects_smoke")
